#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT=$0

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"

###########################################################################
# Defaults
DEFAULT_SPACE=sandbox
FROM_ADDRESS='gov-uk-paas-support@digital.cabinet-office.gov.uk'
# shellcheck disable=SC2016
SUBJECT='Welcome to the Government PaaS'
# shellcheck disable=SC2016,SC1078
MESSAGE='Hello,

Your account for the Government PaaS service has been created.

Your organisation is \"${ORG}\" and your login and password are:

 - login: ${EMAIL}
 - password: ${PASSWORD}

To get started, look at our Quick Setup Guide:
https://docs.cloud.service.gov.uk/#quick-setup-guide

You should make sure to change your password, as explained in the Quick Setup Guide.

You can find our privacy policy here:
https://docs.cloud.service.gov.uk/#privacy-policy

Regards,
Government PaaS team.
'
NOTIFICATION='
As the account has been created now please remeber to update gov-uk-paas-announce
mailing list. You can do that by inviting the user to the group by usng this URL:

https://groups.google.com/a/digital.cabinet-office.gov.uk/forum/#!managemembers/gov-uk-paas-announce/invite

As a welcome message you can use the text from here:
https://groups.google.com/a/digital.cabinet-office.gov.uk/forum/#!forum/gov-uk-paas-announce
'

###########################################################################
usage() {
  cat <<EOF
Usage:

  $SCRIPT [-r] [-m] -e <email> -o <orgname> [--no-email]

$SCRIPT will create a user and organisation in the CF service where you
are currently logged in and send an email to the user if the password changes.

To print the password instead of emailing, supply the '--no-email' flag (useful for development)

Nothing will change if the organisation or the user already exists
(unless the -r flag is used, which recreates the user with a new password).
This way you can add a user to multiple organisations by running the script
multiple times.

Requirements:

 * You must login with the cf client with an "admin" user.
 * You must have a functional aws client with credentials configured.

Where:
  -r           Delete/recreate the user. The user will be recreated
               and the password reset.

  -m           Make the user an Org Manager

  -e <email>   User email to add and configure as organization and
               space manager. If the user is created or recreated,
               they will receive a mail with the new password.

  -o <orgname> Organisation to create and add the user to. If the
               organisation already exists the script will carry on.

EOF
  exit 1
}

abort_usage() {
  echo -e "${COL_RED:-}${COL_LIGHT:-}ERROR:${COL_RESET:-} $*" 1>&2
  usage
  exit 1
}

check_params_and_environment() {
  if [ -z "${EMAIL:-}" ]; then
    abort_usage "Email must be defined"
  fi

  local email_expr="^[A-Za-z0-9._%+\'-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$"
  if ! [[ "${EMAIL}" =~ ${email_expr} ]]; then
    abort "You must specify a valid email"
  fi

  if [ -z "${ORG:-}" ]; then
    abort_usage "Org must be defined"
  fi

  if ! cf orgs >/dev/null 2>&1; then
    abort "You need to be logged into CF CLI"
  fi

  if ! aws ses get-send-quota >/dev/null 2>&1; then
    abort "You must have AWS cli installed and configured with valid credentials. Test it with: aws ses get-send-quota"
  fi

}

generate_password() {
  PASSWORD=$(LC_CTYPE=C tr -cd '[:alpha:]0-9.,;:!?_/-' < /dev/urandom | head -c32 || true)
  if [[ -z "${PASSWORD}" ]]; then
    abort "Failure generating password"
  fi
}

create_org_space() {
  cf create-org "${ORG}"
  cf create-space "${DEFAULT_SPACE}" -o "${ORG}"

  # cf create-{org|space} has the side-effect of giving roles in the org/space
  # to the user making the request. We don't want this, so have to undo it.
  local admin_user
  admin_user=$(cf target | awk '/User:/ { print $2}')
  cf unset-org-role "${admin_user}" "${ORG}" OrgManager
  cf unset-space-role "${admin_user}" "${ORG}" "${DEFAULT_SPACE}" SpaceManager
  cf unset-space-role "${admin_user}" "${ORG}" "${DEFAULT_SPACE}" SpaceDeveloper

  # Even after losing all the roles, user is still present in the list of all users of an org
  # FIXME: remove this fix for https://github.com/cloudfoundry/cli/issues/781 is deployed
  guid=$(cf org "${ORG}" --guid)
  cf curl -X DELETE "/v2/organizations/${guid}/users" -d "{\"username\": \"${admin_user}\"}"
}

create_user() {
  if [[ "${RESET_USER}" == "true" ]]; then
    if cf delete-user "${EMAIL}" -f 2>&1 | tee "${TMP_OUTPUT}"; then
      if grep -q "does not exist" "${TMP_OUTPUT}"; then
        abort "Trying to reset password for non-existing user. Is someone trying to trick you into getting an account?"
      fi
    fi
  fi

  if cf create-user "${EMAIL}" "${PASSWORD}" 2>&1 | tee "${TMP_OUTPUT}"; then
    if ! grep -q "already exists" "${TMP_OUTPUT}"; then
      USER_CREATED=true
    fi
  else
    abort "Error creating user ${EMAIL}"
  fi
}

set_user_roles() {
  if [[ "${ORG_MANAGER}" == "true" ]]; then
    cf set-org-role "${EMAIL}" "${ORG}" OrgManager
    cf set-space-role "${EMAIL}" "${ORG}" "${DEFAULT_SPACE}" SpaceManager
  fi
  cf set-space-role "${EMAIL}" "${ORG}" "${DEFAULT_SPACE}" SpaceDeveloper
}

# Expand variables from subject, escaping quotes
get_subject() {
  eval "echo ${SUBJECT}" | \
    awk '{gsub(/"/, "\\\""); print }'
}

# Expand variables from message body, escaping new lines and quotes
get_body() {
  eval "echo \"${MESSAGE}\"" | \
    awk '{gsub(/"/, "\\\""); printf "%s\\n", $0}'
}

send_mail() {
  MESSAGE_JSON="
  {
    \"Subject\": {
      \"Data\": \"$(get_subject)\",
      \"Charset\": \"utf8\"
    },
    \"Body\": {
      \"Text\": {
        \"Data\": \"$(get_body)\",
        \"Charset\": \"utf8\"
      }
    }
  }
  "

  aws ses send-email \
    --destination "{ \"ToAddresses\": [\"${EMAIL}\"] }" \
    --message "${MESSAGE_JSON}"\
    --from "${FROM_ADDRESS}"  \
    --region eu-west-1 \
    --output text > /dev/null

  echo "An email has been sent to ${EMAIL} with their new credentials."
  show_notification
}

print_password() {
  success "${EMAIL} has had their password changed to ${PASSWORD}"
}

emit_password() {
  if [ "${USER_CREATED}" = "true" ]; then
    if [ "${NO_EMAIL:-}" = "true" ]; then
      print_password
    else
      send_mail
    fi
  else
    echo "No new users created. Use -r to force password reset for existing users."
  fi
}

show_notification() {
    echo
    info "${NOTIFICATION}"
}

TMP_OUTPUT="$(mktemp -t create-tenant-output.XXXXXX)"
trap 'rm -f "${TMP_OUTPUT}"' EXIT

RESET_USER=false
USER_CREATED=false
ORG_MANAGER=false

while [[ $# -gt 0 ]]; do
  key="$1"
  shift
  case $key in
    -o|--org)
      ORG="$1"
      shift
    ;;
    -e|--email)
      EMAIL="$1"
      shift
    ;;
    -r|--reset-user)
      RESET_USER=true
    ;;
    -m|--manager)
      ORG_MANAGER=true
    ;;
    --no-email)
      NO_EMAIL=true
    ;;
    *)
      # unknown option
      usage
    ;;
  esac
done

load_colors
check_params_and_environment

generate_password
create_org_space
create_user
set_user_roles
emit_password
