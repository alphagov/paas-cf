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

  describe "dockerhub docker images" do
    # DockerHub images are those where there's no hostname at the start of the
    # image name. Detecting that by the absence of a full stop.
    # The regex is complicated by not all image names having a slash in.
    dockerhub_images = image_tags_by_repo.select { |repo, _| repo.match?(%r{^[^\.]+(/.+)?$}) }

    it "are not being used" do
      expect(dockerhub_images).to be_empty
    end
  end
end

# rubocop:enable Security/YAMLLoad
