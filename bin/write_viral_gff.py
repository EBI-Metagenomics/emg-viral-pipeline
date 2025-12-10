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
    """Create a mapping between contig names and ENA accession numbers.

    :param ena_contig_file: Path to ENA contig file in FASTA format
    :return: Dictionary mapping contig names to ENA accessions
    """
    ena_mapping = {}
    with gzip.open(ena_contig_file, "rt") as ena_contigs:
        for record in SeqIO.parse(ena_contigs, "fasta"):
            ena_name = record.id
            contig_name = record.description.split(" ")[1]
            ena_mapping[contig_name] = ena_name
    return ena_mapping


def get_contig_lengths_per_contig(assembly_file):
    """Build a dictionary mapping contig names to their lengths.

    :param assembly_file: Path to assembly file in FASTA format
    :return: Dictionary with contig names as keys and lengths as values
    """
    contigs_len_dict = {}
    with open_fasta_file(assembly_file) as handle:
        for record in SeqIO.parse(handle, "fasta"):
            contig_id = str(record.id)
            seq_len = len(str(record.seq))
            contigs_len_dict[contig_id] = seq_len
    return contigs_len_dict


def open_fasta_file(filename):
    """Open a FASTA file, handling both gzipped and uncompressed files.

    :param filename: Path to FASTA file (can be .gz or regular file)
    :return: File handle for reading the FASTA file
    """
    if filename.endswith(".gz"):
        f = gzip.open(filename, "rt")
    else:
        f = open(filename, "rt")
    return f


def aggregate_annotations(
    virify_annotation_files, contigs_len_dict, use_proteins=False
):
    """Aggregate all the virify annotations into a single data structure for
    easier handling when writing the GFF file.

    Handling of VS2's circular genome processing where contigs are extended by duplication (see https://github.com/jiarong/VirSorter2/issues/243)
    - If prophage_end > contig_length, prophage_end is truncated to contig_length
    - Original prophage_start is preserved, only prophage_end is truncated if needed

    :param virify_annotation_files: The virify 08-final/*.annotations tsv files
    :param contigs_len_dict: Dictionary mapping contig names to their lengths for prophage coordinate validation.
                             If provided, prophage end coordinates exceeding contig length will be truncated
                             to handle VS2 circular genome artifacts where extended contigs can lead to
                             prophage predictions that exceed the original contig boundaries.
    :param use_proteins: Boolean flag indicating if the pipeline used already predicted proteins as input
    :return: 3 values - viral_sequences dict, cds_annotations dict, and virify_quality dict
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
    virify_quality = {}

    for virify_summary in virify_annotation_files:
        quality = "unknown"
        if "taxonomy" in virify_summary:
            continue
        if "high_confidence_viral" in virify_summary:
            quality = "HC"
        elif "low_confidence" in virify_summary:
            quality = "LC"
        elif "prophages" in virify_summary:
            quality = "PP"

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
                    if use_proteins:
                        # If pipeline used already predicted proteins as input
                        # they were predicted on whole contigs
                        # that means no need to change coordinates
                        start = start
                        end = end
                    else:
                        # Fixing CDS coordinates to the context of the whole contig
                        # Current coordinates corresponds to the prophage region:
                        # contig_1|prophage-132033:161324	contig_1|prophage-132033:161324_1	2	256	1	No hit	NA
                        start = start + prophage_start
                        end = end + prophage_start

                    # Fix for circular prophages: truncate end coordinate if it exceeds contig length
                    # This handles the VS2 artifact where circular genomes are extended
                    # and prophage predictions can extend beyond the original contig boundaries
                    clean_contig_name = Record.remove_prophage_from_contig(contig)
                    if (
                        clean_contig_name in contigs_len_dict
                        and prophage_end > contigs_len_dict[clean_contig_name]
                    ):
                        prophage_end = contigs_len_dict[clean_contig_name]
                    viral_sequence_type = f"prophage-{prophage_start}:{prophage_end}"

                # save HC, LC, PP
                virify_quality.setdefault(contig, quality)
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

    return viral_sequences, cds_annotations, virify_quality


def write_gff(
    checkv_files,
    taxonomy_files,
    sample_prefix,
    assembly_file,
    viral_sequences,
    cds_annotations,
    virify_quality,
    contigs_len_dict,
    ena_mapping=None,
):
    """Generate a GFF3 file from VIRify output files with comprehensive viral sequence annotations.

    This function creates a GFF3 file containing viral sequence predictions, prophage regions,
    and CDS annotations with ViPhOG information. It handles the VS2 circular genome artifact
    by truncating prophage coordinates that exceed contig boundaries.

    :param checkv_files: List of CheckV summary files containing quality metrics
    :param taxonomy_files: List of taxonomic annotation files
    :param sample_prefix: Prefix for output GFF filename
    :param assembly_file: Assembly FASTA file (used for contig lengths if contigs_len_dict not provided)
    :param viral_sequences: Dictionary of viral sequence annotations from aggregate_annotations()
    :param cds_annotations: Dictionary of CDS annotations from aggregate_annotations()
    :param virify_quality: Dictionary of quality annotations from aggregate_annotations()
    :param ena_mapping: Optional ENA contig mapping for renaming (ERZ accession will be used if provided)
    :param contigs_len_dict: Optional pre-loaded dictionary mapping contig names to lengths.
                            If not provided, will be loaded from assembly_file.

    :return: None (writes GFF file to disk)
    """
    if ena_mapping:
        ena_assembly_accession = list(ena_mapping.values())[0].split(".")[0]
        output_filename = f"{ena_assembly_accession}_virify.gff"
    else:
        output_filename = f"{sample_prefix}_virify.gff"

    # Auxiliary dictionaries to collect some more contig related data
    checkv_dict, taxonomy_dict = {}, {}

    # Getting the checkv evaluation of each contig
    for checkv_file in checkv_files:
        with open(checkv_file, "r") as file_handle:
            csv_reader = csv.DictReader(file_handle, delimiter="\t")
            for row in csv_reader:
                contig_id = row["contig_id"]
                checkv_type = row["provirus"]
                checkv_quality = row["checkv_quality"]
                miuvig_quality = row["miuvig_quality"]
                kmer_freq = row["kmer_freq"]
                viral_genes = row["viral_genes"]
                checkv_info = ";".join(
                    [
                        f"checkv_provirus={checkv_type}",
                        f"checkv_quality={checkv_quality}",
                        f"checkv_miuvig_quality={miuvig_quality}",
                        f"checkv_kmer_freq={kmer_freq}",
                        f"checkv_viral_genes={viral_genes}",
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
                    empty_if_number(row.get("superkingdom", "")),
                    empty_if_number(row.get("kingdom", "")),
                    empty_if_number(row.get("phylum", "")),
                    empty_if_number(row.get("subphylum", "")),
                    empty_if_number(row.get("class", "")),
                    empty_if_number(row.get("order", "")),
                    empty_if_number(row.get("suborder", "")),
                    empty_if_number(row.get("family", "")),
                    empty_if_number(row.get("subfamily", "")),
                    empty_if_number(row.get("genus", "")),
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

    # Constants
    SCORE = "."

    # Collect all sequence-region headers
    sequence_regions = []
    used_contigs = set()
    for contig_name in viral_sequences.keys():
        clean_contig_name = Record.remove_prophage_from_contig(contig_name)
        if clean_contig_name not in used_contigs:
            used_contigs.add(clean_contig_name)
            contig_length = contigs_len_dict[clean_contig_name]
            sequence_regions.append((clean_contig_name, contig_length))

    # Sort sequence-region headers by contig name
    sequence_regions.sort(key=lambda x: x[0])

    # Collect all GFF records (both mobile elements and CDS) before writing
    all_records = []

    # Collect mobile genetic elements (viral sequences)
    for contig_name, viral_sequence_types in viral_sequences.items():
        clean_contig_name = Record.remove_prophage_from_contig(contig_name)
        quality = (
            virify_quality[contig_name] if contig_name in virify_quality else "unknown"
        )

        for viral_seq_type in viral_sequence_types:
            element_category = "viral_sequence"
            id_ = f"ID={clean_contig_name}|viral_sequence"
            start = 1
            end = contigs_len_dict[clean_contig_name]
            mobile_element_type = viral_seq_type

            if "prophage" in viral_seq_type:
                id_ = f"ID={clean_contig_name}|{viral_seq_type}"
                # Prophages include the start and the end in the string
                # encoding: prophage:{prophage_start}-{prophage_end}
                start_str, end_str = viral_seq_type.split("prophage-")[1].split(":")
                start = int(start_str)
                end = int(end_str)

                if start == 0:
                    start = 1
                    id_ = id_.replace("prophage-0:", "prophage-1:")

                element_category = "prophage"
                mobile_element_type = "prophage"

            mobile_element_attributes = [
                id_,
                f"virify_quality={quality}",
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
                str(start),
                str(end),
                SCORE,
                ".",
                ".",
                ";".join(mobile_element_attributes),
            ]

            # Store as tuple: (contig_name, start_position, line_as_string)
            all_records.append(
                (clean_contig_name, start, "\t".join(mobile_elements_line))
            )

    # Collect CDS records
    for contig_name, contig_cds in cds_annotations.items():
        for cds_data in contig_cds:
            cds_id, start, end, direction, viphog_annotation = cds_data
            region_name = "_".join(cds_id.split("_")[:-1])
            cds_id = cds_id.replace("prophage-0:", "prophage-1:")

            # TODO: review this rule.
            if end > contigs_len_dict[contig_name]:
                end = contigs_len_dict[contig_name]

            quality = (
                virify_quality[region_name]
                if region_name in virify_quality
                else "unknown"
            )
            cds_attributes = [
                f"ID={cds_id}",
                f"virify_quality={quality}",
                "gbkey=CDS",
                viphog_annotation,
            ]
            cds_line = [
                contig_name,
                "Prodigal",
                "CDS",
                str(start),
                str(end),
                SCORE,
                direction,
                "0",  # phase
                ";".join(cds_attributes),
            ]

            # Store as tuple: (contig_name, start_position, line_as_string)
            all_records.append((contig_name, start, "\t".join(cds_line)))

    # Sort all records by contig name (lexicographically) then by start position (numerically)
    all_records.sort(key=lambda x: (x[0], x[1]))

    # Write the GFF file with sorted content
    with open(output_filename, "w") as gff:
        print("##gff-version 3", file=gff)

        # Write sorted sequence-region headers
        for contig_name, contig_length in sequence_regions:
            print(
                "\t".join(
                    [
                        "##sequence-region",
                        contig_name,
                        "1",
                        str(contig_length),
                    ]
                ),
                file=gff,
            )

        # Write all sorted records
        for contig_name, start_pos, record_line in all_records:
            print(record_line, file=gff)


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
    parser.add_argument(
        "--use-proteins",
        dest="use_proteins",
        help="Add this argument if pipeline used already predicted proteins as input",
        action="store_true",
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

    # Load contig lengths once for prophage coordinate validation
    contigs_len_dict = get_contig_lengths_per_contig(assembly_file)

    viral_sequences, cds_annotations, virify_quality = aggregate_annotations(
        virify_files, contigs_len_dict, args.use_proteins
    )

    logging.info("Generating the gff output")
    write_gff(
        checkv_files,
        taxonomy_files,
        args.sample_id,
        args.assembly_file,
        viral_sequences,
        cds_annotations,
        virify_quality,
        contigs_len_dict,
        ena_mapping=ena_mapping,
    )
