#!/bin/bash

# Check if a file path is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_vivado_utilization_report>"
    exit 1
fi

file_path="$1"

# Check if the file exists
if [ ! -f "$file_path" ]; then
    echo "File not found: $file_path"
    exit 1
fi

# Define the regex patterns
pattern1='^\|\s*Slice\s*\|'
pattern2='^\|\s*SLICEL\s*\|'
pattern3='^\|\s*SLICEM\s*\|'

# Extract and print the values without leading and trailing whitespaces
grep -E "$pattern1|$pattern2|$pattern3" "$file_path" | awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $3); print $2, $3}'

