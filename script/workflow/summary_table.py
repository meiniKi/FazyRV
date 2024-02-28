import os
import sys
from pathlib import Path

def extract_after_key_value(filename, keyword):
    with open(filename, 'r') as file:
        for line in file:
            if keyword in line:
                return line.strip()
            
    raise ValueError(f"Cannot extract >{keyword}< from file {filename}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python summary_table.py <summary_folder> <arch>")
        sys.exit(1)

    folder = Path(sys.argv[1])
    arch = sys.argv[2]

    file_prefix = f"summary_fmax_"

    if not os.path.exists(folder):
        print("Error: One or both of the specified folders do not exist.")
        sys.exit(1)

    file_names = []
    for root, dirs, files in os.walk(folder):
        for file in files:
            file_path = os.path.join(root, file)
            file_names.append(file_path)

    unique_configs = set()
    for f in list(folder.glob(f"{file_prefix}{arch}*")):
        unique_configs.add(f.stem.replace(f"{file_prefix}", ""))

    txt = ""
    keyw = None

    for conf in sorted(unique_configs):
        if "ice40" in conf:
            keyw = ("LUT4", "cells", "fmax", "ICESTORM_LC")
        elif "ecp5" in conf:
            keyw = (None, None, "fmax", "TRELLIS_COMB")
        elif "gatemate" in conf:
            keyw = (None, None, "fmax", "CPEs")
        elif "gowin" in conf:
            keyw = (None, None, "fmax", "SLICE")
        elif "xilinx" in conf:
            keyw = (None, None, "fmax", "Slice")
        else:
            raise ValueError()

        f_fmax = folder / f"summary_fmax_{conf}"
        f_util = folder / f"summary_util_{conf}"
        f_yosys = folder / f"summary_yosys_{conf}"

        txt += "{}:\t".format(conf)
        if keyw[0] is not None:
            txt += "  {}\t".format(extract_after_key_value(f_yosys, keyw[0]).strip("Number of ").replace(":", ""))
        if keyw[1] is not None:
            txt += "  {}\t".format(extract_after_key_value(f_yosys, keyw[1]).strip("Number of ").replace(":", ""))
        if keyw[2] is not None:
            txt += "  {}\t".format(extract_after_key_value(f_fmax, keyw[2]).replace(":", ""))
        if keyw[3] is not None:
            txt += "  {}\t".format(extract_after_key_value(f_util, keyw[3]).replace(":", ""))
        txt += "\n"

    print (txt)



