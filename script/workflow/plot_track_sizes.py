import os
import sys
import glob
import re
from ascii_graph import Pyasciigraph
import collections
import collections.abc
collections.Iterable = collections.abc.Iterable
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

def extract_ints_after_regex(file_path, regex_pattern):
    result_list = []
    try:
        with open(file_path, 'r') as file:
            for line in file:
                match = re.search(regex_pattern, line)
                if match:
                    matched_value = line[match.end():].strip()
                    result_list.append(int(matched_value))

    except FileNotFoundError:
        print(f"Error extracting after {regex_pattern} in {file_path}")
    return result_list

def get_ascii_plot(folder, file_prefix, plot_title, commit):
    file_paths = glob.glob(f"{folder}/{file_prefix}*")

    lables = []
    luts = []

    for f in file_paths:
        lables.append(os.path.basename(f).split(file_prefix)[1])
        luts.append(extract_ints_after_regex(f, "Number of LUT4:")[0])
    luts, lables = zip(*sorted(zip(luts, lables)))

    txt = ""

    graph = Pyasciigraph(
        separator_length=2,
        titlebar='-',
        graphsymbol='*'
        )
    
    for line in  graph.graph(f'{plot_title} (latest update: {commit})', list(zip(lables, luts))):
        txt += line + "\n"
    return txt

def get_vect_plot(folder_core, folder_soc, file_prefix, commit, save_to):
    fig, axs = plt.subplots(figsize=(8, 2), ncols=2, sharey=True)
    fig.subplots_adjust(left=0.2, right=0.99, bottom=0.2, wspace=0.05)

    # Core
    lables = []
    luts = []

    for f in glob.glob(f"{folder_core}/{file_prefix}*"):
        lables.append(os.path.basename(f).split(file_prefix)[1])
        luts.append(extract_ints_after_regex(f, "Number of LUT4:")[0])
    lables, luts = zip(*sorted(zip(lables, luts), reverse=True))

    axs[0].barh(lables, luts, color='dimgray')
    axs[0].set_title(f"FazyRV, iCE40 (latest update: {commit})", fontsize=10)
    axs[0].set_xlabel("#LUT4", labelpad=0)
    axs[0].grid(True, which='both', axis='x', linestyle='--', linewidth=1)
    axs[0].xaxis.set_major_locator(ticker.MultipleLocator(100))
    axs[0].xaxis.set_minor_locator(ticker.MultipleLocator(50))

    # SoC
    lables = []
    luts = []

    for f in glob.glob(f"{folder_soc}/{file_prefix}*"):
        lables.append(os.path.basename(f).split(file_prefix)[1])
        luts.append(extract_ints_after_regex(f, "Number of LUT4:")[0])

    axs[1].barh(lables, luts, color='dimgray')
    axs[1].set_title(f"fsoc, iCE40 (latest update: {commit})", fontsize=10)
    axs[1].set_xlabel("#LUT4", labelpad=0)
    axs[1].grid(True, which='both', axis='x', linestyle='--', linewidth=1)
    axs[1].xaxis.set_major_locator(ticker.MultipleLocator(100))
    axs[1].xaxis.set_minor_locator(ticker.MultipleLocator(50))

    if save_to is not None:
        fig.savefig(save_to)

if __name__ == "__main__":
    if len(sys.argv) != 6:
        print("Usage: python plot_track_sizes.py <summary_folder_core> <summary_folder_soc> <plot_svg> <plot_ascii> <commit>")
        sys.exit(1)

    folder_core = sys.argv[1]
    folder_soc = sys.argv[2]
    plot_svg = sys.argv[3]
    plot_ascii = sys.argv[4]
    commit = sys.argv[5]
    file_prefix = f"summary_yosys_ice40-"

    if not os.path.exists(folder_core) or not os.path.exists(folder_soc):
        print("Error: One or both of the specified folders do not exist.")
        sys.exit(1)

    txt = get_ascii_plot(folder_core, file_prefix, "FazyRV, iCE40 Number of LUT-4", commit)
    txt += get_ascii_plot(folder_soc, file_prefix, "fsoc, iCE40 Number of LUT-4", commit)
    print(txt)

    with open(plot_ascii, 'a') as f:
        f.write(txt)

    get_vect_plot(folder_core, folder_soc, file_prefix, commit, plot_svg)
