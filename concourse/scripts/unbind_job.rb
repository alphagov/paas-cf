#!/usr/bin/env ruby
require "yaml"
pipe = YAML.safe_load(STDIN)

def remove_passed(obj)
  case obj
  when Array
    obj.each { |v| remove_passed(v) }
  when Hash
    if obj.has_key?("get") && obj["get"] == "paas-cf"
      obj.delete("passed")
    else
      obj.each { |k, v| remove_passed(v) if %w[do aggregate in_parallel].include?(k) }
    end
  end
end

abort "Unable to parse YAML hash from the input" if pipe.class != Hash
abort "Can't find job definitions in the input"  if pipe["jobs"].nil?
abort "Jobs definition not an array"             if pipe["jobs"].class != Array

my_job = pipe["jobs"].find { |j| j["name"] == ARGV[0] }
abort "Job " + ARGV[0] + " not found in the pipeline" if my_job.nil?

remove_passed(my_job["plan"])
puts YAML.dump(pipe)
