require "rest-client"
require "webmock/rspec"

require_relative "../lib/group"
require_relative "../lib/user"

RSpec.describe Group do
  before do
    @fake_uaa_client = RestClient::Resource.new("http://fake-uaa.internal", headers: {
      "Authorization" => "fake-token",
      "Content-Type" => "application/json"
    })
  end

  context "add_member" do
    before do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group")

      stub_searching_for_user(200, "google", "11111111111111", "user-guid")
      @user = User.new("email" => "user-one@na.me", "username" => "11111111111111")
      @user.get_user(@fake_uaa_client)
    end

    it "adds a member" do
      stub_adding_user_to_group(201, "guid-of-__test__-group", "user-guid")

      g = Group.new("__test__", [@user])
      g.get_group(@fake_uaa_client)
      g.add_member("user-guid", @fake_uaa_client)
    end

    it "raises an error when UAA responds with a non-201 status code" do
      stub_adding_user_to_group(400, "guid-of-__test__-group", "user-guid")

      g = Group.new("__test__", [@user])
      g.get_group(@fake_uaa_client)
      expect { g.add_member("user-guid", @fake_uaa_client) }
        .to raise_error(RestClient::BadRequest, /Bad Request/)
    end
  end

  context "remove_member" do
    before do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "guid-of-existing-member" }
      ])
    end

    it "removes a member" do
      stub_removing_user_from_group(200, "guid-of-__test__-group", "guid-of-existing-member")

      g = Group.new("__test__", [])
      g.get_group(@fake_uaa_client)
      g.remove_member("guid-of-existing-member", @fake_uaa_client)
    end

    it "raises an error when UAA responds with a non-200 status code" do
      stub_removing_user_from_group(400, "guid-of-__test__-group", "guid-of-existing-member")

      g = Group.new("__test__", [])
      g.get_group(@fake_uaa_client)
      expect { g.remove_member("guid-of-existing-member", @fake_uaa_client) }
        .to raise_error(RestClient::BadRequest, /Bad Request/)
    end
  end

  context "add_desired_users" do
    before do
      stub_searching_for_user(200, "google", "11111111111111", "user-1-guid")
      stub_getting_user_by_id(200, "user-1-guid", "google", "11111111111111", Time.now)
      @u1 = User.new("email" => "user-one@na.me", "username" => "11111111111111")
      @u1.get_user(@fake_uaa_client)

      stub_searching_for_user(200, "google", "22222222222222", "user-2-guid")
      stub_getting_user_by_id(200, "user-2-guid", "google", "22222222222222", Time.now)
      @u2 = User.new("email" => "user-two@na.me", "username" => "22222222222222")
      @u2.get_user(@fake_uaa_client)
    end

    it "adds its desired users" do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "user-1-guid" }
      ])

      g = Group.new("__test__", [@u1, @u2])
      g.get_group(@fake_uaa_client)

      stub_adding_user_to_group(201, "guid-of-__test__-group", "user-2-guid")
      g.add_desired_users(@fake_uaa_client)
    end
  end

  context "remove_unexpected_members" do
    before do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "desired-user-guid" },
        { "id" => "unwanted-google-user-guid" },
        { "id" => "unwanted-uaa-user-guid" }
      ])

      stub_searching_for_user(200, "google", "11111111111111", "desired-user-guid")
      stub_getting_user_by_id(200, "desired-user-guid", "google", "11111111111111", Time.now)
      @u1 = User.new("email" => "user-one@na.me", "username" => "11111111111111")

      stub_getting_user_by_id(200, "unwanted-google-user-guid", "google", "22222222222222", Time.now - 86400)
      stub_searching_for_user(200, "google", "22222222222222", "unwanted-google-user-guid")

      stub_getting_user_by_id(200, "unwanted-uaa-user-guid", "uaa", "user@unexpected.in.group", Time.now - 86400)
      stub_searching_for_user(200, "uaa", "user@unexpected.in.group", "unwanted-uaa-user-guid")
    end

    it "removes the undesired users" do
      stub_removing_user_from_group(200, "guid-of-__test__-group", "unwanted-google-user-guid")
      stub_removing_user_from_group(200, "guid-of-__test__-group", "unwanted-uaa-user-guid")

      @u1.get_user(@fake_uaa_client)
      g = Group.new("__test__", [@u1])
      g.remove_unexpected_members(@fake_uaa_client)
    end

    it "preserves existing desired users" do
      stub_removing_user_from_group(200, "guid-of-__test__-group", "unwanted-google-user-guid")
      stub_removing_user_from_group(200, "guid-of-__test__-group", "unwanted-uaa-user-guid")

      @u1.get_user(@fake_uaa_client)
      g = Group.new("__test__", [@u1])
      g.remove_unexpected_members(@fake_uaa_client)
      assert_not_requested(:delete, "http://fake-uaa.internal/Groups/guid-of-__test__-group/members/desired-user-guid")
    end

    it "preserves our admin uaa user" do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "guid-of-user-who-is-the-uaa-admin" }
      ])
      stub_getting_user_by_id(200, "guid-of-user-who-is-the-uaa-admin", "uaa", "admin", Time.now - 86400)

      g = Group.new("__test__", [])
      g.remove_unexpected_members(@fake_uaa_client)
      assert_not_requested(:delete, "http://fake-uaa.internal/Groups/guid-of-__test__-group/members/guid-of-user-who-is-the-uaa-admin")
    end

    it "removes non-admin uaa users created more than one hour ago" do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "guid-of-day-old-uaa-user" }
      ])
      stub_getting_user_by_id(200, "guid-of-day-old-uaa-user", "uaa", "day-old-uaa-user", Time.now - 86400)
      stub_removing_user_from_group(200, "guid-of-__test__-group", "guid-of-day-old-uaa-user")

      g = Group.new("__test__", [])
      g.remove_unexpected_members(@fake_uaa_client)
      assert_requested(:delete, "http://fake-uaa.internal/Groups/guid-of-__test__-group/members/guid-of-day-old-uaa-user")
    end

    it "preserves non-admin uaa users created less than an hour ago" do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "guid-of-minute-old-uaa-user" }
      ])
      stub_getting_user_by_id(200, "guid-of-minute-old-uaa-user", "uaa", "minute-old-uaa-user", Time.now - 60)
      stub_removing_user_from_group(200, "guid-of-__test__-group", "guid-of-minute-old-uaa-user")

      g = Group.new("__test__", [])
      g.remove_unexpected_members(@fake_uaa_client)
      assert_not_requested(:delete, "http://fake-uaa.internal/Groups/guid-of-__test__-group/members/guid-of-minute-old-uaa-user")
    end

    it "removes members with an unusual origin" do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "guid-of-unusual-member", "origin" => "something-that-is-not-uaa" }
      ])
      stub_removing_user_from_group(200, "guid-of-__test__-group", "guid-of-unusual-member")

      g = Group.new("__test__", [])
      g.remove_unexpected_members(@fake_uaa_client)
    end

    it "removes members with an unusual type" do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "guid-of-unusual-member", "type" => "GROUP" }
      ])
      stub_removing_user_from_group(200, "guid-of-__test__-group", "guid-of-unusual-member")

      g = Group.new("__test__", [])
      g.remove_unexpected_members(@fake_uaa_client)
    end
  end

  context "get_group" do
    it "retrieves the group from UAA" do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group")

      group = Group.new("__test__", [])
      group.get_group(@fake_uaa_client)
      expect(group.guid).to eq "guid-of-__test__-group"
    end
  end

  context "get_member_users" do
    before do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "guid-of-member-1" },
        { "id" => "guid-of-member-2" }
      ])
      stub_getting_user_by_id(200, "guid-of-member-1", "origin-of-member-1", "username-of-member-1", Time.now)
      stub_getting_user_by_id(200, "guid-of-member-2", "origin-of-member-2", "username-of-member-2", Time.now)
    end

    it "retrieves users who are members of the group" do
      group = Group.new("__test__", [])
      members = group.get_member_users(@fake_uaa_client)
      expect(members.length).to eq 2
      expect(members[0]["id"]).to eq "guid-of-member-1"
      expect(members[0]["origin"]).to eq "origin-of-member-1"
      expect(members[0]["userName"]).to eq "username-of-member-1"
      expect(members[1]["id"]).to eq "guid-of-member-2"
      expect(members[1]["origin"]).to eq "origin-of-member-2"
      expect(members[1]["userName"]).to eq "username-of-member-2"
    end

    it "does not error if the group has a non-user member" do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "guid-of-member-1" },
        { "id" => "guid-of-member-2", "type" => "GROUP" }
      ])
      group = Group.new("__test__", [])
      members = group.get_member_users(@fake_uaa_client)
      expect(members).to include(
        "id" => "guid-of-member-2",
        "origin" => "*** UNUSUAL MEMBER WITH ORIGIN 'uaa' AND TYPE 'GROUP' ***",
        "userName" => "*** UNUSUAL MEMBER WITH ORIGIN 'uaa' AND TYPE 'GROUP' ***"
      )
    end

    it "does not error if the group has a member not managed by UAA" do
      stub_searching_for_group(200, "__test__", "guid-of-__test__-group", [
        { "id" => "guid-of-member-1" },
        { "id" => "guid-of-member-2", "origin" => "something-that-is-not-uaa" }
      ])
      group = Group.new("__test__", [])
      members = group.get_member_users(@fake_uaa_client)
      expect(members).to include(
        "id" => "guid-of-member-2",
        "origin" => "*** UNUSUAL MEMBER WITH ORIGIN 'something-that-is-not-uaa' AND TYPE 'USER' ***",
        "userName" => "*** UNUSUAL MEMBER WITH ORIGIN 'something-that-is-not-uaa' AND TYPE 'USER' ***"
      )
    end
  end

  context "get_uaa_user" do
    it "gets users by their id" do
      stub_getting_user_by_id(200, "guid-of-member", "origin-of-member", "username-of-member", Time.now)

      group = Group.new("__test__", [])
      user = group.get_uaa_user("guid-of-member", @fake_uaa_client)
      expect(user["id"]).to eq "guid-of-member"
      expect(user["origin"]).to eq "origin-of-member"
      expect(user["userName"]).to eq "username-of-member"
    end

    it "does not error when a member does not have a corresponding user" do
      stub_getting_user_by_id(404, "guid-of-member-which-does-not-exist")

      group = Group.new("__test__", [])
      user = group.get_uaa_user("guid-of-member-which-does-not-exist", @fake_uaa_client)
      expect(user["id"]).to eq "guid-of-member-which-does-not-exist"
      expect(user["origin"]).to eq "*** THE USER BEHIND THIS MEMBERSHIP DOES NOT EXIST ***"
      expect(user["userName"]).to eq "*** THE USER BEHIND THIS MEMBERSHIP DOES NOT EXIST ***"
    end
  end
end
