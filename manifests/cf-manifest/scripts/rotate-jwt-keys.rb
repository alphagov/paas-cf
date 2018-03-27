#!/usr/bin/env ruby

require 'yaml'

def rename_if_exists(vars, from, to)
  if vars.is_a?(Hash) && vars.key?(from)
    vars[to] = vars.delete(from)
  end

  vars
end

vars = YAML.safe_load(STDIN)
vars = rename_if_exists(vars, "uaa_jwt_signing_key", "uaa_jwt_signing_key_old")
vars = rename_if_exists(vars, "uaa_jwt_signing_key_id", "uaa_jwt_signing_key_old_id")
puts vars.to_yaml
