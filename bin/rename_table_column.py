#!/usr/bin/env python

import argparse
import csv


def main(input, output, col=0):
    """Restore a tsv/csv file"""
    print("Restoring " + args.input)

    mapping = {}
    with open(args.map, "r") as map_tsv:
        for m in csv.DictReader(map_tsv, delimiter="\t"):
            mapping[m["renamed"]] = m["original"]

    with open(args.input, "r") as table_in, open(args.output, "w") as table_out:
        delimiter = ""
        if ".csv" in args.input:
            delimiter = ","
        elif ".tsv" in args.input:
            delimiter = "\t"
        else:
            raise Exception("Can't guess the table delimiter for + " + args.input)

        csv_input = csv.reader(table_in, delimiter=delimiter)
        csv_writer = csv.writer(table_out, delimiter=delimiter)

        header = next(csv_input)  # skip header
        csv_writer.writerow(header)

        for line in csv_input:
            col_value = line[col]
            original = mapping.get(col_value, None)
            if not original:
                print(
                    f"Missing sequence in mapping for {mod}. Header: {line}",
                    file=sys.stderr,
                )
                original = mod
            line[col] = original
            csv_writer.writerow(line)


if __name__ == "__main__":
    """Table column rename based on a mapping file."""
    parser = argparse.ArgumentParser(
        description="Table column rename based on a mapping file."
    )
    parser.add_argument(
        "-i", "--input", help="indicate input FASTA file", required=True
    )
    parser.add_argument(
        "-m", "--map", help="Map current names with the renames", required=True
    )
    parser.add_argument(
        "-o", "--output", help="indicate output table file", required=True
    )

    args = parser.parse_args()
    main(args.input, args.output)
