#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path

_table_headers = [
    "target name",
    "target accession",
    "tlen",
    "query name",
    "query accession",
    "qlen",
    "full sequence E-value",
    "full sequence score",
    "full sequence bias",
    "#",
    "of",
    "c-Evalue",
    "i-Evalue",
    "domain score",
    "domain bias",
    "hmm coord from",
    "hmm coord to",
    "ali coord from",
    "ali coord to",
    "env coord from",
    "env coord to",
    "acc",
    "description of target"
]

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Format hmmscan domain hits table.")
    parser.add_argument("-t", dest="input_table",
                        help="hmmscan domain hits table")
    parser.add_argument("-o", "--outname",
                        dest="outfile_name", help="Output table name")
    args = parser.parse_args()

    # hmmscan table format specified in http://eddylab.org/software/hmmer/Userguide.pdf
    # basically:
    #   The domain table has 22 whitespace-delimited fields
    #   followed by a free text target sequence description, as follows
    domain_table = Path(args.input_table)
    if not domain_table.is_file():
        raise Exception(
            "Input domain hits table missing. Path: " + args.input_table)

    with open(args.outfile_name + ".tsv", "w", newline="") as out_table:
        tsv_writer = csv.writer(out_table, delimiter="\t",
                                quoting=csv.QUOTE_MINIMAL)
        tsv_writer.writerow(_table_headers)
        with open(domain_table, mode="r") as dt_reader:
            for line in dt_reader:
                if line.startswith("#"):
                    continue
                # the last column has free text, so get it by itself to
                # properly espace it
                cols = line.split()
                data = cols[:22]
                description = " ".join(cols[22:])
                tsv_writer.writerow(data + [description])
