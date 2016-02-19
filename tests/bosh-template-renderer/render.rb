#!/usr/bin/env ruby
require 'yaml'
require 'erb'
require 'bosh/template/evaluation_context'

template_path, spec_path, manifest_path = ARGV

class Hash
  def dig(dotted_path)
    key, rest = dotted_path.split '.', 2
    match = self[key]
    if !rest or match.nil?
      return match
    else
      return match.dig(rest)
    end
  end

  def dig_add(dotted_path, value)
    key, rest = dotted_path.split '.', 2
    match = self[key]
    if not rest
      return self[key] = value
    elsif match.nil?
      self[key] = {}
    end
    self[key].dig_add(rest, value)
  end

  def merge_with_spec(spec)
    spec["properties"].each do |key, val|
      prop_key = "properties.#{key}"
      default = val["default"]
      if not default.nil?
        if not self.dig(prop_key)
          self.dig_add(prop_key, default)
        end
      end
    end
  end
end

template = File.read(template_path)
spec = YAML.load_file(spec_path)
manifest = YAML.load_file(manifest_path)

manifest.merge_with_spec(spec)

# Sometimes we want "spec.index" in the tempates
manifest.dig_add "index", 0

# for discover_external_ip in acceptance-tests/templates/config.json.erb
if not manifest["networks"]
  manifest["networks"] = []
end
manifest.dig_add "networks", {:blurgh => manifest["networks"][0]}
manifest.dig_add "networks.blurgh.ip", "127.0.0.1"

context = Bosh::Template::EvaluationContext.new(manifest)
erb = ERB.new(template)
puts erb.result(context.get_binding)
