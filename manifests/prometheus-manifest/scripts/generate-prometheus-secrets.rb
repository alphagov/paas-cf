#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require File.expand_path("../../../shared/lib/secret_generator", __FILE__)

generator = SecretGenerator.new(
  # Passwords for Prometheus components
  "alertmanager_mesh_password" => :simple,
  "alertmanager_password" => :simple,
  "grafana_password" => :simple,
  "grafana_secret_key" => :simple,
  "postgres_grafana_password" => :simple,
  "prometheus_password" => :simple,
)

option_parser = OptionParser.new do |opts|
  opts.on('--existing-secrets FILE') do |file|
    existing_secrets = YAML.load_file(file)
    if existing_secrets && existing_secrets["secrets"]
      existing_secrets["secrets"].each { |key, value|
        existing_secrets["secrets_#{key}"] = value
      }
      existing_secrets.delete("secrets")
    end
    # An empty file parses as false
    generator.existing_secrets = existing_secrets if existing_secrets
  end
end
option_parser.parse!

output = generator.generate
puts output.to_yaml
