#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

users = YAML.load_file("users.yml", aliases: true)

deploy_env = ENV["AWS_ACCOUNT"]

# Collect static IPs for users with the ssh-access role in the specified environment
static_ips = users["users"].select { |user| user["roles"]&.dig(deploy_env)&.any? { |role| role["role"] == "aws-access" } }.map { |user| user["static_ip"] }.compact

# Format the static IPs as a Terraform command line variable
terraform_var = static_ips.empty? ? "" : "user_static_cidrs=[\"#{static_ips.join('/32","')}/32\"]"

# Print the Terraform variable
puts terraform_var
