# Disable this cop because we are testing YAML anchors
# rubocop:disable Security/YAMLLoad

require "yaml"

RSpec.describe "concourse tasks" do
  it "finds the task files" do
    expect(concourse_tasks).not_to be_empty
  end

  concourse_tasks.each do |filename, contents|
    it "is safe, valid yaml (#{filename})" do
      expect { YAML.load(contents) }.not_to raise_error
    end
  end
end

# rubocop:enable Security/YAMLLoad
