#!/bin/bash

prepare() {
    rm -rf bd &&
    rm -rf logs &&
    python3 build_all.py --arch riscv32 --chip generic --board verilator
}

store() {
    mkdir -p summary/$1
    cp logs/* summary/$1/
    find "bd/src" -name '*.timing' -exec sh -c 'cp {} "$1" && gzip -f "$1/$(basename {})"' _ summary/$1 \;
}


cd embench-iot
mkdir -p summary

# memdly1 -> 0
prepare && python3 benchmark_speed.py --absolute --target-module fsoc_verilator --timeout 14400 --json-output --chunksize 1 --conf MIN --rftype BRAM && store fsoc_8_MIN_BRAM &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 2 --conf MIN --rftype BRAM && store fsoc_2_MIN_BRAM &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 4 --conf MIN --rftype BRAM && store fsoc_4_MIN_BRAM &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 8 --conf MIN --rftype BRAM && store fsoc_8_MIN_BRAM &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 1 --conf MIN --rftype BRAM_BP && store fsoc_1_MIN_BRAM_BP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 2 --conf MIN --rftype BRAM_BP && store fsoc_2_MIN_BRAM_BP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 4 --conf MIN --rftype BRAM_BP && store fsoc_4_MIN_BRAM_BP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 8 --conf MIN --rftype BRAM_BP && store fsoc_8_MIN_BRAM_BP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 1 --conf MIN --rftype BRAM_DP && store fsoc_1_MIN_BRAM_DP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 2 --conf MIN --rftype BRAM_DP && store fsoc_2_MIN_BRAM_DP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 4 --conf MIN --rftype BRAM_DP && store fsoc_4_MIN_BRAM_DP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 8 --conf MIN --rftype BRAM_DP && store fsoc_8_MIN_BRAM_DP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 1 --conf MIN --rftype BRAM_DP_BP && store fsoc_1_MIN_BRAM_DP_BP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 2 --conf MIN --rftype BRAM_DP_BP && store fsoc_2_MIN_BRAM_DP_BP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 4 --conf MIN --rftype BRAM_DP_BP && store fsoc_4_MIN_BRAM_DP_BP &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 8 --conf MIN --rftype BRAM_DP_BP && store fsoc_8_MIN_BRAM_DP_BP &&
#

#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 2 --conf MIN --rftype LOGIC && store fsoc_2_MIN_LOGIC &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 4 --conf MIN --rftype LOGIC && store fsoc_4_MIN_LOGIC &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 8 --conf MIN --rftype LOGIC && store fsoc_8_MIN_LOGIC &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 1 --conf MIN --rftype LOGIC && store fsoc_1_MIN_LOGIC &&

# memdly1 -> 1
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 1 --conf MIN --rftype BRAM_DP_BP && store fsoc_1_MIN_BRAM_DP_BP_MEMDLY1 &&
#prepare && python3 benchmark_speed.py --absolute --sim-parallel --target-module fsoc_verilator --timeout 14400 --insn_timing --json-output --chunksize 4 --conf MIN --rftype BRAM_DP_BP && store fsoc_4_MIN_BRAM_DP_BP_MEMDLY1

#prepare && python3 benchmark_speed.py --absolute --target-module fsoc_verilator --timeout 3600 --json-output --chunksize 1 --conf MIN --rftype BRAM_DP_BP && store fsoc_1_MIN_BRAM_DP_BP
cd ..


