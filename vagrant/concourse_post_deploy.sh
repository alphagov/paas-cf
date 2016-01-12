#!/bin/bash
gardenDir="/var/vcap/data/garden"

echo "Removing packer ssh key..."
sed -i '/ vagrant$/ ! { d }' /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys

# This assumes you are running on an instance with attached ephemeral disk as current (0.70) concourse image does
echo "Mounting ${gardenDir} on to ephemeral disk..."
cp -R ${gardenDir}/* /mnt
umount /mnt

# Unmount all aufs mounts
mounts=$(cat /proc/mounts | grep /var/vcap/data/garden/aufs_graph/aufs/mnt | awk '{print $2}')
[[ -n "${mounts}" ]] && echo ${mounts} | xargs umount

# Only lazy unmount works here
umount -l /var/vcap/data/garden/aufs_graph/aufs

# Mount ephemeral storage as garden data
mount /dev/xvdb ${gardenDir}

/var/vcap/bosh/bin/monit restart garden


echo "Setting up concourse basic auth as $1 : $2"
sed "s/--development-mode//g" -i /var/vcap/jobs/atc/bin/atc_ctl      # dev mode disables all auth
sed "s/--basic-auth-username.*/--basic-auth-username \'$1\' \\\/" -i /var/vcap/jobs/atc/bin/atc_ctl
sed "s/--basic-auth-password.*/--basic-auth-password \'$2\' \\\/" -i /var/vcap/jobs/atc/bin/atc_ctl

/var/vcap/bosh/bin/monit restart atc
