#!/usr/bin/env python3

from __future__ import annotations

import argparse
import csv
import gzip
import logging
import sys
from typing import IO

from Bio import SeqIO
from parse_viral_pred import Record
from utils import parse_attrs

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

SCORE = "."


def parse_args() -> argparse.Namespace:
    """Parse and return command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Generate a GFF3 file from VIRify output files"
    )
    parser.add_argument(
        "-a",
        "--assembly",
        dest="assembly_file",
        help="Original assembly FASTA file",
        required=True,
    )
    parser.add_argument(
        "-v",
        "--virify-files",
        dest="virify_files",
        help="List of VIRify annotation summary TSV files",
        nargs="+",
        required=True,
    )
    parser.add_argument(
        "-c",
        "--checkv-files",
        dest="checkv_files",
        help="List of CheckV summary TSV files",
        required=True,
        nargs="+",
    )
    parser.add_argument(
        "-t",
        "--taxonomy-files",
        dest="taxonomy_files",
        help="List of VIRify taxonomic annotation TSV files",
        required=True,
        nargs="+",
    )
    parser.add_argument(
        "-s",
        "--sample-id",
        dest="sample_id",
        help="Sample ID used as the output filename prefix. Ignored with --rename-contigs.",
        required=True,
    )
    parser.add_argument(
        "--rename-contigs",
        help="Rename contigs from ERR to ERZ accessions",
        required=False,
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--ena-contigs",
        dest="ena_contigs",
        help="Path to ENA contig FASTA file required when --rename-contigs is set",
        required=False,
    )
    parser.add_argument(
        "-g",
        "--gff",
        dest="gff_files",
        help=(
            "Per-category GFF3 files from split_proteins or prodigal. "
            "Used to include viral contigs that have no annotated proteins."
        ),
        nargs="*",
        default=[],
    )
    return parser.parse_args()


def evaluate_inputs(
    args: argparse.Namespace,
) -> tuple[str, list[str], list[str], list[str], dict[str, str] | None]:
    """Validate inputs and resolve the optional ENA contig mapping.

    :param args: Parsed command-line arguments.
    :return: Tuple of (assembly_file, virify_files, checkv_files, taxonomy_files, ena_mapping).
             ena_mapping is None when --rename-contigs is not set.
    """
    if args.rename_contigs and not args.ena_contigs:
        logger.error(
            "Contig renaming selected but no contig file provided. "
            "Provide path to ENA contig file with --ena-contigs"
        )

    assembly_file: str = args.assembly_file
    virify_files: list[str] = args.virify_files
    checkv_files: list[str] = args.checkv_files
    taxonomy_files: list[str] = args.taxonomy_files

    logger.info(f"found assembly file: {assembly_file}")
    logger.info(f"found virify files: {virify_files}")
    logger.info(f"found checkV files: {checkv_files}")
    logger.info(f"found taxonomy files: {taxonomy_files}")

    if not assembly_file:
        logger.info("No contigs in assembly file.. exiting")
        sys.exit(0)

    if args.rename_contigs:
        logger.warning(
            "Provided sample ID is ignored with --rename-contigs option. "
            "ENA ERZ accession will be used"
        )
        ena_mapping: dict[str, str] | None = get_ena_contig_mapping(args.ena_contigs)
    else:
        ena_mapping = None

    return assembly_file, virify_files, checkv_files, taxonomy_files, ena_mapping


def get_ena_contig_mapping(ena_contig_file: str) -> dict[str, str]:
    """Create a mapping between contig names and ENA accession numbers.

    :param ena_contig_file: Path to gzipped ENA contig FASTA file.
    :return: Dictionary mapping original contig names to ENA accessions.
    """
    ena_mapping: dict[str, str] = {}
    with gzip.open(ena_contig_file, "rt") as ena_contigs:
        for record in SeqIO.parse(ena_contigs, "fasta"):
            ena_name = record.id
            contig_name = record.description.split(" ")[1]
            ena_mapping[contig_name] = ena_name
    return ena_mapping


def get_contig_lengths_per_contig(assembly_file: str) -> dict[str, int]:
    """Build a dictionary mapping contig names to their lengths.

    :param assembly_file: Path to assembly FASTA file (plain or gzipped).
    :return: Dictionary with contig names as keys and sequence lengths as values.
    """
    contigs_len_dict: dict[str, int] = {}
    with open_fasta_file(assembly_file) as handle:
        for record in SeqIO.parse(handle, "fasta"):
            contigs_len_dict[str(record.id)] = len(str(record.seq))
    return contigs_len_dict


def open_fasta_file(filename: str) -> IO[str]:
    """Open a FASTA file, handling both gzipped and plain text formats.

    :param filename: Path to FASTA file (.gz or uncompressed).
    :return: Text-mode file handle.
    """
    if filename.endswith(".gz"):
        return gzip.open(filename, "rt")
    return open(filename, "rt")


def define_viral_sequence_type(contig: str, contig_len: int) -> tuple[str, bool]:
    """Determine the viral sequence type string and whether prophage coordinates overrun.

    For prophage contigs (ID contains |prophage-START:END), the type encodes the
    genomic interval.  If the prophage end exceeds the contig length (a VirSorter2
    artefact for circular genomes), the end is clamped to the contig length.

    :param contig: Full contig ID, optionally containing |prophage-START:END or |phage-circular.
    :param contig_len: Length of the base contig (without prophage suffix).
    :return: Tuple of (viral_sequence_type, prophage_overrun) where viral_sequence_type is one of
             "phage_linear", "phage_circular", or "prophage-START:END", and prophage_overrun
             indicates whether the end coordinate was clamped.
    """
    viral_sequence_type = "phage_linear"
    prophage_start, prophage_end, circular = Record.get_prophage_metadata_from_contig(
        contig
    )

    if circular:
        viral_sequence_type = "phage_circular"

    prophage_overrun = False
    if prophage_start is not None and prophage_end is not None:
        if prophage_end > contig_len:
            viral_sequence_type = f"prophage-{prophage_start}:{contig_len}"
            prophage_overrun = True
        else:
            viral_sequence_type = f"prophage-{prophage_start}:{prophage_end}"

    return viral_sequence_type, prophage_overrun


def build_cds_data(contig, contig_len, direction, cds_id):

    viral_sequence_type, does_the_prophage_overrun = define_viral_sequence_type(
        contig, contig_len
    )

    prophage_start, prophage_end, _ = Record.get_prophage_metadata_from_contig(contig)

    direction = direction.replace("-1", "-").replace("1", "+")

    if does_the_prophage_overrun:
        cds_id = cds_id.replace(
            f"prophage-{prophage_start}:{prophage_end}",
            f"prophage-{prophage_start}:{contig_len}",
        )

    return viral_sequence_type, direction, cds_id


def get_annotation_results(
    virify_annotation_files: list[str], contigs_len_dict: dict[str, int]
) -> tuple[dict[str, set[str]], dict[str, list]]:
    """Aggregate VIRify annotation TSVs into structures ready for GFF writing.

    Handles the VirSorter2 circular-genome artefact where contigs are extended by
    duplication: if prophage_end exceeds the contig length, prophage_end is clamped
    to the contig length and the CDS ID is updated accordingly.

    :param virify_annotation_files: Paths to *_annotation.tsv files produced by viral_contigs_annotation.py.
    :param contigs_len_dict: Mapping of base contig name to sequence length.
    :return: Tuple of (viral_sequences, cds_annotations) where:
             - viral_sequences maps full contig ID to a set of viral sequence type strings
               ("phage_linear", "phage_circular", or "prophage-START:END").
             - cds_annotations maps clean contig name to a list of
               [cds_id, start, end, direction, viphog_annotation, original_contig] entries.
    """
    cds_annotations = {}

    for virify_summary in virify_annotation_files:
        with open(virify_summary, "r") as table_handle:
            csv_reader = csv.DictReader(table_handle, delimiter="\t")
            for row in csv_reader:
                contig = row["Contig"]
                cds_id = row["CDS_ID"]
                direction = row["Direction"]

                clean_contig_name = Record.remove_prophage_from_contig(contig)
                contig_len = contigs_len_dict.get(clean_contig_name)
                if contig_len is not None:
                    _, direction, cds_id = build_cds_data(
                        contig, contig_len, direction, cds_id
                    )

                best_hit = row["Best_hit"]

                viphog_annotation = ""
                if best_hit != "No hit":
                    best_hit = best_hit.replace(".faa", "")
                    viphog_annotation = ";".join(
                        [f"viphog={best_hit}", f"viphog_taxonomy={row['Label']}"]
                    )
                cds_annotations.setdefault(contig, {})
                cds_annotations[contig][cds_id] = viphog_annotation
    return cds_annotations


def get_checkv_results(
    checkv_files: list[str],
    sequence_regions: list[tuple[str, int]],
) -> dict[str, str]:
    """Parse CheckV summary files and validate coverage against expected contigs.

    Raises if none of the GFF contigs have CheckV results, which indicates a
    naming mismatch.  Contigs without CheckV results receive NA placeholder values.

    :param checkv_files: Paths to CheckV quality_summary.tsv files.
    :param sequence_regions: List of (contig_name, length) pairs that will appear in the GFF.
    :return: Dictionary mapping clean contig name to a semicolon-joined CheckV attribute string.
    """
    checkv_dict: dict[str, str] = {}
    not_determined = 0
    for checkv_file in checkv_files:
        with open(checkv_file, "r") as file_handle:
            csv_reader = csv.DictReader(file_handle, delimiter="\t")
            for row in csv_reader:
                contig_id = row["contig_id"]
                viral_genes_count = row["viral_genes"].strip()
                if viral_genes_count == "":
                    raise ValueError("viral_genes is empty")
                if (
                    int(viral_genes_count) == 0
                    and row["checkv_quality"] == "Not-determined"
                ):
                    # CheckV values are appended to the attributes for the user to
                    # judge; we deliberately do NOT filter on them, to avoid
                    # discarding novel viral sequences due to CheckV database bias.
                    not_determined += 1

                checkv_info = ";".join(
                    [
                        f"checkv_provirus={row['provirus']}",
                        f"checkv_quality={row['checkv_quality']}",
                        f"checkv_miuvig_quality={row['miuvig_quality']}",
                        f"checkv_kmer_freq={row['kmer_freq']}",
                        f"checkv_viral_genes={row['viral_genes']}",
                    ]
                )
                checkv_dict[Record.remove_prophage_from_contig(contig_id)] = checkv_info

    gff_contig_names = {name for name, _ in sequence_regions}
    contigs_with_checkv = gff_contig_names & checkv_dict.keys()
    contigs_without_checkv = gff_contig_names - checkv_dict.keys()

    if not contigs_with_checkv:
        raise ValueError(
            f"None of the {len(gff_contig_names)} GFF contigs have CheckV results. "
            "CheckV must be run on all viral contigs before generating the GFF. "
            "This likely indicates a naming mismatch between the annotation and CheckV files."
        )

    if contigs_without_checkv:
        logger.warning(
            f"{len(contigs_without_checkv)} viral contigs have no CheckV results "
            "and will use placeholder NA values: "
            + ", ".join(sorted(contigs_without_checkv))
        )

    if not_determined:
        logger.warning(
            f"{not_determined} viral contigs have no viral genes detected by CheckV."
        )

    return checkv_dict


def empty_if_number(string: str) -> str:
    """Return an empty string if the value parses as a float, otherwise return the original string.

    Used to filter numeric-only taxonomy levels that represent missing data.

    :param string: Taxonomy rank value from the assignment table.
    :return: Empty string for numeric values, original string otherwise.
    """
    if string is None:
        return ""
    try:
        float(string)
        return ""
    except ValueError:
        return string


def get_taxonomy_results(taxonomy_files: list[str]) -> dict[str, str]:
    """Parse taxonomy assignment files into a per-contig lineage string.

    Lineage levels are joined with %3B (GFF3-encoded semicolon).  Contigs for
    which all levels are empty or numeric receive the string "unclassified".

    :param taxonomy_files: Paths to *_taxonomy.tsv files produced by contig_taxonomic_assign.py.
    :return: Dictionary mapping contig ID to a %3B-delimited lineage string.
    """
    taxonomy_dict: dict[str, str] = {}

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
                    # %3B is the GFF3-encoded semicolon
                    # https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md
                    taxonomy_string = "%3B".join(level for level in lineage if level)
                taxonomy_dict[contig] = taxonomy_string

    return taxonomy_dict


def get_proteins_from_gff(
    gff_files: list[str], contigs_len_dict: dict[str, int], cds_best_hits
) -> tuple[dict[str, set[str]], dict[str, list[list]]]:
    """Collect viral contigs and their CDS records from the per-category GFF files.

    Only CDS records are read, so a contig is registered here if and only if it has at
    least one CDS.  A contig with no CDS does not reach the final GFF: it cannot be
    annotated without proteins, and it is discarded and reported upstream by
    split_proteins_by_categories.py (or by filter_contigs_no_proteins.py, before the
    prediction tools run).

    A contig that has CDS records but no ViPhOG HMM hits is still included; its CDS
    simply carry an empty annotation, which is logged per contig.

    :param gff_files: Per-category GFF3 files produced by split_proteins or prodigal.
    :param contigs_len_dict: Mapping of base contig name to sequence length.
    :param cds_best_hits: Mapping of full contig ID to {CDS ID: best ViPhOG annotation},
                          used to attach annotations to the CDS records.
    :return: Tuple of (viral_sequences, cds_annotations) where:
             - viral_sequences maps full contig ID to its set of viral sequence types.
             - cds_annotations maps base contig name to a list of
               [cds_id, start, end, direction, annotation, contig_id, genecaller].
    """
    viral_sequences = {}
    cds_annotations = {}
    # parse all proteins
    contigs_proteins = {}
    for gff_file in gff_files:
        with open(gff_file) as fh:
            for line in fh:
                if line.startswith("#"):
                    continue
                cols = line.strip().split("\t")
                if len(cols) == 9:
                    record = cols[2]
                    if record != "CDS":
                        continue
                    contig_id = cols[0]
                    contigs_proteins.setdefault(contig_id, [])
                    contigs_proteins[contig_id].append(line)

    for contig_id, protein_records in contigs_proteins.items():
        # Add contig into processing list
        # TODO: maybe required to change does_the_prophage_overrun to new coords of prophage
        clean_contig_name = Record.remove_prophage_from_contig(contig_id)
        contig_len = contigs_len_dict.get(clean_contig_name, 0)
        viral_sequence_type, _ = define_viral_sequence_type(contig_id, contig_len)
        viral_sequences[contig_id] = {viral_sequence_type}
        logger.info(f"Added contig from GFF {contig_id}")
        annotation_exists = False
        for protein_record in protein_records:
            protein_record_cols = protein_record.strip().split("\t")
            attrs, _ = parse_attrs(protein_record_cols[8])
            cds_id = attrs.get("ID", "").strip()
            start = int(protein_record_cols[3])
            end = int(protein_record_cols[4])
            genecaller = protein_record_cols[1]
            direction = protein_record_cols[6]

            viral_sequence_type, direction, cds_id = build_cds_data(
                contig_id, contig_len, direction, cds_id
            )
            # Add proteins into CDS dictionary
            annotation = ""
            if contig_id in cds_best_hits and cds_id in cds_best_hits[contig_id]:
                annotation = cds_best_hits[contig_id][cds_id]
                annotation_exists = True
            cds_annotations.setdefault(clean_contig_name, []).append(
                [cds_id, start, end, direction, annotation, contig_id, genecaller]
            )
        logger.info(
            f"Viphogs annotation{' does not' if not annotation_exists else ''} exist for contig {contig_id}"
        )
    return viral_sequences, cds_annotations


def get_sequence_regions(
    viral_sequences: dict[str, set[str]], contigs_len_dict: dict[str, int]
) -> list[tuple[str, int]]:
    """Build a sorted list of (contig_name, length) pairs for GFF ##sequence-region headers.

    Each unique base contig name is represented once.  When using proteins predicted on full contig,
    contigs missing from the assembly are skipped with a warning rather than raising
    an error, because users may supply proteins for contigs that were filtered out
    by the length threshold.

    :param viral_sequences: Mapping of full contig ID to viral sequence types.
    :param contigs_len_dict: Mapping of base contig name to sequence length.
    :return: List of (clean_contig_name, length) tuples sorted by contig name.
    """
    sequence_regions: list[tuple[str, int]] = []
    used_contigs: set[str] = set()
    missed_contigs = 0

    for contig_name in viral_sequences:
        clean_contig_name = Record.remove_prophage_from_contig(contig_name)
        if clean_contig_name in used_contigs:
            continue
        used_contigs.add(clean_contig_name)
        contig_length = contigs_len_dict.get(clean_contig_name)
        if contig_length is None:
            missed_contigs += 1
            continue
        sequence_regions.append((clean_contig_name, contig_length))

    if missed_contigs > 0:
        logger.warning(
            f"{missed_contigs} contigs were not found in the assembly and were skipped"
        )

    if not sequence_regions:
        raise ValueError(
            "All the contigs that came from the annotated viral sequences were discarded."
        )

    sequence_regions.sort(key=lambda x: x[0])
    return sequence_regions


def define_virify_quality(virify_annotation_files: list[str]) -> dict[str, str]:
    """Derive a quality label (HC / LC / PP) for each contig from the annotation file it appears in.

    The label is inferred from the filename: files containing "high_confidence_viral"
    map to "HC", "low_confidence" to "LC", and "prophages" to "PP".  If a contig
    appears in multiple files the first assignment is kept (setdefault semantics).

    :param virify_annotation_files: Paths to *_annotation.tsv files produced by viral_contigs_annotation.py.
    :return: Dictionary mapping full contig ID to quality label string.
    """
    virify_quality: dict[str, str] = {}

    for virify_summary in virify_annotation_files:
        quality = "unknown"
        if "high_confidence_viral" in virify_summary:
            quality = "HC"
        elif "low_confidence" in virify_summary:
            quality = "LC"
        elif "prophages" in virify_summary:
            quality = "PP"

        with open(virify_summary, "r") as table_handle:
            csv_reader = csv.DictReader(table_handle, delimiter="\t")
            for row in csv_reader:
                virify_quality.setdefault(row["contig_id"], quality)

    return virify_quality


def write_gff(
    checkv_dict: dict[str, str],
    taxonomy_dict: dict[str, str],
    sample_prefix: str,
    viral_sequences: dict[str, set[str]],
    cds_annotations: dict[str, list],
    virify_quality: dict[str, str],
    contigs_len_dict: dict[str, int],
    sequence_regions: list[tuple[str, int]],
    ena_mapping: dict[str, str] | None = None,
) -> None:
    """Write the final VIRify GFF3 file.

    Produces one mobile_element (viral_sequence or prophage) feature per contig/prophage
    region and one CDS feature per annotated protein.  All records are sorted by contig
    name then start position before writing.

    :param checkv_dict: Mapping of clean contig name to CheckV attribute string.
    :param taxonomy_dict: Mapping of full contig ID to %3B-delimited lineage string.
    :param sample_prefix: Output filename prefix (ignored when ena_mapping is provided).
    :param viral_sequences: Mapping of full contig ID to set of viral sequence type strings.
    :param cds_annotations: Mapping of clean contig name to list of CDS data entries.
    :param virify_quality: Mapping of full contig ID to quality label (HC/LC/PP/unknown).
    :param contigs_len_dict: Mapping of base contig name to sequence length.
    :param sequence_regions: Sorted list of (contig_name, length) for ##sequence-region headers.
    :param ena_mapping: Optional mapping of contig names to ENA ERZ accessions; when provided
                        the output filename uses the ERZ accession prefix.
    """
    if ena_mapping:
        ena_assembly_accession = next(iter(ena_mapping.values())).split(".")[0]
        output_filename = f"{ena_assembly_accession}_virify.gff"
    else:
        output_filename = f"{sample_prefix}_virify.gff"

    all_records: list[tuple[str, int, str]] = []

    for contig_name, viral_sequence_types in viral_sequences.items():
        clean_contig_name = Record.remove_prophage_from_contig(contig_name)
        quality = virify_quality.get(contig_name, "unknown")

        for viral_seq_type in viral_sequence_types:
            element_category = "viral_sequence"
            id_ = f"ID={clean_contig_name}|viral_sequence"
            start = 1
            end = contigs_len_dict.get(clean_contig_name)
            if end is None:
                continue
            mobile_element_type = viral_seq_type

            if "prophage" in viral_seq_type:
                id_ = f"ID={clean_contig_name}|{viral_seq_type}"
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
                checkv_dict.get(
                    clean_contig_name,
                    "checkv_provirus=NA;checkv_quality=NA;checkv_miuvig_quality=NA"
                    ";checkv_kmer_freq=NA;checkv_viral_genes=NA",
                ),
            ]

            taxonomy = taxonomy_dict.get(contig_name)
            if taxonomy:
                mobile_element_attributes.append(f"taxonomy={taxonomy}")
            else:
                mobile_element_attributes.append("taxonomy=unclassified")

            mobile_elements_line = "\t".join(
                [
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
            )
            all_records.append((clean_contig_name, start, mobile_elements_line))

    for contig_name, contig_cds in cds_annotations.items():
        for cds_data in contig_cds:
            (
                cds_id,
                start,
                end,
                direction,
                viphog_annotation,
                original_contig,
                genecaller,
            ) = cds_data
            cds_id = cds_id.replace("prophage-0:", "prophage-1:")

            contig_len = contigs_len_dict.get(contig_name)
            if contig_len is None:
                continue
            end = min(end, contig_len)

            quality = virify_quality.get(original_contig, "unknown")
            cds_attributes = [
                f"ID={cds_id}",
                f"virify_quality={quality}",
                "gbkey=CDS",
            ]
            if viphog_annotation:
                cds_attributes.append(viphog_annotation)

            cds_line = "\t".join(
                [
                    contig_name,
                    genecaller,
                    "CDS",
                    str(start),
                    str(end),
                    SCORE,
                    direction,
                    "0",
                    ";".join(cds_attributes),
                ]
            )
            all_records.append((contig_name, start, cds_line))

    all_records.sort(key=lambda x: (x[0], x[1]))

    with open(output_filename, "w") as gff:
        print("##gff-version 3", file=gff)
        for contig_name, contig_length in sequence_regions:
            print(
                f"##sequence-region\t{contig_name}\t1\t{contig_length}",
                file=gff,
            )
        for _contig, _start, record_line in all_records:
            print(record_line, file=gff)


if __name__ == "__main__":
    args = parse_args()

    assembly_file, virify_files, checkv_files, taxonomy_files, ena_mapping = (
        evaluate_inputs(args)
    )

    logger.info("Collecting annotation data")
    contigs_len_dict = get_contig_lengths_per_contig(assembly_file)
    # define virify HC/LC/PP quality
    virify_quality = define_virify_quality(checkv_files)
    # get viphogs annotation for proteins
    cds_best_hits = get_annotation_results(virify_files, contigs_len_dict)

    # get proteins from GFF and add viphogs annotation where it exists
    viral_sequences, cds_annotations = get_proteins_from_gff(
        args.gff_files, contigs_len_dict, cds_best_hits
    )

    sequence_regions = get_sequence_regions(viral_sequences, contigs_len_dict)
    checkv_dict = get_checkv_results(checkv_files, sequence_regions)
    taxonomy_dict = get_taxonomy_results(taxonomy_files)

    logger.info("Generating the gff output")
    write_gff(
        checkv_dict,
        taxonomy_dict,
        args.sample_id,
        viral_sequences,
        cds_annotations,
        virify_quality,
        contigs_len_dict,
        sequence_regions,
        ena_mapping=ena_mapping,
    )
