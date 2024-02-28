#!/bin/bash

# Check if a file path is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_log_file>"
    exit 1
fi

# Path to the GateMate PnR log file
log_file="$1"

# Function to extract a specific value from the Utilization Report
extract_value() {
    local label="$1"
    awk -v label="$label" '
        $0 ~ /Utilization Report/ { report=1 }
        report && $1 == label {
            print $2;
            exit;
        }
    ' "$log_file"
}

# Extract values from Utilization Report
cpe=$(extract_value "CPEs")
bram_20k=$(extract_value "BRAM_20K")
bram_40k=$(extract_value "BRAM_40K")
fifo_40k=$(extract_value "FIFO_40K")

echo "CPEs $cpe"
echo "BRAM_20K $bram_20k"
echo "BRAM_40K $bram_40k"
echo "FIFO_40K $fifo_40k"
