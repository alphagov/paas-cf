#!/bin/bash
set -eu

SCRIPT=$0

usage() {
   cat <<EOF
Usage:

   $SCRIPT <pipeline> <config> <varsfile>

Being:

   pipeline		pipeline name
   config		config for the pipeline
   varsfile     concourse variables to pass to the pipeline

EOF
   exit 1
}

if [ $# -lt 3 ]; then
   usage
fi

pipeline=$1; shift
config=$1; shift
varsfile=$1; shift

echo "Concourse API target ${FLY_TARGET}"
echo "Pipeline ${pipeline}"
echo "Config file ${config}"

yes y | \
   $FLY_CMD -t "${FLY_TARGET}" \
   set-pipeline \
   --config "${config}" \
   --pipeline "${pipeline}" \
   --load-vars-from "${varsfile}"

$FLY_CMD -t "${FLY_TARGET}" \
  unpause-pipeline \
  --pipeline "${pipeline}"

if [ -n "${EXPOSE_PIPELINE:-}" ]; then
  $FLY_CMD -t "${FLY_TARGET}" \
    expose-pipeline \
    --pipeline "${pipeline}"
fi
