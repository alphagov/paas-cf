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
    let(:target) { "https://test.uaa.target" }
    let(:admin_user) { "admin" }
    let(:admin_password) { "password" }
    let(:uaa_sync_admin_users) {
      UaaSyncAdminUsers.new(target, admin_user, admin_password, skip_ssl_validation: true, log_level: :warn)
    }

    before :each do
      WebMock.stub_request(:post, %r{https://.+:.+@[^/]+/oauth/token}).
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
      let(:users) {
        [
          { username: "existing_user", email: "existing_user@example.com", origin: "uaa" },
          { username: "new_user", email: "new_user@example.com", origin: "uaa" },
        ]
      }

      before(:each) do
        WebMock.stub_request(:get, %r{^#{target}/Users.*}).
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: json_query_responses([])
        )
        %w(admin existing_user removed_user).each { |user_to_match|
          WebMock.stub_request(:get, %r{#{target}/Users\?filter=username eq "#{user_to_match}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com"),
              ])
          )
          WebMock.stub_request(:get, %r{#{target}/Users\?filter=id eq "#{user_uuid(user_to_match)}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com"),
              ])
          )
        }
        %w(test_user_1 test_user_2).each { |user_to_match|
          WebMock.stub_request(:get, %r{#{target}/Users\?filter=id eq "#{user_uuid(user_to_match)}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com", [], 1),
              ])
          )
        }
        WebMock.stub_request(:post, %r{^#{target}/Users.*}).
          with(
            body: /"userName":"new_user".*"emails":\[{"value":"new_user@example\.com"}/,
          ).
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: json_user_response("new_user", "new_user@example.com"),
          )

        uaa_sync_admin_users.admin_groups.each { |group_name|
          WebMock.stub_request(:get, %r{^#{target}/Groups\?filter=displayName eq "#{group_name}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_group_response(group_name, %w(admin existing_user removed_user test_user_1 test_user_2))
              ])
            )
          WebMock.stub_request(:put, %r{^#{target}/Groups/#{group_uuid(group_name)}$}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_group_response(group_name, %w(admin existing_user new_user removed_user))
          )
        }

        WebMock.stub_request(:delete, "#{target}/Users/__user__removed_user__uuid__").
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: json_user_response("removed_user", "removed_user@example.com"),
        )

        @created_users, @deleted_users = uaa_sync_admin_users.update_admin_users(users)
      end

      it "creates only the new users" do
        expect(WebMock).to have_requested(
          :post, "#{target}/Users"
        ).with(
          body: /"userName":"new_user"/,
        ).once
        expect(WebMock).not_to have_requested(
          :post, "#{target}/Users"
        ).with(
          body: /"userName":"existing_user"/,
        ).once
      end

      it "new users are added as members of admin groups" do
        uaa_sync_admin_users.admin_groups.each { |groupname|
          expect(WebMock).to have_requested(
            :put, "#{target}/Groups/__group__#{groupname}__uuid__"
          ).with(
            body: /"members":.*"__user__new_user__uuid__"/,
          ).once
        }
      end

      it "existing members and admin are kept in the groups" do
        uaa_sync_admin_users.admin_groups.each { |groupname|
          expect(WebMock).to have_requested(
            :put, "#{target}/Groups/__group__#{groupname}__uuid__"
          ).with(
            body: /"members":.*"__user__existing_user__uuid__"/,
          ).once
          expect(WebMock).to have_requested(
            :put, "#{target}/Groups/__group__#{groupname}__uuid__"
          ).with(
            body: /"members":.*"__user__admin__uuid__"/,
          ).once
        }
      end
      it "does not delete the admin user" do
        expect(WebMock).not_to have_requested(
          :delete, "#{target}/Users/__user__admin__uuid__"
        )
      end

      it "deletes extra users older than 2h" do
        expect(WebMock).to have_requested(
          :delete, "#{target}/Users/__user__removed_user__uuid__"
        )
      end

      it "keeps extra users newer than 2h" do
        expect(WebMock).not_to have_requested(
          :delete, "#{target}/Users/__user__test_user_1__uuid__"
        )
        expect(WebMock).not_to have_requested(
          :delete, "#{target}/Users/__user__test_user_2__uuid__"
        )
      end

      it "returns created and deleted users" do
        expect(@created_users.length).to be(1)
        expect(@created_users[0]).to include(username: "new_user")
        expect(@deleted_users.length).to be(1)
        expect(@deleted_users[0]).to include(username: "removed_user")
      end
    end

    context "when changing authentication origin" do
      let(:users) {
        [
          { username: "google_user", email: "google_user@example.com", origin: "google" },
        ]
      }

      before(:each) do
        %w(admin google_user).each { |user_to_match|
          WebMock.stub_request(:get, %r{#{target}/Users\?filter=username eq "#{user_to_match}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com"),
              ])
          )
          WebMock.stub_request(:get, %r{#{target}/Users\?filter=id eq "#{user_uuid(user_to_match)}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_user_response(user_to_match, "#{user_to_match}@example.com"),
              ])
          )
        }

        WebMock.stub_request(:post, %r{^#{target}/Users.*}).
          with(
            body: /"userName":"google_user".*"emails":\[{"value":"google_user@example\.com"}/,
          ).
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: json_user_response("google_user", "google_user@example.com"),
          )

        uaa_sync_admin_users.admin_groups.each { |group_name|
          WebMock.stub_request(:get, %r{^#{target}/Groups\?filter=displayName eq "#{group_name}".*}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_query_responses([
                json_group_response(group_name, %w(admin google_user))
              ])
            )
          WebMock.stub_request(:put, %r{^#{target}/Groups/#{group_uuid(group_name)}$}).
            to_return(
              status: 200,
              headers: { "content-type" => "application/json" },
              body: json_group_response(group_name, %w(admin google_user))
          )
        }

        WebMock.stub_request(:delete, "#{target}/Users/__user__google_user__uuid__").
          to_return(
            status: 200,
            headers: { "content-type" => "application/json" },
            body: json_user_response("google_user", "google_user@example.com"),
        )

        @created_users, @deleted_users = uaa_sync_admin_users.update_admin_users(users)
      end

      it "recreates the user" do
        expect(WebMock).to have_requested(
          :delete, "#{target}/Users/__user__google_user__uuid__"
        )
        expect(WebMock).to have_requested(
          :post, "#{target}/Users"
        ).with(
          body: /"userName":"google_user"/
        ).once
      end
    end
  end
end
