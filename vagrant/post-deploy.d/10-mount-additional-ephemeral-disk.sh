#!/bin/bash -e
gardenDir="/var/vcap/data/garden"

if ! mount | grep -q $gardenDir; then
    # This assumes you are running on an instance with attached ephemeral disk as current (0.70) concourse image does
    echo "Mounting ${gardenDir} on to ephemeral disk..."
    cp -R ${gardenDir}/* /mnt
    umount /mnt

    # Unmount all aufs mounts
    mounts=$(grep /var/vcap/data/garden/aufs_graph/aufs/mnt /proc/mounts | awk '{print $2}')
    [[ -n "${mounts}" ]] && echo "${mounts}" | xargs umount

    # Only lazy unmount works here
    umount -l /var/vcap/data/garden/aufs_graph/aufs

    # Mount ephemeral storage as garden data
    mount /dev/xvdb ${gardenDir}
    fstabline="/dev/xvdb\t${gardenDir}\tauto\tdefaults\t0\t0\n"
    grep --silent "$(echo -e $fstabline)" /etc/fstab || echo -e $fstabline >> /etc/fstab

    /var/vcap/bosh/bin/monit restart garden
fi
