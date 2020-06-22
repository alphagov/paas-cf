require "base64"
require "json"

RSpec.describe PaaSAccountsAPIClient do
  before(:all) do
    WebMock.enable!
  end

  after(:all) do
    WebMock.disable!
  end

  let(:accounts_url) { "https://accounts.paas" }

  context "when a username and password is provided to the constructor" do
    it "sets the HTTP Authorization header correctly" do
      stub_request(:get, "#{accounts_url}/users/a-guid")
        .to_return(status: 404)

      client = PaaSAccountsAPIClient.new(
        url: accounts_url,
        username: "un", password: "pw"
      )
      user = client.find_user("a-guid")

      expect(user).to be_nil

      expected_auth_header = "Basic #{Base64.strict_encode64('un:pw').strip}"

      expect(WebMock).to have_requested(:get, "#{accounts_url}/users/a-guid")
        .with(headers: { 'Authorization': expected_auth_header })
    end
  end

  context "when a username and password is not provided to the constructor" do
    it "does not set the HTTP Authorization header" do
      stub_request(:get, "#{accounts_url}/users/a-guid")
        .to_return(status: 404)

      client = PaaSAccountsAPIClient.new(url: accounts_url)
      user = client.find_user("a-guid")

      expect(user).to be_nil

      expect(WebMock).to have_requested(:get, "#{accounts_url}/users/a-guid")
    end
  end

  context "when a user is not found" do
    it "returns nil" do
      stub_request(:get, "#{accounts_url}/users/a-guid")
        .to_return(status: 404)

      client = PaaSAccountsAPIClient.new(url: accounts_url)
      user = client.find_user("a-guid")

      expect(user).to be_nil
    end
  end

  context "when a user is found" do
    it "returns a user struct" do
      stub_request(:get, "#{accounts_url}/users/a-guid")
        .to_return(
          status: 200,
          body: {
            username: "a-username",
            user_email: "email@domain.tld"
          }.to_json
        )

      client = PaaSAccountsAPIClient.new(url: accounts_url)
      user = client.find_user("a-guid")

      expect(user).to have_attributes(
        guid: "a-guid",
        username: "a-username",
        email: "email@domain.tld"
      )
    end
  end
end
