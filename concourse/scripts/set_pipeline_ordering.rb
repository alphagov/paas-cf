#!/usr/bin/env ruby

require "net/http"
require "yaml"
require "json"

if ARGV.length != 1
  abort <<-EOT
Usage:

   #{$0} <pipeline_order>

Being:

   pipeline_order comma-separated list of pipeline names

  EOT
end
pipelines = ARGV[0].split(",")

if ENV["FLY_TARGET"].nil? || ENV["FLY_TARGET"].empty?
  abort "FLY_TARGET not set"
end
flyrc = YAML.load_file("#{ENV['HOME']}/.flyrc")
if flyrc.fetch("targets")[ENV["FLY_TARGET"]].nil?
  abort "Target '#{ENV['FLY_TARGET']}' not found in .flyrc. Use the fly command to set this target up before using this script"
end
concourse_url = flyrc.fetch("targets").fetch(ENV["FLY_TARGET"]).fetch("api")
bearer_token = flyrc.fetch("targets").fetch(ENV["FLY_TARGET"]).fetch("token").fetch("value")

uri = URI.parse("#{concourse_url}/api/v1/teams/main/pipelines/ordering")
req = Net::HTTP::Put.new(uri.request_uri)

req["Authorization"] = "Bearer #{bearer_token}"

req.content_type = "application/json"
req.body = JSON.dump(pipelines)

resp = nil
Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
  resp = http.request(req)
end

unless resp.code.to_i == 200
  abort "Non-200 response '#{resp.code}' from concourse\n#{resp.body}"
end
