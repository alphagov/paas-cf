# Cloud Foundry usage reporting

These are some temporary tools for us to figure out usage for billing.

## `dump_cf_events`

To generate file dumps of usage events from Cloud Foundry before they are purged
by `cutoff_age_in_days`. This is useful to run at the end of the month while
we're not exporting the data in an automated way.

Example:
```
cf login …
./dump_cf_events.py
```

## `process_events`

To generate spreadsheet-friendly data from usage events:

- http://apidocs.cloudfoundry.org/258/app_usage_events/list_all_app_usage_events.html
- http://apidocs.cloudfoundry.org/258/service_usage_events/list_service_usage_events.html

Example:
```
go run event.go process_events.go \
  -org "<ORG_UUID>" \
  -start "2017-10-01T00:00:00Z" \
  -finish "2017-11-01T00:00:00Z" \
  < events.json \
  | tee usage.csv
```

## `generate_service_events`

To generate usage events for service instances that were created prior
`cutoff_age_in_days` and are still running. You will need to manually merge
these with dump of service usage events to make sure that orgs aren't double
billed for services that they created within the month.

This isn't needed after we set a billing epoch and regularly extract the
data:

- http://apidocs.cloudfoundry.org/258/app_usage_events/purge_and_reseed_app_usage_events.html
- http://apidocs.cloudfoundry.org/258/service_usage_events/purge_and_reseed_service_usage_events.html

Example:
```
cf login …
go get github.com/cloudfoundry-community/go-cfclient
go run event.go generate_service_events.go \
  -api "$(cf target | awk '/api endpoint/ { print $NF }')" \
  -token "$(cf oauth-token | awk '{ print $2 }')" \
  -org "<ORG_UUID>" \
  -start "2017-04-01T00:00:00Z" \
  -finish "2017-05-01T00:00:00Z" \
  | tee events.json
```
