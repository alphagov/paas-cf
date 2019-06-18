#!/usr/bin/env bash

set -euo pipefail

usage() { echo "Usage: $0 [-s]" 1>&2; exit 1; }

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

SUBSHELL=false
while getopts "s,subshell" o; do
	case "${o}" in
		s)
			SUBSHELL=true
			;;

		*)
			usage
			;;
	esac
done

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"
check_aws_account_used dev

API_URL="https://api.${DEPLOY_ENV}.dev.cloudpipeline.digital"

# shellcheck disable=SC2091
$("${SCRIPT_DIR}/show-vars-store-secrets.sh" cf-vars-store cf_admin_password)

if [ $SUBSHELL == true ]; then
	TMPDIR=${TMPDIR:-/tmp}
	CF_HOME=$(mktemp -d "${TMPDIR}/cf_home.XXXXXX")
	cleanup() {
	  echo "Cleaning up temporary CF_HOME..."
	  cf logout || true
	  rm -r "${CF_HOME}"
	}
	trap 'cleanup' EXIT

	mkdir -p "${HOME}/.cf/plugins" "${CF_HOME}/.cf"
	ln -s "${HOME}/.cf/plugins" "${CF_HOME}/.cf/plugins"

	export CF_HOME
	export CF_SUBSHELL_TARGET=$DEPLOY_ENV
fi

cf api "$API_URL"
cf login -u admin -p "${CF_ADMIN_PASSWORD}"


if [ $SUBSHELL == true ]; then
	echo
	echo "You are now in a subshell with CF_HOME set to ${CF_HOME}"
	echo "This will be cleaned up when this shell is closed."
	echo
	${SHELL:-bash} -il
fi
