require 'erb'
require 'json'
require 'bosh/template/evaluation_context'

class Hash
  def dig(dotted_path)
    key, rest = dotted_path.split '.', 2
    match = self[key]
    if !rest || match.nil?
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

  def populate_default_properties_from_spec(spec)
    spec["properties"].each do |key, val|
      prop_key = "properties.#{key}"
      default = val["default"]
      if not default.nil?
        if self.dig(prop_key).nil?
          self.dig_add(prop_key, default)
        end
      end
    end
  end
end

def render_template(template, spec, manifest, job = nil)
  job_spec = {}
  job_spec["properties"] = {}

  if manifest["properties"]
    job_spec["properties"] = manifest["properties"].clone
  end

  if job
    job_properties = manifest["jobs"].select { |j| j["name"] == job }.first["properties"].clone
    job_spec["properties"].merge!(job_properties)
  end

  job_spec.populate_default_properties_from_spec(spec)

  # Populate the network
  job_spec["networks"] = { "cf1" => { "ip" => "127.0.0.1" } }

  context = Bosh::Template::EvaluationContext.new(job_spec)
  erb = ERB.new(template)
  erb.result(context.get_binding)
end
