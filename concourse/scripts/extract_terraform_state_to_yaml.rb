#!/usr/bin/env ruby

require "json"
require "yaml"

outputs = JSON.parse($stdin.read)

terraform_outputs = { "terraform_outputs" => {} }
outputs["modules"][0]["outputs"].each { |k, v|
  terraform_outputs["terraform_outputs_#{k}"] = v.fetch("value")
}

puts YAML.dump(terraform_outputs)
