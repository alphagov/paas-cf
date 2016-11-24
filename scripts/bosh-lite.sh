#!/bin/bash

set -eu
set -o pipefail

SCRIPT_NAME="$0"
PROJECT_DIR="$(cd "$(dirname "${SCRIPT_NAME}")/.."; pwd)"
PROJECT_DIR_PARENT="$(cd "${PROJECT_DIR}/.."; pwd)"

# Set to false to disable autohalt
BOSH_LITE_AUTO_HALT=${BOSH_LITE_AUTO_HALT:-true}

# Defaults
DEFAULT_BOSH_LITE_INSTANCE_TYPE=m3.xlarge
DEFAULT_BOSH_LITE_CODEBASE_PATH="${PROJECT_DIR_PARENT}/bosh-lite"
DEFAULT_BOSH_LITE_REGION="eu-west-1"
DEFAULT_BOSH_LITE_SUBNET_TAG_NAME="bosh-lite-subnet-0"
DEFAULT_BOSH_LITE_SECURITY_GROUP_TAG_NAME="bosh-lite-office-access"

export BOSH_LITE_INSTANCE_TYPE="${BOSH_LITE_INSTANCE_TYPE:-${DEFAULT_BOSH_LITE_INSTANCE_TYPE}}"
export BOSH_LITE_CODEBASE_PATH="${BOSH_LITE_CODEBASE_PATH:-${DEFAULT_BOSH_LITE_CODEBASE_PATH}}"
export BOSH_LITE_REGION="${BOSH_LITE_REGION:-${DEFAULT_BOSH_LITE_REGION}}"

export BOSH_LITE_SUBNET_TAG_NAME="${BOSH_LITE_SUBNET_TAG_NAME:-${DEFAULT_BOSH_LITE_SUBNET_TAG_NAME}}"
export BOSH_LITE_SECURITY_GROUP_TAG_NAME="${BOSH_LITE_SECURITY_GROUP_TAG_NAME:-${DEFAULT_BOSH_LITE_SECURITY_GROUP_TAG_NAME}}"

usage() {
  cat <<EOF
Start a bosh-lite instance in AWS.

Usage:
  $SCRIPT_NAME <start|stop|destroy|info|ssh>

Actions:

  start         Start bosh-lite
  stop          Halt bosh-lite
  destroy       Destroy bosh-lite
  info          Print bosh-lite info
  ssh           SSH or execute commands on the bosh-lite instance

Requirements:
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

  BOSH_LITE_SUBNET_TAG_NAME:
    Subnet tag 'Name' to deploy to. The subnet determines the VPC.
    Default: ${DEFAULT_BOSH_LITE_SUBNET_TAG_NAME}

  BOSH_LITE_SECURITY_GROUP_TAG_NAME:
    Security Group tag 'Name' to use for bosh-lite.
    Default: ${DEFAULT_BOSH_LITE_SECURITY_GROUP_TAG_NAME}

  BOSH_LITE_REGION:
    Bosh lite region to deploy
    Defaul: ${DEFAULT_BOSH_LITE_REGION}

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
  if ! ( which vagrant > /dev/null || vagrant plugin list | grep -q vagrant-aws); then
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

init_credentials() {
  export BOSH_LITE_NAME="${DEPLOY_ENV}-bosh-lite"
  export BOSH_AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
  export BOSH_AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
}

get_aws_key_pair_finger_print() {
  aws ec2 describe-key-pairs \
    --region "${BOSH_LITE_REGION}" \
    --filters "Name=key-name,Values=${BOSH_LITE_KEYPAIR}" \
    --query "KeyPairs[0].KeyFingerprint" \
    --output text
}

init_ssh_key_vars() {
  export BOSH_LITE_KEYPAIR="${DEPLOY_ENV}_bosh_lite_ssh_key_pair"

  # Get SSH key pair from the state
  SSH_DIR="${BOSH_LITE_CODEBASE_PATH}/.vagrant/.ssh"
  mkdir -p "${SSH_DIR}"
  export BOSH_LITE_PRIVATE_KEY="${SSH_DIR}/id_rsa"
  if [ ! -f "${BOSH_LITE_PRIVATE_KEY}" ]; then
    echo "SSH key is missing, regenerating..."
    ssh-keygen -f "${BOSH_LITE_PRIVATE_KEY}" -P ""
    chmod 600 "${BOSH_LITE_PRIVATE_KEY}"
  fi

  local aws_key_finger_print
  aws_key_finger_print=$(get_aws_key_pair_finger_print)
  local local_key_finger_print
  local_key_finger_print=$(if [ -f "${BOSH_LITE_PRIVATE_KEY}.fingerprint" ]; then cat "${BOSH_LITE_PRIVATE_KEY}.fingerprint"; fi)

  if [ "${aws_key_finger_print}" != "${local_key_finger_print}" ]; then
    echo "Updating AWS Key ${BOSH_LITE_KEYPAIR}"
    if [ "${aws_key_finger_print}" != "None" ]; then
      aws ec2 delete-key-pair \
        --region "${BOSH_LITE_REGION}" \
        --key-name "${BOSH_LITE_KEYPAIR}" > /dev/null || true
    fi
    aws ec2 import-key-pair \
      --region "${BOSH_LITE_REGION}" \
      --key-name "${BOSH_LITE_KEYPAIR}" \
      --public-key-material "$(cat "${BOSH_LITE_PRIVATE_KEY}.pub")" > /dev/null
    get_aws_key_pair_finger_print > "${BOSH_LITE_PRIVATE_KEY}.fingerprint"
  fi
}

delete_ssh_key_pair() {
  aws ec2 delete-key-pair \
    --region "${BOSH_LITE_REGION}" \
    --key-name "${BOSH_LITE_KEYPAIR}" > /dev/null || true
}

init_subnet_and_security_group() {
  # Query the subnet tagged as Name=bosh-lite-subnet-0
  BOSH_LITE_SUBNET_ID=$(
    aws ec2 describe-subnets \
      --region "${BOSH_LITE_REGION}" \
      --filters "Name=tag:Name,Values=${BOSH_LITE_SUBNET_TAG_NAME}" \
      --query 'Subnets[0].SubnetId' \
      --output text
    )
  export BOSH_LITE_SUBNET_ID
  if ! aws ec2 describe-subnets --region "${BOSH_LITE_REGION}" --subnet-ids "${BOSH_LITE_SUBNET_ID}" > /dev/null; then
    echo
    echo "ERROR: Cannot find valid subnet with Tag '${BOSH_LITE_SUBNET_TAG_NAME}'. Did you create it first?"
    exit 1
  fi

  # Query the security group tagged as Name=bosh-lite-office-access
  BOSH_LITE_SECURITY_GROUP=$(
    aws ec2 describe-security-groups \
      --region "${BOSH_LITE_REGION}" \
      --filters "Name=tag:Name,Values=${BOSH_LITE_SECURITY_GROUP_TAG_NAME}" \
      --query 'SecurityGroups[0].GroupId' \
      --output text
    )
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
  system("/var/vcap/bosh/bin/monit restart director")
  sleep 20
else
  puts "Admin password already changed, not updated."
end

puts "\nBosh-lite admin password is: #{config["user_management"]["local"]["users"][0]["password"]}\n\n"
EOF

  run_vagrant ssh -- sudo ruby ./update_director_password.rb
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
  info|start|stop|destroy|ssh)
  ;;
  *)
    usage
  ;;
esac

case "${ACTION}" in
  info)
    check_bosh_lite_codebase
    check_vagrant
    init_credentials
    init_ssh_key_vars
    print_info
    if [ "$(get_vagrant_state)" == "running" ]; then
      update_and_get_admin_password
    fi
  ;;
  start)
    check_bosh_lite_codebase
    check_vagrant
    init_credentials
    init_ssh_key_vars
    init_subnet_and_security_group

    get_vagrant_box

    run_vagrant up --provider=aws
    echo "Bosh lite instance provisioned."

    update_and_get_admin_password
    configure_auto_halt
    print_info
  ;;
  stop)
    check_bosh_lite_codebase
    check_vagrant
    init_credentials
    init_ssh_key_vars
    echo "Halting Bosh lite VM"
    run_vagrant ssh -- sudo halt
    sleep 10
    echo "Bosh lite VM state: $(get_vagrant_state)"
  ;;
  destroy)
    check_bosh_lite_codebase
    check_vagrant
    init_credentials
    init_ssh_key_vars
    run_vagrant destroy
    delete_ssh_key_pair
  ;;
  ssh)
    check_bosh_lite_codebase
    check_vagrant
    init_credentials
    init_ssh_key_vars
    shift
    run_vagrant ssh ${1:+--} "$@"
  ;;
esac




