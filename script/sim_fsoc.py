from pathlib import Path 
import argparse
import os

def sim_args(parser):
    parser.add_argument("--bench",
        default=None,
        help="Test case")
    
    parser.add_argument(
        '--chunksize',
        type=int,
        default=None,
        help='Bit width of data path (1, 2, 4, 8)'
    )

    parser.add_argument(
        '--conf',
        type=str,
        default=None,
        help='Config of core ("MIN", "INT", "CSR")'
    )

    parser.add_argument(
        '--rftype',
        type=str,
        default=None,
        help='Regfile implementation ("LOGIC", "BRAM", "BRAM_BP")'
    )

    parser.add_argument(
        '--insn_timing',
        action='store_true',
        help='Report insn timing'
    )


if __name__ == "__main__":

    fazyrv_root = Path(__file__).parent.parent
    cur = os.getcwd()

    parser = argparse.ArgumentParser(description="fsoc Arguments")
    sim_args(parser)
    args = parser.parse_args()

    abs_bench = cur + f"/{args.bench}"

    assert args.chunksize is not None
    assert args.conf is not None
    assert args.rftype is not None

    cmd = ""
    cmd += f"fusesoc library add fazyrv {fazyrv_root}"
    cmd += f" && fusesoc library add fsoc {fazyrv_root}"
    cmd += f" && riscv32-unknown-elf-objcopy -O binary {abs_bench} {abs_bench}.bin"
    cmd += f" && python3 ../../../../script/makehex.py {abs_bench}.bin {abs_bench}.hex"
    cmd += f" && fusesoc run --target=verilator_tb --build --work-root=work_simfsoc fsoc \
--MEMSIZE=131072 --CHUNKSIZE={args.chunksize} --CONF={args.conf} --RFTYPE={args.rftype} --BOOTADR=0 --DEBUG=1 --SIM=1"
    cmd += f" && work_simfsoc/Vfsoc_sim \
+firmware={abs_bench}.hex +embench=result"
    if args.insn_timing:
        cmd += f" +timing={args.bench}.timing"
    cmd += " > sim.log 2>&1"

    if os.system(cmd) == 0:
        with open(f'{cur}/result', 'r') as f:
            print(f.read())
        exit(0)
    
    print("Bench time: 0")
