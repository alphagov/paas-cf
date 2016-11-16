#!/usr/bin/env ruby

require File.expand_path("../lib/job_instances_lib", __FILE__)

manifest_path = ARGV[0]
manifest = File.read(manifest_path)

puts JobInstances.generate manifest
