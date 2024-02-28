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
number_of_CC_ADDF=$(grep -E "CC_ADDF[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_CC_BUFG=$(grep -E "CC_BUFG[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_CC_DFF=$(grep -E "CC_DFF[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_CC_IBUF=$(grep -E "CC_IBUF[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_CC_LUT1=$(grep -E "CC_LUT1[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_CC_LUT2=$(grep -E "CC_LUT2[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_CC_LUT3=$(grep -E "CC_LUT3[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_CC_LUT4=$(grep -E "CC_LUT4[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_CC_MX8=$(grep -E "CC_MX8[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_CC_OBUF=$(grep -E "CC_OBUF[[:space:]]+[0-9]+" $log_file | awk '{print $2}')

# Print the extracted information
echo "Number of wires: $number_of_wires"
echo "Number of wire bits: $number_of_wire_bits"
echo "Number of public wires: $number_of_public_wires"
echo "Number of public wire bits: $number_of_public_wire_bits"
echo "Number of memories: $number_of_memories"
echo "Number of memory bits: $number_of_memory_bits"
echo "Number of cells: $number_of_cells"
echo "Number of CC_ADDF: $number_of_CC_ADDF"
echo "Number of CC_BUFG: $number_of_CC_BUFG"
echo "Number of CC_DFF: $number_of_CC_DFF"
echo "Number of CC_IBUF: $number_of_CC_IBUF"
echo "Number of CC_LUT1: $number_of_CC_LUT1"
echo "Number of CC_LUT2: $number_of_CC_LUT2"
echo "Number of CC_LUT3: $number_of_CC_LUT3"
echo "Number of CC_LUT4: $number_of_CC_LUT4"
echo "Number of CC_MX8: $number_of_CC_MX8"
echo "Number of CC_OBUF: $number_of_CC_OBUF"
