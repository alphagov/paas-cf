require 'rest-client'
require 'webmock/rspec'

require_relative '../lib/user'

RSpec.describe User do
  before do
    @fake_uaa_client = RestClient::Resource.new('http://fake-uaa.internal')
  end

  it 'checks if exists in UAA' do
    stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22jeff.jefferson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22')
      .to_return(body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-user',
        }],
        totalResults: 1
      ))

    u = User.new(
      'email' => 'jeff.jefferson@example.com',
      'google_id' => '000000000000000000000',
      'cf_admin' => true
    )

    expect(u.exists?(@fake_uaa_client)).to be true
    assert_requested(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22jeff.jefferson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22')

    stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22rich.richardson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22999999999999999999999%22')
      .to_return(status: 404, body: JSON.generate({}))

    u2 = User.new(
      'email' => 'rich.richardson@example.com',
      'google_id' => '999999999999999999999'
    )

    expect(u2.exists?(@fake_uaa_client)).to be false
  end

  it 'creates the entity' do
    stub_request(:post, 'http://fake-uaa.internal/Users')
      .to_return(status: 201, body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-user',
        }],
        totalResults: 1
      ))

    u = User.new(
      'email' => 'jeff.jefferson@example.com',
      'google_id' => '000000000000000000000',
      'cf_admin' => true
    )

    expect(u.create(@fake_uaa_client)).to be true
    assert_requested(:post, 'http://fake-uaa.internal/Users', times: 1) { |req|
      JSON.parse(req.body)['userName'] == '000000000000000000000'
    }

    stub_request(:post, 'http://fake-uaa.internal/Users')
      .to_return(status: 400, body: JSON.generate({}))

    u2 = User.new(
      'email' => 'rich.richardson',
      'google_id' => '999999999999999999999'
    )

    expect { u2.create(@fake_uaa_client) }.to raise_error(Exception, /Bad Request/)

    stub_request(:post, 'http://fake-uaa.internal/Users')
      .to_return(status: 206, body: JSON.generate({}))

    u3 = User.new(
      'email' => 'jeff.jefferson@example.com',
      'google_id' => '000000000000000000000'
    )

    expect(u3.create(@fake_uaa_client)).to be false
  end

  it 'throw errors when UAA API returns >=400 response' do
    stub_request(:post, 'http://fake-uaa.internal/Users')
      .to_return(status: 201, body: JSON.generate(
        resources: [{
          id: '00000000-0000-0000-0000-000000000000-user'
        }],
        totalResults: 1
      ))

    stub_request(:get, 'http://fake-uaa.internal/Users?filter=email%20eq%20%22jeff.jefferson@example.com%22%20and%20origin%20eq%20%22google%22%20and%20userName%20eq%20%22000000000000000000000%22')
      .to_return(status: 404, body: JSON.generate({}))

    u = User.new(
      'email' => 'jeff.jefferson@example.com',
      'google_id' => '000000000000000000000',
      'cf_admin' => true
    )

    expect { u.get_user(@fake_uaa_client) }.to raise_error(Exception)
  end
end
