#!/usr/bin/env ruby

require 'json'
require 'yaml'

manifest_file = ENV.fetch("CF_MANIFEST")
manifest = YAML.load_file(manifest_file)

admin_password = manifest.fetch("properties").fetch("acceptance_tests").fetch("admin_password")
api_url = manifest.fetch("properties").fetch("cc").fetch("srv_api_uri")
apps_domain = manifest.fetch("properties").fetch("app_domains").first

config = {
  "api" => api_url,
  "admin_user" => "admin",
  "admin_password" => admin_password,
  "apps_domain" => apps_domain,
  "use_http" => false,
}
puts config.to_json
