#!/bin/bash
set -euo pipefail
SCRIPT=$0

###########################################################################
# Defaults
DEFAULT_SPACE=sandbox
FROM_ADDRESS='the-multi-cloud-paas-team@digital.cabinet-office.gov.uk'
# shellcheck disable=SC2016
SUBJECT='Welcome to the Government PaaS'
# shellcheck disable=SC2016,SC1078
MESSAGE='Hello,

Your account has been created for the  Government PaaS service.

Your organisation is \"${ORG}\" and your login and password:

 - login: ${EMAIL}
 - password: ${PASSWORD}

To get started you can follow our Quick Setup Guide:
https://government-paas-developer-docs.readthedocs.io/en/latest/getting_started/quick_setup_guide/

Regards,
Government PaaS team.
'


###########################################################################
usage() {
  cat <<EOF
Usage:

  $SCRIPT [-r] [-m] -e <email> -c <email> -o <orgname>

$SCRIPT will create a user and organisation in the CF service where you
are currently logged in and send an email to the user if the password changes.

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

  -c <email>   The email addresses of copy recipients

  -o <orgname> Organisation to create and add the user to. If the
               organisation already exists the script will carry on.

EOF
  exit 1
}

load_colors() {
  if [ -t 1 ] ; then
    export ESC_SEQ="\x1b["
    export COL_RESET="${ESC_SEQ}39;49;00m"
    export COL_LIGHT="${ESC_SEQ}1m"
    export COL_DIM="${ESC_SEQ}2m"
    export COL_BLINK="${ESC_SEQ}5m"
    export COL_RED="${ESC_SEQ}31m"
    export COL_GREEN="${ESC_SEQ}32m"
    export COL_YELLOW="${ESC_SEQ}33m"
    export COL_BLUE="${ESC_SEQ}34m"
    export COL_MAGENTA="${ESC_SEQ}35m"
    export COL_CYAN="${ESC_SEQ}36m"
  fi
}

abort() {
  echo -e "${COL_RED:-}${COL_LIGHT:-}ERROR:${COL_RESET:-} $*" 1>&2
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

  local email_expr="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$"
  if ! [[ "${EMAIL}" =~ ${email_expr} ]]; then
    abort "You must specify a valid email"
  fi

  if [ -z "${ORG:-}" ]; then
    abort_usage "Org must be defined"
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
}

create_user() {
  if [[ "${RESET_USER}" == "true" ]]; then
    cf delete-user "${EMAIL}" -f
  fi

  if cf create-user "${EMAIL}" "${PASSWORD}" | tee "${TMP_OUTPUT}"; then
    if ! grep -q "already exists" "${TMP_OUTPUT}"; then
      SEND_EMAIL=true
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
  if [[ "${SEND_EMAIL}" == "true" ]]; then
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
    AWS=$(which aws)
    AWSSES="$AWS ses send-email --to ${EMAIL}"
    if "${SEND_CC_EMAIL}"; then
      AWSSES="${AWSSES} --cc ${CC_EMAIL}"
    fi
    AWSSES="$AWSSES --from ${FROM_ADDRESS} --region eu-west-1 --output text --message"
    ${AWSSES} "${MESSAGE_JSON}"

    echo "An email has been sent to ${EMAIL} with their new credentials."
  else
    echo "User was already present and has not been recreated. No mail sent."
  fi
}


TMP_OUTPUT="$(mktemp -t create-tenant-output.XXXXXX)"
trap 'rm -f "${TMP_OUTPUT}"' EXIT

RESET_USER=false
SEND_EMAIL=false
ORG_MANAGER=false
SEND_CC_EMAIL=false

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -o|--org)
      ORG="$2"
      shift # past argument
    ;;
    -e|--email)
      EMAIL="$2"
      shift # past argument
    ;;
    -c|--cc)
      CC_EMAIL="$2"
      SEND_CC_EMAIL=true
      shift # past argument
    ;;
      -r|--reset-user)
      RESET_USER=true
    ;;
      -m|--manager)
      ORG_MANAGER=true
    ;;
    *)
      # unknown option
      usage
    ;;
  esac
  shift # past argument or value
done

load_colors
check_params_and_environment

generate_password
create_org_space
create_user
set_user_roles
send_mail
