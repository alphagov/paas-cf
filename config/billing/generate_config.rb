#!/usr/bin/env ruby

require "yaml"
require "json"
require "erb"

REGIONS = %w(eu-west-1 eu-west-2).freeze

class Generator
  def initialize(region, pricing_data)
    @region = region
    @prices = pricing_data.fetch(region)
  end

  def price(key)
    @prices.fetch(key)
  end

  def generate(template)
    ERB.new(template).result(binding)
  end

  def include(file)
    fp = File.join(__dir__, file)
    ERB.new(
      File.read(File.expand_path(fp))
    ).result(binding)
  end
end

pricing_data = YAML.load_file("#{__dir__}/pricing_data.yml")
template = File.read("#{__dir__}/config.json.erb")

REGIONS.each do |region|
  begin
    g = Generator.new(region, pricing_data)
    json_content = g.generate(template)

    content = JSON.parse json_content
    pretty_json_content = JSON.pretty_generate(content, indent: "\t")

    File.open("#{__dir__}/output/#{region}.json", "w") do |f|
      f.write pretty_json_content
    end

    if File.exist?("#{__dir__}/output/#{region}.err.json")
      File.delete("#{__dir__}/output/#{region}.err.json")
    end
  rescue JSON::ParserError
    puts "Config for #{region} is not valid JSON. Written content to #{__dir__}/output/#{region}.err.json"
    File.open("#{__dir__}/output/#{region}.err.json", "w") do |f|
      f.write pretty_json_content
    end

    puts `jq '.' #{__dir__}/output/#{region}.err.json`
    exit 1
  end
end
