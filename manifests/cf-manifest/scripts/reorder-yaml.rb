#!/usr/bin/env ruby
# Reads a yaml stdin and outputs yaml modified thusly:
# - arrays with any object entries that posess __paas_order keys are reordered. The
#   resulting order will be:
#   - Any object entries with a negative __paas_order key, ordered numerically
#   - Any entries without a __paas_order specified, in their existing order
#   - Any object entries with a positive __paas_order key, ordered numerically
#
#   i.e. entries missing an explicit __paas_order are assumed to have an order of
#   0, and it is a "stable sort" so entries sharing a common __paas_order should
#   be output in their existing order.
#
# - objects are stripped of any remaining __paas_order keys
#
# yaml without any __paas_order keys should be unaffected
#

require "yaml"

DEFAULT_ORDER = 0
PAAS_ORDER_KEY = "__paas_order".freeze

def processed(value)
  if value.is_a?(Array)
    # sort it
    sorted_array = value.sort_by.with_index do |v, i|
      [
        v.is_a?(Hash) && v.key?(PAAS_ORDER_KEY) ? v[PAAS_ORDER_KEY] : DEFAULT_ORDER,
        i, # returning previous index as least significant element to guarantee stable sort
      ]
    end

    # recurse into children
    return sorted_array.map { |v| processed(v) }
  elsif value.is_a?(Hash)
    # strip instructional keys
    stripped_hash = value.clone
    stripped_hash.delete(PAAS_ORDER_KEY)

    # recurse into children
    return stripped_hash.transform_values { |v| processed(v) }
  end

  value
end

if $PROGRAM_NAME == __FILE__
  root = YAML.safe_load(STDIN.read)
  puts processed(root).to_yaml
end
