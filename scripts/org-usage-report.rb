#!/usr/bin/env ruby
# rubocop:disable Style/MultilineBlockChain
# rubocop:disable Lint/EachWithObjectArgument
gem 'activerecord'
gem 'sqlite3'

require 'active_record'
require 'csv'
require 'erb'
require 'English'
require 'date'
require 'json'

def cf_curl(url)
  STDERR.puts "cf curl '#{url}'"
  results = `cf curl '#{url}'`
  abort unless $CHILD_STATUS.success?
  JSON.parse(results)
end

def paginate(url, acc: [], page: 1, per_page: 100)
  response  = cf_curl("#{url}?page=#{page}&results-per-page=#{per_page}")
  resources = acc.concat(response.dig('resources'))

  return resources if response.dig('next_url').nil?

  paginate(
    url,
    acc: resources,
    page: page + 1,
    per_page: per_page
  )
end

def orgs
  paginate '/v2/organizations'
end

def org_managers(org_guid)
  paginate "/v2/organizations/#{org_guid}/managers"
end

def uaa_users(api, token)
  users = []
  start_index = 1
  num_results = nil

  loop do
    url = "#{api}/Users?startIndex=#{start_index}"

    STDERR.puts "curl #{url}"
    response = `curl -s -L -H 'Authorization: #{token}' '#{url}'`
    abort 'Could not get users from UAA' unless $CHILD_STATUS.success?

    response    = JSON.parse(response)
    users       = users.concat(response.dig('resources'))
    num_results = response.dig('totalResults')
    start_index = response.dig('startIndex') + 100

    break if start_index > num_results
  end

  users.map { |user| [user.dig('id'), user] }.to_h
end

begin
  db_file = "/tmp/db-#{rand(36**8).to_s(36)}.sqlite3"
  abandoned_orgs_csv_file = "#{ENV.fetch 'HOME'}/Desktop/abandoned-orgs.csv"
  expiring_orgs_csv_file = "#{ENV.fetch 'HOME'}/Desktop/expiring-orgs.csv"
  org_usage_html_file = "#{ENV.fetch 'HOME'}/Desktop/org-usage.html"

  ActiveRecord::Base.establish_connection(adapter: :sqlite3, database: db_file)
  ActiveRecord::Schema.define(version: 0) do
    create_table 'orgs', id: :string, force: true do |t|
      t.string 'name'
      t.string 'quota_guid'

      t.integer 'num_users'
      t.integer 'num_running_apps'
      t.integer 'num_stopped_apps'
      t.integer 'num_services'

      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'quotas', id: :string, force: true do |t|
      t.string 'name'
    end

    create_table 'org_managers', id: :string, force: true do |t|
      t.string 'email'

      t.string 'org_guid'

      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.datetime 'last_logon_time'
    end
  end

  class Org < ActiveRecord::Base
    self.table_name = :orgs

    has_many   :org_managers, foreign_key: :org_guid
    belongs_to :quota, foreign_key: :quota_guid

    alias_attribute :guid, :id
  end

  class Quota < ActiveRecord::Base
    self.table_name = :quotas

    has_many :orgs, foreign_key: :quota_guid

    alias_attribute :guid, :id
  end

  class OrgManager < ActiveRecord::Base
    self.table_name = :org_managers

    belongs_to :org, foreign_key: :org_guid

    alias_attribute :guid, :id
  end

  uaa_api = JSON.parse(
    File.read("#{ENV['HOME']}/.cf/config.json")
  ).dig('UaaEndpoint')
  uaa_token = `cf oauth-token`.chomp
  abort 'Could not get UAA token' unless $CHILD_STATUS.success?

  STDERR.puts 'Checking you are logged in'
  Process.wait(spawn('cf target', in: STDIN, out: STDERR, err: STDERR))
  abort 'Please log in' unless $CHILD_STATUS.success?

  orgs.each do |org|
    org_name = org.dig('entity', 'name')

    next if org_name.match?(/^PERF/)
    next if org_name.match?(/^CAT/)
    next if org_name.match?(/^ACC/)
    next if org_name.match?(/^SMOKE/)

    model = Org.new
    model.guid       = org.dig('metadata', 'guid')
    model.created_at = org.dig('metadata', 'created_at')
    model.updated_at = org.dig('metadata', 'updated_at')
    model.name       = org_name
    model.quota_guid = org.dig('entity', 'quota_definition_guid')
    model.save
  end

  Org.pluck(:quota_guid).uniq.each do |quota_guid|
    quota = cf_curl("/v2/quota_definitions/#{quota_guid}")
    model = Quota.new
    model.guid = quota_guid
    model.name = quota.dig('entity', 'name')
    model.save
  end

  users = uaa_users(uaa_api, uaa_token)

  Org.pluck(:guid).each do |org_guid|
    org_managers(org_guid).each do |manager|
      user            = users[manager.dig('metadata', 'guid')]
      last_logon_time = user['lastLogonTime'] && Time.at(
        user['lastLogonTime'] / 1000
      )

      OrgManager.find_or_initialize_by(
        guid: manager.dig('metadata', 'guid')
      ).update_attributes!(
        org_guid:        org_guid,
        created_at:      manager.dig('metadata', 'created_at'),
        updated_at:      manager.dig('metadata', 'updated_at'),
        email:           manager.dig('entity', 'username'),
        last_logon_time: last_logon_time
      )
    end
  end

  Org.pluck(:guid).each do |org_guid|
    org = cf_curl "/v2/organizations/#{org_guid}/users"
    num_users = org.dig('total_results')
    Org.find_by(guid: org_guid).update_attributes!(num_users: num_users)
  end

  Org.pluck(:guid).each do |org_guid|
    paginate("/v2/organizations/#{org_guid}/spaces")
      .flat_map { |space| space.dig('entity', 'apps_url') }
      .flat_map { |apps_url| paginate apps_url }
      .each_with_object({}) do |app, states|
        state = app.dig('entity', 'state').downcase
        states[state] ||= 0
        states[state] += 1
        states
      end
      .tap do |states|
        Org.find_by(guid: org_guid).update_attributes!(
          num_running_apps: states['running'] || 0,
          num_stopped_apps: states['stopped'] || 0
        )
      end
  end

  Org.pluck(:guid).each do |org_guid|
    num_services = cf_curl("/v2/organizations/#{org_guid}/summary")
      .dig('spaces')
      .each_with_object(0) { |s, acc| acc + s.dig('service_count') }

    Org.find_by(guid: org_guid).update_attributes!(num_services: num_services)
  end

  expiry_cutoff = Date.today - 75

  expiring_orgs = Quota
    .find_by(name: 'default')
    .orgs.where('created_at < ?', expiry_cutoff)
    .order('created_at DESC')

  abandoned_orgs = Org
    .where('num_users = 0 OR (num_running_apps + num_stopped_apps = 0)')
    .where('created_at < ?', expiry_cutoff)
    .order('created_at DESC')

  CSV.open(expiring_orgs_csv_file, 'wb') do |csv|
    csv << [
      'email address', 'organisation', 'creation_date', 'guid', 'updated_at',
      'managers', 'users', 'running_apps', 'stopped_apps', 'services',
      'last_logon_time', 'quota'
    ]
    expiring_orgs.each do |org|
      org.org_managers.each do |manager|
        csv << [
          manager.email, org.name, org.created_at.strftime('%Y-%m-%d'),
          org.guid, org.updated_at.strftime('%Y-%m-%d'),
          org.org_managers.length, org.num_users, org.num_running_apps,
          org.num_stopped_apps, org.num_services,
          manager.last_logon_time || '', org.quota.name
        ]
      end
    end
  end

  CSV.open(abandoned_orgs_csv_file, 'wb') do |csv|
    csv << [
      'email address', 'organisation', 'creation_date', 'guid', 'updated_at',
      'managers', 'users', 'running_apps', 'stopped_apps', 'services',
      'last_logon_time', 'quota'
    ]
    abandoned_orgs.each do |org|
      org.org_managers.each do |manager|
        csv << [
          manager.email, org.name, org.created_at.strftime('%Y-%m-%d'),
          org.guid, org.updated_at.strftime('%Y-%m-%d'),
          org.org_managers.length, org.num_users, org.num_running_apps,
          org.num_stopped_apps, org.num_services,
          manager.last_logon_time || '', org.quota.name
        ]
      end
    end
  end

  html_table_template = ERB.new <<~TPL
    <table class="govuk-table">
      <thead class="govuk-table__head"><tr class="govuk-table__row">
        <th class="govuk-table__header">Org</th>
        <th class="govuk-table__header">Name</th>
        <th class="govuk-table__header">Created</th>
        <th class="govuk-table__header">Updated</th>
        <th class="govuk-table__header">Managers</th>
        <th class="govuk-table__header">Users</th>
        <th class="govuk-table__header">Running apps</th>
        <th class="govuk-table__header">Stopped apps</th>
        <th class="govuk-table__header">Services</th>
        <th class="govuk-table__header">Quota</th>
      </tr></thead>
      <tbody class="govuk-table__body"><% orgs.each do |org| %>
        <tr class="govuk-table__row">
          <td rowspan="2"class="govuk-table__cell"><%= org.guid %></td>
          <td rowspan="2"class="govuk-table__cell"><%= org.name %></td>
          <td class="govuk-table__cell"><%= org.created_at.strftime('%Y-%m-%d') %></td>
          <td class="govuk-table__cell"><%= org.updated_at.strftime('%Y-%m-%d') %></td>
          <td class="govuk-table__cell"><%= org.org_managers.length %></td>
          <td class="govuk-table__cell"><%= org.num_users %></td>
          <td class="govuk-table__cell"><%= org.num_running_apps %></td>
          <td class="govuk-table__cell"><%= org.num_stopped_apps %></td>
          <td class="govuk-table__cell"><%= org.num_services %></td>
          <td class="govuk-table__cell"><%= org.quota.name %></td>
        </tr>
        <tr class="govuk-table__row">
          <td  class="govuk-table__cell"colspan="8">
            <ul class="govuk-list">
              <% org.org_managers.each do |manager| %>
                <li>
                  <a class="govuk-link" href="mailto:<%= manager.email %>">
                    <%= manager.email %>
                  </a>
                  last logged on
                  <%= manager.last_logon_time&.strftime('%Y-%m-%d') || '' %>
                </li>
              <% end %>
            </ul>
          </td>
        </tr>
      <% end %></tbody>
    </table>
  TPL

  generation_time = Time.now.strftime('%Y-%m-%d %H-%M')

  File.write(
    org_usage_html_file,
    <<~HTML
      <!DOCTYPE html>
      <html lang="en" class="govuk-template app-html-class">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <title>GOV.UK PaaS - Org usage</title>
        <link href="https://rawcdn.githack.com/alphagov/govuk-frontend/8d3e41fb2fafb1d16704fdb2389515b44c4cc470/dist/govuk-frontend-2.11.0.min.css" type="text/css" rel="stylesheet"/>
      </head>
      <body class="govuk-template__body app-body-class">
        <header class="govuk-header " role="banner" data-module="header">
          <div class="govuk-header__container govuk-width-container">
            <div class="govuk-header__logo">
              <a href="#" class="govuk-header__link govuk-header__link--homepage">
                  <span class="govuk-header__logotype-text">
                    GOV.UK
                  </span>
                </span>
              </a>
            </div>
            <div class="govuk-header__content">
              <a href="#" class="govuk-header__link govuk-header__link--service-name">
                PaaS Org Usage
              </a>
            </div>
          </div>
        </header>
        <div class="govuk-width-container">
          <main class="govuk-main-wrapper app-main-class" id="main-content" role="main">
            <p class="govuk-body">Generated: #{generation_time}</p>
            <h1 class="govuk-heading-l">Expiring Orgs</h1>
            #{html_table_template.result_with_hash(orgs: expiring_orgs)}
            <h1 class="govuk-heading-l">Abandoned Orgs</h1>
            #{html_table_template.result_with_hash(orgs: abandoned_orgs)}
          </main>
        </div>
      </body>
      </html>
    HTML
  )

  `open #{abandoned_orgs_csv_file}`
  `open #{expiring_orgs_csv_file}`
  `open #{org_usage_html_file}`

  STDERR.puts <<~INFO
    The following files have been created:
    - #{abandoned_orgs_csv_file}
    - #{expiring_orgs_csv_file}
    - #{org_usage_html_file}
  INFO
ensure
  File.delete(db_file)
end
# rubocop:enable Style/MultilineBlockChain
# rubocop:enable Lint/EachWithObjectArgument
