#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'json/minify'

dashboards_dir = ARGV[0]
dashboard_files = Dir[dashboards_dir + '/*.json']

dashboards = dashboard_files.map { |dashboard_file|
  json = File.read(dashboard_file)
  {
    "name" => File.basename(dashboard_file, ".json"),
    "content" => JSON.minify(json),
  }
}

dashboards_hash = {
  "instance_groups" => [
    {
      "name" => "graphite",
      "jobs" => [
        "name" => "grafana",
        "properties" => {
          "grafana" => {
            "dashboards" => dashboards
          }
        }
      ]
    }
  ]
}

puts YAML.dump(dashboards_hash, line_width: 1000000)
