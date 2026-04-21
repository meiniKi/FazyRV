import os
import re
import sys
import glob
import json
from ascii_graph import Pyasciigraph
import collections
import collections.abc
collections.Iterable = collections.abc.Iterable
import argparse
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate summary from parsed reports."
    )
    
    parser.add_argument(
        "arch",
        type=str,
        help="Target architecture (e.g., 'ice40' or 'ecp5')"
    )

    parser.add_argument(
        "report_soc_dir",
        type=Path,
        help="Path to the directory containing the soc summary reports"
    )
    
    parser.add_argument(
        "--commit_hash",
        type=str,
        default="n/a",
        help="Commit hash for the current report"
    )

    parser.add_argument(
        "--svg",
        type=Path,
        default=Path("plot.svg"),
        help="Path to write the svg plot (default: %(default)s)"
    )
    
    parser.add_argument(
        "--ascii",
        type=Path,
        default=Path("plot.ascii"),
        help="Path to write the ascii plot (default: %(default)s)"
    )

    args = parser.parse_args()
    return args

def from_json_summary(file_path, element):
    with open(file_path, 'r') as file:
        d = json.load(file)
    return float(d['summary'][element])

def get_ascii_plot(folder, file_prefix, plot_title, element, commit):
    file_paths = glob.glob(f"{folder}/{file_prefix}-*")

    lables = []
    data = []
    for f in file_paths:
        lables.append('-'.join(Path(f).stem.split("-")[1:]))
        data.append(from_json_summary(f, element))

    data, lables = zip(*sorted(zip(data, lables)))
    txt = ""

    graph = Pyasciigraph(
        separator_length=2,
        titlebar='-',
        graphsymbol='*'
        )
    
    for line in  graph.graph(f'{plot_title} (latest update: {commit})', list(zip(lables, data))):
        txt += line + "\n"
    return txt

def get_vect_plot(folder, file_prefix, commit, save_to):
    fig, axs = plt.subplots(figsize=(7, 2), ncols=2, sharey=True, gridspec_kw={'width_ratios': [1.5, 1]})
    fig.subplots_adjust(left=0.28, right=0.99, bottom=0.2, wspace=0.05)

    # LUTs
    #
    lables = []
    data = []

    for f in glob.glob(f"{folder}/{file_prefix}-*"):
        lables.append('-'.join(Path(f).stem.split("-")[1:]))
        data.append(from_json_summary(f, "lut"))

    lables, data = zip(*sorted(zip(lables, data), reverse=True))
    
    fig.suptitle(f"fsoc: FazyRV minimal reference SoC, iCE40 (latest update: {commit})", fontsize=10)

    axs[0].barh(lables, data, color='dimgray')
    axs[0].set_xlabel("#LUT4", labelpad=0)
    axs[0].grid(True, which='both', axis='x', linestyle='--', linewidth=1)
    axs[0].xaxis.set_major_locator(ticker.MultipleLocator(100))
    axs[0].xaxis.set_minor_locator(ticker.MultipleLocator(50))
    
    # fmax
    #
    lables = []
    data = []

    for f in glob.glob(f"{folder}/{file_prefix}*"):
        lables.append('-'.join(Path(f).stem.split("-")[1:]))
        data.append(from_json_summary(f, "fmax"))

    axs[1].barh(lables, data, color='dimgray')
    axs[1].set_xlabel("fmax / MHz", labelpad=0)
    axs[1].grid(True, which='both', axis='x', linestyle='--', linewidth=1)
    axs[1].xaxis.set_major_locator(ticker.MultipleLocator(20))
    axs[1].xaxis.set_minor_locator(ticker.MultipleLocator(10))
    
    if save_to is not None:
        fig.savefig(save_to)


def main():
    args = parse_args()

    if not os.path.exists(args.report_soc_dir):
        print("Error: Folder does not exist.")
        sys.exit(1)

    txt = get_ascii_plot(folder=args.report_soc_dir,
                        file_prefix=args.arch,
                        plot_title="fsoc: FazyRV minimal reference SoC, iCE40 Number of LUTs",
                        element="lut",
                        commit=args.commit_hash)

    txt += get_ascii_plot(folder=args.report_soc_dir,
                        file_prefix=args.arch,
                        plot_title="fsoc: FazyRV minimal reference SoC, iCE40 Number of fmax",
                        element="fmax",
                        commit=args.commit_hash)

    with open(args.ascii, 'w') as f:
        f.write(txt)

    get_vect_plot(folder=args.report_soc_dir,
                  file_prefix=args.arch,
                  commit=args.commit_hash, save_to=args.svg)


if __name__ == "__main__":
    main()
