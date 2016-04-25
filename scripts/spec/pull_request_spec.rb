
require 'pull_request'

RSpec.describe PullRequest do
  let(:repo) { "example/test-repo" }
  let(:pull_request) { PullRequest.new("example/test-repo", 1) }
  let(:pr_commit_id) { "12345678901234567890" }

  def stub_pr_details(details)
    WebMock.stub_request(:get, "#{PullRequest::BASE_URL}/#{repo}/pulls/1")
      .to_return(
        :headers => {"Content-Type" => "application/json"},
        :body => details.to_json,
      )
  end

  describe "open?" do
    it "is true if the PR is open" do
      stub_pr_details({"state" => "open"})
      expect(pull_request.open?).to eq(true)
    end

    it "is false otherwise" do
      stub_pr_details({"state" => "closed"})
      expect(pull_request.open?).to eq(false)
    end
  end

  describe "mergeable?" do
    it "is false when Github reports the PR as not mergable" do
      stub_pr_details({"mergeable" => false})
      expect(pull_request.mergeable?).to eq(false)
    end

    it "is false when Github hasn't computed the mergability yet" do
      stub_pr_details({"mergeable" => nil})
      expect(pull_request.mergeable?).to eq(false)
    end

    it "is true when Github reports the PR as mergeable" do
      stub_pr_details({"mergeable" => true})
      expect(pull_request.mergeable?).to eq(true)
    end
  end

  describe "status_checks_passed?" do
    let(:status_url) { "#{PullRequest::BASE_URL}/example/test-repo/commits/#{pr_commit_id}/status" }

    before :each do
      stub_pr_details({"head" => { "sha" => pr_commit_id } })
    end

    it "is true when Github reports that all checks have succeeded" do
      WebMock.stub_request(:get, status_url)
        .to_return(
          :headers => {"Content-Type" => "application/json"},
          :body => {"state" => "success"}.to_json,
        )

      expect(pull_request.status_checks_passed?).to eq(true)
    end

    it "is true when there are no status checks" do
      WebMock.stub_request(:get, status_url)
        .to_return(
          :headers => {"Content-Type" => "application/json"},
          :body => {
            "state" => "pending",
            "statuses" => [],
          }.to_json,
        )

      expect(pull_request.status_checks_passed?).to eq(true)
    end

    it "is false otherwise" do
      WebMock.stub_request(:get, status_url)
        .to_return(
          :headers => {"Content-Type" => "application/json"},
          :body => {
            "state" => "pending",
            "statuses" => [:something],
          }.to_json,
        )

      expect(pull_request.status_checks_passed?).to eq(false)
    end
  end

  describe "merge commit message" do
    it "should populate the commit message with details from the PR" do
      stub_pr_details({
        "title" => "[#1234] A nice PR",
        "head" => {
          "ref" => "nice_pr",
          "user" => {
            "login" => "example",
          },
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
        :status => 404,
        :headers => {"Content-Type" => "application/json"},
        :body => {"message" => "Not Found"}.to_json,
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

    before(:each) do
      allow_command('git diff --quiet --exit-code HEAD')

      allow(pull_request).to receive_messages(
        :open? => true,
        :mergeable? => true,
        :status_checks_passed? => true,
        :head_commit_id => pr_commit_id,
        :commit_message => "Dummy commit message\n\nWith multiple lines\n",
      )
    end

    it "raises an error if the PR isn't open" do
      allow(pull_request).to receive_messages(:open? => false)
      expect {
        pull_request.merge!
      }.to raise_error(/is not open/)
    end

    it "raises an error if the PR isn't mergeable" do
      allow(pull_request).to receive_messages(:mergeable? => false)
      expect {
        pull_request.merge!
      }.to raise_error(/is not mergeable/)
    end

    it "raises an error if the status checks haven't passed" do
      allow(pull_request).to receive_messages(:status_checks_passed? => false)
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

      pull_request.merge!
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
