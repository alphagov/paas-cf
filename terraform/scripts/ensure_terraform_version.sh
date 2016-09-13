#!/bin/bash

set -eu
set -o pipefail

MIN_REQUIRED_VERSION=${1-}
if [ -z "${MIN_REQUIRED_VERSION}" ]; then
  echo "Usage: ${0} <min_required_version>"
  exit 1
fi

terraform version | awk -v MinRequiredVersion="${MIN_REQUIRED_VERSION}" '
BEGIN { FS = " v" } # to strip the leading v from the version
NR==1 {
  if ( MinRequiredVersion !~ /^([[:digit:]]{1,4}\.){1,2}[[:digit:]]{1,4}$/ ) {
    print "ERR: Requested terraform version "MinRequiredVersion" is not a valid version number"
    exit 1
  }
  if ( $2 !~ /^([[:digit:]]{1,4}\.){1,2}[[:digit:]]{1,4}$/ ) {
    print "ERR: Matched terraform version "$2" is not a valid version number"
    exit 1
  }

  # Split each version into an array
  split(MinRequiredVersion, RequiredVersArr, ".")
  split($2, ActualVersArr, ".")

  # Translate into a large decimal
  RequiredVersDec = RequiredVersArr[1] * 10^8 + RequiredVersArr[2] * 10^4 + RequiredVersArr[3]
  ActualVersDec = ActualVersArr[1] * 10^8 + ActualVersArr[2] * 10^4 + ActualVersArr[3]

  if ( ActualVersDec < RequiredVersDec ) {
    print "ERR: Terraform version "$2" is less than required version "MinRequiredVersion""
    exit 1
  }
}
'
