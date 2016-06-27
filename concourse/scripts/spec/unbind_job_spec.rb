require 'securerandom'

RSpec.describe "unbind_job.rb", :type => :aruba do
  def unbind(yml, job)
    run("./unbind_job.rb #{job}")
    last_command_started.write(yml)
    close_input
  end

  it "exits on empty YAML" do
    unbind("", "")
    expect(last_command_started).to have_exit_status(1)
    expect(last_command_started.stderr).to eq "Unable to parse YAML hash from the input\n"
  end

  it "exits on broken YAML" do
    unbind("? :", "")
    expect(last_command_started).to have_exit_status(1)
    expect(last_command_started.stderr).to match "psych.rb"
  end

  it "exits on missing jobs in YAML" do
    unbind("a: b", "")
    expect(last_command_started).to have_exit_status(1)
    expect(last_command_started.stderr).to eq "Can't find job definitions in the input\n"
  end

  it "exits on jobs not being an array" do
    unbind("jobs: b", "")
    expect(last_command_started).to have_exit_status(1)
    expect(last_command_started.stderr).to eq "Jobs definition not an array\n"
  end

  it "exits on job not found" do
    myjob=SecureRandom.hex
    unbind("jobs:\n  - name: a", myjob)
    expect(last_command_started).to have_exit_status(1)
    expect(last_command_started.stderr).to eq "Job #{myjob} not found in the pipeline\n"
  end

  it "removes passed from paas-cf in plan" do
    unbind("---
jobs:
- name: myjob
  plan:
  - get: paas-cf
    passed: ['some_previous_job']", "myjob")
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started.stdout).to eq "---
jobs:
- name: myjob
  plan:
  - get: paas-cf
"
  end

  it "removes passed from paas-cf in do in plan" do
    unbind("---
jobs:
- name: myjob
  plan:
  - do:
    - get: paas-cf
      passed: ['some_previous_job']", "myjob")
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started.stdout).to eq "---
jobs:
- name: myjob
  plan:
  - do:
    - get: paas-cf
"
  end

  it "removes passed from paas-cf in aggregate in plan" do
    unbind("---
jobs:
- name: myjob
  plan:
  - aggregate:
    - get: paas-cf
      passed: ['some_previous_job']", "myjob")
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started.stdout).to eq "---
jobs:
- name: myjob
  plan:
  - aggregate:
    - get: paas-cf
"
  end

  it "removes passed from paas-cf in do in aggregate in plan" do
    unbind("---
jobs:
- name: myjob
  plan:
  - aggregate:
    - do:
      - get: paas-cf
        passed: ['some_previous_job']", "myjob")
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started.stdout).to eq "---
jobs:
- name: myjob
  plan:
  - aggregate:
    - do:
      - get: paas-cf
"
  end

  it "removes all occurences of passed from paas-cf nested anywhere in plan" do
    unbind("---
jobs:
- name: myjob
  plan:
  - get: paas-cf
    passed: 'some_job'
  - aggregate:
    - get: paas-cf
      passed: ['some', 'jobs']
    - do:
      - get: paas-cf
        passed: ['some_previous_job']", "myjob")
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started.stdout).to eq "---
jobs:
- name: myjob
  plan:
  - get: paas-cf
  - aggregate:
    - get: paas-cf
    - do:
      - get: paas-cf
"
  end

end
