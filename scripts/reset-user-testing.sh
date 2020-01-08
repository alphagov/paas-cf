#!/bin/bash

set -euo pipefail

echo "${0#$PWD}" >> ~/.paas-script-usage

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

TARGET_EMAIL_USER=${TARGET_EMAIL_USER:-holly.challenger}
TARGET_ENVIRONMENT=${TARGET_ENVIRONMENT:-prod}
TARGET_ENVIRONMENT_API=${TARGET_ENVIRONMENT_API:-api.cloud.service.gov.uk}

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"

check_aws_account_used "${TARGET_ENVIRONMENT}"
check_logged_in_cf "${TARGET_ENVIRONMENT_API}"

"${SCRIPT_DIR}"/reset-org.py \
	-o paas_user_research \
	-s sandbox \
	-u \
	"${TARGET_EMAIL_USER}+1@digital.cabinet-office.gov.uk" \
	"${TARGET_EMAIL_USER}+2@digital.cabinet-office.gov.uk" \
	"${TARGET_EMAIL_USER}+3@digital.cabinet-office.gov.uk" \
	"${TARGET_EMAIL_USER}+4@digital.cabinet-office.gov.uk" \
	"${TARGET_EMAIL_USER}+5@digital.cabinet-office.gov.uk" \
	"${TARGET_EMAIL_USER}+6@digital.cabinet-office.gov.uk" \
	--org-managers \
	--space-managers \
	--space-developers \
	--quota small

"${SCRIPT_DIR}"/create-user.sh -r -m -o paas_user_research -e "${TARGET_EMAIL_USER}+1@digital.cabinet-office.gov.uk"
"${SCRIPT_DIR}"/create-user.sh -r -m -o paas_user_research -e "${TARGET_EMAIL_USER}+2@digital.cabinet-office.gov.uk"
"${SCRIPT_DIR}"/create-user.sh -r -m -o paas_user_research -e "${TARGET_EMAIL_USER}+3@digital.cabinet-office.gov.uk"
"${SCRIPT_DIR}"/create-user.sh -r -m -o paas_user_research -e "${TARGET_EMAIL_USER}+4@digital.cabinet-office.gov.uk"
"${SCRIPT_DIR}"/create-user.sh -r -m -o paas_user_research -e "${TARGET_EMAIL_USER}+5@digital.cabinet-office.gov.uk"
"${SCRIPT_DIR}"/create-user.sh -r -m -o paas_user_research -e "${TARGET_EMAIL_USER}+6@digital.cabinet-office.gov.uk"
