#!/usr/bin/env python3

import argparse
import csv
import re
from collections import Counter
from pathlib import Path


def clean(lineage_parts, ranks):
    """
    Assigns ranks to annotations. 
    If rank is not presented - add 'undefined rank' and closest defined rank
    for example, Caudoviricetes --> undefined_order_Caudoviricetes --> undefined_family_Caudoviricetes --> Guernseyvirinae --> Jerseyvirus
    """
    converted_tax = []
    last_known_rank = ''
    undefined_count = 0
    if lineage_parts:
        if lineage_parts[0] == '':
            # TODO: fix that bug in assign script
            lineage_parts = lineage_parts[1:]   
        for tax_value, rank in zip(lineage_parts, ranks):
            if tax_value == "" or \
                tax_value == "\n" or \
                re.match(r"^[+-]?\d(>?\.\d+)?$", tax_value):
                if last_known_rank:
                    converted_tax.append(f"undefined_{rank}_{last_known_rank}")
                else:
                    converted_tax.append(f"undefined_{rank}")
                undefined_count += 1
            else:
                converted_tax.append(tax_value.strip())
                last_known_rank = tax_value.strip()
        if len(lineage_parts) == undefined_count:
            return(tuple(["undefined"]))
        # check last values should not end to undefined_
        remove_elements = 0
        for item in reversed(converted_tax):
            if item.startswith('undefined'):
                remove_elements += 1  
            else:
                break
        if remove_elements:
            converted_tax = converted_tax[:-remove_elements]    
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
    for input_table in args.files:
        header = False
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
