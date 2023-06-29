#!/bin/

import sqlite3
import argparse
import csv


def main(ncbi_db, virify_vphmms):
    """This script will remove all the NCBI taxons that are not present in 
    the additional_data_vpHMMs_v3 file from the ete3 ncbi taxonomy file.
    """
    tax_ids = set()
    with open(virify_vphmms, "r") as fh, sqlite3.connect(ncbi_db) as conn:
        reader = csv.reader(fh, delimiter="\t")
        next(reader)
        for _, taxonomy, _, _, _ in reader:
            result = conn.execute(
                "SELECT taxid, track FROM species WHERE spname = ?", (taxonomy,)
            )
            db_row = result.fetchone()
            if db_row is None:
                continue
            row_tax_ids = [db_row[0]]
            row_tax_ids.extend([int(x) for x in db_row[1].split(",")])
            [tax_ids.add(tid) for tid in row_tax_ids]

        # Run the delete statements now
        placeholder = ", ".join(["?"] * len(tax_ids))
        species_delete = conn.execute(
            f"DELETE FROM species WHERE taxid NOT IN ({placeholder})",
            list(tax_ids),
        )
        conn.commit()
        print(f"Number of species deleted {species_delete.rowcount}")
        merge_delete = conn.execute(
            "DELETE FROM merged WHERE taxid_old NOT IN (select taxid from species) AND taxid_new NOT IN (select taxid from species)"
        )
        conn.commit()
        print(f"Number of merged deleted {merge_delete.rowcount}")
        conn.execute("VACUUM")
        conn.commit()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-n", "--ncbi_sqlite", help="ETE3 NCBI taxonomy sqlite.", required=True
    )
    parser.add_argument(
        "-v", "--virify_vphmms", help="additional_data_vpHMMs_v3.csv", required=True
    )
    args = parser.parse_args()

    main(args.ncbi_sqlite, args.virify_vphmms)
