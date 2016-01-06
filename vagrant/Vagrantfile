# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = ENV['VAGRANT_BOX_NAME'] || 'aws_vagrant_box'

  config.vm.provision "shell" do |s|
    s.privileged = true
    s.path = "enable_concourse_auth.sh"
    s.args = "#{ENV['CONCOURSE_ATC_USER']} #{ENV['CONCOURSE_ATC_PASSWORD']}"
  end

  config.vm.provider :aws do |aws, override|
    aws.access_key_id = ENV['AWS_ACCESS_KEY_ID']
    aws.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    aws.associate_public_ip = true
    aws.tags = { 'Name' => (ENV['DEPLOY_ENV'] || ENV['USER']) + " concourse" }

    # The Concourse AMI is currently only available in us-east-1, this is v. 0.70
    aws.ami = 'ami-5c104436'
    aws.region = 'us-east-1'

    # Only HVM instances with ephemeral disks can be used
    aws.instance_type = 'm3.large'

    # us-east-1e in default VPC, 172.31.0.0/20 range
    aws.subnet_id = 'subnet-b2e3a488'

    # "Concourse Vagrant" security group
    aws.security_groups = ['sg-ee21a597']

    # Could be replaced by key per user in the future. But would require each user's key to be in AWS.
    aws.keypair_name = 'insecure-deployer'
    override.ssh.username = "ubuntu"

    # Fix issue on osx: https://github.com/mitchellh/vagrant/issues/5401#issuecomment-115240904
    override.nfs.functional = false
  end

end
