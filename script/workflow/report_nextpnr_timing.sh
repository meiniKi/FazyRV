#!/bin/bash

# Check if the file path is provided
if [[ -z "$1" ]]; then
    echo "Please provide a file path as argument."
    exit 1
fi

# Check if the file exists
if [[ ! -f "$1" ]]; then
    echo "File not found."
    exit 1
fi

# Extract the desired value using awk and tac
tac "$1" | awk -F: '/^Info: Max frequency/ { 
    match($0, /[0-9]+\.[0-9]+/); 
    if (RSTART) {
        freq = substr($0, RSTART, RLENGTH);
        print "fmax " freq;
        exit;
    }
}'


exit 0
