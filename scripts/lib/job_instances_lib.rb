require 'yaml'

class JobInstances
  def self.generate(manifest_yaml)
    manifest = YAML.load(manifest_yaml)
    return "" unless manifest

    jobs = YAML.load(manifest_yaml)['jobs']
    jobs_list = Array.new

    if jobs
      jobs.each do |job|
        if job['instances'] > 0
          jobs_list << "\"#{job['name']}:#{job['instances']}\""
        end
      end
    end

    "job_instances = [ #{jobs_list.join(', ')} ]"
  end
end
