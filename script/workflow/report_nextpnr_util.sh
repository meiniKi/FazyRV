#!/bin/bash

# Check if a filename argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

log_file="$1"

# Check if the log file exists
if [ ! -f "$log_file" ]; then
    echo "Nextpnr log file ($log_file) not found."
    exit 1
fi

awk '/Info: Device utilisation:/{flag=1; next} /^$/ {flag=0} /Info: /{if(flag) print}' $log_file | awk '{gsub("/.*", "", $3); print $2, $3}' | sed 's/://'


