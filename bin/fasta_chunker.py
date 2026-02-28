#!/usr/bin/env python3

import argparse
import os

from Bio import SeqIO

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Split to chunks")
    parser.add_argument("-i", "--input", dest="input", help="Input fasta file", required=True)
    parser.add_argument("-s", "--size", dest="size", type=int, help="Chunk size")
    parser.add_argument("-f", "--file_format", dest="file_format", required=False,
                        choices=("fasta", "fastq"), default="fasta")

    args = parser.parse_args()
    file_format = args.file_format

    _, file_extension = os.path.splitext(args.input)
    file_extension = file_extension or "." + file_format

    current_nr = 0
    current_seqs = []

    for record in SeqIO.parse(args.input, file_format):
        current_nr += 1
        current_seqs.append(record)
        if len(current_seqs) == args.size:
            file_name = f"{(current_nr - args.size + 1)}_{current_nr}{file_extension}"
            SeqIO.write(current_seqs, file_name, file_format)
            current_seqs = []

    # write any remaining sequences
    if len(current_seqs):
        file_name = f"{(current_nr - len(current_seqs))}_{current_nr}{file_extension}"
        SeqIO.write(current_seqs, file_name, file_format)

    # if there are no seqs then create an empty file
    # this is to prevent the pipeline from breaking.
    if current_nr == 0:
        file_name = "0_0" + file_extension
        open(file_name, "w").close()
