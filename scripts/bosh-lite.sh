#!/bin/bash

set -eu
set -o pipefail

SCRIPT_NAME="$0"
PROJECT_DIR="$(cd "$(dirname "${SCRIPT_NAME}")/.."; pwd)"
PROJECT_DIR_PARENT="$(cd "${PROJECT_DIR}/.."; pwd)"

# Set to false to disable autohalt
BOSH_LITE_AUTO_HALT=${BOSH_LITE_AUTO_HALT:-true}

# Set to false to not run terraform
BOSH_LITE_TERRAFORM=${BOSH_LITE_TERRAFORM:-true}

# Defaults
DEFAULT_BOSH_LITE_INSTANCE_TYPE=m3.xlarge
DEFAULT_BOSH_LITE_CODEBASE_PATH="${PROJECT_DIR_PARENT}/bosh-lite"
DEFAULT_BOSH_LITE_REGION="eu-west-1"
DEFAULT_BOSH_LITE_VPC_TAG_NAME_SUFFIX="bosh-lite-vpc"
DEFAULT_BOSH_LITE_SUBNET_TAG_NAME_SUFFIX="bosh-lite-subnet-0"
DEFAULT_BOSH_LITE_SECURITY_GROUP_TAG_NAME_SUFFIX="bosh-lite-office-access"
DEFAULT_BOSH_LITE_KEYPAIR_SUFFIX=bosh-lite-ssh-key-pair

usage() {
  cat <<EOF
Start a bosh-lite instance in AWS.

Usage:
  $SCRIPT_NAME <action>

Actions:

  start                     Start bosh-lite
  stop                      Halt bosh-lite
  destroy                   Destroy bosh-lite
  info                      Print bosh-lite info
  ssh                       SSH or execute commands on the bosh-lite instance
  manifest <file.yml>       From the vagrant VM, login in bosh, upload the
                            given manifest, and set the deployment.
  bosh <bosh args>          Execute the give bosh-cli command in the vagrant.
                            Examples:
                              $SCRIPT_NAME bosh ssh app/0
                              $SCRIPT_NAME bosh deploy
  cleanup                   Delete all bosh-lite resources for \$DEPLOY_ENV
                            To use if the terraform and vagrant state are
                            not available.

Basic requirements:
 * Exported \$DEPLOY_ENV variable
 * Exported AWS credentials as \$AWS_ACCESS_KEY_ID and \$AWS_SECRET_ACCESS_KEY
 * aws_cli installed
 * vagrant and vagrant-aws plugin
 * terraform

Variables to override:

  BOSH_LITE_INSTANCE_TYPE:
    VM size for this VM. More info: https://aws.amazon.com/ec2/instance-types/
    Default: ${DEFAULT_BOSH_LITE_INSTANCE_TYPE}

  BOSH_LITE_CODEBASE_PATH:
    Where bosh-lite code is cloned
    Default: ${DEFAULT_BOSH_LITE_CODEBASE_PATH}

  BOSH_LITE_REGION:
    Bosh lite region to deploy
    Defaul: ${DEFAULT_BOSH_LITE_REGION}

  BOSH_LITE_AUTO_HALT:
    Enable or disable auto-halt of the VM at 19:00 UTC
    Default: true

  BOSH_LITE_RUN_TERRAFORM:
    Run terraform to create the AWS required resources: VPC, subnet, SG, keys...
    Default: true

When not using terraform, these variables would allow to select
alternative resources. Do not override if using terraform.

  BOSH_LITE_SUBNET_TAG_NAME:
    VPC tag 'Name' to deploy to. Will be created if missing.
    Default: \${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_VPC_TAG_NAME_SUFFIX}

  BOSH_LITE_SUBNET_TAG_NAME:
    Subnet tag 'Name' to deploy to. Will be created if missing.
    Default: \${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_SUBNET_TAG_NAME_SUFFIX}

  BOSH_LITE_SECURITY_GROUP_TAG_NAME:
    Security Group tag 'Name' to use for bosh-lite. Will be created if missing.
    Default: \${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_SECURITY_GROUP_TAG_NAME_SUFFIX}

  BOSH_LITE_KEYPAIR:
    AWS SSH key pair to use.
    Default: \${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_KEYPAIR_SUFFIX}

EOF

  exit 0
}

check_bosh_lite_codebase() {
  if [ ! -f "${BOSH_LITE_CODEBASE_PATH}/Vagrantfile" ]; then
    cat <<EOF
Path ${BOSH_LITE_CODEBASE_PATH} does not seem to contain the bosh-lite code base"

You can clone it by running:

  git clone https://github.com/cloudfoundry/bosh-lite.git "${BOSH_LITE_CODEBASE_PATH}"

or export \$BOSH_LITE_CODEBASE_PATH to a path containing the bosh-lite code.

EOF
    exit 1
  fi
}

check_vagrant() {
  if ! ( which vagrant > /dev/null && vagrant plugin list | grep -q vagrant-aws); then
    cat <<EOF
You must have vagrant installed in your system with the vagrant-aws plugin.

1. Check https://www.vagrantup.com/docs/installation/ to install vagrant
2. run 'vagrant plugin install vagrant-aws' to install the vagrant-aws plugin
EOF
    exit 1
  fi
}

get_vagrant_box() {
  if ! vagrant box list | grep -qe 'cloudfoundry/bosh-lite .*aws'; then
    vagrant box add cloudfoundry/bosh-lite --provider aws
  fi
}

init_environment() {
  if [ -z "${DEPLOY_ENV:-}" ]; then
    echo "Error: You must set \$DEPLOY_ENV"
    exit 1
  fi

  export BOSH_LITE_NAME="${DEPLOY_ENV}-bosh-lite"
  export BOSH_AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
  export BOSH_AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"

  export BOSH_LITE_CODEBASE_PATH="${BOSH_LITE_CODEBASE_PATH:-$DEFAULT_BOSH_LITE_CODEBASE_PATH}"

  export BOSH_LITE_INSTANCE_TYPE="${BOSH_LITE_INSTANCE_TYPE:-${DEFAULT_BOSH_LITE_INSTANCE_TYPE}}"
  export BOSH_LITE_CODEBASE_PATH="${BOSH_LITE_CODEBASE_PATH:-${DEFAULT_BOSH_LITE_CODEBASE_PATH}}"
  export BOSH_LITE_REGION="${BOSH_LITE_REGION:-${DEFAULT_BOSH_LITE_REGION}}"

  export BOSH_LITE_VPC_TAG_NAME="${BOSH_LITE_VPC_TAG_NAME:-${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_VPC_TAG_NAME_SUFFIX}}"
  export BOSH_LITE_SUBNET_TAG_NAME="${BOSH_LITE_SUBNET_TAG_NAME:-${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_SUBNET_TAG_NAME_SUFFIX}}"
  export BOSH_LITE_SECURITY_GROUP_TAG_NAME="${BOSH_LITE_SECURITY_GROUP_TAG_NAME:-${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_SECURITY_GROUP_TAG_NAME_SUFFIX}}"

  export BOSH_LITE_KEYPAIR="${BOSH_LITE_KEYPAIR:-${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_KEYPAIR_SUFFIX}}"
}

init_ssh_key_vars() {
  # Get SSH key pair from the state
  SSH_DIR="${BOSH_LITE_CODEBASE_PATH}/.vagrant/.ssh"
  mkdir -p "${SSH_DIR}"
  export BOSH_LITE_PRIVATE_KEY="${SSH_DIR}/id_rsa"
  if [ ! -f "${BOSH_LITE_PRIVATE_KEY}" ]; then
    echo "SSH key is missing, regenerating..."
    ssh-keygen -f "${BOSH_LITE_PRIVATE_KEY}" -P ""
    chmod 600 "${BOSH_LITE_PRIVATE_KEY}"
  fi
}

build_aws_cli_tag_filter() {
  local pair
  local filter
  filter=""
  for pair in "$@"; do
    filter="${filter:+${filter} }Name=tag:${pair%:*},Values=${pair#*:}"
  done
  echo "${filter}"
}

find_vpc_by_tags() {
  local tag_filter
  tag_filter="$(build_aws_cli_tag_filter "$@")"
  # shellcheck disable=SC2086
  aws ec2 describe-vpcs \
    --region "${BOSH_LITE_REGION}" \
    --filters ${tag_filter} \
    --query 'Vpcs[0].VpcId' \
    --output text
}

find_subnet_by_tags() {
  local tag_filter
  tag_filter="$(build_aws_cli_tag_filter "$@")"
  # shellcheck disable=SC2086
  aws ec2 describe-subnets \
    --region "${BOSH_LITE_REGION}" \
    --filters ${tag_filter} \
    --query 'Subnets[0].SubnetId' \
    --output text
}

find_security_group_by_tags() {
  local tag_filter
  tag_filter="$(build_aws_cli_tag_filter "$@")"
  # shellcheck disable=SC2086
  aws ec2 describe-security-groups \
    --region "${BOSH_LITE_REGION}" \
    --filters ${tag_filter} \
    --query 'SecurityGroups[0].GroupId' \
    --output text
}

find_route_table_by_tags() {
  local tag_filter
  tag_filter="$(build_aws_cli_tag_filter "$@")"
  # shellcheck disable=SC2086
  aws ec2 describe-route-tables \
    --region "${BOSH_LITE_REGION}" \
    --filters ${tag_filter} \
    --query 'RouteTables[0].RouteTableId' \
    --output text
}

find_internet_gateway_by_tags() {
  local tag_filter
  tag_filter="$(build_aws_cli_tag_filter "$@")"
  # shellcheck disable=SC2086
  aws ec2 describe-internet-gateways \
    --region "${BOSH_LITE_REGION}" \
    --filters ${tag_filter} \
    --query 'InternetGateways[0].InternetGatewayId' \
    --output text
}

find_all_instances_by_tags() {
  local tag_filter
  tag_filter="$(build_aws_cli_tag_filter "$@")"
  # shellcheck disable=SC2086
  aws ec2 describe-instances \
    --region "${BOSH_LITE_REGION}" \
    --filters ${tag_filter} \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text | xargs
}

get_instance_state() {
  aws ec2 describe-instances \
    --region "${BOSH_LITE_REGION}" \
    --instance-ids "$1" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text
}

cleanup_bosh_lite() {
  instanceids="$(find_all_instances_by_tags "Name:${DEPLOY_ENV}-bosh-lite")"
  subnetid=$(find_subnet_by_tags "Name:${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_SUBNET_TAG_NAME_SUFFIX}" "Created-by:terraform-bosh-lite")
  rtbid="$(find_route_table_by_tags "Name:${DEPLOY_ENV}-bosh-lite-rtb" "Created-by:terraform-bosh-lite")"
  gwid="$(find_internet_gateway_by_tags "Name:${DEPLOY_ENV}-bosh-lite-igw" "Created-by:terraform-bosh-lite")"
  sgid="$(find_security_group_by_tags "Name:${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_SECURITY_GROUP_TAG_NAME_SUFFIX}" "Created-by:terraform-bosh-lite")"
  vpcid=$(find_vpc_by_tags "Name:${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_VPC_TAG_NAME_SUFFIX}" "Created-by:terraform-bosh-lite")

  cat <<EOF

WARNING: This is a destructive operation! It will delete all the objects directly.

If you still have the terraform and the vagrant state for this bosh lite, use:

  DEPLOY_ENV=$DEPLOY_ENV ${SCRIPT_NAME} destroy

These resources will get deleted:

  * Instances: ${instanceids}
  * Subnet: ${subnetid}
  * Routing table: ${rtbid}
  * Gateway ID: ${gwid}
  * Security Group: ${sgid}
  * VPC: ${vpcid}

EOF
  read -r -p "Do you want to continue? [y/N] " c
  if [ "$c" != "y" ] && [ "$c" != "Y" ]; then
    exit 1
  fi

  if [ "$instanceids" != "None" ]; then
    for instanceid in $instanceids; do
      if [ "$(get_instance_state "${instanceid}")" != "terminated" ]; then
        echo "Deleting VM with ${instanceid} Name:${DEPLOY_ENV}-bosh-lite"
        aws ec2 terminate-instances \
          --region "${BOSH_LITE_REGION}" \
          --instance-ids "${instanceid}" > /dev/null
        echo -n "Waiting for ${instanceid} to be terminated"
        while [ "$(get_instance_state "${instanceid}")" != "terminated" ]; do
          echo -n .
          sleep 2
        done
        echo "Done"
      fi
    done
  fi

  if [ "$subnetid" != "None" ]; then
    echo "Deleting Subnet with ${subnetid} Name:${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_SUBNET_TAG_NAME_SUFFIX}"
    aws ec2 delete-subnet \
      --region "${BOSH_LITE_REGION}" \
      --subnet-id "${subnetid}"
  fi

  if [ "$rtbid" != "None" ]; then
    echo "Deleting Routing Table ${rtbid} with Name:${DEPLOY_ENV}-bosh-lite-rtb"
    aws ec2 delete-route-table \
      --region "${BOSH_LITE_REGION}" \
      --route-table-id "${rtbid}"
  fi

  if [ "$gwid" != "None" ]; then
    echo "Deleting Internet Gateway ${gwid} with Name:${DEPLOY_ENV}-bosh-lite-igw"
    vpcid="$(
      aws ec2 describe-internet-gateways \
        --region "${BOSH_LITE_REGION}" \
        --internet-gateway-id "${gwid}" \
        --query InternetGateways[0].Attachments[0].VpcId \
        --output text
    )"
    aws ec2 detach-internet-gateway \
      --region "${BOSH_LITE_REGION}" \
      --internet-gateway-id "${gwid}" \
      --vpc-id "${vpcid}"

    aws ec2 delete-internet-gateway \
      --region "${BOSH_LITE_REGION}" \
      --internet-gateway-id "${gwid}"
  fi

  if [ "$sgid" != "None" ]; then
    echo "Deleting Security Group ${sgid} with Name:${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_SECURITY_GROUP_TAG_NAME_SUFFIX}"
    aws ec2 delete-security-group \
      --region "${BOSH_LITE_REGION}" \
      --group-id "${sgid}"
  fi

  if [ "$vpcid" != "None" ]; then
    echo "Deleting VPC ${vpcid} with Name:${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_VPC_TAG_NAME_SUFFIX}"
    aws ec2 delete-vpc \
      --region "${BOSH_LITE_REGION}" \
      --vpc-id "${vpcid}"
  fi

  aws ec2 delete-key-pair \
    --region "${BOSH_LITE_REGION}" \
    --key-name "${DEPLOY_ENV}-${DEFAULT_BOSH_LITE_KEYPAIR_SUFFIX}" > /dev/null || true

  echo "Bosh-lite called ${DEPLOY_ENV} cleaned!"
}

run_terraform() {
  mkdir -p "${BOSH_LITE_CODEBASE_PATH}/.vagrant"
  terraform "$@" \
    -state="${BOSH_LITE_CODEBASE_PATH}/.vagrant/terraform.tfstate" \
    -var "env=${DEPLOY_ENV}" \
    -var "bosh_lite_ssh_key=$(cat "${BOSH_LITE_PRIVATE_KEY}.pub")" \
    -var-file="${PROJECT_DIR}/terraform/dev.tfvars" \
    "${PROJECT_DIR}/terraform/bosh-lite"
}

init_subnet_and_security_group_vars() {
  # Query the subnet tagged as Name=bosh-lite-subnet-0
  BOSH_LITE_SUBNET_ID="$(find_subnet_by_tags "Name:${BOSH_LITE_SUBNET_TAG_NAME}")"
  export BOSH_LITE_SUBNET_ID
  if ! aws ec2 describe-subnets --region "${BOSH_LITE_REGION}" --subnet-ids "${BOSH_LITE_SUBNET_ID}" > /dev/null; then
    echo
    echo "ERROR: Cannot find valid subnet with Tag '${BOSH_LITE_SUBNET_TAG_NAME}'. Did you create it first?"
    exit 1
  fi

  # Query the security group tagged as Name=bosh-lite-office-access
  BOSH_LITE_SECURITY_GROUP="$(find_security_group_by_tags "Name:${BOSH_LITE_SECURITY_GROUP_TAG_NAME}")"
  export BOSH_LITE_SECURITY_GROUP
  if ! aws ec2 describe-security-groups --region "${BOSH_LITE_REGION}" --group-ids "${BOSH_LITE_SECURITY_GROUP}" > /dev/null; then
    echo
    echo "ERROR: Cannot find valid security group with Tag '${BOSH_LITE_SECURITY_GROUP_TAG_NAME}'. Did you create it first?"
    exit 1
  fi
}

run_vagrant() {
  (
    cd "${BOSH_LITE_CODEBASE_PATH}"
    vagrant "$@"
  )
}

configure_auto_halt() {
  if [ "${BOSH_LITE_AUTO_HALT}" == "true" ]; then
    # m h dom mon dow user  command
    echo "0 19 * * * root /sbin/halt -p" | run_vagrant ssh -- sudo tee /etc/cron.d/auto_halt > /dev/null
    run_vagrant ssh -- sudo /etc/init.d/cron restart > /dev/null
  else
    run_vagrant ssh -- sudo rm -f /etc/cron.d/auto_halt
  fi
}

get_vagrant_state() {
  aws ec2 describe-instances \
    --region "${BOSH_LITE_REGION}" \
    --filter "Name=tag:Name,Values=${BOSH_LITE_NAME}" \
    --query 'Reservations[*].Instances[*].State.Name' \
    --output text | grep -v terminated
}

get_vagrant_public_ip() {
  aws ec2 describe-instances \
    --region "${BOSH_LITE_REGION}" \
    --filter "Name=tag:Name,Values=${BOSH_LITE_NAME}" \
    --query 'Reservations[*].Instances[*].PublicIpAddress' \
    --output text
}

get_vagrant_private_ip() {
  aws ec2 describe-instances \
    --region "${BOSH_LITE_REGION}" \
    --filter "Name=tag:Name,Values=${BOSH_LITE_NAME}" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text
}

get_admin_password() {
  run_vagrant ssh -- sudo /etc/init.d/cron restart > /dev/null
}

update_and_get_admin_password() {
  echo "Updating and getting admin password..."
  cat <<EOF | run_vagrant ssh -- tee update_director_password.rb > /dev/null
#!/bin/env ruby

require 'yaml'

config = YAML.load_file('/var/vcap/jobs/director/config/director.yml.erb')
if config["user_management"]["local"]["users"] == []
  puts "Generating new password and restarting bosh..."
  new_password = (1..12).map{|i| ('a'..'z').to_a[rand(26)]}.join
  config["user_management"]["local"]["users"] =  [{"name" => "admin", "password" => new_password}]
  File.open('/var/vcap/jobs/director/config/director.yml.erb', 'w') { |file| file.write(YAML.dump(config)) }
  File.open('/home/ubuntu/director_admin_password.txt', 'w') { |file| file.write(new_password) }
  system("/var/vcap/bosh/bin/monit restart director")
  sleep 20
else
  puts "Admin password already changed, not updated."
end

puts "\nBosh-lite admin password is: #{config["user_management"]["local"]["users"][0]["password"]}\n\n"
EOF

  run_vagrant ssh -- sudo ruby ./update_director_password.rb
}

setup_bosh_manifest() {
  # shellcheck disable=SC2002
  # shellcheck disable=SC2016
  cat "$1" | run_vagrant ssh -- '
      echo -e "admin\n$(cat /home/ubuntu/director_admin_password.txt)" | bosh login
      sed "s/^director_uuid:.*/director_uuid: $(bosh status --uuid)/" > manifest.yml
      bosh deployment manifest.yml
    '
}

print_info() {
  BOSH_LITE_PUBLIC_IP=$(get_vagrant_public_ip)
  BOSH_LITE_PRIVATE_IP=$(get_vagrant_private_ip)
  echo "Bosh-Lite state: $(get_vagrant_state)"
  if [ -z "${BOSH_LITE_PUBLIC_IP}" ] && [ -z "${BOSH_LITE_PRIVATE_IP}" ]; then
    echo "Cannot find the public or private IP for a bosh-lite VM with name '${BOSH_LITE_NAME}' in region ${BOSH_LITE_REGION}. Is it running?"
    return
  fi
  cat <<EOF
Bosh-Lite public IP: ${BOSH_LITE_PUBLIC_IP:-n/a}
Bosh-Lite private IP: ${BOSH_LITE_PRIVATE_IP}

Add it as a target by running:

  bosh target ${BOSH_LITE_PUBLIC_IP}

  or

  bosh target ${BOSH_LITE_PRIVATE_IP}

SSH to it running:

  DEPLOY_ENV=${DEPLOY_ENV} $SCRIPT_NAME ssh

or

  DEPLOY_ENV=${DEPLOY_ENV} $SCRIPT_NAME ssh <commands>

EOF

  if [ "${BOSH_LITE_AUTO_HALT}" == "true" ]; then
    echo "Note: This VM will be automatically stopped in the evenings"
  else
    echo "Note: This VM will NOT be automatically stopped in the evenings"
  fi
}

ACTION=${1:-}

case "${ACTION}" in
  info|start|stop|destroy|ssh|bosh|cleanup)
  ;;
  manifest)
    if [ -z "${2:-}" ] && ! [ -f "${2:-}" ]; then
      echo "You must pass a manifest file."
      exit 1
    fi
  ;;
  *)
    usage
  ;;
esac

case "${ACTION}" in
  info)
    init_environment
    check_bosh_lite_codebase
    check_vagrant
    init_ssh_key_vars
    print_info
    if [ "$(get_vagrant_state)" == "running" ]; then
      update_and_get_admin_password
    fi
  ;;
  start)
    init_environment
    check_bosh_lite_codebase
    check_vagrant

    init_ssh_key_vars

    if [ "${BOSH_LITE_TERRAFORM}" == "true" ]; then
      run_terraform apply
    fi

    init_subnet_and_security_group_vars

    get_vagrant_box
    run_vagrant up --provider=aws
    echo "Bosh lite instance provisioned."

    update_and_get_admin_password
    configure_auto_halt
    print_info
  ;;
  stop)
    init_environment
    check_bosh_lite_codebase
    check_vagrant
    init_ssh_key_vars
    echo "Halting Bosh lite VM"
    run_vagrant ssh -- sudo halt
    sleep 10
    echo "Bosh lite VM state: $(get_vagrant_state)"
  ;;
  destroy)
    init_environment
    check_bosh_lite_codebase
    check_vagrant
    init_ssh_key_vars

    run_vagrant destroy

    if [ "${BOSH_LITE_TERRAFORM}" == "true" ]; then
      run_terraform destroy -force
    fi
  ;;
  ssh)
    init_environment
    check_bosh_lite_codebase
    check_vagrant
    init_ssh_key_vars
    shift
    run_vagrant ssh ${1:+--} "$@"
  ;;
  manifest)
    init_environment
    check_bosh_lite_codebase
    check_vagrant
    init_ssh_key_vars
    setup_bosh_manifest "$2"
  ;;
  bosh)
    init_environment
    check_bosh_lite_codebase
    check_vagrant
    init_ssh_key_vars
    shift
    run_vagrant ssh -- -t bosh "$@"
  ;;
  cleanup)
    init_environment
    cleanup_bosh_lite
  ;;
esac




