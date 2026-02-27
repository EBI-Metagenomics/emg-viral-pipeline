#!/usr/bin/env python3

import argparse
import operator
import re
from pathlib import Path

from Bio import SeqIO

import pandas as pd


def extract_annotations(protein_file: str, ratio_evalue_file: str) -> list:
    """
    Generate annotation list for viral proteins using ViPhOG database results.

    :param protein_file: Path to FASTA file containing predicted viral proteins
    :param ratio_evalue_file: Path to tabular file with ViPhOG hmmscan results
    :return: List of annotation rows, where each row contains:
             [Contig, CDS_ID, Start, End, Direction, Best_hit, Abs_Evalue_exp, Label]
    :raises: None (returns empty list for invalid/missing files)

    .. note::
        Only processes proteins with '#' delimiter in description (Prodigal format).
        Returns empty list if protein file doesn't exist or contains no proteins.
    """

    ratio_evalue_df = pd.read_csv(ratio_evalue_file, sep="\t")

    # Parse proteins and build annotation list
    annotation_list = []

    for protein in SeqIO.parse(protein_file, "fasta"):
        # Extract contig ID by removing protein number suffix
        contig_id = re.split(r"_\d+$", protein.id)[0]

        # Parse protein properties (Prodigal format: "start_end # direction")
        # Skip if protein description doesn't contain expected format
        protein_prop = protein.description.split(" # ")[:-1]

        # Skip proteins that don't have Prodigal format (e.g., frageneScan proteins)
        if not protein_prop:
            continue

        # Find matching ViPhOG results
        query_id = protein_prop[0]
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
            # No ViPhOG hit found
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
    annotations = extract_annotations(str(prot_path), str(ratio_path))

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
