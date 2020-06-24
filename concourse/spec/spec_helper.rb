SPEC_DIR = File.expand_path(__dir__)
CONCOURSE_DIR = File.expand_path(File.join(SPEC_DIR, ".."))
TASKS_DIR = File.join(CONCOURSE_DIR, "tasks")
PIPELINES_DIR = File.join(CONCOURSE_DIR, "pipelines")

def concourse_tasks
  Dir
    .glob(File.join(TASKS_DIR, "*.yml"))
    .map { |f| [File.basename(f), File.read(f)] }
end

def concourse_pipelines
  Dir
    .glob(File.join(PIPELINES_DIR, "*.yml"))
    .map { |f| [File.basename(f), File.read(f)] }
end

def all_image_resources(frag)
  if frag.is_a?(Array)
    frag.flat_map { |val| all_image_resources(val) }
  elsif !frag.is_a?(Hash)
    []
  elsif [frag.dig("source", "repository"), frag.dig("source", "tag")].none?
    frag.values.flat_map { |val| all_image_resources(val) }
  else
    [{ repository: frag.dig("source", "repository"),
       tag: frag.dig("source", "tag") }]
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
