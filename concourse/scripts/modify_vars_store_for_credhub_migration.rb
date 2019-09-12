#!/usr/bin/env ruby

require 'yaml'

unless ARGV[0]
  puts "USAGE: #{$PROGRAM_NAME} /path/to/vars-store.yml"
  exit 1
end

def should_migrate?(_, val)
  return true if val['ca'] != ''
end

def gen_public_key?(key, val)
  if key == 'diego_ssh_proxy_host_key'
    File.write('id_rsa', val['private_key'])
    system("chmod 0600 id_rsa & ssh-keygen -y -f id_rsa > id_rsa.pub")
    f = File.read('id_rsa.pub')
    val['public_key'] = f.strip
    system("rm id_rsa")
  end
end


File.open(ARGV[0].to_s, 'r') do |f|
  vars = YAML.safe_load(f)

  vars_to_migrate = vars.select do |key, val|
    gen_public_key?(key, val)
    should_migrate?(key, val)
  end

  File.write('cf_vars_to_migrate.yml', vars_to_migrate.to_yaml)
end
