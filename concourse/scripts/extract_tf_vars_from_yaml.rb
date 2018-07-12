#!/usr/bin/env ruby
#
# Converts a YAML to a bunch of bash variable assignations.
# - It will concatenate the key tree using '_' until it finds a basic value
# - for lists, if the element is a hash and has a key 'name', uses that as
#   a node name, if not, uses the index.

require 'yaml'

def process_yaml(yaml_tree, prefix_chain)
  case yaml_tree
  when Hash
    yaml_tree.each { |k, v|
      process_yaml(v, prefix_chain + [k])
    }
  when Array
    yaml_tree.each_with_index { |v, i|
      name = if v.instance_of?(Hash) && v['name']
               v['name']
             else
               i
             end
      process_yaml(v, prefix_chain + [name])
    }
  else
    puts "#{prefix_chain.join('_').tr('-', '_')}='#{yaml_tree}'"
  end
end

process_yaml(YAML.safe_load($stdin), ["export TF_VAR"])
