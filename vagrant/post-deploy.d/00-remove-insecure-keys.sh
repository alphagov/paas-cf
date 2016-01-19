#!/bin/sh
echo "Removing packer ssh key..."
sed -i '/ vagrant$/ ! { d }' /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys


