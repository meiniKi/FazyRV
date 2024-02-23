#!/bin/bash

# Check if the user provided a directory
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory-path>"
    exit 1
fi

DIR="$1"

# Check if the provided directory exists
if [ ! -d "$DIR" ]; then
    echo "Error: Directory $DIR does not exist."
    exit 1
fi

# Create an associative array to store the file content
declare -A table

# Flag to track if any file has content other than "0"
non_zero_content_found=0

# Extract the stringA, stringB, and number from the filename and populate the table
for file in "$DIR"/*; do
    filename=$(basename -- "$file")
    number=$(echo "$filename" | cut -d'-' -f1)
    stringA=$(echo "$filename" | cut -d'-' -f2)
    stringB=$(echo "$filename" | cut -d'-' -f3 | cut -d'.' -f1) # remove .log extension

    # Read the file content
    content=$(cat "$file" | tr -d '\n') # Remove newline character if present

    # Check if the content is not "0" and set the flag
    if [ "$content" != "0" ]; then
        non_zero_content_found=1
    fi

    # Populate the table based on the content value
    if [ "$content" == "0" ]; then
        table["$stringA-$stringB,$number"]="OK"
    else
        table["$stringA-$stringB,$number"]="ERR"
    fi
done

# Display the transposed table
echo -e "CONF-RF\\CHUNKSIZE\t$(echo "${!table[@]}" | tr ' ' '\n' | cut -d',' -f2 | sort -u | tr '\n' '\t')"
for key in $(echo "${!table[@]}" | tr ' ' '\n' | cut -d',' -f1 | sort -u); do
    row="$key\t\t"
    for number in $(echo "${!table[@]}" | tr ' ' '\n' | cut -d',' -f2 | sort -u); do
        row+="${table["$key,$number"]}\t"
    done
    echo -e "$row"
done

# Return -1 if any file had content other than "0", otherwise return 0
if [ $non_zero_content_found -eq 1 ]; then
    exit -1
else
    exit 0
fi
