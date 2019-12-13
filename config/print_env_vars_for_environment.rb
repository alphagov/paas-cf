#!/usr/bin/env ruby

require 'yaml'

def print_assign_if_not_set(name, value, emit_makefile_syntax = false)
  if emit_makefile_syntax
    puts "#{name}?=#{value}"
  else
    puts "export #{name}=${#{name}:-#{value.inspect}}"
  end
end

def print_assign(name, value, emit_makefile_syntax = false)
  if emit_makefile_syntax
    puts "#{name}=#{value}"
  else
    puts "export #{name}=#{value.inspect}"
  end
end

environment_name = ARGV.fetch(0)
emit_makefile_syntax = ARGV.fetch(1, false)

#STDERR.puts "environment_name=#{environment_name.inspect}"
#STDERR.puts "emit_makefile_syntax=#{emit_makefile_syntax.inspect}"

environments_config_path = File.expand_path(File.join(__dir__, 'environments.yml'))
environments_config = YAML.safe_load(File.read(environments_config_path), [], [], true)
environments = environments_config.fetch('environments')

environment = environments.fetch(environment_name)
environment.each do |environment_variable_name, value|
  if emit_makefile_syntax && (environment_variable_name.inspect.match(/\s/) || value.inspect.match(/\s/))
    raise 'makefile foreach interprets whitespace as the end of a line. environment variable definitions cannot contain whitespace.'
  end

  if environment_variable_name.end_with? '?'
    environment_variable_name = environment_variable_name.delete_suffix '?'
    print_assign_if_not_set(environment_variable_name, value, emit_makefile_syntax)
  else
    print_assign(environment_variable_name, value, emit_makefile_syntax)
  end
end
