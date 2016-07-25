require 'mimic'

RSpec.describe "kibana_set_utc.rb", :type => :aruba do

  ES_HOST = "127.0.0.1"
  ES_PORT = "9200"
  KIBANA_CONFIG_PATH = "/.kibana/config/4.3.1"
  KIBANA_INDEX_PATH = "/.kibana"

  Thread.abort_on_exception = true

  def run_set_utc_script
    run("./kibana_set_utc.rb")
  end

  before :all do
    @elasticsearch = Mimic.mimic(:hostname => ES_HOST, :port => ES_PORT)
    set_environment_variable 'ES_HOST', ES_HOST
    set_environment_variable 'ES_PORT', ES_PORT
  end

  after :each do
    Mimic.reset_all!
  end

  after :all do
    Mimic.cleanup!
  end

  it "creates index and adds utc config if no index exists" do

    @elasticsearch.instance_variable_get(:@app).not_found do
      # override the not_found handler provided by mimic,
      # so that we don't emit an empty body instead of the json we want with the 404
      [404, {}, nil]
    end

    @elasticsearch.get(KIBANA_CONFIG_PATH).returning('{ "found": false }', 404)
    @elasticsearch.put(KIBANA_INDEX_PATH).returning('{}', 201)
    @elasticsearch.put(KIBANA_CONFIG_PATH).returning('{}', 201)

    run_set_utc_script

    expect(last_command_started).to have_exit_status(0)
    expect(@elasticsearch.received_requests.size).to be(3)
    expect(@elasticsearch.received_requests).to contain_request('GET', KIBANA_CONFIG_PATH)
    expect(@elasticsearch.received_requests).to contain_request('PUT', KIBANA_INDEX_PATH)
    expect(@elasticsearch.received_requests).to contain_request('PUT', KIBANA_CONFIG_PATH)
  end

  it "adds utc config if index exists but config is not present" do
    @elasticsearch.get(KIBANA_CONFIG_PATH).returning('{ "found": true }', 200)
    @elasticsearch.put(KIBANA_CONFIG_PATH).returning('{}', 200)

    run_set_utc_script

    expect(last_command_started).to have_exit_status(0)

    expect(@elasticsearch.received_requests.size).to be(2)
    expect(@elasticsearch.received_requests).to contain_request('GET', KIBANA_CONFIG_PATH)
    expect(@elasticsearch.received_requests).to contain_request('PUT', KIBANA_CONFIG_PATH)
  end

  it "adds utc config if index exists and wrong config is present" do
    @elasticsearch.get(KIBANA_CONFIG_PATH).returning('{ "found": true, "_source": { "dateFormat:tz": "NOT_UTC" } }', 200)
    @elasticsearch.put(KIBANA_CONFIG_PATH).returning('{}', 200)

    run_set_utc_script

    expect(last_command_started).to have_exit_status(0)

    expect(@elasticsearch.received_requests.size).to be(2)
    expect(@elasticsearch.received_requests).to contain_request('GET', KIBANA_CONFIG_PATH)
    expect(@elasticsearch.received_requests).to contain_request('PUT', KIBANA_CONFIG_PATH)
  end

  it "reports an error if elastic search is not available" do

    run_set_utc_script

    expect(last_command_started).to have_exit_status(1)
    expect(@elasticsearch.received_requests.size).to be(0)
  end

  it "does nothing if index exists and config is already UTC" do
    @elasticsearch.get(KIBANA_CONFIG_PATH).returning('{ "found": true, "_source": { "dateFormat:tz": "UTC" } }', 200)

    run_set_utc_script

    expect(last_command_started).to have_exit_status(0)

    expect(@elasticsearch.received_requests.size).to be(1)
    expect(@elasticsearch.received_requests).to contain_request('GET', KIBANA_CONFIG_PATH)
  end

  it "reports an error if elastic search responds with an unexpected status code" do
    @elasticsearch.get(KIBANA_CONFIG_PATH).returning('{ "found": true, "_source": { "dateFormat:tz": "UTC" } }', 500)

    run_set_utc_script

    expect(last_command_started).to have_exit_status(1)

    expect(@elasticsearch.received_requests.size).to be(1)
    expect(@elasticsearch.received_requests).to contain_request('GET', KIBANA_CONFIG_PATH)
  end

  matcher :contain_request do |expected_method, expected_path|
    match do |requests|
      requests.any? do |request|
        actual_path = request.instance_variable_get(:@path)
        actual_method = request.instance_variable_get(:@method)
        actual_method == expected_method && actual_path == expected_path
      end
    end
  end
end
