#!/bin/sh

set -eu

splay=$((60*20))
# The following sleep monstrosity deterministically sleeps for a
# period of time between 0-${splay} seconds in order to prevent all our
# deletion jobs running at the same time. See the commit message for
# how it works.

sum=$(echo "${DEPLOY_ENV}" | md5sum);
short=$(echo "${sum}" | cut -b 1-15)
decimal=$((0x${short}));
sleeptime=$((${decimal##-} % splay));
echo "Sleeping for ${sleeptime} seconds before continuing..."
sleep ${sleeptime}
