#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"

check_aws_account_used prod
check_logged_in_cf api.cloud.service.gov.uk

"${SCRIPT_DIR}"/reset-org.py \
	-o paas_user_research \
	-s sandbox \
	-u \
	holly.challenger+1@digital.cabinet-office.gov.uk \
	holly.challenger+2@digital.cabinet-office.gov.uk \
	holly.challenger+3@digital.cabinet-office.gov.uk \
	holly.challenger+4@digital.cabinet-office.gov.uk \
	holly.challenger+5@digital.cabinet-office.gov.uk \
	holly.challenger+6@digital.cabinet-office.gov.uk \
	--org-managers \
	--space-managers \
	--space-developers \
	--quota small

"${SCRIPT_DIR}"/rotate-user-password.sh -e prod -u holly.challenger+1@digital.cabinet-office.gov.uk
"${SCRIPT_DIR}"/rotate-user-password.sh -e prod -u holly.challenger+2@digital.cabinet-office.gov.uk
"${SCRIPT_DIR}"/rotate-user-password.sh -e prod -u holly.challenger+3@digital.cabinet-office.gov.uk
"${SCRIPT_DIR}"/rotate-user-password.sh -e prod -u holly.challenger+4@digital.cabinet-office.gov.uk
"${SCRIPT_DIR}"/rotate-user-password.sh -e prod -u holly.challenger+5@digital.cabinet-office.gov.uk
"${SCRIPT_DIR}"/rotate-user-password.sh -e prod -u holly.challenger+6@digital.cabinet-office.gov.uk
