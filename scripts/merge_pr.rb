#!/usr/bin/env ruby

require 'optparse'
require File.expand_path("../lib/pull_request", __FILE__)

repo = nil
pr_number = 0
OptionParser.new do |opts|
  opts.on('--repo user/repo') do |value|
    repo = value
  end
  opts.on('--pr   number', Integer) do |value|
    pr_number = value
  end
end.parse!

abort "Must specify repo" unless repo
abort "Must specify PR number" unless pr_number > 0

pull_request = PullRequest.new(repo, pr_number).merge!
