#!/usr/bin/env python3
#
# File   :  fsoc_verilator.py
# Usage  :  Python module to run programs on fsoc.
# -----------------------------------------------------------------------------
# Template adopted from Embench:
#   Python module to run programs on a stm32f4-discovery board

"""
Embench module to run benchmark programs.
This version is suitable for a gdbserver with simulator.
"""

__all__ = [
    'get_target_args',
    'build_benchmark_cmd',
    'decode_results',
]

import argparse
import re
import sys

from embench_core import log

cpu_mhz = 1

def get_target_args(remnant):
    """Parse left over arguments"""
    parser = argparse.ArgumentParser(description='Get target specific args')

    parser.add_argument(
        '--cpu-mhz',
        type=int,
        default=1,
        help='Processor clock speed in MHz'
    )

    parser.add_argument(
        '--chunksize',
        type=int,
        default=8,
        help='Bit width of data path (1, 2, 4, 8)'
    )

    parser.add_argument(
        '--conf',
        type=str,
        default="MIN",
        help='Config of core ("MIN", "INT", "CSR")'
    )

    parser.add_argument(
        '--rftype',
        type=str,
        default="BRAM",
        help='Regfile implementation ("LOGIC", "BRAM", "BRAM_BP")'
    )

    parser.add_argument(
        '--insn_timing',
        action='store_true',
        help='Report insn timing'
    )

    return parser.parse_args(remnant)


def build_benchmark_cmd(bench, args):
    """Construct the command to run the benchmark. "args" is a
       namespace with target specific arguments"""
    
    global cpu_mhz
    cpu_mhz = args.cpu_mhz
    chunksize = args.chunksize
    rftype = args.rftype
    conf = args.conf

    cmd = ["python3", "../../../../script/sim_fsoc.py",
            "--bench", f"{bench}",
            "--chunksize", f"{chunksize}",
            "--conf", f"{conf}",
            "--rftype", f"{rftype}"]
    
    if args.insn_timing:
        cmd.append("--insn_timing")

    return cmd

def decode_results(stdout_str, stderr_str):
    """Extract the results from the output string of the run. Return the
        elapsed time in milliseconds or zero if the run failed."""

    time_re = re.findall('(?<=Bench time: )[0-9]+', stdout_str)

    if not time_re:
        log.debug('Warning: Failed to find timing')
        return 0.0

    return int(time_re[0]) / cpu_mhz / 1000.0

