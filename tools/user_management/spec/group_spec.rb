require 'rest-client'
require 'webmock/rspec'

require_relative '../lib/group'
require_relative '../lib/user'

RSpec.describe Group do
  before do
    @fake_user = {
      'email' => 'jeff.jefferson@example.com',
      'google_id' => '000000000000000000000',
      'cf_admin' => true
    }
    @fake_group = {
      'totalResults' => 1,
      'resources' => [
        { id: '00000000-0000-0000-0000-000000000000-group' }
      ]
    }
    @fake_member = {
      'origin' => 'google',
      'value' => '00000000-0000-0000-0000-000000000001-user',
      'entity' => {
        'userName' => '000000000000000000000',
      }
    }
    @fake_uaa_client = RestClient::Resource.new('http://fake-uaa.internal')
  end

  context 'get_group' do
    it 'retrieves the group from UAA' do
      stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
        .to_return(body: JSON.generate(@fake_group))

      group = Group.new('__test__', [])
      expect { group.get_group(@fake_uaa_client) }.to_not raise_error(Exception)
      assert_requested(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
      expect(group.guid).to eq '00000000-0000-0000-0000-000000000000-group'
    end
  end

  context 'get_members' do
    it 'retrieves its members' do
      stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
        .to_return(body: JSON.generate(@fake_group))

      stub_request(:get, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members?returnEntities=true')
        .to_return(body: JSON.generate([@fake_member]))

      group = Group.new('__test__', [])
      members = group.get_members(@fake_uaa_client)
      expect(members.length).to eq 1
      expect(members[0]['origin']).to eq 'google'
      expect(members[0]['entity']['userName']).to eq '000000000000000000000'
      expect(members[0]['value']).to eq '00000000-0000-0000-0000-000000000001-user'
    end
  end

  context 'add_member' do
    before do
      stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
        .to_return(body: JSON.generate(@fake_group))
    end

    it 'adds a member' do
      stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
        .to_return(body: JSON.generate(@fake_group))

      stub_request(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members')
        .to_return(status: 201, body: JSON.generate({}))

      g = Group.new('__test__', [User.new(@fake_user)])
      g.get_group(@fake_uaa_client)

      expect { g.add_member('00000000-0000-0000-0000-000000000001-user', 'google', @fake_uaa_client) }
        .to_not raise_error(Exception)
      assert_requested(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members', times: 1) { |req|
        JSON.parse(req.body)['value'] == '00000000-0000-0000-0000-000000000001-user'
      }
    end

    it 'raises an error when UAA responds with a non-201 status code' do
      stub_request(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members')
        .to_return(status: 400, body: JSON.generate({}))

      g = Group.new('__test__', [User.new(@fake_user)])
      g.get_group(@fake_uaa_client)

      expect { g.add_member('00000000-0000-0000-0000-000000000001-user', 'google', @fake_uaa_client) }
        .to raise_error(Exception, /Bad Request/)
    end
  end

  context 'remove_member' do
    before do
      stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
        .to_return(body: JSON.generate(@fake_group))
    end

    it 'removes a member' do
      stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
        .to_return(body: JSON.generate(@fake_group))

      stub_request(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000001-user')
        .to_return(status: 200, body: JSON.generate({}))

      g = Group.new('__test__', [User.new(@fake_user)])
      g.get_group(@fake_uaa_client)

      expect { g.remove_member('00000000-0000-0000-0000-000000000001-user', @fake_uaa_client) }
        .to_not raise_error(Exception)
      assert_requested(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000001-user')
    end

    it 'raises an error when UAA responds with a non-200 status code' do
      stub_request(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000001-user')
        .to_return(status: 404, body: JSON.generate({}))

      g = Group.new('__test__', [User.new(@fake_user)])
      g.get_group(@fake_uaa_client)

      expect { g.remove_member('00000000-0000-0000-0000-000000000001-user', @fake_uaa_client) }
        .to raise_error(Exception, /Not Found/)
    end
  end

  context 'add_desired_users' do
    before do
      stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22jeff.jefferson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22')
        .to_return(status: 200, body: JSON.generate(
          totalResults: 1,
          resources: [{
            id: '00000000-0000-0000-0000-000000000001-user'
          }]
        ))

      stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22rich.richardson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22100000000000000000001%22')
        .to_return(status: 200, body: JSON.generate(
          totalResults: 1,
          resources: [{
            id: '00000000-0000-0000-0000-000000000002-user'
          }]
        ))

      stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
        .to_return(body: JSON.generate(@fake_group))

      @u1 = User.new(@fake_user)
      @u2 = User.new(
        'email' => 'rich.richardson@example.com',
        'google_id' => '100000000000000000001'
      )
    end

    it 'adds its desired users' do
      stub_request(:get, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members?returnEntities=true')
        .to_return(body: JSON.generate([@fake_member]))

      stub_request(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members')
        .to_return(status: 201, body: JSON.generate({}))

      @u1.get_user(@fake_uaa_client)
      @u2.get_user(@fake_uaa_client)

      g = Group.new('__test__', [@u1, @u2])
      g.get_group(@fake_uaa_client)

      g.add_desired_users(@fake_uaa_client)
      assert_requested(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members', times: 1) { |req|
        JSON.parse(req.body)['value'] == '00000000-0000-0000-0000-000000000002-user'
      }
    end

    it 'only adds desired users' do
      stub_request(:get, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members?returnEntities=true')
        .to_return(body: JSON.generate([]))

      stub_request(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members')
        .to_return(status: 201, body: JSON.generate({}))

      @u1.get_user(@fake_uaa_client)
      @u2.get_user(@fake_uaa_client)

      g = Group.new('__test__', [@u1])
      g.get_group(@fake_uaa_client)

      expect { g.add_desired_users(@fake_uaa_client) }.to_not raise_error(Exception)
      assert_requested(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members', times: 1) { |req|
        JSON.parse(req.body)['value'] == '00000000-0000-0000-0000-000000000001-user'
      }
      assert_not_requested(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members', times: 1) { |req|
        JSON.parse(req.body)['value'] == '00000000-0000-0000-0000-000000000002-user'
      }
    end
  end

  context 'remove_unexpected_members' do
    before do
      stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22jeff.jefferson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22')
        .to_return(status: 200, body: JSON.generate(
          totalResults: 1,
          resources: [{
            id: '00000000-0000-0000-0000-000000000001-user'
          }]
        ))

      stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22rich.richardson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22100000000000000000001%22')
        .to_return(status: 200, body: JSON.generate(
          totalResults: 1,
          resources: [{
            id: '00000000-0000-0000-0000-000000000002-user'
          }]
        ))

      stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
        .to_return(body: JSON.generate(
          totalResults: 1,
          resources: [
            { id: '00000000-0000-0000-0000-000000000000-group' }
          ]
        ))

      stub_request(:get, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members?returnEntities=true')
        .to_return(body: JSON.generate([
          @fake_member,
          {
            'origin' => 'google',
            'value' => '00000000-0000-0000-0000-000000000002-user',
            'entity' => {
              'userName' => '000000000000000000011',
            }
          }
        ]))

      @u1 = User.new(@fake_user)
      @u2 = User.new(
        'email' => 'rich.richardson@example.com',
        'google_id' => '100000000000000000001'
      )
    end

    it 'removes the undesired users' do
      stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22jeff.jefferson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22')
        .to_return(status: 200, body: JSON.generate(
          totalResults: 1,
          resources: [
            { id: '00000000-0000-0000-0000-000000000001-user' }
          ]
        ))

      stub_request(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000002-user')
        .to_return(status: 200, body: JSON.generate({}))

      @u1.get_user(@fake_uaa_client)
      g = Group.new('__test__', [@u1])

      g.remove_unexpected_members(@fake_uaa_client)
      assert_requested(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000002-user')
    end

    it 'preserves existing desired users' do
      stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22jeff.jefferson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22')
        .to_return(status: 200, body: JSON.generate(
          totalResults: 1,
          resources: [{
            id: '00000000-0000-0000-0000-000000000001-user'
          }]
        ))

      stub_request(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000001-user')
        .to_return(status: 200, body: JSON.generate({}))

      stub_request(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000002-user')
        .to_return(status: 200, body: JSON.generate({}))

      @u1.get_user(@fake_uaa_client)
      g = Group.new('__test__', [@u1])

      g.remove_unexpected_members(@fake_uaa_client)
      assert_not_requested(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000001-user')
    end

    it 'preserves our admin uaa user' do
      stub_request(:get, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members?returnEntities=true')
        .to_return(body: JSON.generate([
          @fake_member,
          {
            'origin' => 'uaa',
            'value' => '00000000-0000-0000-0000-000000000009-user',
            'entity' => {
              'userName' => 'admin',
            }
          }
        ]))

      @u1.get_user(@fake_uaa_client)
      g = Group.new('__test__', [@u1])

      g.remove_unexpected_members(@fake_uaa_client)
      assert_not_requested(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000009-user')
    end

    it 'removes non-admin uaa users' do
      stub_request(:get, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members?returnEntities=true')
        .to_return(body: JSON.generate([
          @fake_member,
          {
            'origin' => 'uaa',
            'value' => '00000000-0000-0000-0000-000000000010-user',
            'entity' => {
              'userName' => 'not-admin',
            }
          }
        ]))

      stub_request(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000010-user')
        .to_return(status: 200, body: JSON.generate({}))

      @u1.get_user(@fake_uaa_client)
      g = Group.new('__test__', [@u1])

      g.remove_unexpected_members(@fake_uaa_client)
      assert_requested(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000010-user')
    end
  end
end
