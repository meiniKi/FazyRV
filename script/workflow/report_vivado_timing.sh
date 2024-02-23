#!/bin/bash

# Check if a file path is provided
if [ $# -eq 0 ]; then
    echo "No file path provided."
    exit 1
fi

# Assign the file path to a variable
FILE_PATH="$1"

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "File does not exist: $FILE_PATH"
    exit 1
fi

# Use awk to find the line after "WNS(ns)", skip the next line, then extract the float value
awk '/WNS\(ns\)/{getline; getline; print $1; exit}' "$FILE_PATH"
