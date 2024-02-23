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
number_of_ALU=$(grep -E "ALU[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_DFF=$(grep -E "DFF[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_DFFE=$(grep -E "DFFE[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_DFFR=$(grep -E "DFFR[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_DFFRE=$(grep -E "DFFRE[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_GND=$(grep -E "GND[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_IBUF=$(grep -E "IBUF[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_LUT1=$(grep -E "LUT1[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_LUT2=$(grep -E "LUT2[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_LUT3=$(grep -E "LUT3[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_LUT4=$(grep -E "LUT4[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_MUX2_LUT5=$(grep -E "MUX2_LUT5[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_MUX2_LUT6=$(grep -E "MUX2_LUT6[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_MUX2_LUT7=$(grep -E "MUX2_LUT7[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_MUX2_LUT8=$(grep -E "MUX2_LUT8[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_OBUF=$(grep -E "OBUF[[:space:]]+[0-9]+" $log_file | awk '{print $2}')
number_of_VCC=$(grep -E "VCC[[:space:]]+[0-9]+" $log_file | awk '{print $2}')

# Print the extracted information
echo "Number of wires: $number_of_wires"
echo "Number of wire bits: $number_of_wire_bits"
echo "Number of public wires: $number_of_public_wires"
echo "Number of public wire bits: $number_of_public_wire_bits"
echo "Number of memories: $number_of_memories"
echo "Number of memory bits: $number_of_memory_bits"
echo "Number of cells: $number_of_cells"
echo "Number of ALU: $number_of_ALU"
echo "Number of DFF: $number_of_DFF"
echo "Number of DFFE: $number_of_DFFE"
echo "Number of DFFR: $number_of_DFFR"
echo "Number of DFFRE: $number_of_DFFRE"
echo "Number of GND: $number_of_GND"
echo "Number of IBUF: $number_of_IBUF"
echo "Number of LUT1: $number_of_LUT1"
echo "Number of LUT2: $number_of_LUT2"
echo "Number of LUT3: $number_of_LUT3"
echo "Number of LUT4: $number_of_LUT4"
echo "Number of MUX2_LUT5: $number_of_MUX2_LUT5"
echo "Number of MUX2_LUT6: $number_of_MUX2_LUT6"
echo "Number of MUX2_LUT7: $number_of_MUX2_LUT7"
echo "Number of MUX2_LUT8: $number_of_MUX2_LUT8"
echo "Number of OBUF: $number_of_OBUF"
echo "Number of VCC: $number_of_VCC"
