require "json"

require_relative "uaa_resource"

class User < UAAResource
  attr_reader :email, :username, :origin

  def initialize(obj)
    @email = obj.fetch("email")
    @username = obj.fetch("username")
    @roles_by_env = obj.fetch("roles", {})
    @origin = obj.fetch("origin", "google")
  end

  def exists?(uaa_client)
    begin
      get_user(uaa_client)
    rescue StandardError
      return false
    end
    true
  end

  def has_role_for_env?(env, role)
    @roles_by_env.fetch(env, []).any? { |x| x["role"] == role }
  end

  def create(uaa_client)
    resp = uaa_client["/Users"].post({
      emails: [{ value: @email }],
      origin: @origin,
      userName: @username
    }.to_json)
    resp.code == 201
  end

  def get_user(uaa_client)
    scim_filter = [
      "origin+eq+\"#{@origin}\"",
      "userName+eq+\"#{@username}\""
    ].join("+and+")
    get_resource("/Users?filter=#{scim_filter}", uaa_client)
  end
end
