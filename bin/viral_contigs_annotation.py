#!/usr/bin/env python3

import argparse
import operator
import re
from pathlib import Path

from Bio import SeqIO

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
                cds_info[protein_id] = {
                    'contig': cols[0],
                    'start': cols[3],
                    'end': cols[4],
                    'strand': cols[6],
                }
    return cds_info


def extract_annotations(protein_file: str, ratio_evalue_file: str, gff_data: dict = None) -> list:
    """
    Generate annotation list for viral proteins using ViPhOG database results.

    :param protein_file: Path to FASTA file containing predicted viral proteins
    :param ratio_evalue_file: Path to tabular file with ViPhOG hmmscan results
    :param gff_data: Optional dict from parse_gff(); when provided, CDS coordinates
                     are taken from the GFF instead of the protein description.
    :return: List of annotation rows, where each row contains:
             [Contig, CDS_ID, Start, End, Direction, Best_hit, Abs_Evalue_exp, Label]
    """
    ratio_evalue_df = pd.read_csv(ratio_evalue_file, sep="\t")

    annotation_list = []

    for protein in SeqIO.parse(protein_file, "fasta"):
        if gff_data is not None and protein.id in gff_data:
            info = gff_data[protein.id]
            contig_id = info['contig']
            protein_prop = [protein.id, info['start'], info['end'], info['strand']]
            query_id = protein.id
        else:
            # Fallback: extract coordinates from Prodigal-format description
            contig_id = re.split(r"_\d+$", protein.id)[0]
            protein_prop = protein.description.split(" # ")[:-1]
            if protein_prop:
                query_id = protein_prop[0]
            else:
                query_id = protein.id
                protein_prop = [protein.id, "NA", "NA", "NA"]

        # Find matching ViPhOG results
        if query_id in ratio_evalue_df["query"].values:
            filtered_df = ratio_evalue_df[ratio_evalue_df["query"] == query_id]

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
        "-p",
        "--proteins",
        dest="proteins_fasta",
        help="Path to protein FASTA file of predicted viral contigs",
        required=True,
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
        help="GFF3 file with CDS features; when provided, coordinates are read from "
             "the GFF instead of the protein description",
        required=False,
        default=None,
    )

    args = parser.parse_args()

    # Validate input files
    prot_path = Path(args.proteins_fasta)
    ratio_path = Path(args.ratio_file_table)
    output_dir = Path(args.output_dir)

    if not prot_path.exists():
        raise FileNotFoundError(f"Protein file not found: {args.proteins_fasta}")
    if not ratio_path.exists():
        raise FileNotFoundError(f"Ratio evalue file not found: {args.ratio_file_table}")

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Generate output filename
    output_name = prot_path.stem
    csv_output = output_dir / f"{output_name}_annotation.tsv"

    # Process and save results
    gff_data = parse_gff(args.gff_file) if args.gff_file else None
    annotations = extract_annotations(str(prot_path), str(ratio_path), gff_data)

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
