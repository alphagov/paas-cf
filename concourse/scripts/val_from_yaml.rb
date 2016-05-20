#!/usr/bin/env ruby
require 'yaml'

class PropertyTree
  def initialize(tree)
    @tree = tree
  end

  def self.load_yaml(yaml_string)
    PropertyTree.new(YAML.load(yaml_string))
  end

  def recursive_get(tree, key_array)
    return tree if key_array.empty?
    current_key, *next_keys = key_array

    case tree
    when Hash
      next_level = tree[current_key]
    when Array
      if /\A[-+]?\d+\z/ === current_key # If the key is an int, access by index
        next_level = tree[current_key.to_i]
      else # if not, search for a element with `name: current_key`
        next_level = tree.select {|x| x.is_a? Hash and x['name'] == current_key}.first
      end
    else
      next_level = nil
    end
    if not next_level.nil?
      recursive_get(next_level, next_keys)
    else
      nil
    end
  end

  def get(key)
    key_array = key.split('.')
    self.recursive_get(@tree, key_array)
  end

  def [](key)
    self.get(key)
  end
end

if __FILE__ == $0 # Only execute if called directly as command
  key = ARGV[0] || abort("Usage: #{$PROGRAM_NAME} <key.dot.delimited> [input.yml]")

  if ARGV[1]
    property_tree = PropertyTree.load_yaml(File.open(ARGV[1]).read())
  else
    property_tree = PropertyTree.load_yaml(STDIN.load())
  end

  val = property_tree[key]
  abort "Unable to find key: #{key}" if val.nil?

  if val.is_a? Array or val.is_a? Hash
    puts YAML.dump(val)
  else
    puts val
  end
end
