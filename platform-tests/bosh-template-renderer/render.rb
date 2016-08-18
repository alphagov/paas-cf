#!/usr/bin/env ruby
require 'yaml'
require File.join(File.dirname(__FILE__), 'render_lib.rb')

template_path, spec_path, manifest_path, job = ARGV

template = File.read(template_path)
spec = YAML.load_file(spec_path)
manifest = YAML.load_file(manifest_path)
puts render_template(template, spec, manifest, job)
