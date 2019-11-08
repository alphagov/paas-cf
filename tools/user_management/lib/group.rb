require 'json'

require_relative 'uaa_resource'

class Group < UAAResource
  attr_reader :name, :users

  def initialize(name, users)
    @name = name
    @users = users
  end

  def remove_unexpected_members(uaa_client)
    get_members(uaa_client).each do |member|
      member_guid = member['value']
      unless @users.any? { |user| user.guid == member_guid || member['origin'] == 'uaa' }
        puts "WARNING: Removing unexpected user '#{member_guid}' from group '#{@name}"
        remove_member(member_guid, uaa_client)
      end
    end
  end

  def remove_member(member_guid, uaa_client)
    resp = uaa_client["/Groups/#{@guid}/members/#{member_guid}"].delete
    raise "unexpected response code '#{resp.code}' when deleting member '#{member_guid}' from group '#{@name}'" unless resp.code == 200
  end

  def add_desired_users(uaa_client)
    original_members = get_members(uaa_client)
    @users.each do |user|
      unless original_members.any? { |member| member['value'] == user.guid }
        puts "Adding desired user '#{user.google_id}'/'#{user.email}'/'#{user.guid}' to group '#{@name}"
        add_member(user.guid, 'google', uaa_client)
      end
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

  def get_members(uaa_client)
    get_group(uaa_client)['members']
  end

  def get_group(uaa_client)
    get_resource("/Groups?filter=displayName+eq+\"#{@name}\"", uaa_client)
  end
end
