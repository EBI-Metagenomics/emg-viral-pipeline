#!/usr/bin/env python3

import argparse
import os
from pathlib import Path

from Bio import SeqIO


def _filter_and_rename(iterator, threshold, run_id):
    counter = 1
    for record in iterator:
        if len(record) >= threshold:
            record.description = run_id + "_" + str(counter)
            counter += 1
            yield record


def filter_contigs(contig_file, length, out_dir, run_id):
    """Filter the contigs by length."""
    threshold = length * 1000
    seq_records = SeqIO.parse(contig_file, "fasta")

    if out_dir == ".":
        out_dir = os.getcwd()

    out_name = Path(contig_file).stem + "_filt" + str(int(threshold)) + "bp.fasta"

    final_records = ()
    if run_id is None:
        final_records = (
            record for record in seq_records if len(record.seq) >= threshold
        )
    else:
        final_records = _filter_and_rename(seq_records, threshold, run_id)

    SeqIO.write(final_records, os.path.join(out_dir, out_name), "fasta")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract sequences at least X kb long")
    parser.add_argument(
        "-f",
        dest="fasta_file",
        help="Relative or absolute path to input fasta file",
        required=True,
    )
    parser.add_argument(
        "-l",
        dest="length",
        help="Length threshold in kb of selected sequences (default: 5kb)",
        type=float,
        default="5.0",
    )
    parser.add_argument(
        "-o",
        dest="outdir",
        help="Relative or absolute path to directory where you "
        "want to store output (default: cwd)",
        default=".",
    )
    parser.add_argument(
        "-i",
        dest="ident",
        help="Dataset identifier or accession number. Should only "
        " be introduced if you want to add it to each sequence header, along with a "
        "sequential number",
        default=None,
    )

    args = parser.parse_args()

    filter_contigs(args.fasta_file, args.length, args.outdir, args.ident)
