#!/usr/bin/env python3
import os
import json
import argparse
from pathlib import Path

def parse_args():
    parser = argparse.ArgumentParser(
        description="Parse implementation results and generate reports"
    )

    parser.add_argument(
        "arch",
        type=str,
        help="Target architecture for the implementation results"
    )

    parser.add_argument(
        "workdir",
        type=Path,
        help="Path to the working directory containing implementation results"
    )

    # Optional argument with a short and long flag
    parser.add_argument(
        "-o", "--output",
        type=Path,
        default=Path("report.json"),
        help="Path to the report file (default: %(default)s)"
    )

    args = parser.parse_args()
    return args


def main():
    args = parse_args()

    if args.arch == "ice40":
        from edalize.icestorm_reporting import IcestormReporting
        data = IcestormReporting.report(args.workdir)
    elif args.arch == "ecp5":
        from edalize.trellis_reporting import TrellisReporting
        data = TrellisReporting.report(args.workdir)
    elif args.arch == "gatemate":
        from edalize.peppercorn_reporting import PeppercornReporting
        data = PeppercornReporting.report(args.workdir)
    elif args.arch == "gowin":
        from edalize.apicula_reporting import ApiculaReporting
        data = ApiculaReporting.report(args.workdir)
    elif args.arch == "xilinx":
        from edalize.vivado_reporting import VivadoReporting
        base = Path(args.workdir)
        runs_dir = next(p for p in base.iterdir() if p.is_dir() and p.name.endswith('.runs'))
        data = VivadoReporting.report(runs_dir / "impl_1")
        resources = list(data["resources"].keys())
        timing = list(data["timing"].keys())

        # convert pandas tables to normal dicts
        for r in resources:
            js = data["resources"][r].to_json(orient="records")
            data["resources"][r] = json.loads(js)
        for t in timing:
            js = data["timing"][t].to_json(orient="records")
            data["timing"][t] = json.loads(js)
    else:
        raise ValueError(f"Unsupported architecture: {args.arch}")
    
    os.makedirs(args.output.parent, exist_ok=True)
    with open(args.output, "w") as f:
        json.dump(data, f, indent=4)

if __name__ == "__main__":
    main()
    

    
    
