#!/usr/bin/env ruby
require 'cli'

def usage
  puts "Usage: bosh_create_and_upload_release.rb <release_name> <release_version> <release_dir>"
  exit 101
end

def check_release(name, version)
  bosh_cli = Bosh::Cli::Command::Base.new.director

  this_release = bosh_cli.list_releases.select { |r| r["name"] == name }.first
  unless this_release.nil? || this_release.empty?
    this_release_version = this_release["release_versions"].select { |rv|
      rv["version"] == version
    }.first
  end
  this_release_version
end

def create_release(name, version, dir)
  cr_cmd = Bosh::Cli::Command::Release::CreateRelease.new
  cr_cmd.add_option(:name, name)
  cr_cmd.add_option(:version, version)
  cr_cmd.add_option(:dir, dir)
  cr_cmd.add_option(:with_tarball, true)
  Bosh::Cli::Config.output = STDOUT

  puts "Create release #{name} version #{version}"

  begin
    cr_cmd.create
  rescue Bosh::Cli::CliError => e
    if e.message.include?("Release version already exists")
      puts "Release version already exists locally"
    else
      raise e
    end
  end
end

def upload_release(name, version, dir)
  release_filename = "dev_releases/#{name}/#{name}-#{version}.tgz"
  options = {
    dir: dir,
    name: name,
    version: version
  }

  bosh_cli = Bosh::Cli::Command::Base.new.director

  puts "Upload release #{name} version #{version}"
  bosh_cli.upload_release(release_filename, options)
end


release_name, release_version, release_dir = ARGV
if ARGV.size != 3 || release_name == '' || release_version == '' || release_dir == ''
  usage
end

unless File.directory?(release_dir)
  puts "Error: release directory #{release_dir} does not exist"
  exit 102
end

this_release_version = check_release(release_name, release_version)
unless this_release_version.nil? || this_release_version.empty?
  puts "Release #{release_name} version #{release_version} already uploaded, skipping"
  exit 0
end

puts "Release #{release_name} version #{release_version} not found in BOSH"

create_release(release_name, release_version, release_dir)

upload_release(release_name, release_version, release_dir)
