#!/usr/bin/env python3

import logging
import argparse
import sys
import gzip

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


def collect_annot(virify_files, sample_prefix, ena_mapping=None):
    ## Parsing the annotation files
    contig_protID = {}
    prot_data = {}
    contig_data = {}
    for vfile in virify_files:
        with open(vfile, "r") as input_table:
            next(input_table)
            for line in input_table:
                line_l = line.rstrip().split("\t")
                contig = line_l[0]
                CDS_ID = line_l[1]
                start = line_l[2]
                if start == "0":
                    start = "1"
                end = line_l[3]
                direction = line_l[4]
                best_hit = line_l[5]

                if "|phage-circular" in contig:
                    contig = contig.replace("|phage-circular", "")
                    CDS_ID = CDS_ID.replace("|phage-circular", "")
                    desc = "phage_circular"

                elif "|prophage-" in contig:
                    desc = "prophage"
                    # Fixing CDS coordinates to the context of the whole contig
                    # Current coordinates corresponds to the prophage region:
                    # contig_1|prophage-132033:161324	contig_1|prophage-132033:161324_1	2	256	1	No hit	NA
                    prophage_start = int(
                        contig.split("|")[1].split("-")[1].split(":")[0]
                    )
                    start = int(start) + prophage_start
                    end = int(end) + prophage_start

                else:
                    contig = contig.replace("|", "")
                    CDS_ID = CDS_ID.replace("|", "")
                    desc = "phage_linear"

                if contig not in contig_protID.keys():
                    contig_protID[contig] = [CDS_ID]
                    contig_data[contig] = desc
                else:
                    contig_protID[contig].append(CDS_ID)

                direction = direction.replace("-1", "-").replace("1", "+")

                if not best_hit == "No hit":
                    best_hit = best_hit.replace(".faa", "")
                    label = line_l[7]
                    annotation = "viphog=" + best_hit + ";" + "viphog_taxonomy=" + label

                    values = (str(start), str(end), direction, annotation)
                    prot_data[CDS_ID] = values

    # return dictionaries
    return contig_protID, prot_data, contig_data


def write_gff(
    checkv_files,
    taxonomy_files,
    sample_prefix,
    assembly_file,
    annot_dicts,
    ena_mapping=None,
):
    if ena_mapping:
        ena_assembly_accession = list(ena_mapping.values())[0].split(".")[0]
        output_filename = f"{ena_assembly_accession}_virify.gff"
    else:
        output_filename = f"{sample_prefix}_virify.gff"

    checkv_dict, taxonomy_dict, contigs_len_dict = {}, {}, {}
    #   parse checkv for quality
    for cfile in checkv_files:
        with open(cfile, "r") as input_table:
            next(input_table)
            for line in input_table:
                line_l = line.rstrip().split("\t")
                contig_id = line_l[0]
                checkv_type = line_l[2]
                checkv_quality = line_l[7]
                miuvig_quality = line_l[8]
                checkv_info = ";".join([
                    f"checkv_provirus={checkv_type}",
                    f"checkv_quality={checkv_quality}",
                    f"miuvig_quality={miuvig_quality}"
                ])
                checkv_dict[contig_id] = checkv_info

    # Recovering taxonomic information and integrating the lineage as Uroviricota;Caudoviricetes,Caudovirales;
    for tfile in taxonomy_files:
        with open(tfile, "r") as input_table:
            next(input_table)
            for line in input_table:
                line_l = line.rstrip().split("\t")
                contig = line_l.pop(0)

                if "|phage-circular" in contig:
                    contig = contig.replace("|phage-circular", "")
                elif "|prophage-" in contig:
                    desc = "prophage"
                else:
                    contig = contig.replace("|", "")

                lineage = []
                for element in line_l:
                    if len(element) > 0:
                        try:
                            float(element)
                        except:
                            lineage.append(element)
                if len(lineage) > 0:
                    taxo_string = "%3B".join(lineage)
                else:
                    taxo_string = "unclassified"

                taxonomy_dict[contig] = taxo_string

    # Saving the original contig length
    for record in SeqIO.parse(assembly_file, "fasta"):
        contig_id = str(record.id)
        seq_len = len(str(record.seq))
        contigs_len_dict[contig_id] = str(seq_len)

    contig_protID, prot_data, contig_data = annot_dicts

    # Writing the gff file
    with open(output_filename, "w") as gff:
        gff.write("##gff-version 3\n")

        # Writing the gff header
        printed_contig = []
        for prediction in contig_protID.keys():
            clean_id = prediction
            if "prophage" in prediction:
                clean_id = prediction.split("|")[0]

            if clean_id not in printed_contig:
                printed_contig.append(clean_id)
                element_len = contigs_len_dict[clean_id]
                gff.write("##sequence-region " + clean_id + " 1 " + element_len + "\n")

        # Writing the mobile genetic elements coordinates and attributes
        phage_counter = 0
        phage_ids = {}
        for prediction in contig_protID.keys():
            phage_counter += 1
            element_id = "phage_" + str(phage_counter)
            phage_ids[prediction] = element_id
            if "prophage" in prediction:
                seq_type = "prophage"
                seqid = prediction.split("|")[0]
                start = prediction.split("|")[1].split("-")[1].split(":")[0]
                if start == "0":
                    start = "1"
                region_end = prediction.split("|")[1].split("-")[1].split(":")[1]
                if int(region_end) > int(contigs_len_dict[seqid]):
                    region_end = str(contigs_len_dict[seqid])
            else:
                seq_type = "viral_sequence"
                seqid = prediction
                start = "1"
                region_end = contigs_len_dict[prediction]

            attributes = ";".join([
                f"ID={element_id}",
                'gbkey=mobile_element',
                f"mobile_element_type={contig_data[prediction]}",
                checkv_dict[prediction]
            ])

            if prediction in taxonomy_dict.keys():
                attributes = (
                    attributes
                    + ';'
                    + 'taxonomy='
                    + taxonomy_dict[prediction]
                )
        
            source = "VIRify"
            score = "."
            strand = "."
            phase = "."

            tsv_line = [
                seqid,
                source,
                seq_type,
                start,
                region_end,
                score,
                strand,
                phase,
                attributes,
            ]
            tsv_line = "\t".join(tsv_line)
            gff.write(tsv_line + "\n")

            for protein in contig_protID[prediction]:
                if protein in prot_data.keys():
                    source = "Prodigal"
                    seq_type = "CDS"
                    start = prot_data[protein][0]
                    end = prot_data[protein][1]
                    if int(end) > int(region_end):
                        end = region_end
                    score = "."
                    strand = prot_data[protein][2]
                    phase = "0"
                    attributes = "ID=" + protein + ";gbkey=CDS;" + prot_data[protein][3]

                    tsv_line = [
                        seqid,
                        source,
                        seq_type,
                        start,
                        end,
                        score,
                        strand,
                        phase,
                        attributes,
                    ]
                    tsv_line = "\t".join(tsv_line)
                    gff.write(tsv_line + "\n")


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
            "Contig renaming selected but no contig file provided. Provide path to ENA contig "
            "file with --ena-contigs"
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
            "Provided sample ID is ignored with --rename-contigs option. ENA ERZ accession will be used"
        )
        ena_mapping = get_ena_contig_mapping(args.ena_contigs)
    else:
        ena_mapping = None

    logging.info("Collecting annotation data")
    annot_dicts = collect_annot(virify_files, args.sample_id, ena_mapping=ena_mapping)
    logging.info("Generating the gff output")
    write_gff(
        checkv_files,
        taxonomy_files,
        args.sample_id,
        args.assembly_file,
        annot_dicts,
        ena_mapping=ena_mapping,
    )
