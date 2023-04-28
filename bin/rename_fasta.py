#!/usr/bin/env python

import argparse
import csv
import sys
import re
import os


def _parse_name(seq):
    """Parse a fasta header and remove > and new lines.
    If [metadata is True] then parse the prophage metadata from
    the header.
    Current metadata: phage-circular and prophage-<start>:<end>
    """
    if not seq:
        return seq
    clean = seq.replace(">", "").replace("\n", "")
    phage_data = clean.split("|")
    seq_name = phage_data[0]
    phage_circular = "phage-circular" if "phage-circular" in seq else ""

    metadata = []
    if phage_circular:
        metadata.append(phage_circular)

    if len(phage_data) == 1:
        return seq_name.strip(), metadata

    for phage_metadata in phage_data[1:]:
        match = re.search(r"prophage-\d+:\d+", phage_metadata)
        if match:
            metadata.append(match[0])

    return seq_name.strip(), metadata


def rename(args):
    """Rename a multi-fasta fasta entries with <name>.<counter> and store the
    mapping between new and old files in tsv (args.map)
    """
    print("Renaming " + args.input)
    with open(args.input, "r") as fasta_in:
        with open(args.output, "w") as fasta_out, open(args.map, "w") as map_tsv:
            count = 1
            tsv_map = csv.writer(map_tsv, delimiter="\t")
            tsv_map.writerow(["original", "renamed"])
            for line in fasta_in:
                if line.startswith(">"):
                    fasta_out.write(f">{args.prefix}{count}\n")
                    name, _ = _parse_name(line)
                    tsv_map.writerow([name, f"{args.prefix}{count}"])
                    count += 1
                else:
                    fasta_out.write(line)
    print(f"Wrote {count} sequences to {args.output}.")


def restore(args):
    """Restore a multi-fasta fasta using the mapping file.

    VirSorter metadata is preserved.
    """
    if not args.input:
        print("File not provided. Skipping")
        return

    if not os.path.exists(args.input):
        print("File " + args.input + " doesn't exist. Skipping")
        return

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
                    # prophage metada removal
                    original = mapping.get(mod, None)
                    if not original:
                        print(
                            f"Missing sequence in mapping for {mod}. Header: {line}",
                            file=sys.stderr,
                        )
                        original = mod
                    if len(metadata):
                        fasta_out.write(f">{original}|{'|'.join(metadata)}\n")
                    else:
                        fasta_out.write(f">{original}\n")
                else:
                    fasta_out.write(line)


def main():
    """Multi fasta rename and restore."""
    parser = argparse.ArgumentParser(
        description="Rename multi fastas and restore the names tools."
    )
    parser.add_argument(
        "-i", "--input", help="indicate input FASTA file", required=False
    )
    parser.add_argument(
        "-m",
        "--map",
        help="Map current names with the renames",
        type=str,
        default="fasta_map.tsv",
    )
    parser.add_argument(
        "-o", "--output", help="indicate output FASTA file", required=True
    )
    subparser = parser.add_subparsers()

    rename_parser = subparser.add_parser("rename")
    rename_parser.add_argument(
        "--prefix",
        help="string pre fasta count, i.e. default is seq such as seq1, seq2...",
        type=str,
        default="seq",
    )
    rename_parser.set_defaults(func=rename)

    restore_parser = subparser.add_parser("restore")
    restore_parser.set_defaults(func=restore)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
