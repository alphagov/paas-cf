#!/usr/bin/env ruby

require 'optparse'
require File.expand_path("../lib/pull_request", __FILE__)

pr_number = 0
option_parser = OptionParser.new do |opts|
  opts.on('--pr   number', Integer) do |value|
    pr_number = value
  end
end
option_parser.parse!

abort "Must specify PR number" unless pr_number > 0

PullRequest.new(pr_number).merge!
