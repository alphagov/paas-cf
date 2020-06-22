require "colorize"

require_relative "group"

def ensure_users_exist_in_uaa(users, uaa_client)
  users.each do |user|
    next if user.exists?(uaa_client)

    puts "Creating new user '#{user.email}' with Google ID '#{user.username}'".green
    user.create(uaa_client)
    user.get_user(uaa_client)
    puts "  CREATED WITH GUID #{user.guid}".green
  end
  puts
end

def ensure_uaa_groups_have_correct_members(groups, uaa_client)
  groups.each do |group|
    puts group.name.bold
    group.remove_unexpected_members(uaa_client)
    group.add_desired_users(uaa_client)
    puts
  end
end
