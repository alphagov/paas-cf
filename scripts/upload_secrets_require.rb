#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'
require 'tempfile'

require_relative ARGV[0]

secrets = get_secrets

config = secrets['config']

credhub_secrets = Hash['credentials', []]
secrets['secrets'].each do |secret, value|
  name = "#{config['credhub_namespace']}/#{secret}"
  credhub_secrets['credentials'].push(
    Hash['name', name, 'type', 'value', 'value', value]
  )
end

s3_secrets_file = Tempfile.new('s3-secrets')
begin
  s3_secrets_file.write({ 'secrets' => secrets['secrets'] }.to_yaml)
  s3_secrets_file.close
  system('aws', 's3', 'cp', s3_secrets_file.path, config['s3_path'])
ensure
  s3_secrets_file.unlink
end

credhub_secrets_file = Tempfile.new('credhub-secrets', '/tmp')
begin
  credhub_secrets_file.write(credhub_secrets.to_yaml)
  credhub_secrets_file.close
  system('./scripts/credhub-import.sh', credhub_secrets_file.path)
ensure
  credhub_secrets_file.unlink
end
