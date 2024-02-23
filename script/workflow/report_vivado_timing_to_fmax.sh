#!/bin/bash

# Check if two arguments are given
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path_to_directory> <T in ns>"
    exit 1
fi

directory=$1
Tns=$2
export Tns

# Function to process each file
process_file() {
    local file=$1
    local T=$2
    local wns=$(cat "$file")
    if [ ! -z "$wns" ]; then
        local fmax=$(bc <<< "scale=4; 1000/($T - $wns)")
        local new_file_name=$(echo $file | sed 's/summary_wns_/summary_fmax_/')
        echo "fmax $fmax" > "$new_file_name"
    fi
}

export -f process_file

# Find files and process them
find "$directory" -type f -name "summary_wns_*" -exec bash -c 'process_file "$0" $Tns' {} \;

echo "Processing complete."
