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
SUBJECT='Your GOV.UK PaaS account'
# shellcheck disable=SC2016,SC1078
MESSAGE='Hello,

We'"'"'ve noticed that you have not yet reset the password for your GOV.UK PaaS
account since it was first created.

To keep your account secure, please follow this link to activate it and set
a new password: ${INVITE_URL}

This link will only work once.

If you do not activate your account within 7 days it will automatically be
locked. If you wish to reactivate it after this time, please email us at
gov-uk-paas-support@digital.cabinet-office.gov.uk

If you’ve not yet signed up to our mailing list to receive important
notifications about GOV.UK PaaS, please do so here:
https://groups.google.com/a/digital.cabinet-office.gov.uk/forum/#!forum/gov-uk-paas-announce

You can find advice about choosing a password:
https://docs.cloud.service.gov.uk/#choosing-passwords

To get started, look at our Quick Setup Guide:
https://docs.cloud.service.gov.uk/#quick-setup-guide

You can find our privacy policy here:
https://docs.cloud.service.gov.uk/#privacy-policy

Regards,
GOV.UK PaaS team

PS Some departmental email systems will check links in inbound emails as
part of their virus protection. This may have invalidated your one-time
link. If this is the case please contact support to set your password
another way.
'

###########################################################################
usage() {
  cat <<EOF
Usage:

  $SCRIPT [-r] [-m] -e <email> -o <orgname> [--no-email]

$SCRIPT will create a user and organisation in the CF service where you
are currently logged in and send an email to the user with an invite URL if
they didn't previously have an account.

To print the invite URL instead of emailing, supply the '--no-email' flag (useful for development)

Nothing will change if the organisation or the user already exists. This way
you can add a user to multiple organisations by running the script multiple
times.

Requirements:

 * You must login with the cf client with an "admin" user.
 * You must have a functional aws client with credentials configured.

Where:
  -r           Mark the user as "unverified" and send a new invite link.

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

  if ! jq -V >/dev/null 2>&1; then
    abort "You need to have jq installed"
  fi

  if ! cf orgs >/dev/null 2>&1; then
    abort "You need to be logged into CF CLI"
  fi

  if ! aws ses get-send-quota >/dev/null 2>&1; then
    abort "You must have AWS cli installed and configured with valid credentials. Test it with: aws ses get-send-quota"
  fi

}

create_user() {
  export INVITE_URL
  local uaa_endpoint auth_token ssl_arg uaa_uuid

  uaa_endpoint=$(cf curl /v2/info | jq -er '.authorization_endpoint')
  auth_token=$(cf oauth-token)
  ssl_arg=$(if jq -e '.SSLDisabled == true' ~/.cf/config.json >/dev/null; then echo "-k"; fi)

  curl -sf "${ssl_arg}" \
    -H "Authorization: ${auth_token}" \
    -H "Accept: application/json" -H "Content-Type: application/json" \
    -G --data-urlencode "filter=userName eq \"${EMAIL}\"" \
    "${uaa_endpoint}/Users" >"${TMP_OUTPUT}"

  if jq -e '.resources | length > 1' "${TMP_OUTPUT}" >/dev/null; then
    cat "${TMP_OUTPUT}"
    abort "Multiple UAA users found for: ${EMAIL}"
  fi

  if jq -e '.resources | length == 1' "${TMP_OUTPUT}" >/dev/null; then
    uaa_uuid=$(jq -er '.resources[0].id' "${TMP_OUTPUT}")

    if [[ "${RESET_USER}" == "true" ]]; then
      curl -sf "${ssl_arg}" \
        -X PATCH \
        -H "Authorization: ${auth_token}" \
        -H "Accept: application/json" -H "Content-Type: application/json" \
        -H "If-Match: *" \
        -d "{\"verified\": false}" \
        "${uaa_endpoint}/Users/${uaa_uuid}" >"${TMP_OUTPUT}"
    fi
  fi

  if [[ -z "${uaa_uuid}" ]] && [[ "${RESET_USER}" == "true" ]]; then
    abort "Trying to reset invite for non-existing user. Is someone trying to trick you into getting an account?"
  fi

  if [[ -z "${uaa_uuid}" ]] || [[ "${RESET_USER}" == "true" ]]; then
    curl -sf "${ssl_arg}" \
      -X POST \
      -H "Authorization: ${auth_token}" \
      -H "Accept: application/json" -H "Content-Type: application/json" \
      -d "{\"emails\": [\"${EMAIL}\"]}" \
      "${uaa_endpoint}/invite_users?redirect_uri=" >"${TMP_OUTPUT}"

    if ! jq -e '.new_invites | length == 1' "${TMP_OUTPUT}" >/dev/null; then
      cat "${TMP_OUTPUT}"
      abort "Error creating invite for ${EMAIL}"
    fi

    uaa_uuid=$(jq -er '.new_invites[0].userId' "${TMP_OUTPUT}")
    INVITE_URL=$(jq -er '.new_invites[0].inviteLink' "${TMP_OUTPUT}")
    USER_CREATED=true
  fi

  cf curl \
    -X POST \
    -d "{\"guid\": \"${uaa_uuid}\"}" \
    /v2/users >"${TMP_OUTPUT}"

  if ! jq -e '(.metadata.guid != null) or (.error_code == "CF-UaaIdTaken")' "${TMP_OUTPUT}" >/dev/null; then
    cat "${TMP_OUTPUT}"
    abort "Error creating user ${EMAIL}"
  fi
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
}

print_invite() {
  success "Created invite ${INVITE_URL} for ${EMAIL}"
}

emit_invite() {
  if [ "${USER_CREATED}" = "true" ]; then
    if [ "${NO_EMAIL:-}" = "true" ]; then
      print_invite
    else
      send_mail
    fi
  else
    echo "No new users created. Use -r to force new invites for existing users."
  fi
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

create_user
emit_invite
