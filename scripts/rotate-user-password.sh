#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT=$(basename "$0")

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"

FROM_ADDRESS='gov-uk-paas-support@digital.cabinet-office.gov.uk'
SUBJECT='Government PaaS Password Reset Request'
# shellcheck disable=SC2016
MESSAGE='Hello,

We have received a request to reset the password associated with this email address.

Your new password is: ${PASSWORD}

For guidance on logging in and changing your password you can visit:
https://docs.cloud.service.gov.uk/#setting-up-the-command-line

You should make sure to change your password, as explained in the documentation in the above link.

Regards,
Government PaaS team.
'

usage() {
  cat <<EOF

Usage:

  ./$SCRIPT -e \$ENV -u \$USERNAME [--no-email]

Example:

  ./$SCRIPT -e prod -u user@example.com

Description:

  This script will generate a new password for an existing user, change their password to the newly generated one, and then email them the password.
  To print the password instead of emailing, supply the '--no-email' flag (useful for development)

Requirements:

  * You must set the \$DEPLOY_ENV environment variable
  * You must have a functional aws client with credentials configured.
  * You must have the UAA Command Line Interface installed
  * The user must already exist

EOF
  exit 1
}

if [[ $# -lt 2 ]]
then
  usage
fi

while [[ $# -gt 1 ]]
do
key="$1"
shift

case $key in
  -e|--env)
  ENVIRONMENT="$1"
  shift
  ;;
  -u|--username)
  USERNAME="$1"
  shift
  ;;
  --no-email)
  NO_EMAIL="true"
  ;;
  *)
  echo "You have passed an unknown option: $key" >&2
  usage
  ;;
esac
done

check_environment() {
  if ! [[ "${ENVIRONMENT:-}" =~ ^(dev|ci|staging|prod)$ ]]; then
    abort "You must supply an -e option with one of: dev|ci|staging|prod"
  fi
}

check_params_and_environment() {

  if [ -z "${USERNAME:-}" ]; then
    echo "Username must be defined." >&2
    usage
  fi

  local email_expr="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$"
  if ! [[ "${USERNAME}" =~ ${email_expr} ]]; then
    abort "The username must be a valid email address"
  fi

  if ! aws ses get-send-quota >/dev/null 2>&1; then
    abort "You must have AWS cli installed and configured with valid credentials. Test it with: aws ses get-send-quota"
  fi

}

check_deploy_env_set() {
  if [ -z "${DEPLOY_ENV:-}" ]; then
    echo "You must set the \$DEPLOY_ENV variable." >&2
    exit 1
  fi
}

set_uaac_target() {
  SKIP_SSL_VALIDATION=""
  case "$ENVIRONMENT" in
    dev)
    TARGET="https://uaa.${DEPLOY_ENV}.dev.cloudpipeline.digital"
    SKIP_SSL_VALIDATION="--skip-ssl-validation"
    ;;
    ci)
    TARGET="https://uaa.${DEPLOY_ENV}.ci.cloudpipeline.digital"
    SKIP_SSL_VALIDATION="--skip-ssl-validation"
    ;;
    staging)
    TARGET="https://uaa.staging.cloudpipeline.digital"
    ;;
    prod)
    TARGET="https://uaa.cloud.service.gov.uk"
    ;;
  esac
  echo
  info "Setting uaac target:"
  echo uaac target "$TARGET" ${SKIP_SSL_VALIDATION}
  uaac target "$TARGET" ${SKIP_SSL_VALIDATION}
}

set_uaac_context() {
  info "Fetching uaa_admin_client_secret using AWS cli."
  echo
  UAA_ADMIN_CLIENT_SECRET=$(aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/cf-secrets.yml" - | awk '/uaa_admin_client_secret/ {print $2}')
  info "Setting uaac client token:"
  echo uaac token client get admin -s REDACTED
  echo
  uaac token client get admin -s "$UAA_ADMIN_CLIENT_SECRET"
}

change_password() {
  info "Changing user password:"
  echo uaac password set "${USERNAME}" -p REDACTED
  uaac password set "${USERNAME}" -p "${PASSWORD}"
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
    --destination "ToAddresses=${USERNAME}" \
    --message "${MESSAGE_JSON}"\
    --from "${FROM_ADDRESS}"  \
    --region eu-west-1 \
    --output text > /dev/null

  success "An email has been sent to ${USERNAME} with their new credentials."
  echo
}

print_password() {
  success "${USERNAME} has had their password changed to ${PASSWORD}"
}

emit_password() {
  if [ "${NO_EMAIL:-}" = "true" ]; then
    print_password
  else
    send_mail
  fi
}

delete_token() {
  info "Deleting your uaac token..."
  uaac token delete
  info "Token deleted"
  echo
}

load_colors
check_deploy_env_set
check_environment
check_params_and_environment
set_uaac_target
set_uaac_context
generate_password
change_password
emit_password
delete_token
