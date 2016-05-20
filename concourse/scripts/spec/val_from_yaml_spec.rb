RSpec.describe "val_from_yaml.rb", :type => :aruba do
  FIXTURE = File.expand_path("../fixtures/val_from_yaml.yml", __FILE__)

  def run_with_fixture(arg)
    run("./val_from_yaml.rb #{arg} #{FIXTURE}")
  end

  it "retrieves a simple value" do
    run_with_fixture("foo.bar.val1")
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started.output).to eq <<-EOF
a
    EOF
  end

  it "retrieves a full data structure" do
    run_with_fixture("foo.bar")
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started.output).to eq <<-EOF
---
val1: a
val2: b
    EOF
  end

  it "exits non-zero with no output for non existing properties" do
    run_with_fixture("x.y.z")
    expect(last_command_started).to have_exit_status(1)
    expect(last_command_started.stdout).to be_empty
    expect(last_command_started.stderr).to eq <<-EOF
Unable to find key: x.y.z
    EOF
  end

  it "exits non-zero with no output when traversing simple values" do
    run_with_fixture("foo.var.val1.nothing_to_see_here")
    expect(last_command_started).to have_exit_status(1)
    expect(last_command_started.stdout).to be_empty
    expect(last_command_started.stderr).to eq <<-EOF
Unable to find key: foo.var.val1.nothing_to_see_here
    EOF
  end

  it "retrieves a value from an array indexed by name" do
    run_with_fixture("foo.array1.item1.val")
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started.output).to eq <<-EOF
array1_item1_value
    EOF
  end

  it "exits non-zero with no output for non existing array item indexed by name" do
    run_with_fixture("foo.array1.item3.val")
    expect(last_command_started).to have_exit_status(1)
    expect(last_command_started.stdout).to be_empty
    expect(last_command_started.stderr).to eq <<-EOF
Unable to find key: foo.array1.item3.val
    EOF
  end

  it "exits non-zero with no output for non existing key in a array item indexed by name" do
    run_with_fixture("foo.array1.item1.other_val")
    expect(last_command_started).to have_exit_status(1)
    expect(last_command_started.stdout).to be_empty
    expect(last_command_started.stderr).to eq <<-EOF
Unable to find key: foo.array1.item1.other_val
    EOF
  end

  it "retrieves a value from an array indexed by index" do
    run_with_fixture("foo.array2.0")
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started.output).to eq <<-EOF
array2_value1
    EOF
  end

  it "retrieves a value from an array of hashes indexed by index" do
    run_with_fixture("foo.array1.0.val")
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started.output).to eq <<-EOF
array1_item1_value
    EOF
  end
end
