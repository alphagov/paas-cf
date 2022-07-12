# Disable this cop because we are testing YAML anchors
# rubocop:disable Security/YAMLLoad

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
            "Could not find use of #{a}",
          )
        end

      grafana_add_annotations
        .map { |a| [a, contents.scan(a.sub("&add", "&end")).count == 1] }
        .each do |a, matched|
          expect(matched).to(
            eq(true),
            "Could not finding matching #{a.sub('&add', '&end')} anchor",
          )
        end

      grafana_add_annotations
        .map { |a| a.sub("&add", "*add") }
        .map { |a| [a, contents.scan(a).count] }
        .map { |a, c| [a, c, contents.scan(a.sub("*add", "*end")).count] }
        .each do |a, add_count, end_count|
          expect(add_count).to(
            eq(end_count),
            "#{a} (#{add_count}) != #{a.sub('*add', '*end')} (#{end_count})",
          )
        end
    end

    describe "#{filename} git resources" do
      let(:pipeline) { YAML.load(contents) }
      let(:resources) { pipeline["resources"] || [] }
      let(:git_resources) { resources.select { |r| r["type"] == "git" } }

      describe "alphagov repos" do
        let(:alphagov_git_resources) do
          git_resources.select { |r| r["source"]["uri"].match?(/alphagov/) }
        end

        it "has correct branches" do
          valid_branches = %w[gds_master master main gds_main ((branch_name))]

          valid_branches << "cf13.2" # FIXME: cf-upgrade

          alphagov_git_resources.each do |r|
            name = r.dig("name")
            branch = r.dig("source", "branch")
            expect(valid_branches).to include(branch),
              "resource #{name} should be in #{valid_branches} got #{branch}"
          end
        end
      end
    end
  end
end
# rubocop:enable Security/YAMLLoad
