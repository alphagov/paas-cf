# Disable this cop because we are testing YAML anchors
# rubocop:disable Security/YAMLLoad

require "yaml"

RSpec.describe "image resources" do
  concourse_fragments = concourse_tasks
    .concat(concourse_pipelines)
    .map { |_, contents| YAML.load(contents) }

  image_tags_by_repo = concourse_fragments
    .flat_map { |f| all_image_resources(f) }
    .group_by { |image_def| image_def[:repository] }
    .map { |repo, image_defs| [repo, image_defs.map { |d| d[:tag] }.uniq] }

  it "should exist" do
    expect(image_tags_by_repo).not_to be_empty
  end

  context "tag checking" do
    image_tags_by_repo.each do |repo, tags|
      it "should never be 'latest' (#{repo})" do
        tags.each do |tag|
          expect(tag).not_to eq("latest")
        end
      end
    end
  end

  context "governmentpaas" do
    image_tags_by_repo
      .select { |repo, _| repo.match?(%r{^governmentpaas/}) }
      .each do |repo, tags|

      context "repo #{repo}" do
        it "should have only one tag" do
          expect(tags.length).to eq(1)
        end

        it "should be a lowercase git hash" do
          expect(tags.first).to match(/^[a-f0-9]{40}$/)
        end
      end
    end

    context "things that are not resources" do
      image_tags_by_repo
        .select { |repo, _| repo.match?(%r{^governmentpaas/}) }
        .reject { |repo, _| repo.match?(/-resource$/) }
        .to_h.values .flatten .uniq.tap do |all_tags|
          it "should only have one tag" do
            expect(all_tags.length).to eq(1)
          end
        end
    end
  end
end

# rubocop:enable Security/YAMLLoad
