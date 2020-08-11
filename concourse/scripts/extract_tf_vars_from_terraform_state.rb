#!/usr/bin/env ruby

require "json"

tfstate = JSON.parse($stdin.read)

if tfstate["version"] == 4
  tfstate["outputs"].each do |k, v|
    puts "export TF_VAR_#{k}='#{v.fetch('value')}'"
  end
else
  tfstate["modules"][0]["outputs"].each do |k, v|
    puts "export TF_VAR_#{k}='#{v.fetch('value')}'"
  end
end
