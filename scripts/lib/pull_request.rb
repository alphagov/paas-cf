require 'net/http'
require 'json'

class PullRequest
  BASE_URL = 'https://api.github.com/repos'.freeze

  def initialize(pr_number)
    @pr_number = pr_number
  end

  def repo
    @repo ||= read_repo_from_git
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

  def external_pr?
    details.fetch("base").fetch("repo").fetch("full_name") !=
      details.fetch("head").fetch("repo").fetch("full_name")
  end

  def target_branch
    details.fetch("base").fetch("ref")
  end

  def head_commit_id
    details.fetch("head").fetch("sha")
  end

  def head_ref
    details.fetch("head").fetch("ref")
  end

  def commit_message
    <<-EOT
Merge pull request ##{@pr_number} from #{details.fetch('head').fetch('user').fetch('login')}/#{head_ref}

#{details.fetch('title')}
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

    info "Checking out and updating #{target_branch}"
    execute_command("git checkout #{target_branch}")
    execute_command("git pull --ff-only origin #{target_branch}")

    if external_pr?
      info "Fetching commits from PR #{@pr_number}"
      execute_command("git fetch origin refs/pull/#{@pr_number}/head")
    end

    info "Merging PR with commit message:\n#{commit_message}"
    execute_command('git', 'merge', '--no-ff', '-S', '-m', commit_message, head_commit_id)

    info "Pushing to origin"
    execute_command("git push origin #{target_branch}")

    unless external_pr?
      info "Deleting remote branch #{head_ref}"
      execute_command("git push origin :#{head_ref}")
    end

    info "Done."
  end

private

  def read_repo_from_git
    details = `git remote -v`
    unless $?.success?
      raise "Error reading git remotes: exit status #{$?.exitstatus}."
    end
    details.each_line do |line|
      line.strip!
      if line =~ /\Aorigin\t(\S+)\s+\(fetch\)\z/
        url = $1
        if url =~ /\A(?:https:\/\/|git@)github\.com[\/:](\S+?)(?:\.git)?\z/
          return $1
        end
      end
    end
    raise "origin is not a Github URL"
  end

  def execute_command(*args)
    unless Kernel.system(*args)
      raise "Error: command '#{args.join(' ')}' exited #{$?.exitstatus}."
    end
  end

  def details
    @_details ||= get_json("#{BASE_URL}/#{repo}/pulls/#{@pr_number}")
  end

  def status
    url = "#{BASE_URL}/#{repo}/commits/#{head_commit_id}/status"
    @_status ||= get_json(url)
  end

  def get_json(url)
    response = http_get(url)
    if response.is_a?(Net::HTTPForbidden) && response.body =~ /API rate limit exceeded for/
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
      uri.query = [uri.query, "access_token=#{ENV['GITHUB_API_TOKEN']}"].compact.join('&')
    end
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      return http.request(request)
    end
  end

  def info(message)
    if $stdout.isatty
      puts "\e[36m#{message}\e[0m"
    else
      puts message
    end
  end
end
