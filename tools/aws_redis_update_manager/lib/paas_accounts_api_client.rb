require "http"
require "json"

class PaaSAccountsAPIClient
  User = Struct.new(:guid, :username, :email)

  class UnhandledResponseError < RuntimeError
    def initialize(resp)
      @resp = resp
      super(message)
    end

    def message
      "PaaS accounts unhandled response (code: #{@resp.code}) (req: #{req_id})"
    end

    def req_id
      @resp.headers["X-Vcap-Request-Id"] || "no-request-id"
    end
  end

  def initialize(url:, username: nil, password: nil)
    @url = url
    @username = username
    @password = password
  end

  def http_client
    return HTTP if @username.nil? || @password.nil?
    HTTP.basic_auth(user: @username, pass: @password)
  end

  def find_user(guid)
    response = http_client.get("#{@url}/users/#{guid}")

    return nil if response.code == 404

    if response.code == 200
      p = JSON.parse(response.to_s)
      return User
        .new(guid, p["username"], p["user_email"])
    end

    raise UnhandledResponseError.new(response)
  end
end
