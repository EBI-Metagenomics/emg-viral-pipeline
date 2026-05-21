#!/usr/bin/env python3

import argparse
import operator
import re
from pathlib import Path

import pandas as pd


def parse_gff(gff_file: str) -> dict:
    """Parse a GFF3 file and return CDS metadata keyed by protein ID.

    :param gff_file: Path to GFF3 file containing CDS features with ID attributes
    :return: Dict mapping protein ID to {contig, start, end, strand}
    """
    cds_info = {}
    with open(gff_file) as fh:
        for line in fh:
            if line.startswith('#'):
                continue
            cols = line.strip().split('\t')
            if len(cols) != 9 or cols[2] != 'CDS':
                continue
            attrs = {}
            for part in cols[8].rstrip(';').split(';'):
                if '=' in part:
                    k, v = part.split('=', 1)
                    attrs[k.strip()] = v.strip()
            protein_id = attrs.get('ID', '').strip()
            if protein_id:
                seqid = cols[0]
                if '|prophage-' in seqid:
                    # Prodigal can use <contigNumber_proteinNumber> like 1_1 
                    # and do not apply _proteinNumber to real contig name
                    if re.fullmatch(r"\d+_\d+", protein_id):
                        # if GFF ID has pattern <contigNumber_proteinNumber>
                        protein_suffix = protein_id.rsplit('_', 1)[-1]
                        protein_id = f"{seqid}_{protein_suffix}"
                cds_info[protein_id] = {
                    'contig': seqid,
                    'start': cols[3],
                    'end': cols[4],
                    'strand': cols[6],
                }
    return cds_info


def extract_annotations(ratio_evalue_file: str, gff_data: dict) -> list:
    """
    Generate annotation list for viral proteins using ViPhOG database results.

    :param ratio_evalue_file: Path to tabular file with ViPhOG hmmscan results
    :param gff_data: Dict from parse_gff() mapping protein ID to CDS coordinates
    :return: List of annotation rows, where each row contains:
             [Contig, CDS_ID, Start, End, Direction, Best_hit, Abs_Evalue_exp, Label]
    """
    ratio_evalue_df = pd.read_csv(ratio_evalue_file, sep="\t")

    annotation_list = []

    for protein_id, info in gff_data.items():
        contig_id = info['contig']
        protein_prop = [protein_id, info['start'], info['end'], info['strand']]

        ratio_lookup_key = protein_id

        if ratio_lookup_key in ratio_evalue_df["query"].values:
            filtered_df = ratio_evalue_df[ratio_evalue_df["query"] == ratio_lookup_key]

            # Handle multiple hits - select best by Abs_Evalue_exp
            if len(filtered_df) > 1:
                best_value_index = max(
                    filtered_df["Abs_Evalue_exp"].items(),
                    key=operator.itemgetter(1),
                )[0]
                hit_data = filtered_df.loc[
                    best_value_index, ["ViPhOG", "Abs_Evalue_exp", "Taxon"]
                ].tolist()
            else:
                hit_data = filtered_df.loc[
                    filtered_df.index[0],
                    ["ViPhOG", "Abs_Evalue_exp", "Taxon"],
                ].tolist()

            protein_prop.extend(hit_data)
        else:
            protein_prop.extend(["No hit", "NA", ""])

        annotation_list.append([contig_id] + protein_prop)

    return annotation_list


def main():
    """Main function to parse arguments and generate viral contig annotations."""
    parser = argparse.ArgumentParser(
        description="Generate tabular file with ViPhOG annotation results for proteins predicted in viral contigs"
    )
    parser.add_argument(
        "-t",
        "--ratio-table",
        dest="ratio_file_table",
        help="Path to ratio_evalue tabular file with ViPhOG hmmscan results",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--outdir",
        dest="output_dir",
        help="Output directory path (default: current working directory)",
        default=".",
    )
    parser.add_argument(
        "-g",
        "--gff",
        dest="gff_file",
        help="GFF3 file with CDS features; protein IDs and coordinates are read from here",
        required=True,
    )

    args = parser.parse_args()

    gff_path = Path(args.gff_file)
    ratio_path = Path(args.ratio_file_table)
    output_dir = Path(args.output_dir)

    if not gff_path.exists():
        raise FileNotFoundError(f"GFF file not found: {args.gff_file}")
    if not ratio_path.exists():
        raise FileNotFoundError(f"Ratio evalue file not found: {args.ratio_file_table}")

    output_dir.mkdir(parents=True, exist_ok=True)

    output_name = gff_path.stem
    csv_output = output_dir / f"{output_name}_annotation.tsv"

    gff_data = parse_gff(str(gff_path))
    annotations = extract_annotations(str(ratio_path), gff_data)

    dataframe = pd.DataFrame(
        annotations,
        columns=[
            "Contig",
            "CDS_ID",
            "Start",
            "End",
            "Direction",
            "Best_hit",
            "Abs_Evalue_exp",
            "Label",
        ],
    )

    dataframe.to_csv(csv_output, sep="\t", index=False)

    if not len(dataframe):
        print("Creating an empty file as no annotations were found")

    print(f"Annotation table saved to: {csv_output}")


if __name__ == "__main__":
    main()
