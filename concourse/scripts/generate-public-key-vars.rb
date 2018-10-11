#!/usr/bin/env ruby

require 'yaml'

gpg_public_keys = { "gpg_public_keys" => [] }

public_key_ids = File.read('./.gpg-id')
public_key_ids.each_line do |id|
  # Assert key can be found locally
  `gpg -k #{id}`
  if $?.exitstatus != 0
    puts "This key needs to be imported: #{id}"
    puts """Try running
    gpg --recv #{id}
    """
    exit $?.exitstatus
  end
  public_key = `gpg --armor --export-options export-minimal --export #{id}`
  gpg_public_keys["gpg_public_keys"] << public_key
end

output_file = './concourse/vars-files/gpg-keys.yml'
output = gpg_public_keys.to_yaml
annotated_output = """# THIS FILE WAS GENERATED AUTOMATICALLY. DO NOT EDIT
# See https://team-manual.cloud.service.gov.uk/team/working_practices/#merging-pull-requests
#{output}"""
File.write(output_file, annotated_output)
puts "Public keys written to #{output_file}"
