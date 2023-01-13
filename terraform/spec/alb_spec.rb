require "json"
require "open3"

def hcl2json(tf)
  stdout, stderr, exit_status = Open3.capture3("hcl2json", { stdin_data: tf })

  unless exit_status.success?
    warn stderr

  end
  JSON.parse(stdout)
end

def get_lbs(tf)
  tf.dig("resource", "aws_lb").values
end

def get_tgs(tf)
  tf.dig("resource", "aws_lb_target_group").values
end

describe "alb" do
  describe "alb helpers" do
    it "gets lbs correctly" do
      terraform = {
        "resource" => {
          "aws_lb" => {
            "my_alb_resource" => { "name" => "my-application-load-balancer" },
            "my_nlb_resource" => { "name" => "my-network-load-balancer" },
          },
        },
      }

      lbs = get_lbs(terraform)

      expect(lbs.length).to be(2)
      expect(lbs.first["name"]).to eq("my-application-load-balancer")
      expect(lbs.last["name"]).to eq("my-network-load-balancer")
    end

    it "gets lb tgs correctly" do
      terraform = {
        "resource" => {
          "aws_lb_target_group" => {
            "my_alb_target_group" => { "port" => "443" },
            "my_nlb_target_group" => { "port" => "8443" },
          },
        },
      }

      tgs = get_tgs(terraform)

      expect(tgs.length).to be(2)
      expect(tgs.first["port"]).to eq("443")
      expect(tgs.last["port"]).to eq("8443")
    end
  end

  describe "albs" do
    terraform_files = TERRAFORM_FILES
      .reject { |f| File.read(f).lines.grep(/resource\s+"aws_lb"/).empty? }

    terraform_contents = terraform_files
      .map { |f| File.read(f) }
      .join("\n\n")

    terraform = hcl2json(terraform_contents)

    it "does not contain any aws_alb resources" do
      expect(
        TERRAFORM_FILES
          .map { |f| File.read(f) }.join("\n").lines.grep(/"aws_alb"/),
      ).to be_empty
    end

    it "is have terraform files describing albs" do
      expect(terraform_files).not_to be_empty
    end

    it "is valid terraform" do
      expect(terraform).not_to be(false)
    end

    it "has names less than 32 characters" do
      lb_names = get_lbs(terraform)
        .map { |r| r[0]["name"] }
        .map { |val| val.gsub("${var.env}", "prod-lon") }

      expect(lb_names).not_to be_empty
      expect(lb_names).to all(match(/^[-a-z]{4,32}$/))
      expect(lb_names).not_to include(match("var.env"))
    end

    it "has access_logs configured" do
      access_logs = get_lbs(terraform)
        .map { |r| r[0]["access_logs"] }

      expect(access_logs).not_to be_empty
      expect(access_logs).not_to include(nil)
    end

    it "does not have deletion protection enabled" do
      deletion_protection = get_lbs(terraform)
        .map { |r| r[0]["enable_deletion_protection"] }

      expect(deletion_protection).not_to be_empty
      expect(deletion_protection).to all(be(nil))
    end
  end

  describe "alb_tgs" do
    terraform_files = TERRAFORM_FILES
      .reject { |f| File.read(f).lines.grep(/resource\s+"aws_lb"/).empty? }

    terraform_contents = terraform_files
      .map { |f| File.read(f) }
      .join("\n\n")

    terraform = hcl2json(terraform_contents)

    it "is have terraform files describing albs" do
      expect(terraform_files).not_to be_empty
    end

    it "is valid terraform" do
      expect(terraform).not_to be(false)
    end

    it "has deregistration configured" do
      deregistration_delay = get_tgs(terraform)
        .reject { |r| r[0]["name"].match?(/broker|alertmanager|prometheus/) }
        .reject { |r| r[0]["port"] == 83 } # This is temporary port
        .map { |r| r[0]["deregistration_delay"] }

      expect(deregistration_delay).not_to be_empty
      expect(deregistration_delay).to all(be < 120)
    end

    it "has slow_start configured if it is a router" do
      router_tgs = get_tgs(terraform)
        .reject { |r| r[0]["name"].match?(/broker|alertmanager|prometheus|rlp|doppler/) }
        .reject { |r| r[0]["port"] == 83 } # This is temporary port

      expect(router_tgs).not_to be_empty

      slow_start = router_tgs.map { |r| r[0]["slow_start"] }

      expect(slow_start).to all(be > 30) # More than the routing table sync interval
      expect(slow_start).to all(be < 110) # Less than the drain wait time
    end
  end
end
