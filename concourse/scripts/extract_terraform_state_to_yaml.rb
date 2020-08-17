#!/usr/bin/env ruby

require "json"
require "yaml"

outputs = JSON.parse($stdin.read)
terraform_outputs = { "terraform_outputs" => {} }

if outputs["version"] == 4
  outputs["outputs"].each do |k, v|
    terraform_outputs["terraform_outputs_#{k}"] = v.fetch("value")
  end
else
  outputs["modules"][0]["outputs"].each do |k, v|
    terraform_outputs["terraform_outputs_#{k}"] = v.fetch("value")
  end
end

puts YAML.dump(terraform_outputs)
