#!/bin/sh
set -e

APPNAME=$1
VERSION=$(git rev-parse --short HEAD)
CURRENT=$(cf apps | grep -E "^${APPNAME}-${VERSION}" | cat)
OTHERS=$(cf apps | grep -o -E "^${APPNAME}[^ ]*" | grep -E -v "^${APPNAME}-${VERSION}" | cat)

# Delete all other running instances of this app
if [ "$OTHERS" != "" ]; then
    echo "$OTHERS" | xargs -n1 cf delete -f
fi

# And if this version is missing, push it
if [ "$CURRENT" = "" ]; then
    cf push "${APPNAME}-${VERSION}"
fi
