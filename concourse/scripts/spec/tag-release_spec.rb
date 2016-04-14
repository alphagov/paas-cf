require 'fileutils'

RSpec.describe "tag-release.sh", :type => :aruba do
  before(:each) do
    prepare_ssh_keys()
    config_git_email_and_name()
    setup_cloned_repository()

    set_environment_variable 'GIT_REPO_URL', File.join(@workdir, "origin_repo")
  end
  context("when I have some tags to promote") do
    before(:each) do
      bash_block(%q{
        cd origin_repo

        git commit --allow-empty -m "First commit"

        git tag previous-0.0.1
        git tag previous-0.0.2

        git commit --allow-empty -m "Second commit"
        git tag previous-0.0.3

        # cannot push to repo while its checked out to a branch
        git checkout refs/heads/master
      })
    end

    context("when I checkout the before last tag of 'previous-*' and promote it") do
      before(:each) do
        clone_repository("paas-cf")
        bash_block("cd paas-cf && git checkout previous-0.0.2")

        run("./tag-release.sh next- test_aws_account test_env \"previous-*\"")
        expect(last_command_started).to have_exit_status(0)
      end

      it("should promote the same tag version for 'next-*'") do
        bash_block("cd paas-cf && echo a && git tag -l \"next-*\" --sort version:refname | tail -n 1", :quiet => true)
        expect(last_command_started.output).to include("next-0.0.2")
        expect(last_command_started.output).not_to include("next-0.0.3")
      end

      it("should set the both tags pointing to the current commit") do
        bash_block('cd paas-cf && git rev-list -n 1 previous-0.0.2', quiet: true)
        previous_commit_hash = last_command_started.output.strip

        bash_block('cd paas-cf && git rev-list -n 1 next-0.0.2', quiet: true)
        next_commit_hash = last_command_started.output.strip

        expect(previous_commit_hash).to eq(next_commit_hash)
      end


      it("should have push the new tag to the remote repo") do
        clone_repository("paas-cf-new")

        bash_block("cd paas-cf-new && git tag -l \"next-*\" --sort version:refname | tail -n 1", :quiet => true)
        expect(last_command_started).to have_output include_output_string "next-0.0.2"
        expect(last_command_started).not_to have_output include_output_string "next-0.0.3"
      end
    end
  end
end

def prepare_ssh_keys()
    # The script expects git-keys/git-keys.tar.gz
    bash_block(%q{
      mkdir -p git-keys
      cd git-keys
      ssh-keygen -f git-key -N ""
      tar -cvzf git-keys.tar.gz git-key git-key.pub
   })
end

def config_git_email_and_name()
    bash_block(%q{
      git config --global user.email "you@example.com"
      git config --global user.name "Your Name"
    })
end

def setup_cloned_repository()
    bash_block(%q{
      mkdir origin_repo
      cd origin_repo
      git init .
    })
end

def clone_repository(target)
    bash_block(%Q{
      git clone origin_repo #{target}
      cd #{target}
      git fetch --tags
    })
end


