#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'json/minify'

dashboards_dir = ARGV[0]
dashboard_files = Dir[dashboards_dir + '/*.json']
dashboards_hash = { 'properties' => { 'grafana' => { 'dashboards' => [] } } }

dashboard_files.each { |dashboard_file|
  json = File.read(dashboard_file)
  dashboard_definition = {
    "name" => File.basename(dashboard_file, ".json"),
    "content" => JSON.minify(json),
  }
  dashboards_hash['properties']['grafana']['dashboards'] << dashboard_definition
}

puts YAML.dump(dashboards_hash, line_width: 1000000)
