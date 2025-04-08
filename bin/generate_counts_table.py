#!/usr/bin/env python3

import argparse
import csv
import re
from collections import Counter
from pathlib import Path


def clean(arr, ranks):
    """
    Assigns ranks to annotations. 
    If rank is not presented - add 'undefined rank' and closest defined rank
    for example, Caudoviricetes --> Undefined Caudoviricetes (Order) --> Undefined Caudoviricetes (Family) --> Guernseyvirinae --> Jerseyvirus
    """
    converted_tax = []
    last_known_rank = ''
    if len(arr) > 0:
        if arr[0] == '':
            # TODO: fix that bug in assign script
            arr = arr[1:]   
        for iter in range(len(arr)):
            tax_value = arr[iter]
            rank = ranks[iter]
            if tax_value == "" or \
                tax_value == "\n" or \
                re.match(r"^[+-]?\d(>?\.\d+)?$", tax_value):
                converted_tax.append(f"undefined_{rank}_{last_known_rank}")
            else:
                converted_tax.append(tax_value.strip())
                last_known_rank = tax_value.strip()
    else:
        converted_tax = ["undefined"]
    return tuple(converted_tax)


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="Convert the tabular file with the taxonomic assignment of"
        " viral contigs based on ViPhOG annotations to an OTUs "
        "count table for Krona")
    parser.add_argument("-f", "--files", dest="files", nargs="+",
                        help="List of taxonomic annotation tables generated with script "
                        "contig_taxonomic_assign.py. "
                        "To call -f file1.tsv -f file2.tsv...", required=True)
    parser.add_argument("-o", "--outfile", dest="outfile",
                        help="OTU table count file", required=True)
    args = parser.parse_args()

    taxons = []
    header = False
    for input_table in args.files:
        tsv = Path(input_table)
        if not tsv.is_file():
            raise Exception("Input file missing. Path: " + input_table)
        with open(tsv, mode="r") as tsv_reader:
            for line in tsv_reader:
                if not header:
                    header = line.strip().split('\t')
                else:
                    tax_lineage = line.strip().split("\t")[1:]
                    taxons.append(clean(tax_lineage, header[1:]))

    with open(args.outfile, "w", newline="") as tsv_out:
        tsv_writer = csv.writer(tsv_out, delimiter="\t",
                                quoting=csv.QUOTE_MINIMAL)
        for tax, count in Counter(taxons).most_common():
            tsv_writer.writerow((count, *tax))
