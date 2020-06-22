#!/usr/bin/env ruby
require "yaml"

class PropertyTree
  def initialize(tree)
    @tree = tree
  end

  def self.load_yaml(yaml_string)
    PropertyTree.new(YAML.safe_load(yaml_string))
  end

  def recursive_get(tree, key_array)
    return tree if key_array.empty?

    current_key, *next_keys = key_array

    next_level = case tree
                 when Hash
                   tree[current_key]
                 when Array
                   if current_key =~ /\A[-+]?\d+\z/ # If the key is an int, access by index
                     tree[current_key.to_i]
                   else # if not, search for a element with `name: current_key`
                     tree.select { |x| x.is_a?(Hash) && x["name"] == current_key }.first
                   end
                 end
    if not next_level.nil?
      recursive_get(next_level, next_keys)
    end
  end

  def get(key)
    key_array = key.split(".")
    self.recursive_get(@tree, key_array)
  end

  def [](key)
    self.get(key)
  end
end

if $0 == __FILE__ # Only execute if called directly as command
  key = ARGV[0] || abort("Usage: #{$PROGRAM_NAME} <key.dot.delimited> [input.yml]")

  property_tree = if ARGV[1]
                    PropertyTree.load_yaml(File.open(ARGV[1]).read)
                  else
                    PropertyTree.load_yaml(STDIN.load)
                  end

  val = property_tree[key]
  abort "Unable to find key: #{key}" if val.nil?

  if val.is_a?(Array) || val.is_a?(Hash)
    puts YAML.dump(val)
  else
    puts val
  end
end
