#!/usr/bin/env ruby

require 'json'
require 'yaml'

manifest_file = ENV.fetch("CF_MANIFEST")
manifest = YAML.load_file(manifest_file)

admin_user = File.read('admin-creds/username').strip
admin_password = File.read('admin-creds/password').strip

api_url = manifest.fetch("properties").fetch("cc").fetch("srv_api_uri")
apps_domain = manifest.fetch("properties").fetch("app_domains").first
system_domain = manifest.fetch("properties").fetch("system_domain")

config = {
  "api" => api_url,
  "admin_user" => admin_user,
  "admin_password" => admin_password,
  "apps_domain" => apps_domain,
  "system_domain" => system_domain,
  "use_http" => false,
}
puts config.to_json
