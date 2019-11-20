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
    @fake_uaa_client = RestClient::Resource.new('http://fake-uaa.internal')
  end

  it 'is retrived from UAA' do
    stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
      .to_return(body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-user'
        }],
        totalResults: 1
      ))

    g = Group.new('__test__', [])

    expect { g.get_group(@fake_uaa_client) }.to_not raise_error(Exception)
    assert_requested(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
  end

  it 'retrives its members' do
    stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
      .to_return(body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-group',
          members: [{
            value: '00000000-0000-0000-0000-000000000000-user'
          }],
        }],
        totalResults: 1
      ))

    g = Group.new('__test__', [])

    members = []
    expect { members.concat(g.get_members(@fake_uaa_client)) }.to_not raise_error(Exception)
    expect(members.length).to eq 1
  end

  it 'adds a member' do
    stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
      .to_return(body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-group',
        }],
        totalResults: 1
      ))

    stub_request(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members')
      .to_return(status: 201, body: JSON.generate({}))

    g = Group.new('__test__', [User.new(@fake_user)])
    g.get_group(@fake_uaa_client)

    expect { g.add_member('00000000-0000-0000-0000-000000000000-user', 'google', @fake_uaa_client) }.to_not raise_error(Exception)
    assert_requested(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members', times: 1) { |req|
      JSON.parse(req.body)['value'] == '00000000-0000-0000-0000-000000000000-user'
    }

    stub_request(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members')
      .to_return(status: 400, body: JSON.generate({}))

    g = Group.new('__test__', [User.new(@fake_user)])
    g.get_group(@fake_uaa_client)

    expect { g.add_member('00000000-0000-0000-0000-000000000000-user', 'google', @fake_uaa_client) }.to raise_error(Exception, /Bad Request/)

    stub_request(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members')
      .to_return(status: 203, body: JSON.generate({}))

    g = Group.new('__test__', [User.new(@fake_user)])
    g.get_group(@fake_uaa_client)

    expect { g.add_member('00000000-0000-0000-0000-000000000000-user', 'google', @fake_uaa_client) }.to raise_error(Exception, /unexpected response code (.+?) when adding member/)
  end

  it 'removes a member' do
    stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
      .to_return(body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-group',
          members: [{
            value: '00000000-0000-0000-0000-000000000000-user',
          }],
        }],
        totalResults: 1
      ))

    stub_request(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000000-user')
      .to_return(status: 200, body: JSON.generate({}))

    g = Group.new('__test__', [User.new(@fake_user)])
    g.get_group(@fake_uaa_client)

    expect { g.remove_member('00000000-0000-0000-0000-000000000000-user', @fake_uaa_client) }.to_not raise_error(Exception)
    assert_requested(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000000-user')

    stub_request(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000000-user')
      .to_return(status: 404, body: JSON.generate({}))

    g = Group.new('__test__', [User.new(@fake_user)])
    g.get_group(@fake_uaa_client)

    expect { g.remove_member('00000000-0000-0000-0000-000000000000-user', @fake_uaa_client) }.to raise_error(Exception, /Not Found/)

    stub_request(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000000-user')
      .to_return(status: 203, body: JSON.generate({}))

    g = Group.new('__test__', [User.new(@fake_user)])
    g.get_group(@fake_uaa_client)

    expect { g.remove_member('00000000-0000-0000-0000-000000000000-user', @fake_uaa_client) }.to raise_error(Exception, /unexpected response code (.+?) when deleting member/)
  end

  it 'adds its desired users' do
    stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
      .to_return(body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-group',
          members: [{
            value: '00000000-0000-0000-0000-000000000000-user'
          }],
        }],
        totalResults: 1
      ))

    stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22jeff.jefferson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22')
      .to_return(status: 200, body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-user'
        }],
        totalResults: 1
      ))

    stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22rich.richardson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22100000000000000000001%22')
      .to_return(status: 200, body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000001-user'
        }],
        totalResults: 1
      ))

    stub_request(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members')
      .to_return(status: 201, body: JSON.generate({}))

    u = User.new(@fake_user)
    u.get_user(@fake_uaa_client)

    u2 = User.new(
      'email' => 'rich.richardson@example.com',
      'google_id' => '100000000000000000001'
    )
    u2.get_user(@fake_uaa_client)

    g = Group.new('__test__', [u, u2])
    g.get_group(@fake_uaa_client)

    expect { g.add_desired_users(@fake_uaa_client) }.to_not raise_error(Exception)
    assert_not_requested(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members', times: 1) { |req|
      JSON.parse(req.body)['value'] == '00000000-0000-0000-0000-000000000000-user'
    }
    assert_requested(:post, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members', times: 1) { |req|
      JSON.parse(req.body)['value'] == '00000000-0000-0000-0000-000000000001-user'
    }
  end

  it 'removes the undesired users' do
    stub_request(:get, 'http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22__test__%22')
      .to_return(body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-group',
          members: [
            {
              value: '00000000-0000-0000-0000-000000000000-user',
              origin: 'google'
            },
            {
              value: '00000000-0000-0000-0000-000000000001-user',
              origin: 'google'
            },
            {
              value: '00000000-0000-0000-0000-000000000002-user',
              origin: 'uaa'
            },
          ],
        }],
        totalResults: 1
      ))

    stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22jeff.jefferson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22')
      .to_return(status: 200, body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-user'
        }],
        totalResults: 1
      ))

    stub_request(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000001-user')
      .to_return(status: 200, body: JSON.generate({}))

    u = User.new(@fake_user)
    u.get_user(@fake_uaa_client)
    g = Group.new('__test__', [u])

    expect { g.remove_unexpected_members(@fake_uaa_client) }.to_not raise_error(Exception)
    assert_not_requested(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000000-user')
    assert_requested(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000001-user')
    assert_not_requested(:delete, 'http://fake-uaa.internal/Groups/00000000-0000-0000-0000-000000000000-group/members/00000000-0000-0000-0000-000000000002-user')
  end
end
