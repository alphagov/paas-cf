#!/usr/bin/env ruby

require "rubygems"
require "json"
require "yaml"

peering_file = ARGV[0]

operations = Array.new

if File.file?(ARGV[0])
  operations = JSON.parse(File.read(peering_file)).map do |peer|
    {
      "type" => "replace",
      "path" => "/instance_groups/name=api/jobs/name=cloud_controller_ng/properties/cc/security_group_definitions?/-",
      "value" => {
        "name" => "vpc_peer_" + peer["peer_name"],
        "rules" => [{
            "protocol" => "all",
            "destination" => peer["subnet_cidr"],
        }],
      },
    }
  end
end

puts YAML.dump(operations)
