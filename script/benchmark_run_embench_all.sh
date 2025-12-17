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

prepare && python3 benchmark_speed.py --absolute --target-module fsoc_verilator --timeout 14400 --json-output --chunksize 1 --conf MIN --rftype BRAM && store fsoc_8_MIN_BRAM
cd ..


