# What

This directory contains the logstash filters to be used in logit.io to parse
the logs from our Cloud Foundry platform.

The scripts are based on
 - Upstream [logsearch filters](https://github.com/cloudfoundry-community/logsearch-boshrelease/tree/develop/src/logsearch-config/src/logstash-filters)
 - [logsearch-for-cloudfoundry filters](https://github.com/cloudfoundry-community/logsearch-for-cloudfoundry)
 - Custom filters added adhoc by us.

These filters can be manually updated in the logit interface. To generate the filters or update them, follow the instructions in this file.

## How to generate the Logit Logstash filters

Ensure the `LOGSEARCH_BOSHRELEASE_TAG` and `LOGSEARCH_FOR_CLOUDFOUNDRY_TAG` variables towards the top of the `Makefile` have the correct values. Run `make logit-filters` from the paas-cf directory. This uses docker to update `config/logit/output/generated_logit_filters.conf`.

## Component configuration files

### 10\_base.conf

This contains the base filters. It's based on the upstream
[filters_pre.conf.erb](https://github.com/cloudfoundry-community/logsearch-boshrelease/blob/v205.0.1/jobs/parser/templates/config/filters_pre.conf.erb)
file modified as follows so that it can be used in Logit:

  - remove the ERB template blocks
  - replace the first alter {} block with this:

   ```
   mutate {
     add_field => [ "type", "syslog" ]
   }
   ```

  - remove all ruby {} blocks

### 20\_custom\_filters.conf

You can add custom filters in this file.
