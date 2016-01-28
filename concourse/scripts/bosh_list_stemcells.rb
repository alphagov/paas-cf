#!/usr/bin/env ruby
require 'rubygems'
require 'cli'
bosh_cli = Bosh::Cli::Command::Base.new.director
bosh_cli.list_stemcells.each { |s| puts "#{s['name']}/#{s['version']}" } ;
