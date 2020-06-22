#!/usr/bin/env ruby

require "yaml"

config_file = ARGV[0]
deploy_env = ARGV[1]

if File.file?(config_file)
  config = YAML.load_file(config_file)
  if config == nil
    warn "could not parse config file at #{config_file}"
    exit(1)
  end

  if config[deploy_env] == nil
    exit(0)
  end

  ops = config[deploy_env].flat_map do |client|
    client["uaa_client"]["secret"] = "((#{client['secret_name']}))"

    [
      {
        "type" => "replace",
        "path" => "/instance_groups/name=uaa/jobs/name=uaa/properties/uaa/clients/#{client['name']}?",
        "value" => client["uaa_client"],
      },
      {
        "type" => "replace",
        "path" => "/variables/-",
        "value" => {
          "name" => client["secret_name"],
          "type" => "password",
        },
      },
    ]
  end
  puts YAML.dump(ops)
else
  warn "config file not found at #{config_file}"
  exit(1)
end
