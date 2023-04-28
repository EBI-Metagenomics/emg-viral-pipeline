#!/usr/bin/env python3

import logging
import argparse
import sys
import gzip
import csv

from parse_viral_pred import Record

from Bio import SeqIO

logging.basicConfig(level=logging.INFO)


def get_ena_contig_mapping(ena_contig_file):
    ena_mapping = {}
    with gzip.open(ena_contig_file, "rt") as ena_contigs:
        for record in SeqIO.parse(ena_contigs, "fasta"):
            ena_name = record.id
            contig_name = record.description.split(" ")[1]
            ena_mapping[contig_name] = ena_name
    return ena_mapping


def aggregate_annotations(virify_annotation_files):
    """Aggregate all the virify annotations into a single data structure for
    easier handling when writing the GFF file.

    :param virify_annotation_files: The virify 08-final/*.annotations tsv files
    :return: 2 dicts, one with the viral_sequences elements, and one for the cds
    """
    # structure of the viral_sequences
    # {
    #   contig_name: [
    #       "phage_circular" or "prophage" or "phage_linear",
    #       ...
    #   ]
    # }
    viral_sequences = {}

    # structure of the cds_annotations
    # {
    #   contig_name: [
    #       cds_id,
    #       start,
    #       end,
    #       direction,
    #       viphog_annotation,
    #   ]
    # }
    cds_annotations = {}

    for virify_summary in virify_annotation_files:
        with open(virify_summary, "r") as table_handle:
            csv_reader = csv.DictReader(table_handle, delimiter="\t")
            for row in csv_reader:
                contig = row["Contig"]
                start = int(row["Start"])
                # FIXME: validate this
                # Correct the index for GFF
                # start -= 1
                end = int(row["End"])
                direction = row["Direction"]
                viral_sequence_type = "phage_linear"
                (
                    prophage_start,
                    prophage_end,
                    circular,
                ) = Record.get_prophage_metadata_from_contig(contig)

                if circular is True:
                    viral_sequence_type = "phage_circular"

                if prophage_start is not None and prophage_end is not None:
                    # Fixing CDS coordinates to the context of the whole contig
                    # Current coordinates corresponds to the prophage region:
                    # contig_1|prophage-132033:161324	contig_1|prophage-132033:161324_1	2	256	1	No hit	NA
                    start = start + prophage_start
                    end = end + prophage_start
                    viral_sequence_type = f"prophage-{prophage_start}:{prophage_end}"

                # We use the contig name without any extra annotations
                # This also collapses multiples prophages annotations
                # per contig, if any.
                viral_sequences.setdefault(contig, set()).add(viral_sequence_type)

                best_hit = row["Best_hit"]
                cds_id = row["CDS_ID"]
                direction = direction.replace("-1", "-").replace("1", "+")

                # viphog hits #
                viphog_annotation = ""
                ## The best hit contains the ViPhOGXXX.faa that matches
                if best_hit != "No hit":
                    best_hit = best_hit.replace(".faa", "")
                    viphog_annotation = ";".join(
                        [f"viphog={best_hit}", f'viphog_taxonomy={row["Label"]}']
                    )
                    # We need to remove all the virify prophage annotations, if any
                    contig_name_clean = Record.remove_prophage_from_contig(contig)
                    cds_annotations.setdefault(contig_name_clean, []).append(
                        [
                            cds_id,
                            start,
                            end,
                            direction,
                            viphog_annotation,
                        ]
                    )

    return viral_sequences, cds_annotations


def write_gff(
    checkv_files,
    taxonomy_files,
    sample_prefix,
    assembly_file,
    viral_sequences,
    cds_annotations,
    ena_mapping=None,
):
    if ena_mapping:
        ena_assembly_accession = list(ena_mapping.values())[0].split(".")[0]
        output_filename = f"{ena_assembly_accession}_virify.gff"
    else:
        output_filename = f"{sample_prefix}_virify.gff"

    # Auxiliary dictionaries to collect some more contig related data
    checkv_dict, taxonomy_dict, contigs_len_dict = {}, {}, {}

    # Getting the checkv evaluation of each contig
    for checkv_file in checkv_files:
        with open(checkv_file, "r") as file_handle:
            csv_reader = csv.DictReader(file_handle, delimiter="\t")
            for row in csv_reader:
                contig_id = row["contig_id"]
                checkv_type = row["provirus"]
                checkv_quality = row["checkv_quality"]
                miuvig_quality = row["miuvig_quality"]
                checkv_info = ";".join(
                    [
                        f"checkv_provirus={checkv_type}",
                        f"checkv_quality={checkv_quality}",
                        f"miuvig_quality={miuvig_quality}",
                    ]
                )
                checkv_dict[contig_id] = checkv_info

    # Recovering taxonomic information and integrating the lineage
    # as Uroviricota;Caudoviricetes,Caudovirales;
    taxonomy_dict = {}

    def empty_if_number(string):
        try:
            float(string)
            return ""
        except ValueError:
            return string

    for taxonomy_file in taxonomy_files:
        with open(taxonomy_file, "r") as file_handle:
            csv_reader = csv.DictReader(file_handle, delimiter="\t")
            for row in csv_reader:
                contig = row["contig_ID"]
                lineage = [
                    empty_if_number(row.get("genus", "")),
                    empty_if_number(row.get("subfamily", "")),
                    empty_if_number(row.get("family", "")),
                    empty_if_number(row.get("order", "")),
                ]
                if all(level == "" for level in lineage):
                    taxonomy_string = "unclassified"
                else:
                    # %3B is ';', it's part of the GFF3 - col 9 encoding
                    # https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md
                    taxonomy_string = "%3B".join(
                        [line for line in lineage if line != ""]
                    )
                taxonomy_dict[contig] = taxonomy_string

    # Read unmodified contig length from the renamed assembly file
    for record in SeqIO.parse(assembly_file, "fasta"):
        contig_id = str(record.id)
        seq_len = len(str(record.seq))
        contigs_len_dict[contig_id] = seq_len

    with open(output_filename, "w") as gff:
        print("##gff-version 3", file=gff)
        # Constants
        SCORE = "."

        # Writing the gff header
        used_contigs=[]
        for contig_name in viral_sequences.keys():
            clean_contig_name = Record.remove_prophage_from_contig(contig_name)
            contig_length = contigs_len_dict[clean_contig_name]
            if clean_contig_name not in used_contigs:
                used_contigs.append(clean_contig_name)
                print(
                    "\t".join(
                        [
                            "##sequence-region",
                            clean_contig_name,
                            "1",
                            str(contig_length),
                        ]
                    ),
                    file=gff,
                )

        # Writing the mobile genetic elements (viral sequences)
        # coordinates and attributes
        for contig_name, viral_sequence_types in viral_sequences.items():
            clean_contig_name = Record.remove_prophage_from_contig(contig_name)
            for viral_seq_type in viral_sequence_types:
                element_category = "viral_sequence"

                id_ = f"ID={clean_contig_name}|viral_sequence"
                start = "1"
                end = contigs_len_dict[clean_contig_name]
                mobile_element_type = viral_seq_type

                if "prophage" in viral_seq_type:
                    id_ = f"ID={clean_contig_name}|{viral_seq_type}"
                    # Prophages include the start and the end in the string
                    # encoding: prophage:{prophage_start}-{prophage_end}
                    start, end = viral_seq_type.split("prophage-")[1].split(":")

                    if int(start) == 0:
                        start = '1'
                        id_=id_.replace('prophage-0:','prophage-1:')

                    element_category = "prophage"
                    mobile_element_type = "prophage"

                mobile_element_attributes = [
                    id_,
                    "gbkey=mobile_element",
                    f"mobile_element_type={mobile_element_type}",
                    checkv_dict[contig_name],
                ]

                taxonomy = taxonomy_dict.get(contig_name)
                if taxonomy:
                    mobile_element_attributes.append(f"taxonomy={taxonomy}")

                mobile_elements_line = [
                    clean_contig_name,
                    "VIRify",
                    element_category,
                    start,
                    end,
                    SCORE,
                    ".",
                    ".",
                    ";".join(mobile_element_attributes),
                ]

                print("\t".join(map(str, mobile_elements_line)), file=gff)

        # Write the CDS for the viral sequences
        for contig_name, contig_cds in cds_annotations.items():
            for cds_data in contig_cds:
                cds_id, start, end, direction, viphog_annotation = cds_data

                cds_id=cds_id.replace('prophage-0:','prophage-1:')

                # TODO: review this rule.
                if end > contigs_len_dict[contig_name]:
                    end = contigs_len_dict[contig_name]

                cds_attributes = [f"ID={cds_id}", "gbkey=CDS", viphog_annotation]
                cds_line = [
                    contig_name,
                    "Prodigal",
                    "CDS",
                    start,
                    end,
                    SCORE,
                    direction,
                    "0",  # phase
                    ";".join(cds_attributes),
                ]
                print("\t".join(map(str, cds_line)), file=gff)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate GFF and corresponding from VIRify output files"
    )
    parser.add_argument(
        "-a",
        "--assembly",
        dest="assembly_file",
        help="Original assembly fasta file",
        required=True,
    )

    parser.add_argument(
        "-v",
        "--virify-files",
        dest="virify_files",
        help="List of virify annotation summary files",
        nargs="+",
        required=True,
    )
    parser.add_argument(
        "-c",
        "--checkv-files",
        dest="checkv_files",
        help="list of checkv summary files",
        required=True,
        nargs="+",
    )
    parser.add_argument(
        "-t",
        "--taxonomy-files",
        dest="taxonomy_files",
        help="list of virify taxonomic annotation summary files",
        required=True,
        nargs="+",
    )
    parser.add_argument(
        "-s",
        "--sample-id",
        dest="sample_id",
        help="sample_id to prefix output file name."
        "Ignored with --rename-contigs option",
        required=True,
    )
    parser.add_argument(
        "--rename-contigs",
        help="True if contigs needs renaming from ERR to ERZ",
        required=False,
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--ena-contigs",
        dest="ena_contigs",
        help="Path to ENA contig file if renaming needed",
        required=False,
    )

    args = parser.parse_args()

    if args.rename_contigs and not args.ena_contigs:
        logging.error(
            (
                "Contig renaming selected but no contig file provided."
                "Provide path to ENA contig file with --ena-contigs"
            )
        )

    assembly_file = args.assembly_file
    virify_files = args.virify_files
    checkv_files = args.checkv_files
    taxonomy_files = args.taxonomy_files

    logging.info(f"found assembly file: {assembly_file}")
    logging.info(f"found virify files: {virify_files}")
    logging.info(f"found checkV files: {checkv_files}")
    logging.info(f"found taxonomy files: {taxonomy_files}")

    # sanity check: only keep any confidence level that is present in all three folders
    for confidence in ["high", "low", "prophage"]:
        vf_exists = any(confidence in x for x in virify_files)
        cf_exists = any(confidence in x for x in checkv_files)
        tf_exists = any(confidence in x for x in taxonomy_files)

        if not vf_exists or not cf_exists or not tf_exists:
            for file_list in [virify_files, checkv_files, taxonomy_files]:
                for f in file_list:
                    if confidence in f:
                        file_list.remove(f)

    logging.info(f"Filtered virify files: {virify_files}")
    logging.info(f"Filtered checkV files: {checkv_files}")
    logging.info(f"Filtered taxonomy files: {taxonomy_files}")

    if not len(virify_files):
        logging.info("No viral predictions found.. exiting")
        sys.exit(0)

    if not len(assembly_file):
        logging.info("No contigs in assembly file.. exiting")
        sys.exit(0)

    if args.rename_contigs:
        logging.warning(
            (
                "Provided sample ID is ignored with --rename-contigs option."
                " ENA ERZ accession will be used"
            )
        )
        ena_mapping = get_ena_contig_mapping(args.ena_contigs)
    else:
        ena_mapping = None

    logging.info("Collecting annotation data")

    viral_sequences, cds_annotations = aggregate_annotations(virify_files)

    logging.info("Generating the gff output")
    write_gff(
        checkv_files,
        taxonomy_files,
        args.sample_id,
        args.assembly_file,
        viral_sequences,
        cds_annotations,
        ena_mapping=ena_mapping,
    )
