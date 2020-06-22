def get_lbs(tf)
  tf.dig("resource", "aws_lb").values
end

def get_tgs(tf)
  tf.dig("resource", "aws_lb_target_group").values
end

describe "alb helpers" do
  it "should get lbs correctly" do
    terraform = {
      "resource" => {
        "aws_lb" => {
          "my_alb_resource" => { "name" => "my-application-load-balancer" },
          "my_nlb_resource" => { "name" => "my-network-load-balancer" },
        }
      }
    }

    lbs = get_lbs(terraform)

    expect(lbs.length).to be(2)
    expect(lbs.first.dig("name")).to eq("my-application-load-balancer")
    expect(lbs.last.dig("name")).to eq("my-network-load-balancer")
  end

  it "should get lb tgs correctly" do
    terraform = {
      "resource" => {
        "aws_lb_target_group" => {
          "my_alb_target_group" => { "port" => "443" },
          "my_nlb_target_group" => { "port" => "8443" },
        }
      }
    }

    tgs = get_tgs(terraform)

    expect(tgs.length).to be(2)
    expect(tgs.first.dig("port")).to eq("443")
    expect(tgs.last.dig("port")).to eq("8443")
  end
end

describe "alb" do
  terraform_files = TERRAFORM_FILES
    .reject { |f| File.read(f).lines.grep(/resource\s+"aws_lb"/).empty? }

  terraform_contents = terraform_files
    .map { |f| File.read(f) }
    .join("\n\n")

  terraform = HCL::Checker.parse(terraform_contents)

  it "should not contain any aws_alb resources" do
    expect(
      TERRAFORM_FILES
        .map { |f| File.read(f) }.join("\n").lines .grep(/"aws_alb"/)
    ).to be_empty
  end

  it "should be have terraform files describing albs" do
    expect(terraform_files).not_to be_empty
  end

  it "should be valid terraform" do
    expect(terraform).not_to be(false)
  end

  it "should have names less than 32 characters" do
    lb_names = get_lbs(terraform)
      .map { |r| r.dig("name") }
      .map { |val| val.gsub("${var.env}", "prod-lon") }


    expect(lb_names).not_to be_empty
    expect(lb_names).to all(match(/^[-a-z]{4,32}$/))
    expect(lb_names).not_to include(match("var.env"))
  end

  it "should have access_logs configured" do
    access_logs = get_lbs(terraform)
      .map { |r| r.dig("access_logs") }

    expect(access_logs).not_to be_empty
    expect(access_logs).not_to include(nil)
  end

  it "should not have deletion protection enabled" do
    deletion_protection = get_lbs(terraform)
      .map { |r| r.dig("enable_deletion_protection") }

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

  terraform = HCL::Checker.parse(terraform_contents)

  it "should be have terraform files describing albs" do
    expect(terraform_files).not_to be_empty
  end

  it "should be valid terraform" do
    expect(terraform).not_to be(false)
  end

  it "should have deregistration configured" do
    deregistration_delay = get_tgs(terraform)
      .reject { |r| r.dig("name").match?(/broker|alertmanager|prometheus/) }
      .reject { |r| r.dig("port") == 83 } # This is temporary port
      .map { |r| r.dig("deregistration_delay") }

    expect(deregistration_delay).not_to be_empty
    expect(deregistration_delay).to all(be < 120)
  end

  it "should have slow_start configured if it is a router" do
    router_tgs = get_tgs(terraform)
      .reject { |r| r.dig("name").match?(/broker|alertmanager|prometheus|rlp|doppler/) }
      .reject { |r| r.dig("port") == 83 } # This is temporary port

    expect(router_tgs).not_to be_empty

    slow_start = router_tgs.map { |r| r.dig("slow_start") }

    expect(slow_start).to all(be > 30) # More than the routing table sync interval
    expect(slow_start).to all(be < 110) # Less than the drain wait time
  end
end
