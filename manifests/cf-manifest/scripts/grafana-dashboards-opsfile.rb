#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'json/minify'

dashboards_dir = ARGV[0]
dashboard_files = Dir[dashboards_dir + '/*.json']

operations = dashboard_files.map { |dashboard_file|
  json = File.read(dashboard_file)
  {
    "type" => "replace",
    "path" => "/instance_groups/name=graphite/jobs/name=grafana/properties/grafana/dashboards?/-",
    "value" => {
      "name" => File.basename(dashboard_file, ".json"),
      "content" => JSON.minify(json),
    }
  }
}

puts YAML.dump(operations, line_width: 1000000)
