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

  it "exists" do
    expect(image_tags_by_repo).not_to be_empty
  end

  describe "tag checking" do
    image_tags_by_repo.each do |repo, tags|
      it "never is 'latest' (#{repo})" do
        tags.each do |tag|
          expect(tag).not_to eq("latest")
        end
      end
    end
  end

  describe "governmentpaas docker images" do
    image_tags_by_repo
      .select { |repo, _| repo.match?(%r{^governmentpaas/}) }
      .each do |repo, tags|
      context "repo #{repo}" do
        it "has only one tag" do
          expect(tags.length).to eq(1)
        end

        it "is a lowercase git hash" do
          expect(tags.first).to match(/^[a-f0-9]{40}$/)
        end
      end
    end

    describe "things that are not resource types" do
      image_tags_by_repo
        .select { |repo, _| repo.match?(%r{^governmentpaas/}) }
        .reject { |repo, _| repo.match?(/-resource$/) }
        .to_h.values .flatten .uniq.tap do |all_tags|
          it "onlies have one tag" do
            expect(all_tags.length).to eq(1)
          end
        end
    end
  end
end

# rubocop:enable Security/YAMLLoad
