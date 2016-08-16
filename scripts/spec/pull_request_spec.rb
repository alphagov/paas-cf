
require 'pull_request'

RSpec.describe PullRequest do
  let(:repo) { "example/test-repo" }
  let(:pull_request) { PullRequest.new(1) }
  let(:pr_commit_id) { "12345678901234567890" }

  before :all do
    # Clear any value set in a user's global environment (eg from .bashrc etc).
    ENV.delete("GITHUB_API_TOKEN")
  end

  before :each do
    allow_any_instance_of(PullRequest).to receive(:info) # silence logging

    allow_any_instance_of(PullRequest).to receive(:`).with('git remote -v') do
      system("exit 0") # setup $?
      "origin\tgit@github.com:#{repo} (fetch)\norigin\tgit@github.com:#{repo} (push)\n"
    end
  end

  def stub_pr_details(details, options = {})
    url = "#{PullRequest::BASE_URL}/#{repo}/pulls/1"
    url << "?access_token=#{options[:token]}" if options[:token]
    WebMock.stub_request(:get, url)
      .to_return(
        headers: { "Content-Type" => "application/json" },
        body: details.to_json,
      )
  end

  it "outputs a useful error message when the API rate limit is hit" do
    WebMock.stub_request(:get, "#{PullRequest::BASE_URL}/#{repo}/pulls/1")
      .to_return(
        status: 403,
        headers: { "Content-Type" => "application/json" },
        body: {
          "message" => "API rate limit exceeded for 192.0.2.#{rand(1..254)}. (But here's the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)",
        }.to_json,
      )

    expect {
      pull_request.open?
    }.to raise_error(/Github rate-limit exceeded/)
  end

  describe "Using authenticated requests when configured" do
    before :each do
      ENV["GITHUB_API_TOKEN"] = "1234567890"
    end
    after :each do
      ENV.delete("GITHUB_API_TOKEN")
    end

    it "should add an access token to API requests" do
      stub_without_token = stub_pr_details("state" => "open")
      stub_with_token = stub_pr_details({ "state" => "open" }, token: "1234567890")

      pull_request.open?

      expect(stub_with_token).to have_been_requested
      expect(stub_without_token).not_to have_been_requested
    end
  end

  describe "parsing the github repo from git remotes" do
    [
      'https://github.com/user/repo',
      'https://github.com/user/repo.git',
      'git@github.com:user/repo',
      'git@github.com:user/repo.git',
    ].each do |url|
      it "correctly parses URLs of the form '#{url}'" do
        allow(pull_request).to receive(:`).with('git remote -v') do
          system("exit 0") # setup $?
          "origin\t#{url} (fetch)\norigin\t#{url} (push)\n"
        end

        expect(pull_request.repo).to eq("user/repo")
      end
    end

    it "ignores non-origin remotes in the list" do
      allow(pull_request).to receive(:`).with('git remote -v') do
        system("exit 0") # setup $?
        output = ""
        output << "mine\thttps://github.com/mine/repo (fetch)\nmine\thttps://github.com/mine/repo (push)\n"
        output << "origin\thttps://github.com/user/repo (fetch)\norigin\thttps://github.com/user/repo (push)\n"
        output << "upstream\thttps://github.com/upstream/repo (fetch)\nupstream\thttps://github.com/upstream/repo (push)\n"
        output
      end

      expect(pull_request.repo).to eq("user/repo")
    end

    it "raises an error when running `git remote` fails" do
      allow(pull_request).to receive(:`).with('git remote -v') do
        system("exit 2")
      end
      expect {
        pull_request.repo
      }.to raise_error(/Error reading git remotes/)
    end

    it "raises an error when origin is not a github remote" do
      allow(pull_request).to receive(:`).with('git remote -v') do
        system("exit 0") # setup $?
        "origin\thttps://somewhere.com/user/repo (fetch)\norigin\thttps://somewhere.com/user/repo (push)\n"
      end

      expect {
        pull_request.repo
      }.to raise_error(/origin is not a Github URL/)
    end
  end

  describe "open?" do
    it "is true if the PR is open" do
      stub_pr_details("state" => "open")
      expect(pull_request.open?).to eq(true)
    end

    it "is false otherwise" do
      stub_pr_details("state" => "closed")
      expect(pull_request.open?).to eq(false)
    end
  end

  describe "mergeable?" do
    it "is false when Github reports the PR as not mergable" do
      stub_pr_details("mergeable" => false)
      expect(pull_request.mergeable?).to eq(false)
    end

    it "is false when Github hasn't computed the mergability yet" do
      stub_pr_details("mergeable" => nil)
      expect(pull_request.mergeable?).to eq(false)
    end

    it "is true when Github reports the PR as mergeable" do
      stub_pr_details("mergeable" => true)
      expect(pull_request.mergeable?).to eq(true)
    end
  end

  describe "status_checks_passed?" do
    let(:status_url) { "#{PullRequest::BASE_URL}/example/test-repo/commits/#{pr_commit_id}/status" }

    before :each do
      stub_pr_details("head" => { "sha" => pr_commit_id })
    end

    it "is true when Github reports that all checks have succeeded" do
      WebMock.stub_request(:get, status_url)
        .to_return(
          headers: { "Content-Type" => "application/json" },
          body: { "state" => "success" }.to_json,
        )

      expect(pull_request.status_checks_passed?).to eq(true)
    end

    it "is true when there are no status checks" do
      WebMock.stub_request(:get, status_url)
        .to_return(
          headers: { "Content-Type" => "application/json" },
          body: {
            "state" => "pending",
            "statuses" => [],
          }.to_json,
        )

      expect(pull_request.status_checks_passed?).to eq(true)
    end

    it "is false otherwise" do
      WebMock.stub_request(:get, status_url)
        .to_return(
          headers: { "Content-Type" => "application/json" },
          body: {
            "state" => "pending",
            "statuses" => [:something],
          }.to_json,
        )

      expect(pull_request.status_checks_passed?).to eq(false)
    end
  end

  describe "external_pr?" do
    it "is false when the head and the base reference the same repo" do
      stub_pr_details("title" => "[#1234] A nice PR",
        "head" => {
          "repo" => {
            "full_name" => repo,
          },
        },
        "base" => {
          "repo" => {
            "full_name" => repo,
          },
        })

      expect(pull_request.external_pr?).to eq(false)
    end

    it "is true otherwise" do
      stub_pr_details("title" => "[#1234] A nice PR",
        "head" => {
          "repo" => {
            "full_name" => "elsewhere/test",
          },
        },
        "base" => {
          "repo" => {
            "full_name" => repo,
          },
        })

      expect(pull_request.external_pr?).to eq(true)
    end
  end

  describe "target_branch" do
    it "returns the target branch from the PR details" do
      stub_pr_details("title" => "[#1234] A nice PR",
        "base" => {
          "ref" => "target_branch",
        })

      expect(pull_request.target_branch).to eq("target_branch")
    end
  end

  describe "merge commit message" do
    it "should populate the commit message with details from the PR" do
      stub_pr_details("title" => "[#1234] A nice PR",
        "head" => {
          "ref" => "nice_pr",
          "user" => {
            "login" => "example",
          },
        })

      expect(pull_request.commit_message).to eq(<<-EOT)
Merge pull request #1 from example/nice_pr

[#1234] A nice PR
      EOT
    end
  end

  it "returns an error if the PR doesn't exist" do
    WebMock.stub_request(:get, "#{PullRequest::BASE_URL}/#{repo}/pulls/1")
      .to_return(
        status: 404,
        headers: { "Content-Type" => "application/json" },
        body: { "message" => "Not Found" }.to_json,
      )

    expect {
      pull_request.open?
    }.to raise_error(/Failed to fetch PR details/)
  end

  describe "merge!" do
    def allow_command(command, success = true)
      allow(Kernel).to receive(:system).with(command).and_return(success)
    end

    def expect_command(*command)
      expect(Kernel).to receive(:system).with(*command).and_return(true)
    end

    def refute_command(*command)
      expect(Kernel).not_to receive(:system).with(*command)
    end

    before(:each) do
      allow_command('git diff --quiet --exit-code HEAD')

      allow(pull_request).to receive_messages(
        open?: true,
        mergeable?: true,
        status_checks_passed?: true,
        external_pr?: false,
        target_branch: "master",
        head_commit_id: pr_commit_id,
        head_ref: "pr_branch",
        commit_message: "Dummy commit message\n\nWith multiple lines\n",
      )
    end

    it "raises an error if the PR isn't open" do
      allow(pull_request).to receive_messages(open?: false)
      expect {
        pull_request.merge!
      }.to raise_error(/is not open/)
    end

    it "raises an error if the PR isn't mergeable" do
      allow(pull_request).to receive_messages(mergeable?: false)
      expect {
        pull_request.merge!
      }.to raise_error(/is not mergeable/)
    end

    it "raises an error if the status checks haven't passed" do
      allow(pull_request).to receive_messages(status_checks_passed?: false)
      expect {
        pull_request.merge!
      }.to raise_error(/has not passed all status checks/)
    end

    it "raises an error when the working directory isn't clean" do
      allow_command('git diff --quiet --exit-code HEAD', false)

      expect {
        pull_request.merge!
      }.to raise_error(/Working directory is not clean/)
    end

    it "switches to master, and merges the relevant commit" do
      expect_command('git checkout master')
      expect_command('git pull --ff-only origin master')
      expect_command('git', 'merge', '--no-ff', '-S', '-m', "Dummy commit message\n\nWith multiple lines\n", pr_commit_id)
      expect_command('git push origin master')
      expect_command('git push origin :pr_branch')

      pull_request.merge!
    end

    context "when the target branch isn't master" do
      before :each do
        allow(pull_request).to receive_messages(target_branch: "another_branch")
      end

      it "switches to the target_branch, and merges the relevant commit" do
        expect_command('git checkout another_branch')
        expect_command('git pull --ff-only origin another_branch')
        expect_command('git', 'merge', '--no-ff', '-S', '-m', "Dummy commit message\n\nWith multiple lines\n", pr_commit_id)
        expect_command('git push origin another_branch')
        expect_command('git push origin :pr_branch')

        pull_request.merge!
      end
    end

    context "a PR from a different fork of our repo" do
      before :each do
        allow(pull_request).to receive_messages(external_pr?: true)
      end

      it "fetches the commits for the PR and doesn't delete the remote branch" do
        expect_command('git checkout master')
        expect_command('git pull --ff-only origin master')
        expect_command('git fetch origin refs/pull/1/head')
        expect_command('git', 'merge', '--no-ff', '-S', '-m', "Dummy commit message\n\nWith multiple lines\n", pr_commit_id)
        expect_command('git push origin master')

        refute_command('git push origin :pr_branch')

        pull_request.merge!
      end
    end

    it "raises an error if one of the git commands errors" do
      expect_command('git checkout master')
      expect(Kernel).to receive(:system).with('git pull --ff-only origin master') { system("exit 3") }

      expect {
        pull_request.merge!
      }.to raise_error(/exited 3/)
    end
  end
end
