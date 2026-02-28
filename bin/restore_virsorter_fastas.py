#!/usr/bin/env python

import argparse
import csv
import os
import re
import sys


def _parse_name(seq):
    """Parse a fasta header and remove > and new lines.
    From a contig name:
    >VirSorter_<renamed>-metadata returns
    renamed, metadata
    Note: this assumes the there are no dashes (-) in renamed
    """
    if not seq:
        return seq

    clean = seq.replace(">", "").replace("\n", "").replace("VIRSorter_", "")
    contig_name, *metadata = clean.split("-")

    return contig_name, "-".join(metadata)


def restore(args):
    """Restore a multi-fasta fasta using the mapping file."""

    print("Restoring " + args.input)

    mapping = {}
    with open(args.map, "r") as map_tsv:
        for m in csv.DictReader(map_tsv, delimiter="\t"):
            mapping[m["renamed"]] = m["original"]

    with open(args.input, "r") as fasta_in:
        with open(args.output, "w") as fasta_out:
            for line in fasta_in:
                if line.startswith(">"):
                    mod, metadata = _parse_name(line)
                    original = mapping.get(mod, None)
                    if not original:
                        print(
                            f"Missing sequence in mapping for {mod}. Header: {line}",
                            file=sys.stderr,
                        )
                        original = mod
                    fasta_out.write(f">VirSorter_{original}-{metadata}\n")
                else:
                    fasta_out.write(line)


def main():
    parser = argparse.ArgumentParser(
        description="VirSorter fasta contigs renamer, reverts the renaming of virify on virsorter results"
    )
    parser.add_argument(
        "-i", "--input", help="indicate input FASTA file", required=True
    )
    parser.add_argument(
        "-m",
        "--map",
        help="Map current names with the renames (generated with fasta_rename)",
        required=True,
    )
    parser.add_argument(
        "-o", "--output", help="indicate output FASTA file", required=True
    )

    args = parser.parse_args()
    restore(args)


if __name__ == "__main__":
    main()
