import subprocess
from pathlib import Path
import os
import sys

CHUNKSIZE = sys.argv[1]
CONF = sys.argv[2]
RFTYPE = sys.argv[3]
RVC = sys.argv[4]
BOOT_ADDR = f"{0x80000000}"
PASSFAIL_ADDR = "8c000000"
PRINT_ADDR = "8a000000"

WORKDIR = os.path.abspath(os.path.join(sys.argv[5], "fazyrv/elfs"))
SUMMARYDIR = os.path.abspath(sys.argv[6])
MAKEHEX_SCRIPT = os.path.abspath(f"{__file__}/../../../script/makehex.py")
SIM_EXC = os.path.abspath(f"{__file__}/../../../work_simfsoc/Vfsoc_sim")

TRACE = False


def main():
    run_fusesoc()

    files = ['.'.join(str(file).split(".")[:-1])
             for file in list(Path(f"{WORKDIR}").rglob('*.elf'))
             if str(file).split("/")[-2] == "I" or RVC != "NONE"]

    if len(files) == 0:
        print("No elf files found!")

    convert_elfs(files)
    fail = run_on_dut(files)
    return 1 if fail else 0


def run_on_dut(files):
    fail = False
    log = ""

    for file in files:
        hexfile = file + ".hex"
        cmd = f"{SIM_EXC} +firmware={hexfile} +passfail={PASSFAIL_ADDR} " + \
            f"+print={PRINT_ADDR}" + (" +vcd=trace.fst" if TRACE else "")
        try:
            p = subprocess.run(
                cmd,
                shell=True,
                timeout=10,
                check=True,
                stdout=subprocess.PIPE,
                text=True
            )
            output = p.stdout
            output = '\n'.join([line for line in output.split('\n')
                                if line.startswith("RVCP")])

            if ("FAILED" in output) or ("PASSED" not in output):
                fail = True

            log += output + "\n"
            output = output.replace("PASSED", "\033[32mPASSED\033[0m")
            output = output.replace("FAILED", "\033[31mFAILED\033[0m")
            print(output)
        except subprocess.TimeoutExpired as e:
            print("\033[31mTIMEOUT\033[0m: " + file)
            log += ("TIMEOUT: " + file + "\n")
            fail = True
    
    with open(
        f"{SUMMARYDIR}/logs/{CHUNKSIZE}-{CONF}-{RFTYPE}-{RVC}.log", "w"
    ) as f:
        f.write(log)
    
    with open(
        f"{SUMMARYDIR}/result/{CHUNKSIZE}-{CONF}-{RFTYPE}-{RVC}", "w"
    ) as f:
        f.write("1" if fail else "0")

    return fail


def convert_elfs(files):
    for file in files:
        elffile = file + ".elf"

        # create bin
        binfile = file + ".bin"
        cmd = ["riscv32-unknown-elf-objcopy",
               "-O", "binary", elffile, binfile]
        subprocess.run(cmd, check=True)

        # bin disassembly
        asmfile = file + ".s"
        cmd = ["riscv32-unknown-elf-objdump -m riscv "
               f"--target binary {binfile} -D > {asmfile}"]
        subprocess.run(cmd, shell=True, check=True)

        # create hex file
        hexfile = file + ".hex"
        cmd = ["python3", MAKEHEX_SCRIPT, binfile, hexfile]
        subprocess.run(cmd, check=True)


def run_fusesoc():
    cmd = [
        "fusesoc",
        "run",
        "--target", "verilator_tb",
        "--build",
        "--work-root", "work_simfsoc",
        "fsoc",
        "--MEMSIZE", "8388608",
        "--CHUNKSIZE", CHUNKSIZE,
        "--CONF", CONF,
        "--RFTYPE", RFTYPE,
        "--RVC", RVC,
        "--BOOTADR", BOOT_ADDR,
        "--DEBUG", "1", "--SIM", "1"
    ]
    subprocess.run(cmd)


if __name__ == "__main__":
    exit(main())
