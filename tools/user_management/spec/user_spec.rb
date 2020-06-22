require "rest-client"
require "webmock/rspec"

require_relative "../lib/user"

RSpec.describe User do
  before do
    @fake_uaa_client = RestClient::Resource.new("http://fake-uaa.internal", headers: {
      "Authorization" => "fake-token",
      "Content-Type" => "application/json"
    })
  end

  it "checks if a role for a user exists in an environment" do
    u = User.new(
      "email" => "jeff.jefferson@example.com",
      "username" => "000000000000000000000",
      "roles" => {
        "dev" => [{ "role" => "some_role" }],
        "prod" => [{ "role" => "some_other_role" }],
      },
    )
    expect(u.has_role_for_env?("dev", "some_role")).to be(true)
    expect(u.has_role_for_env?("dev", "some_other_role")).to be(false)
    expect(u.has_role_for_env?("prod", "some_other_role")).to be(true)
    expect(u.has_role_for_env?("prod", "some_role")).to be(false)
    expect(u.has_role_for_env?("some_env_that_does_not_exist", "some_role_that_does_not_exist")).to be(false)
  end

  it "does not give any roles to users without roles" do
    u = User.new(
      "email" => "jeff.jefferson@example.com",
      "username" => "000000000000000000000",
      "roles" => {},
    )
    expect(u.has_role_for_env?("dev", "some_role")).to be(false)
    expect(u.has_role_for_env?("dev", "some_other_role")).to be(false)
    expect(u.has_role_for_env?("prod", "some_other_role")).to be(false)
    expect(u.has_role_for_env?("prod", "some_role")).to be(false)
    expect(u.has_role_for_env?("some_env_that_does_not_exist", "some_role_that_does_not_exist")).to be(false)
  end

  it "checks if exists in UAA" do
    stub_request(:get, "http://fake-uaa.internal/Users?filter=origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22")
      .to_return(body: JSON.generate(
        resources: [{
          id: "00000000-0000-0000-0000-000000000000-user",
        }],
        totalResults: 1
      ))

    u = User.new(
      "email" => "jeff.jefferson@example.com",
      "username" => "000000000000000000000",
      "roles" => { "dev" => [{ "role" => "some_role" }] },
    )

    expect(u.exists?(@fake_uaa_client)).to be true
    assert_requested(:get, "http://fake-uaa.internal/Users?filter=origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22")

    stub_request(:get, "http://fake-uaa.internal/Users?filter=origin%20eq%20%22google%22%20and%20userName%20eq%20%22999999999999999999999%22")
      .to_return(status: 404, body: JSON.generate({}))

    u2 = User.new(
      "email" => "rich.richardson@example.com",
      "username" => "999999999999999999999"
    )

    expect(u2.exists?(@fake_uaa_client)).to be false
  end

  it "creates the entity" do
    stub_request(:post, "http://fake-uaa.internal/Users").to_return(status: 201)

    u = User.new(
      "email" => "jeff.jefferson@example.com",
      "username" => "000000000000000000000",
      "roles" => { "dev" => [{ "role" => "some_role" }] },
    )

    expect(u.create(@fake_uaa_client)).to be true
    assert_requested(:post, "http://fake-uaa.internal/Users", times: 1) { |req|
      JSON.parse(req.body)["userName"] == "000000000000000000000"
    }

    stub_request(:post, "http://fake-uaa.internal/Users")
      .to_return(status: 400, body: JSON.generate({}))

    u2 = User.new(
      "email" => "rich.richardson",
      "username" => "999999999999999999999"
    )

    expect { u2.create(@fake_uaa_client) }.to raise_error(Exception, /Bad Request/)

    stub_request(:post, "http://fake-uaa.internal/Users")
      .to_return(status: 206, body: JSON.generate({}))

    u3 = User.new(
      "email" => "jeff.jefferson@example.com",
      "username" => "000000000000000000000"
    )

    expect(u3.create(@fake_uaa_client)).to be false
  end

  it "throw errors when UAA API returns >=400 response" do
    stub_request(:post, "http://fake-uaa.internal/Users")
      .to_return(status: 201, body: JSON.generate(
        resources: [{
          id: "00000000-0000-0000-0000-000000000000-user"
        }],
        totalResults: 1
      ))

    stub_request(:get, "http://fake-uaa.internal/Users?filter=origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22")
      .to_return(status: 404, body: JSON.generate({}))

    u = User.new(
      "email" => "jeff.jefferson@example.com",
      "username" => "000000000000000000000",
      "roles" => { "dev" => [{ "role" => "some_role" }] },
    )

    expect { u.get_user(@fake_uaa_client) }.to raise_error(Exception)
  end
end
