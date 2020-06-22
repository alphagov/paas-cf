#!/usr/bin/env ruby

require "json"

tfstate = JSON.parse($stdin.read)

tfstate["modules"][0]["outputs"].each { |k, v|
  puts "export TF_VAR_#{k}='#{v.fetch('value')}'"
}
