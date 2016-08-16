#!/usr/bin/env ruby

require 'json'

outputs = JSON.load($stdin)

outputs['modules'][0]['outputs'].each { |k, v|
  puts "export TF_VAR_#{k}='#{v}'"
}
