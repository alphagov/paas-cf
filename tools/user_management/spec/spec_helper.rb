require "simplecov"

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.
  #   # These two settings work together to allow you to limit a spec run
  #   # to individual examples or groups you care about by tagging them with
  #   # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  #   # get run.
  #   config.filter_run :focus
  #   config.run_all_when_everything_filtered = true
  #
  #   # Allows RSpec to persist some state between runs in order to support
  #   # the `--only-failures` and `--next-failure` CLI options. We recommend
  #   # you configure your source control system to ignore this file.
  #   config.example_status_persistence_file_path = "spec/examples.txt"
  #
  #   # Limits the available syntax to the non-monkey patched syntax that is
  #   # recommended. For more details, see:
  #   #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  #   config.disable_monkey_patching!
  #
  #   # This setting enables warnings. It's recommended, but in some cases may
  #   # be too noisy due to issues in dependencies.
  #   config.warnings = true
  #
  #   # Many RSpec users commonly either run the entire suite or an individual
  #   # file, and it's useful to allow more verbose output when running an
  #   # individual spec file.
  #   if config.files_to_run.one?
  #     # Use the documentation formatter for detailed output,
  #     # unless a formatter has already been configured
  #     # (e.g. via a command-line flag).
  #     config.default_formatter = 'doc'
  #   end
  #
  #   # Print the 10 slowest examples and example groups at the
  #   # end of the spec run, to help surface which specs are running
  #   # particularly slow.
  #   config.profile_examples = 10
  #
  #   # Run specs in random order to surface order dependencies. If you find an
  #   # order dependency and want to debug it, you can fix the order by providing
  #   # the seed, which is printed after each run.
  #   #     --seed 1234
  #   config.order = :random
  #
  #   # Seed global randomization in this process using the `--seed` CLI option.
  #   # Setting this allows you to use `--seed` to deterministically reproduce
  #   # test failures related to randomization by passing the same `--seed` value
  #   # as the one that triggered the failure.
  #   Kernel.srand config.seed
end

SimpleCov.start do
  add_filter "/spec/"
end

# The following functions mock out relevant parts of the UAA API

# GET /Groups?filter=displayName eq DISPLAY_NAME
# Used to find Groups based upon their name (e.g., the global auditor group)
def stub_searching_for_group(status, display_name, id = nil, members = [])
  url = "http://fake-uaa.internal/Groups?filter=displayName%20eq%20%22#{display_name}%22"
  stub_body_if_status_is_200 url, status,
    "totalResults" => 1,
    "resources" => [
      "id" => id,
      "displayName" => display_name,
      "members" => members.map do |member|
        {
          "type" => member.fetch("type", "USER"),
          "origin" => member.fetch("origin", "uaa"),
          "value" => member.fetch("id"),
        }
      end,
    ]
end

def stub_searching_for_user(status, origin, username, id = nil)
  url = "http://fake-uaa.internal/Users?filter=origin%20eq%20%22#{origin}%22%20and%20userName%20eq%20%22#{username}%22"
  stub_body_if_status_is_200 url, status,
    "totalResults" => 1,
    "resources" => [{ id: }]
end

def stub_getting_user_by_id(status, id, origin = nil, username = nil, created = nil)
  url = "http://fake-uaa.internal/Users/#{id}"
  stub_body_if_status_is_200 url, status,
    "id" => id,
    "origin" => origin,
    "userName" => username,
    "meta" => {
      "created" => created.nil? ? nil : created.iso8601,
    }
end

def stub_adding_user_to_group(status, group_id, user_id)
  url = "http://fake-uaa.internal/Groups/#{group_id}/members"
  stub_request(:post, url)
    .with(body: { 'type': "USER", 'origin': "uaa", 'value': user_id })
    .to_return(status:)
end

def stub_removing_user_from_group(status, group_id, user_id)
  url = "http://fake-uaa.internal/Groups/#{group_id}/members/#{user_id}"
  stub_request(:delete, url).to_return(status:)
end

def stub_body_if_status_is_200(url, status, body)
  stub = { status: }
  stub[:body] = JSON.generate(body) if (200..299).cover?(status)
  stub_request(:get, url).to_return(stub)
end
