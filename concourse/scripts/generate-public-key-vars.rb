#!/usr/bin/env ruby

require "English"
require "yaml"

gpg_public_keys = { "gpg_public_keys" => [] }

public_key_ids = File.read("./.gpg-id")
public_key_ids.each_line do |id|
  # Assert key can be found locally
  key_output = `gpg -k #{id}`

  unless $CHILD_STATUS.success?
    puts "This key needs to be imported: #{id}"
    puts """Try running
    gpg --recv #{id}
    """
    abort key_output
  end

  public_key = `gpg --armor --export-options export-minimal --export #{id}`
  abort public_key unless $CHILD_STATUS.success?

  gpg_public_keys["gpg_public_keys"] << public_key
end

output_file = "./concourse/vars-files/gpg-keys.yml"
output = gpg_public_keys.to_yaml
annotated_output = """# THIS FILE WAS GENERATED AUTOMATICALLY. DO NOT EDIT
# See https://team-manual.cloud.service.gov.uk/team/working_practices/#merging-pull-requests
#{output}"""
File.write(output_file, annotated_output)
puts "Public keys written to #{output_file}"
puts "Note: we don't yet have a way of producing a canonical output via GPG, so when you run this script you may see changes to everybody's public keys. These differences are okay to commit - what matters is they are derived from the correct public key IDs."
