#!/usr/bin/env ruby

require 'yaml'
require 'erb'

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
end

pricing_data = YAML.load_file("#{__dir__}/pricing_data.yml")
template = File.read("#{__dir__}/config.json.erb")

REGIONS.each do |region|
  g = Generator.new(region, pricing_data)
  File.open("#{__dir__}/output/#{region}.json", "w") do |f|
    f.write g.generate(template)
  end
end
