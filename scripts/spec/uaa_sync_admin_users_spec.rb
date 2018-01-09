require 'uaa_sync_admin_users'
require 'mail_credentials_helper'

RSpec.describe UaaSyncAdminUsers do
  def user_uuid(username)
    "__user__#{username}__uuid__"
  end

  def group_uuid(groupname)
    "__group__#{groupname}__uuid__"
  end

  def json_admin_token_response
    reply = {
      access_token: "test_access_token",
      token_type: "bearer",
      scope: "clients.read password.write clients.secret clients.write uaa.admin scim.write scim.read",
      expires_in: 98765
    }
    CF::UAA::Util.json(reply)
  end

  def json_query_responses(json_resources)
    %{
      {
        "totalResults" : #{json_resources.length},
        "resources" : [
          #{json_resources.join("\n,")}
        ],
        "itemsPerPage" : 100,
        "schemas" : [
            "urn:scim:schemas:core:1.0"
        ],
        "startIndex" : 1
      }
    }
  end

  def json_user_groups_response(groups)
    groups.map { |g|
      %{
        {
        "type" : "DIRECT",
          "display" : "#{g}",
          "value" : "#{group_uuid(g)}"
        }
      }
    }.join(",\n")
  end

  def json_group_response(groupname, members = [])
    %{
      {
        "zoneId" : "uaa",
        "schemas" : [
            "urn:scim:schemas:core:1.0"
        ],
        "id" : "#{group_uuid(groupname)}",
        "meta" : {
            "version" : 12,
            "created" : "2016-05-18T15:06:22.925Z",
            "lastModified" : "2016-05-19T14:46:40.174Z"
        },
        "displayName" : "#{groupname}",
        "members" : [
          #{members.map { |m|
              %{
              {
                "value" : "#{user_uuid(m)}",
                  "type" : "USER",
                  "origin" : "uaa"
                }
                  }
            }.join(",\n")}
        ]
      }
      }
  end

  def json_user_response(username, email, groups = [], hours_since_creation = 24)
    change_time = (Time.now - hours_since_creation * 60 * 60).iso8601
    %{
    {
      "userName" : "#{username}",
      "id" : "#{user_uuid(username)}",
      "groups" : [
        #{json_user_groups_response(groups)}
      ],
      "passwordLastModified" : "#{change_time}",
      "origin" : "uaa",
      "active" : true,
      "meta" : {
          "created" : "#{change_time}",
          "lastModified" : "#{change_time}",
          "version" : 3
      },
      "verified" : true,
      "emails" : [
          {
            "primary" : false,
            "value" : "#{email}"
          }
      ],
      "zoneId" : "uaa",
      "approvals" : [],
      "name" : {},
      "schemas" : [
          "urn:scim:schemas:core:1.0"
      ]
    }
    }
  end

  context "when connecting to a fake server" do
    let(:cf_api_url) { "https://api.test.target" }
    let(:admin_user) { "admin" }
    let(:admin_password) { "password" }
    let(:uaa_sync_admin_users) {
      UaaSyncAdminUsers.new(cf_api_url, admin_user, admin_password, skip_ssl_validation: true, log_level: :warn)
    }

    before :each do
      WebMock.stub_request(:get, "#{cf_api_url}/v2/info").
         to_return(
           status: 200,
           headers: {},
           body: '{"token_endpoint": "https://uaa.test"}',
         )

      WebMock.stub_request(:post, "https://cf:@uaa.test/oauth/token").
         with(body: 'grant_type=password&username=admin&password=password&scope=cloud_controller.read+cloud_controller.write+openid+password.write+cloud_controller.admin+cloud_controller.admin_read_only+cloud_controller.global_auditor+scim.read+scim.write+scim.invite+uaa.user').
         to_return(
           status: 200,
           headers: { "content-type" => "application/json" },
           body: json_admin_token_response,
         )

      uaa_sync_admin_users.request_token
    end

    it "connects and authenticates and gets a token" do
      expect(uaa_sync_admin_users.token["access_token"]).to eq "test_access_token"
    end

    context "when updating from a list with existing and new users" do
      let(:uaa_api_url) { uaa_sync_admin_users.target }
      let(:users) {
        [
          { username: "existing_user", email: "existing_user@example.com", origin: "uaa" },
          { username: "new_user", email: "new_user@example.com", origin: "uaa" },
        ]
      }

      before(:each) do
        WebMock.stub_request(:get, %r{^#{uaa_api_url}/Users.*}).
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: json_query_responses([])
        )
        %w(admin existing_user removed_user).each { |user_to_match|
          WebMock.stub_request(:get, %r{#{uaa_api_url}/Users\?filter=username eq "#{user_to_match}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com"),
              ])
          )
          WebMock.stub_request(:get, %r{#{uaa_api_url}/Users\?filter=id eq "#{user_uuid(user_to_match)}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com"),
              ])
          )
        }
        %w(test_user_1 test_user_2).each { |user_to_match|
          WebMock.stub_request(:get, %r{#{uaa_api_url}/Users\?filter=id eq "#{user_uuid(user_to_match)}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com", [], 1),
              ])
          )
        }
        WebMock.stub_request(:post, %r{^#{uaa_api_url}/Users.*}).
          with(
            body: /"userName":"new_user".*"emails":\[{"value":"new_user@example\.com"}/,
          ).
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: json_user_response("new_user", "new_user@example.com"),
          )

        uaa_sync_admin_users.admin_groups.each { |group_name|
          WebMock.stub_request(:get, %r{^#{uaa_api_url}/Groups\?filter=displayName eq "#{group_name}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_group_response(group_name, %w(admin existing_user removed_user test_user_1 test_user_2))
              ])
            )
          WebMock.stub_request(:put, %r{^#{uaa_api_url}/Groups/#{group_uuid(group_name)}$}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_group_response(group_name, %w(admin existing_user new_user removed_user))
          )
        }

        WebMock.stub_request(:delete, "#{cf_api_url}/v2/users/__user__removed_user__uuid__").
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: "{}",
        )

        @created_users, @deleted_users = uaa_sync_admin_users.update_admin_users(users)
      end

      it "creates only the new users" do
        expect(WebMock).to have_requested(
          :post, "#{uaa_api_url}/Users"
        ).with(
          body: /"userName":"new_user"/,
        ).once
        expect(WebMock).not_to have_requested(
          :post, "#{uaa_api_url}/Users"
        ).with(
          body: /"userName":"existing_user"/,
        ).once
      end

      it "new users are added as members of admin groups" do
        uaa_sync_admin_users.admin_groups.each { |groupname|
          expect(WebMock).to have_requested(
            :put, "#{uaa_api_url}/Groups/__group__#{groupname}__uuid__"
          ).with(
            body: /"members":.*"__user__new_user__uuid__"/,
          ).once
        }
      end

      it "existing members and admin are kept in the groups" do
        uaa_sync_admin_users.admin_groups.each { |groupname|
          expect(WebMock).to have_requested(
            :put, "#{uaa_api_url}/Groups/__group__#{groupname}__uuid__"
          ).with(
            body: /"members":.*"__user__existing_user__uuid__"/,
          ).once
          expect(WebMock).to have_requested(
            :put, "#{uaa_api_url}/Groups/__group__#{groupname}__uuid__"
          ).with(
            body: /"members":.*"__user__admin__uuid__"/,
          ).once
        }
      end

      it "does not delete the admin user" do
        expect(WebMock).not_to have_requested(
          :delete, "#{cf_api_url}/v2/users/__user__admin__uuid__"
        )
      end

      it "deletes extra users older than 2h" do
        expect(WebMock).to have_requested(
          :delete, "#{cf_api_url}/v2/users/__user__removed_user__uuid__"
        )
      end

      it "keeps extra users newer than 2h" do
        expect(WebMock).not_to have_requested(
          :delete, "#{cf_api_url}/v2/users/__user__test_user_1__uuid__"
        )
        expect(WebMock).not_to have_requested(
          :delete, "#{cf_api_url}/v2/users/__user__test_user_2__uuid__"
        )
      end

      it "returns created and deleted users" do
        expect(@created_users.length).to be(1)
        expect(@created_users[0]).to include(username: "new_user")
        expect(@deleted_users.length).to be(1)
        expect(@deleted_users[0]).to include(username: "removed_user")
      end
    end

    context "when deleting a user fails because they are not in Cloud Foundry" do
      let(:uaa_api_url) { uaa_sync_admin_users.target }
      let(:users) { [] }
      before(:each) do
        WebMock.stub_request(:get, %r{^#{uaa_api_url}/Users.*}).
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: json_query_responses([])
          )
        %w(admin removed_user).each { |user_to_match|
          WebMock.stub_request(:get, %r{#{uaa_api_url}/Users\?filter=username eq "#{user_to_match}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com"),
              ])
            )
          WebMock.stub_request(:get, %r{#{uaa_api_url}/Users\?filter=id eq "#{user_uuid(user_to_match)}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com"),
              ])
            )
        }

        uaa_sync_admin_users.admin_groups.each { |group_name|
          WebMock.stub_request(:get, %r{^#{uaa_api_url}/Groups\?filter=displayName eq "#{group_name}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_group_response(group_name, %w(admin existing_user removed_user test_user_1 test_user_2))
              ])
            )
          WebMock.stub_request(:put, %r{^#{uaa_api_url}/Groups/#{group_uuid(group_name)}$}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_group_response(group_name, %w(admin existing_user new_user removed_user))
          )
        }
        WebMock.stub_request(:delete, "#{cf_api_url}/v2/users/__user__removed_user__uuid__").
          to_return(
            status: 404,
            headers: { "content-type" => "application/json" },
            body: '{"error_code": "CF-UserNotFound"}',
          )

        WebMock.stub_request(:delete, "#{uaa_api_url}/Users/__user__removed_user__uuid__").
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: json_user_response("removed_user", "removed_user@example.com"),
          )

        @created_users, @deleted_users = uaa_sync_admin_users.update_admin_users(users)
      end

      it "falls back to the UAA API" do
        expect(WebMock).to have_requested(
          :delete, "#{cf_api_url}/v2/users/__user__removed_user__uuid__"
        )
        expect(WebMock).to have_requested(
          :delete, "#{uaa_api_url}/Users/__user__removed_user__uuid__"
        )
      end
    end

    context "when changing authentication origin" do
      let(:uaa_api_url) { uaa_sync_admin_users.target }
      let(:users) {
        [
          { username: "google_user", email: "google_user@example.com", origin: "google" },
        ]
      }

      before(:each) do
        %w(admin google_user).each { |user_to_match|
          WebMock.stub_request(:get, %r{#{uaa_api_url}/Users\?filter=username eq "#{user_to_match}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com"),
              ])
          )
          WebMock.stub_request(:get, %r{#{uaa_api_url}/Users\?filter=id eq "#{user_uuid(user_to_match)}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com"),
              ])
          )
        }

        WebMock.stub_request(:post, %r{^#{uaa_api_url}/Users.*}).
          with(
            body: /"userName":"google_user".*"emails":\[{"value":"google_user@example\.com"}/,
          ).
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: json_user_response("google_user", "google_user@example.com"),
          )

        uaa_sync_admin_users.admin_groups.each { |group_name|
          WebMock.stub_request(:get, %r{^#{uaa_api_url}/Groups\?filter=displayName eq "#{group_name}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_group_response(group_name, %w(admin google_user))
              ])
            )
          WebMock.stub_request(:put, %r{^#{uaa_api_url}/Groups/#{group_uuid(group_name)}$}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_group_response(group_name, %w(admin google_user))
          )
        }

        WebMock.stub_request(:delete, "#{cf_api_url}/v2/users/__user__google_user__uuid__").
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: "{}",
        )

        @created_users, @deleted_users = uaa_sync_admin_users.update_admin_users(users)
      end

      it "recreates the user" do
        expect(WebMock).to have_requested(
          :delete, "#{cf_api_url}/v2/users/__user__google_user__uuid__"
        )
        expect(WebMock).to have_requested(
          :post, "#{uaa_api_url}/Users"
        ).with(
          body: /"userName":"google_user"/
        ).once
      end
    end
  end
end
