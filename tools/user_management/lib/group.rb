require 'json'

require_relative 'uaa_resource'

class Group < UAAResource
  attr_reader :name, :users

  def initialize(name, users)
    @name = name
    @users = users
  end

  def remove_unexpected_members(uaa_client)
    desired_user_guids = @users.map(&:guid)

    get_members(uaa_client).each do |member|
      unless member['entity'] && member['entity']['userName']
        raise "did not find a userName for '#{member['value']}'"
      end

      if member['origin'] == 'uaa' && member['entity']['userName'] == 'admin'
        puts "Preserving UAA admin user in group '#{@name}'"
        next
      end

      unless desired_user_guids.include?(member['value'])
        puts "WARNING: Removing unexpected user '#{member['value']}'/'#{member['entity']['userName']}' from group '#{@name}'"
        remove_member(member['value'], uaa_client)
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
    original_member_guids = get_members(uaa_client).map { |member| member['value'] }
    @users.each do |user|
      if original_member_guids.include? user.guid
        puts "Preserving desired user '#{user.google_id}'/'#{user.email}'/'#{user.guid}' in group '#{@name}'"
      else
        puts "Adding desired user '#{user.google_id}'/'#{user.email}'/'#{user.guid}' to group '#{@name}'"
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

  def get_group(uaa_client)
    get_resource("/Groups?filter=displayName+eq+\"#{@name}\"", uaa_client)
  end

  def get_members(uaa_client)
    get_group(uaa_client) if @guid.nil?
    get("/Groups/#{@guid}/members?returnEntities=true", uaa_client)
  end
end
