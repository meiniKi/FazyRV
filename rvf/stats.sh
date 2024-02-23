#!/bin/bash

# Check if a filename argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <dir_name>"
    exit 1
fi

# Set a variable to track whether any lines have been printed
has_error=0

# Navigate to the "checks" directory
cd "$1"

# Loop through the immediate subdirectories in the "checks" directory
for dir in */; do
    if [ ! -e "$dir/PASS" ]; then
        echo "Directory with no PASS file: $dir"
        has_error=1
    fi
done

cd ..

# Set the exit code based on whether any lines have been printed
if [ $has_error -eq 1 ]; then
    exit -1
else
    exit 0
fi
