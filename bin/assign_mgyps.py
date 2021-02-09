#!/usr/bin/env python

import argparse
import csv
import hashlib
import sys
import pathlib

from Bio import SeqIO


# FIXME: maybe we need to import this from the pipeline, to avoid conflicts in the future
def create_digest(seq):
    digest = hashlib.sha256(str(seq).encode("utf-8")).hexdigest()
    return digest


def assign(args):
    mapping = {}
    with open(args.map, "r") as map_tsv:
        for m in csv.DictReader(map_tsv, delimiter="\t"):
            mapping[m["digest"]] = m["mgyp"]

    for fasta_input in args.fasta:
        fpath = pathlib.Path(fasta_input)
        fasta_name = fpath.stem
        fasta_extension = fpath.suffix
        with open(fasta_name + args.suffix + fasta_extension, "w") as fasta_out:
            for record in SeqIO.parse(fpath, "fasta"):
                digest = create_digest(record.seq)
                description = record.description
                mgyp = mapping.get(digest, None)
                if not mgyp:
                    print(
                        f"Missing sequence in mapping for {digest}. File {fasta_input}. Header: {description}",
                        file=sys.stderr,
                    )
                    mgyp = description
                record.description = mgyp
                record.id = mgyp
                SeqIO.write(record, fasta_out, "fasta")


if __name__ == "__main__":
    """Assign MGYP accessions using the provided mapping file."""
    parser = argparse.ArgumentParser(
        description="Assign MGYP accessions using the provided mapping file."
    )
    parser.add_argument(
        "-f", "--fasta", action="append", help="Protein FASTA file", required=True,
    )
    parser.add_argument(
        "-m", "--map", help="Map current names with the renames", required=True
    )
    parser.add_argument(
        "-s",
        "--suffix",
        help="Output FASTA suffix file",
        default="_mgyps",
        required=False,
    )
    args = parser.parse_args()

    assign(args)
