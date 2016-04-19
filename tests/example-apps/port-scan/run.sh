#!/bin/bash
/bin/bash ./scan.sh &

# Show scan progress in logs for convenience
sleep 3 ; tail -F results &

python exec.py
