require 'job_instances_lib'

RSpec.describe JobInstances do
  it "generates an empty string when the manifest is empty" do
    manifest = ""
    tfvars = JobInstances.generate manifest
    expect(tfvars).to be_empty
  end

  it "generates an empty list when there is no job" do
    manifest = %{
      jobs:
    }
    tfvars = JobInstances.generate manifest
    expect(tfvars).to eq("job_instances = [  ]")
  end

  it "ignores a job with 0 instance" do
    manifest = %{
      jobs:
      - name: ajob
        instances: 0
    }
    tfvars = JobInstances.generate manifest
    expect(tfvars).to eq("job_instances = [  ]")
  end

  it "generates a list when there are several jobs" do
    manifest = %{
      jobs:
        - name: ajob
          instances: 3
        - name: nats
          instances: 2
    }
    tfvars = JobInstances.generate manifest
    expect(tfvars).to eq("job_instances = [ \"ajob:3\", \"nats:2\" ]")
  end
end
