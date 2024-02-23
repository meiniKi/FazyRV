#!/bin/bash

# Check if a file path is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_log_file>"
    exit 1
fi

# Path to the GateMate PnR log file
log_file="$1"

# Search for the last occurrence of the desired pattern and extract the frequency
frequency=$(tac "$log_file" | grep -m 1 -oP 'Maximum Clock Frequency on CLK \d+ \(\d+/\d+\): +\K\d+\.\d+(?= MHz)')

# Check if the frequency was found
if [ -z "$frequency" ]; then
    echo "Frequency not found in the log file."
    exit 1
else
    # Print the frequency
    echo "fmax $frequency MHz"
fi
