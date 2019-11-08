require_relative 'group'

def ensure_users_exist_in_uaa(users, uaa_client)
  users.each do |user|
    user.create(uaa_client) unless user.exists?(uaa_client)
  end
end

def ensure_uaa_groups_have_correct_members(groups, uaa_client)
  groups.each do |group|
    group.remove_unexpected_members(uaa_client)
    group.add_desired_users(uaa_client)
  end
end
