#!/usr/bin/env ruby

script_path = File.absolute_path(__FILE__).sub!(Dir.pwd + "/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require "json"
require "set"

routes_by_domain_url = {}

next_url = "/v2/routes?results-per-page=100"
while next_url
  page = JSON.parse `cf curl '#{next_url}'`
  page["resources"].map do |resource|
    host = resource.dig("entity", "host")
    domain_url = resource.dig("entity", "domain_url")
    if routes_by_domain_url.include? domain_url
      routes_by_domain_url[domain_url] << host
    else
      routes_by_domain_url[domain_url] = [host].to_set
    end
  end
  next_url = page["next_url"]
end

routes_by_domain_url.each do |url, hosts|
  domain = JSON.parse(`cf curl '#{url}'`).dig("entity", "name")
  hosts.each do |host|
    fqdn = host.empty? ? domain : "#{host}.#{domain}"
    puts "https://#{fqdn}"
  end
end
