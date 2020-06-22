#!/usr/bin/env ruby

require "rubygems"
require "json"

names = []
vpc_ids = []
account_ids = []
cidrs = []

if File.file?(ARGV[0])
  peers = JSON.parse(File.read(ARGV[0]))
  peers.each do |peer|
    names.push(peer["peer_name"])
    vpc_ids.push(peer["vpc_id"])
    account_ids.push(peer["account_id"])
    cidrs.push(peer["subnet_cidr"])
  end

  printf "peer_names = %s\n", names
  printf "peer_vpc_ids = %s\n", vpc_ids
  printf "peer_account_ids = %s\n", account_ids
  printf "peer_cidrs = %s\n", cidrs
end
