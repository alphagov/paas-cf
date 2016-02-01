#!/usr/bin/env ruby
require 'rubygems'
require 'cli'
bosh_cli = Bosh::Cli::Command::Base.new.director
bosh_cli.list_releases.each { |r|
    r['release_versions'].each { |v|
        puts "#{r['name']}/#{v['version']}"
    }
};
