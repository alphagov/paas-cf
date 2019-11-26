require 'json'
require 'time'
require 'colorize'

require_relative 'uaa_resource'

class Group < UAAResource
  attr_reader :name, :users

  def initialize(name, users)
    @name = name
    @users = users
  end

  def remove_unexpected_members(uaa_client)
    desired_user_guids = @users.map(&:guid)
    unexpected_members = get_members(uaa_client).select do |member|
      if desired_user_guids.include?(member['entity']['id'])
        false
      elsif member['entity']['origin'] == 'uaa' && member['entity']['userName'] == 'admin'
        false
      else
        true
      end
    end

    if unexpected_members.empty?
      puts "No unexpected users found in group #{@name}.".green
      return
    end

    puts "WARNING: Unexpected members found in group #{@name}:".red
    unexpected_members.each do |member|
      puts "- guid=#{member['entity']['id']}".red
      puts "  origin=#{member['entity']['origin']}".red
      puts "  userName='#{member['entity']['userName']}'".red

      created = Time.iso8601(member['entity']['meta']['created'])
      if Time.now - created < 3600
        puts "  NOT REMOVING USER FROM GROUP BECAUSE IT IS LESS THAN 1 HOUR OLD".yellow
      else
        remove_member(member['entity']['id'], uaa_client)
        puts "  USER REMOVED FROM GROUP".green
      end
    end
  end

  def remove_member(member_guid, uaa_client)
    resp = uaa_client["/Groups/#{@guid}/members/#{member_guid}"].delete
    unless resp.code == 200
      raise "unexpected response code '#{resp.code}' when deleting member '#{member_guid}' from group '#{@name}'"
    end
  end

  def add_desired_users(uaa_client)
    existing_member_guids = get_members(uaa_client).map { |member| member['entity']['id'] }
    new_users_to_add = @users.reject { |user| existing_member_guids.include?(user.guid) }

    if new_users_to_add.empty?
      puts "No users need adding to to group #{@name}.".green
      return
    end

    puts "Adding new members to group #{@name}:".green
    new_users_to_add.each do |user|
      puts "- guid=#{user.guid}".green
      puts "  origin=google".green
      puts "  userName='#{user.google_id}'".green
      add_member(user.guid, 'google', uaa_client)
      puts "  USER ADDED TO GROUP".green
    end
  end

  def add_member(member_guid, origin, uaa_client)
    resp = uaa_client["/Groups/#{@guid}/members"].post({
      origin: origin,
      type: 'USER',
      value: member_guid
    }.to_json)
    raise "unexpected response code '#{resp.code}' when adding member '#{member_guid}' to group '#{@name}'" unless resp.code == 201
  end

  def get_group(uaa_client)
    get_resource("/Groups?filter=displayName+eq+\"#{@name}\"", uaa_client)
  end

  def get_members(uaa_client)
    get_group(uaa_client) if @guid.nil?
    get("/Groups/#{@guid}/members?returnEntities=true", uaa_client)
  end
end
