require 'net/http'
require 'json'

class PullRequest
  BASE_URL = 'https://api.github.com/repos'

  def initialize(repo, pr_number)
    @repo = repo
    @pr_number = pr_number
  end

  def open?
    details.fetch("state") == "open"
  end

  def mergeable?
    !! details.fetch("mergeable")
  end

  def status_checks_passed?
    status.fetch("state") == "success" || status.fetch("statuses").empty?
  end

  def head_commit_id
    details.fetch("head").fetch("sha")
  end

  def commit_message
    head = details.fetch("head")
    <<-EOT
Merge pull request ##{@pr_number} from #{head.fetch("user").fetch("login")}/#{head.fetch("ref")}

#{details.fetch("title")}
    EOT
  end

  def merge!
    raise "PR is not open" unless open?
    raise "PR is not mergeable" unless mergeable?
    raise "PR has not passed all status checks" unless status_checks_passed?

    # Check working directorty is clean
    unless Kernel.system('git diff --quiet --exit-code HEAD')
      raise "Working directory is not clean. Aborting..."
    end

    execute_command('git checkout master')
    execute_command('git pull --ff-only origin master')
    execute_command('git', 'merge', '--no-ff', '-S', '-m', commit_message, head_commit_id)
    execute_command('git push origin master')
  end

  private

  def execute_command(*args)
    unless Kernel.system(*args)
      raise "Error: command '#{args.join(' ')}' exited #{$?.exitstatus}."
    end
  end

  def details
    @_details ||= get_json("#{BASE_URL}/#{@repo}/pulls/#{@pr_number}")
  end

  def status
    url = "#{BASE_URL}/#{@repo}/commits/#{head_commit_id}/status"
    @_status ||= get_json(url)
  end

  def get_json(url)
    response = http_get(url)
    if response.is_a?(Net::HTTPForbidden) and response.body =~ /API rate limit exceeded for/
      raise "Github rate-limit exceeded. To avoid this create a Github API token with public access and put it in GITHUB_API_TOKEN env var."
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Failed to fetch PR details.\nGot #{response.code} fetching '#{url}':\n#{response.body}"
    end

    JSON.parse(response.body)
  end

  def http_get(url)
    uri = URI.parse(url)
    if ENV["GITHUB_API_TOKEN"]
      uri.query = [uri.query, "access_token=#{ENV["GITHUB_API_TOKEN"]}"].compact.join('&')
    end
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      return http.request(request)
    end
  end
end
