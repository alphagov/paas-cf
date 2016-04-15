#!/bin/bash
echo "Starting scan..."
export LD_LIBRARY_PATH=/home/vcap/app/portable/usr/lib/:/home/vcap/app/portable/usr/lib/x86_64-linux-gnu

# shellcheck disable=SC2046
/home/vcap/app/portable/usr/bin/nmap -vv -sT -Pn -T5 -n --min-rate 50000 --min-hostgroup 1000 -p0-65535 -oG - $(cat IPs) >results 2>errors

echo "Finished"
touch scan_done
