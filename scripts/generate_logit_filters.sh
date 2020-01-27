#!/usr/bin/env bash

# Pull together the various components of the logstash filters from their various sources
# and combine them into a single file for consumption by logit.

set -eo pipefail

echo "${0#$PWD}" >> ~/.paas-script-usage

logsearch_boshrelease_tag=$1
logsearch_for_cloudfoundry_tag=$2

if [ -z "${logsearch_boshrelease_tag}" ]
then
    echo "logsearch boshrelease tag not set."
    exit 1
fi

if [ -z "${logsearch_for_cloudfoundry_tag}" ]
then
    echo "logsearch for cloudfoundry tag not set."
    exit 1
fi

set -u

apk update && apk add git

cd /tmp
git clone --branch="${logsearch_for_cloudfoundry_tag}" --depth=1 https://github.com/cloudfoundry-community/logsearch-for-cloudfoundry.git
cd logsearch-for-cloudfoundry/src/logsearch-config
bundle install
bundle exec rake build

# Remove the following stanza as it's not supported in the context of logit.
# mutate {
#   add_field => { "[@metadata][index]" => "%{@index_type}" }
# }
sed -i '/^ *mutate *{/{N;N;s/^ *mutate *{\n *add_field.*index_type}" *}\n *}//;}' /tmp/logsearch-for-cloudfoundry/src/logsearch-config/target/logstash-filters-default.conf

wget -q -O /tmp/redact_passwords.conf "https://raw.githubusercontent.com/cloudfoundry-community/logsearch-boshrelease/${logsearch_boshrelease_tag}/src/logsearch-config/src/logstash-filters/snippets/redact_passwords.conf"
wget -q -O /tmp/syslog_standard.conf "https://raw.githubusercontent.com/cloudfoundry-community/logsearch-boshrelease/${logsearch_boshrelease_tag}/src/logsearch-config/src/logstash-filters/snippets/syslog_standard.conf"

echo "filter {" > /output/generated_logit_filters.conf
{
    sed 's/^/  /' < /mnt/config/logit/10_base.conf
    sed 's/^/  /' < /tmp/redact_passwords.conf
    sed 's/^/  /' < /tmp/syslog_standard.conf
    sed 's/^/  /' < /mnt/config/logit/11_app_syslog_drain.conf
    sed 's/^/  /' < /tmp/logsearch-for-cloudfoundry/src/logsearch-config/target/logstash-filters-default.conf
    sed 's/^/  /' < /mnt/config/logit/20_custom_cf_filters.conf
    sed 's/^/  /' < /mnt/config/logit/21_paas_billing_filters.conf
    echo "}"
} >> /output/generated_logit_filters.conf

sed -i 's/^ *$//g' /output/generated_logit_filters.conf

sed -i \
    "s/if \[@source\]\[component\] != \"vcap.uaa\".*/if [@source][component] != \"uaa\" and [@source][component] != \"app\" {/" \
    /output/generated_logit_filters.conf

sed -i \
    "s/if \[@index_type\] == \"platform\" {/if [@index_type] == \"platform\" and [@source][component] != \"app\" {/" \
    /output/generated_logit_filters.conf

sed -i \
    "s/vcap\.uaa/uaa/" \
    /output/generated_logit_filters.conf
