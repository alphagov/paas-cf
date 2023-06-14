#!/usr/bin/env bash

# Pull together the various components of the logstash filters from their various sources
# and combine them into a single file for consumption by logit.

set -eo pipefail

echo "${0#$PWD}" >> ~/.paas-script-usage

set -u

# Remove the following stanza as it's not supported in the context of logit.
# mutate {
#   add_field => { "[@metadata][index]" => "%{@index_type}" }
# }
sed -i '/^ *mutate *{/{N;N;s/^ *mutate *{\n *add_field.*index_type}" *}\n *}//;}' /tmp/logsearch-for-cloudfoundry/src/logsearch-config/target/logstash-filters-default.conf

echo "filter {" > /output/generated_logit_filters.conf
{
    sed 's/^/  /' < /mnt/config/logit/filters.d/10_base.conf
    sed 's/^/  /' < /tmp/redact_passwords.conf
    sed 's/^/  /' < /tmp/syslog_standard.conf
    sed 's/^/  /' < /mnt/config/logit/filters.d/11_app_syslog_drain.conf
    sed 's/^/  /' < /tmp/logsearch-for-cloudfoundry/src/logsearch-config/target/logstash-filters-default.conf
    sed 's/^/  /' < /mnt/config/logit/filters.d/20_custom_cf_filters.conf
    sed 's/^/  /' < /mnt/config/logit/filters.d/21_paas_billing_filters.conf
    sed 's/^/  /' < /mnt/config/logit/filters.d/30_various_timestamps.conf
    echo "}"
} >> /output/generated_logit_filters.conf

sed 's/^ *$//g' /output/generated_logit_filters.conf > /output/generated_logit_filters.conf.tmp && \
    mv /output/generated_logit_filters.conf.tmp /output/generated_logit_filters.conf

sed \
    "s/if \[@source\]\[component\] != \"vcap.uaa\".*/if [@source][component] != \"uaa\" and [@source][component] != \"app\" {/" \
    /output/generated_logit_filters.conf > /output/generated_logit_filters.conf.tmp && \
    mv /output/generated_logit_filters.conf.tmp /output/generated_logit_filters.conf

sed \
    "s/if \[@index_type\] == \"platform\" {/if [@index_type] == \"platform\" and [@source][component] != \"app\" {/" \
    /output/generated_logit_filters.conf > /output/generated_logit_filters.conf.tmp && \
    mv /output/generated_logit_filters.conf.tmp /output/generated_logit_filters.conf

sed \
    "s/vcap\.uaa/uaa/" \
    /output/generated_logit_filters.conf > /output/generated_logit_filters.conf.tmp && \
    mv /output/generated_logit_filters.conf.tmp /output/generated_logit_filters.conf

# FIXME: Allowed in Logstash 6
sed '/tag_on_failure.*kv/d' /output/generated_logit_filters.conf > /output/generated_logit_filters.conf.tmp && \
    mv /output/generated_logit_filters.conf.tmp /output/generated_logit_filters.conf
