require "csv"
require "json"

# INSTRUCTIONS
#
# First, you need to run this while logged in with the `cf` CLI. You
# probably want to run this multiple times against all PaaS's
# production envs (e.g., Ireland and London) to get full data.
#
# Second, run `cf target -o admin -s billing`.
# Access the auditor DB using Conduit: `cf conduit auditor-db -- psql`.
# Run the following query to copy the organisation quota updates into
# a CSV file:
# \copy (
#   WITH rows_and_their_previous_quota AS (
#     SELECT
#       *,
#       LAG(quota_definition_guid, 1) OVER (PARTITION BY guid ORDER BY valid_from ASC) AS previous_quota_definition_guid
#     FROM
#       orgs
#     WHERE
#       name !~ '^[A-Z]+-[0-9]+-ORG-'
#       AND name !~ '^CAT-paas-'
#       AND name !~ '^govuk-paas'
#       AND name != 'admin'
#   )
#   SELECT
#     *
#   FROM
#     rows_and_their_previous_quota
#   WHERE
#     quota_definition_guid != previous_quota_definition_guid
#     OR previous_quota_definition_guid IS NULL
#   ORDER BY name ASC, valid_from ASC;
# ) TO '/tmp/org-quota-changes.csv' (format csv, delimiter ',', header);
#
# Third, invoke this script:
# ruby tools/org_quota_history/main.rb /tmp/org-quota-changes.csv
org_quota_changes_filename = ARGV[0]

org_quota_change_rows = CSV.parse(File.read(org_quota_changes_filename), headers: true)

orgs_seen = {}
quotas_seen = {}
org_quota_changes = {}

org_quota_change_rows.each do |org_quota_change_row|
  org_guid = org_quota_change_row["guid"]
  orgs_seen[org_guid] = {}

  org_quota_changes[org_guid] ||= []
  org_quota_changes[org_guid].push org_quota_change_row

  new_quota_guid = org_quota_change_row["quota_definition_guid"]
  quotas_seen[new_quota_guid] = {}
end

default_quota = nil
default_quota_guid = nil
quotas_seen.each do |quota_guid, _|
  quota_current_metadata = JSON.parse(`cf curl /v3/organization_quotas/#{quota_guid}`)
  quotas_seen[quota_guid] = quota_current_metadata
  if quota_current_metadata["name"] == "default"
    default_quota = quota_current_metadata
  end
end
default_quota_guid = default_quota["guid"]

orgs_seen.each do |org_guid, _|
  org_current_metadata = JSON.parse(`cf curl /v3/organizations/#{org_guid}`)
  orgs_seen[org_guid] = org_current_metadata["errors"] ? false : org_current_metadata
end

headers = ["ORG NAME", "ORG STILL EXISTS", "ORG CREATION DATE", "ORG BILLABLE UPGRADE DATE"]
rows = []

org_quota_changes.each do |org_guid, quota_changes|
  org_created = quota_changes[-1]["created_at"][0...10]
  current_org_name = quota_changes[-1]["name"]
  org_still_exists = orgs_seen[org_guid]

  row = [current_org_name, org_still_exists.to_s, org_created]

  currently_on_default = quota_changes[-1]["quota_definition_guid"] == default_quota_guid
  if currently_on_default
    row << "N/A"
  else
    upgrade = nil
    quota_changes.reverse_each do |quota_change|
      previous_quota_guid = quota_change["previous_quota_definition_guid"]
      if previous_quota_guid.nil? || previous_quota_guid == default_quota_guid
        upgrade = quota_change
        break
      end
    end
    row << upgrade["valid_from"][0...10]
  end

  rows << row
end

puts headers.join(",")
puts rows.map { |r| r.join(",") }.join("\n")
