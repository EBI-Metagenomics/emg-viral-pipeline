#!/usr/bin/env python3

import argparse
from pathlib import Path
import re
from collections import Counter


def _clean(arr):
    """Convert ratio values for missing pieces of the tax into 'unclassified'
    and remove empty entries
    """
    for value in arr:
        if value:
            if re.match('^[+-]?\d(>?\.\d+)?$', value):
                yield 'unclassified'
            else:
                yield value
        else:
            yield 'unclassified'


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="Convert the tabular file with the taxonomic assignment of"
        " viral contigs based on ViPhOG annotations to an OTUs "
        "count table for Krona")
    parser.add_argument("-f", "--files", dest="files", nargs='+',
                        help="List of taxonomic annotation tables generated with script "
                        "contig_taxonomic_assign.py. "
                        "To call -f file1.tsv -f file2.tsv...", required=True)
    parser.add_argument("-o", "--outfile", dest="outfile",
                        help="OTU table count file", required=True)
    args = parser.parse_args()

    taxons = []
    print(args.files)
    for input_table in args.files:
        tsv = Path(input_table)
        if not tsv.is_file():
            raise Exception('Input file missing. Path: ' + input_table)
        with open(tsv, mode='r') as tsv_reader:
            next(tsv_reader)  # header
            # contig_ID	genus subfamily family order
            for line in tsv_reader:
                taxons.append('\t'.join(_clean(line.split('\t')[1:])))
    with open(args.outfile, 'w') as tsv_out:
        for tax, count in Counter(taxons).most_common():
            print(f'{count}\t{tax}', file=tsv_out, end='')