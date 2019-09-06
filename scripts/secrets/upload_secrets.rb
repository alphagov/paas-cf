#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'
require 'tempfile'

def upload_secrets secrets
  config = secrets['config']

  s3_secrets = []
  credhub_secrets = Hash['credentials', []]

  # create objects containing the secrets for s3 and credhub.
  # although we could parse the 'raw' object for s3, a new object is
  # created so we can `chomp` each secret to remove `\n`
  secrets['secrets'].each do |secret, value|
    s3_secrets.push(Hash[secret, value.chomp])
    config['credhub_namespace'].each do |namespace|
      name = "#{namespace}/#{secret}"
      credhub_secrets['credentials'].push(
        Hash['name', name, 'type', 'value', 'value', value.chomp]
      )
    end
  end

  s3_secrets_file = Tempfile.new('s3-secrets')
  begin
    s3_secrets_file.write({ 'secrets' => s3_secrets }.to_yaml)
    s3_secrets_file.close
    system('aws', 's3', 'cp', s3_secrets_file.path, config['s3_path'])
  ensure
    s3_secrets_file.unlink
  end

  # create tempfile for credhub in /tmp because docker for mac can't mount
  # from the standard mac temp dir by default
  credhub_secrets_file = Tempfile.new('credhub-secrets', '/tmp')
  begin
    credhub_secrets_file.write(credhub_secrets.to_yaml)
    credhub_secrets_file.close
    system('./scripts/credhub-import.sh', credhub_secrets_file.path)
  ensure
    credhub_secrets_file.unlink
  end
end
