RSpec.describe "the global update block" do

  let(:manifest) { manifest_with_defaults }

  describe "in order to run parallel deployment by default" do
    it "has serial false" do
      expect(manifest["update"]["serial"]).to be false
    end
  end

end

RSpec.describe "the jobs definitions block" do

  let(:jobs) { manifest_with_defaults["jobs"] }

  def get_job(job_name)
    jobs.select{ |j| j["name"] == job_name}.first
  end

  def is_serial(job_name)
    job = get_job(job_name)
    job["update"]["serial"]
  end

  def ordered(job1_name, job2_name)
    i1 = jobs.index{ |j| j["name"] == job1_name }
    i2 = jobs.index{ |j| j["name"] == job2_name }
    i1 < i2
  end

  describe "in order to enforce etcd dependency on NATS" do
    it "has etcd serial" do
      expect(is_serial("etcd")).to be true
    end

    it "has nats before etcd" do
      expect(ordered("nats", "etcd")).to be true
    end
  end

  describe "in order to start/upgrade etcd cluster while maintaining consensus" do
    it "has etcd serial" do
      expect(is_serial("etcd")).to be true
    end
  end

  describe "in order to start one consul master for consensus" do
    it "has consul serial" do
      expect(is_serial("consul")).to be true
    end

    specify "has consul first" do
      expect(jobs[0]["name"]).to eq("consul")
    end
  end


end

RSpec.describe "the job definitions" do

  let(:jobs) { manifest_with_defaults["jobs"] }

  it "should list consul_agent first if present" do
    jobs_with_consul = jobs.select{ |j|
      not j["templates"].select{ |t|
        t["name"] == "consul_agent"
      }.empty?
    }

    jobs_with_consul.each{ |j|
      expect(j["templates"].first["name"]).to eq("consul_agent"),
        "expected '#{j["name"]}' job to list 'consul_agent' first"
    }
  end

end
