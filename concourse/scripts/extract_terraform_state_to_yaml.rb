#!/usr/bin/env ruby

require 'json'
require 'yaml'

outputs = JSON.load($stdin)
terraform_outputs = {
  'terraform_outputs' => outputs['modules'][0]['outputs']
}

puts YAML.dump(terraform_outputs)
