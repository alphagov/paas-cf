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

RSpec.describe "concourse pipelines" do
  it "finds the pipeline files" do
    expect(concourse_pipelines).not_to be_empty
  end

  concourse_pipelines.each do |filename, contents|
    it "is safe, valid yaml (#{filename})" do
      expect { YAML.load(contents) }.not_to raise_error
    end

    it "adds matching grafana-job-annotations (#{filename})" do
      grafana_add_annotations = contents.scan(/[&]add-[-a-z]*grafana[-a-z]+/)

      grafana_add_annotations
        .map { |a| [a, contents.scan(a.sub("&add", "*add")).count] }
        .each do |a, matched|
          expect(matched).to(
            be > 0,
            "Could not find use of #{a}"
          )
        end

      grafana_add_annotations
        .map { |a| [a, contents.scan(a.sub("&add", "&end")).count == 1] }
        .each do |a, matched|
          expect(matched).to(
            eq(true),
            "Could not finding matching #{a.sub('&add', '&end')} anchor"
          )
        end

      grafana_add_annotations
        .map { |a| a.sub("&add", "*add") }
        .map { |a| [a, contents.scan(a).count] }
        .map { |a, c| [a, c, contents.scan(a.sub("*add", "*end")).count] }
        .each do |a, add_count, end_count|
          expect(add_count).to(
            eq(end_count),
            "#{a} (#{add_count}) != #{a.sub('*add', '*end')} (#{end_count})"
          )
        end
    end
  end
end

# rubocop:enable Security/YAMLLoad
