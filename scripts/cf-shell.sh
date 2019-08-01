#!/bin/bash
PAAS_CF_DIR=${PAAS_CF_DIR:-"$GOPATH/src/github.com/alphagov/paas-cf"}

ARGS=""
SCRIPT="$0"
usage() {
  cat <<EOF
Usage: $SCRIPT [-f] DEPLOY_ENV

Log in to any GOV.UK PaaS environemnt, optionally forcing the login to happen
inside a subshell.

Supported DEPLOY_ENV values:
  prod      Production Cloud Foundry deployment in Ireland (subshell forced)
  prod-lon  Production Cloud Foundry deployment in London (subshell forced)
  stg-lon   Staging Cloud Foundry deployment in London (subshell forced)
  *         Assumed as a development Cloud Foundry deployment

Options:
  -f  Force the use of a subshell
EOF
  exit 1;
}

while getopts "f" o; do
	case "${o}" in
		f)
			ARGS+=" -s"
			;;

		*)
			usage
			;;
	esac
done

if [ -z "$1" ]; then
  usage;
fi

shift $((OPTIND - 1))

if [ "${1}" == "prod" ] ||  [ "${1}" == "prod-lon" ] ||  [ "${1}" == "stg-lon" ] ; then
  "${PAAS_CF_DIR}/scripts/cf_subshell_scoped_login.sh" "${1}"
else
  eval "DEPLOY_ENV=${1} gds aws paas-dev -- $PAAS_CF_DIR/scripts/cf_admin_login_dev.sh ${ARGS}"
fi
