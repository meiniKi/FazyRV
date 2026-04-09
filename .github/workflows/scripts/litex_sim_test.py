import argparse
import pexpect
import sys

def parse_args(argv):
    parser = argparse.ArgumentParser(description="FazyRV parameters.")
    parser.add_argument("chunksize", type=int, help="Chunk size", choices=[1, 2, 4, 8])
    parser.add_argument("conf",      type=str, help="Config", choices=["MIN", "INT", "CSR"])
    parser.add_argument("rftype",    type=str, help="Register file type.", choices=["LOGIC", "BRAM", "BRAM_BP", "BRAM_DP", "BRAM_DP_BP"])
    #parser.add_argument("rvc",       type=str, help="RVC support.", choices=["NONE", "COMB", "REGS"])
    return parser.parse_args(argv)

def main(argv=None):
    args = parse_args(argv)
    
    cmd = [f"litex_sim",
        f"--cpu-type=fazyrv",
        f"--cpu-chunksize={args.chunksize}",
        f"--cpu-conf={args.conf}",
        f"--cpu-rftype={args.rftype}",
        #f"--cpu-rvc={args.rvc}"
    ]
    
    cmd = " ".join(cmd)
    patterns = [r"No boot medium found"]
    
    child = pexpect.spawn(cmd, encoding="utf-8", timeout=60)
    child.logfile = sys.stdout

    try:
        child.expect(patterns)
        child.terminate(force=False)
        try:
            child.wait()
        except Exception:
            pass
        sys.exit(0)
    except pexpect.TIMEOUT:
        print("Timeout waiting for pattern", file=sys.stderr)
        child.terminate(force=True)
        child.wait()
        sys.exit(1)
    except pexpect.EOF:
        print("Exited without pattern", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    sys.exit(main())