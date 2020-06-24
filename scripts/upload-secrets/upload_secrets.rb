#!/usr/bin/env ruby
# frozen_string_literal: true

script_path = File.absolute_path(__FILE__).sub!(Dir.pwd + "/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require "English"
require "yaml"
require "tempfile"

def upload_secrets(credhub_namespaces, secrets)
  credentials = secrets.flat_map do |secret, value|
    credhub_namespaces.map do |namespace|
      {
        "name" => "#{namespace}/#{secret}",
        "type" => "value",
        "value" => value.chomp,
      }
    end
  end

  import_to_credhub("credentials" => credentials)
end

def import_to_credhub(credhub_secrets)
  unless ENV.key? "CREDHUB_CA_CERT"
    raise "CREDHUB_CA_CERT not set, are you in a shell? (make <env> credhub)"
  end

  Tempfile.create("credhub-secrets") do |f|
    f.write(credhub_secrets.to_yaml)
    f.flush

    pid = spawn(
      "credhub import -f '#{f.path}'",
      in: STDIN, out: STDOUT, err: STDERR,
    )

    Process.wait pid
    raise "Child process did not exit successfully" unless $CHILD_STATUS.success?
  end
end
