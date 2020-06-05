#!/usr/bin/env python3

import argparse
import csv
import sys


if __name__ == "__main__":
    """Combine the filtered blast results with meta information from the IMG/VR database.
    """
    parser = argparse.ArgumentParser(
        description="Combine the filtered blast results with meta information "
        "from the IMG/VR database.")
    parser.add_argument("-f", "--filtered",
                        help="Filtered blast hits", required=True)
    parser.add_argument("-d", "--db",
                        help="Path to IMG_VR_2018-07-01_4/IMGVR_all_Sequence_information.tsv",
                        required=True)
    parser.add_argument("-o", "--outfile", dest="outfile",
                        help="TSV output",
                        default="imgvd_hits_metadata.tsv")
    args = parser.parse_args()

    # ignore empty files
    if "empty" in args.filtered:
        print("Empty file, ignoring and creating empty tsv")
        open(args.outfile, "w").close()
        exit(0)

    db = {}
    db_headers = []
    with open(args.db, "r") as db_file:
        reader = csv.reader(db_file, delimiter="\t")
        db_headers = next(reader)
        # first column "UViG"
        db = {row[0]: row for row in reader}

    print(f"Loaded {len(db)} entries from the db tsv file")

    with open(args.filtered, "r") as filtered_file, \
         open(args.outfile, "w") as out_file:

        out_writer = csv.writer(out_file, delimiter="\t")
        filtered_reader = csv.reader(filtered_file, delimiter="\t")

        f_headers = next(filtered_reader)
        out_writer.writerow([*f_headers, *db_headers])

        for hit_data in filtered_reader:
            hit_id = hit_data[1].replace("REF:", "")
            meta_info = db.get(hit_id, None)
            if meta_info is None:
                print("Missing entry from db tsv.", file=sys.stderr)
            else:
                out_writer.writerow([*hit_data, *meta_info])

    print("Completed")
