#!/usr/bin/env python3
import os
import json
import argparse
from pathlib import Path
from py_markdown_table.markdown_table import markdown_table

def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate summary from parsed reports."
    )

    parser.add_argument(
        "reportdir",
        type=Path,
        help="Path to the directory containing parsed reports"
    )

    # Optional argument with a short and long flag
    parser.add_argument(
        "-o", "--output",
        type=Path,
        default=Path("summary.md"),
        help="Path to the summary file (default: %(default)s)"
    )

    args = parser.parse_args()
    return args

def read(root_dir: str | Path) -> dict[str, dict[str, object]]:
    grouped: dict[str, dict[str, object]] = {}
    json_files = sorted(root_dir.rglob("*.json"), key=lambda p: p.name.lower())

    for path in json_files:
        stem = path.stem
        if "-" not in stem:
            continue

        first, second = stem.split("-", 1)

        with path.open("r", encoding="utf-8") as f:
            try:
                content = json.load(f)
            except json.JSONDecodeError as e:
                raise RuntimeError(f"Invalid JSON in {path}: {e}") from e

        grouped.setdefault(first, []).append({'Config': second} | content['summary'])

    return grouped

def summarize(data: dict[str, dict[str, object]]) -> str:
    str = "# Summary Report\n\n"
    for arch, entries in data.items():
        str += f"## {arch}\n\n"
        str += markdown_table(entries).set_params(row_sep = 'markdown', quote = False).get_markdown()
        str += "\n\n"
    return str
    
def main():
    args = parse_args()
    data = read(args.reportdir)
    s = summarize(data)
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(s)


if __name__ == "__main__":
    main()

