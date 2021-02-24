#!/usr/bin/env python3

import argparse
import csv
import re
from collections import Counter
from pathlib import Path


def _clean(arr):
    """Convert ratio values for missing pieces of the tax into "unclassified"
    and remove empty entries.
    Rules:
        - if all the cols are unclassified then remove row.
        - if there is no classification for either genus, subfamily or family then remove row.
        - collapse unclassified values from low to high
            - example: Caudovirales	unclassified	unclassified	unclassified
              should be: Caudovirales
    """
    converted_tax = []
    for tax_value in arr[::-1]:
        if tax_value == "" or \
           tax_value == "\n" or \
           re.match(r"^[+-]?\d(>?\.\d+)?$", tax_value):
            converted_tax.append("unclassified")
        else:
            converted_tax.append(tax_value.strip())
    # rule 1
    if len(converted_tax) == converted_tax.count("unclassified"):
        return tuple(("unclassified",))
    # rule 2 and 3
    result = []
    for i in range(0, len(converted_tax) - 1):
        if not (converted_tax[i] == "unclassified" and
           converted_tax[i + 1] == "unclassified"):
            result.append(converted_tax[i])
    if converted_tax[-1] != "unclassified":
        result.append(converted_tax[-1])
    return tuple(result)


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

    for input_table in args.files:
        tsv = Path(input_table)
        if not tsv.is_file():
            raise Exception("Input file missing. Path: " + input_table)
        with open(tsv, mode="r") as tsv_reader:
            next(tsv_reader)  # header
            # contig_ID	genus subfamily family order
            for line in tsv_reader:
                tax_lineage = line.split("\t")[1:]
                taxons.append(_clean(tax_lineage))

    with open(args.outfile, "w", newline="") as tsv_out:
        tsv_writer = csv.writer(tsv_out, delimiter="\t",
                                quoting=csv.QUOTE_MINIMAL)
        for tax, count in Counter(taxons).most_common():
            tsv_writer.writerow((count, *tax))
