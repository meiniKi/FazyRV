#!/bin/bash

# Check if a filename argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

log_file="$1"

# Check if the log file exists
if [ ! -f "$log_file" ]; then
    echo "Yosys log file ($log_file) not found."
    exit 1
fi

# Extract the resource information using regular expressions
number_of_wires=$(grep -E "Number of wires:[[:space:]]+[0-9]+" $log_file | awk '{print $4}')
number_of_wire_bits=$(grep -E "Number of wire bits:[[:space:]]+[0-9]+" $log_file | awk '{print $5}')
number_of_public_wires=$(grep -E "Number of public wires:[[:space:]]+[0-9]+" $log_file | awk '{print $5}')
number_of_public_wire_bits=$(grep -E "Number of public wire bits:[[:space:]]+[0-9]+" $log_file | awk '{print $6}')
number_of_memories=$(grep -E "Number of memories:[[:space:]]+[0-9]+" $log_file | awk '{print $4}')
number_of_memory_bits=$(grep -E "Number of memory bits:[[:space:]]+[0-9]+" $log_file | awk '{print $5}')
number_of_processes=$(grep -E "Number of processes:[[:space:]]+[0-9]+" $log_file | awk '{print $4}')
number_of_cells=$(grep -E "Number of cells:[[:space:]]+[0-9]+" $log_file | awk '{print $4}')
number_of_SB_CARRY=$(grep -E "SB_CARRY[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_SB_DFF=$(grep -E "SB_DFF[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_SB_DFFE=$(grep -E "SB_DFFESR[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_SB_DFFESR=$(grep -E "SB_DFFSR[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_SB_LUT4=$(grep -E "SB_LUT4[[:space:]]+[0-9]+" $log_file | awk '{print $2}')

# Print the extracted information
echo "Number of wires: $number_of_wires"
echo "Number of wire bits: $number_of_wire_bits"
echo "Number of public wires: $number_of_public_wires"
echo "Number of public wire bits: $number_of_public_wire_bits"
echo "Number of memories: $number_of_memories"
echo "Number of memory bits: $number_of_memory_bits"
echo "Number of cells: $number_of_cells"
echo "Number of CARRY: $number_of_SB_CARRY"
echo "Number of DFF: $number_of_SB_DFF"
echo "Number of DFFE: $number_of_SB_DFFE"
echo "Number of DFFESR: $number_of_SB_DFFESR"
echo "Number of LUT4: $number_of_SB_LUT4"
