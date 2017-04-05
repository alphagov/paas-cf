#!/usr/bin/env ruby

require "rubygems"
require "json"
require "yaml"

security_groups = Array.new

if File.file?(ARGV[0])
  peers = JSON.parse(File.read(ARGV[0]))
  peers.each do |peer|
    group = {
      "name" => "vpc_peer_" + peer["peer_name"],
      "rules" => [{
          "protocol" => "all",
          "destination" => peer["subnet_cidr"],
      }]
    }
    security_groups.push(group)
  end
end

manifest = {
  "properties" => {
    "cc" => {
      "security_group_definitions" => security_groups
    }
  }
}

puts manifest.to_yaml
