require "json"
require "time"
require "colorize"

require_relative "uaa_resource"

class Group < UAAResource
  attr_reader :name, :users

  def initialize(name, users)
    @name = name
    @users = users
  end

  def remove_unexpected_members(uaa_client)
    desired_user_guids = @users.map(&:guid)
    unexpected_member_users = get_member_users(uaa_client).select do |member_user|
      if member_user["origin"] == "uaa" && member_user["userName"] == "admin"
        false
      elsif (member_user["origin"] == "google" || member_user["origin"] == "admin-google") && desired_user_guids.include?(member_user["id"])
        false
      else
        true
      end
    end

    if unexpected_member_users.empty?
      puts "No unexpected members of group #{@name}.".green
      return
    end

    puts "WARNING: Unexpected members of group #{@name}:".red
    unexpected_member_users.each do |member_user|
      puts "* guid=#{member_user['id']}".red
      puts "  origin=#{member_user['origin']}".red
      puts "  userName='#{member_user['userName']}'".red

      if member_user["meta"] && member_user["meta"]["created"] && Time.now - Time.iso8601(member_user["meta"]["created"]) < 3600
        puts "  NOT REMOVING USER FROM GROUP BECAUSE IT IS LESS THAN 1 HOUR OLD".yellow
      else
        remove_member(member_user["id"], uaa_client)
        puts "  USER REMOVED FROM GROUP".green
      end
    end
  end

  def remove_member(user_guid, uaa_client)
    resp = uaa_client["/Groups/#{@guid}/members/#{user_guid}"].delete
    unless resp.code == 200
      raise "unexpected response code '#{resp.code}' when removing user '#{user_guid}' from being a member of group '#{@name}'"
    end
  end

  def add_desired_users(uaa_client)
    existing_member_guids = get_member_users(uaa_client).map { |member| member["id"] }
    new_users_to_add = @users.reject { |user| existing_member_guids.include?(user.guid) }

    if new_users_to_add.empty?
      puts "No users need adding to group #{@name}.".green
      return
    end

    puts "Adding new users to group #{@name}:".green
    new_users_to_add.each do |user|
      puts "* guid=#{user.guid}".green
      puts "  email='#{user.email}'".green
      puts "  origin='#{user.origin}'".green
      puts "  userName='#{user.username}'".green
      add_member(user.guid, uaa_client)
      puts "  USER GIVEN MEMBERSHIP OF GROUP".green
    end
  end

  def add_member(user_guid, uaa_client)
    resp = uaa_client["/Groups/#{@guid}/members"].post({
      origin: "uaa",
      type: "USER",
      value: user_guid,
    }.to_json)
    raise "unexpected response code '#{resp.code}' when adding user '#{user_guid}' as a member of group '#{@name}'" unless resp.code == 201
  end

  def get_group(uaa_client)
    get_resource("/Groups?filter=displayName+eq+\"#{@name}\"", uaa_client)
  end

  def get_member_users(uaa_client)
    get_group(uaa_client)["members"].map do |member|
      if member["origin"] == "uaa" && member["type"] == "USER"
        get_uaa_user(member["value"], uaa_client)
      else
        {
          "id" => member["value"],
          "origin" => "*** UNUSUAL MEMBER WITH ORIGIN '#{member['origin']}' AND TYPE '#{member['type']}' ***",
          "userName" => "*** UNUSUAL MEMBER WITH ORIGIN '#{member['origin']}' AND TYPE '#{member['type']}' ***",
        }
      end
    end
  end

  def get_uaa_user(user_guid, uaa_client)

    get("/Users/#{user_guid}", uaa_client)
  rescue RestClient::NotFound
    # When we first ran this script, some of our Groups had members without
    # accompanying Users. These users had been manually destroyed but their
    # memberships hadn't been cleaned up.
    {
      "id" => user_guid,
      "origin" => "*** THE USER BEHIND THIS MEMBERSHIP DOES NOT EXIST ***",
      "userName" => "*** THE USER BEHIND THIS MEMBERSHIP DOES NOT EXIST ***",
    }

  end
end
