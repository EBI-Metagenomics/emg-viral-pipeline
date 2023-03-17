#!/usr/bin/env python3

import logging
import argparse
import sys
import gzip
import csv

from bin.parse_viral_pred import Record

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


def collect_annotations(virify_annotation_files):
    """Collect all the virify annotations into a single data structure for
    easier handling when writing the GFF file.
    All the annotations will be collapsed into a single dictionary:
    {
        "contig_name": [ // without any prophage metadata
            [
                cds_id,
                "prophage | phage_circular | phage_linear",
                start,
                end,
                direction,
                viphog_annotation string ("viphog=VIPHOGYY;viphog_taxonomy=XX")
            ]
        ]...]
    }
    :param virify_annotation_files: The virify 08-final/*.annotations tsv files
    :return: A dict with all the annotations per contig
    """
    annotations_dict = {}

    for virify_summary in virify_annotation_files:
        with open(virify_summary, "r") as table_handle:
            csv_reader = csv.DictReader(table_handle, delimiter="\t")
            for row in csv_reader:
                contig = row["Contig"]
                clean_contig = Record.remove_prophage_from_contig(contig)
                cds_id = Record.remove_prophage_from_contig(row["CDS_ID"])
                start = int(row["Start"])
                # Correct the index for GFF
                start -= 1

                end = int(row["End"])
                direction = row["Direction"]
                best_hit = row["Best_hit"]

                prophage_description = ""

                (
                    prophage_start,
                    prophage_end,
                    circular,
                ) = Record.get_prophage_metadata_from_contig(contig)

                if circular is True:
                    prophage_description = "phage_circular"

                if prophage_start is not None and prophage_end is not None:
                    prophage_description = "prophage"
                    # Fixing CDS coordinates to the context of the whole contig
                    # Current coordinates corresponds to the prophage region:
                    # contig_1|prophage-132033:161324	contig_1|prophage-132033:161324_1	2	256	1	No hit	NA
                    start = start + prophage_start
                    end = end + prophage_end

                # No prophage information in the contig name #
                else:
                    prophage_description = "phage_linear"

                direction = direction.replace("-1", "-").replace("1", "+")

                # viphog hits #
                viphog_annotation = ""
                if best_hit != "No hit":
                    ## The best hit contains the ViPhOGXXX.faa that matches
                    best_hit = best_hit.replace(".faa", "")
                    viphog_annotation = ";".join(
                        [f"viphog={best_hit}", f'viphog_taxonomy={row["Label"]}']
                    )

                annotations_dict.setdefault(clean_contig, []).append(
                    [
                        cds_id,
                        prophage_description,
                        start,
                        end,
                        direction,
                        viphog_annotation,
                    ]
                )

    return annotations_dict


def write_gff(
    checkv_files,
    taxonomy_files,
    sample_prefix,
    assembly_file,
    collected_annotations,
    ena_mapping=None,
):
    if ena_mapping:
        ena_assembly_accession = list(ena_mapping.values())[0].split(".")[0]
        output_filename = f"{ena_assembly_accession}_virify.gff"
    else:
        output_filename = f"{sample_prefix}_virify.gff"

    checkv_dict, taxonomy_dict, contigs_len_dict = {}, {}, {}
    # parse checkv for quality
    for checkv_file in checkv_files:
        with open(checkv_file, "r") as file_handle:
            csv_reader = csv.DictReader(file_handle, delimiter="\t")
            for row in csv_reader:
                contig_id = Record.remove_prophage_from_contig(row["contig_id"])
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
    for taxonomy_file in taxonomy_files:
        with open(taxonomy_file, "r") as file_handle:
            csv_reader = csv.DictReader(file_handle, delimiter="\t")
            for row in csv_reader:
                contig = Record.remove_prophage_from_contig(row["contig_ID"])
                lineage = [
                    row.get("genus", ""),
                    row.get("subfamily", ""),
                    row.get("family", ""),
                    row.get("order", ""),
                ]
                if all(level == "" for level in lineage):
                    taxonomy_string = "unclassified"
                else:
                    taxonomy_string = "%3B".join(lineage)
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
        for contig_name in collected_annotations.keys():
            contig_length = contigs_len_dict[contig_name]
            print(f"##sequence-region {contig_length} 1 {contig_length}", file=gff)

        # Writing the mobile genetic elements coordinates and attributes
        phage_counter = 0
        for contig_name, contig_cds_list in collected_annotations.items():
            for contig_data in contig_cds_list:
                (
                    cds_id,
                    prophage_description,
                    start,
                    end,
                    direction,
                    viphog_annotation,
                ) = contig_data

                phage_counter += 1
                gff_element_id = f"phage_{phage_counter}"

                seq_type = ""

                if prophage_description == "prophage":
                    seq_type = ""
                    if end > contigs_len_dict[contig_name]:
                        end = contigs_len_dict[contig_name]
                else:
                    seq_type = "viral_sequence"
                    start = "1"
                    end = contigs_len_dict[contig_name]

                mobile_element_attributes = [
                    f"ID={gff_element_id}",
                    "gbkey=mobile_element",
                    f"mobile_element_type={prophage_description}",
                    checkv_dict[contig_name],
                ]

                taxonomy = taxonomy_dict.get(contig_name)
                if taxonomy:
                    mobile_element_attributes.append(f"taxonomy={taxonomy}")

                strand = "."
                phase = "."

                mobile_elements_line = [
                    contig_name,
                    "VIRify",
                    seq_type,
                    start,
                    end,
                    SCORE,
                    strand,
                    phase,
                    ";".join(mobile_element_attributes),
                ]
                print("\t".join(map(str, mobile_elements_line)), file=gff)

                if len(viphog_annotation):
                    phase = "0"

                    # TODO: review this rule.
                    # assert end <= contigs_len_dict[contig_id]

                    cds_attributes = [f"ID={cds_id}", "gbkey=CDS", viphog_annotation]
                    cds_line = [
                        contig_name,
                        "Prodigal",
                        "CDS",
                        start,
                        end,
                        SCORE,
                        direction,
                        phase,
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
        help="sample_id to prefix output file name. "
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
    annot_dicts = collect_annotations(virify_files)

    logging.info("Generating the gff output")
    write_gff(
        checkv_files,
        taxonomy_files,
        args.sample_id,
        args.assembly_file,
        annot_dicts,
        ena_mapping=ena_mapping,
    )
