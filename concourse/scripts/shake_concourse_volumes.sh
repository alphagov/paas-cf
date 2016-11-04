#!/bin/bash

cat <<"EOF"

This operation will restart concourse and dropping all the volumes...

                 ,-.
       _,.      /  /          ,--.!,
      ; \____,-==-._  )    __/   -*-
      //_    `----' {+>  ,d08b.  '|`
      `  `'--/  /-'`(    0088MM
            /  /         `9MMP'       BLOW THAT CONCOURSE!!!
      dew   `='       hjm
                               via http://ascii.co.uk/art/plane
                               and http://ascii.co.uk/art/bomb

EOF

set -e

sudo -v -p "Type sudo password to continue: "

echo "Stopping all the concourse services..."
for i in atc beacon tsa baggageclaim garden ; do
   sudo -i /var/vcap/bosh/bin/monit stop $i;
done
sleep 10

echo -n "Killing all runc containers..."
sudo pkill -f runc # Be sure that all containers are stopped
while pgrep -f runc; do
   sleep 1
   echo .
done
echo

echo "Flushing all iptables rules from previus containers..."
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X

echo "Deleting all baggageclaim volumes and garden data"
if grep -q /var/vcap/data/baggageclaim/volumes /proc/mounts; then
   sudo umount -fl /var/vcap/data/baggageclaim/volumes
fi
if grep -q /var/vcap/data/garden/graph /proc/mounts; then
   sudo umount -fl /var/vcap/data/garden/graph
fi
if sudo losetup -a | grep -q /dev/loop0; then
   sudo losetup -d /dev/loop0
fi
if sudo losetup -a | grep -q /dev/loop1; then
   sudo losetup -d /dev/loop1
fi
sudo rm -rf /var/vcap/data/garden /var/vcap/data/baggageclaim/volumes.img

echo "Dropping volume, containers and images references from concourse DB..."
# Remove all the tables related to containers
sudo /var/vcap/packages/postgresql_9.3/bin/psql -U atc -h 127.0.0.1 <<EOF
delete from volumes;
delete from image_resource_versions;
delete from containers;
EOF

echo "Starting the concourse services again..."
for i in atc beacon tsa baggageclaim garden ; do
   sudo -i /var/vcap/bosh/bin/monit start $i;
done
