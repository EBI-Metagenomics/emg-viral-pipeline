import sys
import os
import logging
import argparse
import glob
import pandas as pd
from Bio import SeqIO
import gzip

logging.basicConfig(level=logging.INFO)


def get_ena_contig_mapping(ena_contig_file):
    ena_mapping = {}
    with gzip.open(ena_contig_file, 'rt') as ena_contigs:
        for record in SeqIO.parse(ena_contigs, "fasta"):
            ena_name = record.id
            contig_name = record.description.split(' ')[1]
            ena_mapping[contig_name] = ena_name
    return ena_mapping


def write_gff(virify_files, sample_prefix, ena_mapping=None):
    contigs = {}
    if ena_mapping:
        ena_assembly_accession = list(ena_mapping.values())[0].split('.')[0]
        output_filename = f'{ena_assembly_accession}_virify.gff'
    else:
        output_filename = f'{sample_prefix}_virify.gff'
    with open(output_filename, 'w') as gff:
        gff.write(f'##gff-version 3\n')
        #   annotation type specify this is virify confidence level
        for vfile in virify_files:
            virify_df = pd.read_csv(vfile, sep="\t")
            filtered_df = virify_df[virify_df["Best_hit"] != 'No hit']
            #   set lowest possible start and highest possible end
            for index, row in filtered_df.iterrows():
                if not row["Contig"] in contigs:
                    contigs[row["Contig"]] = {'start': row["Start"], 'end': row["End"]}
                else:
                    if contigs[row["Contig"]]['start'] > row["Start"]:
                        contigs[row["Contig"]]['start'] = row["Start"]
                    if contigs[row["Contig"]]['end'] < row["End"]:
                        contigs[row["Contig"]]['end'] = row["End"]
                #   remove '.faa' trailing viphog ID
                viphog = row["Best_hit"].strip('.faa')
                if row["Direction"] == '-1':
                    direction = '-'
                else:
                    direction = '+'
                #   change contig name if ena mapping required
                if ena_mapping:
                    contig_name = f'{ena_mapping[row["Contig"]]}-{row["Contig"]}'
                else:
                    contig_name = row["Contig"]
                #   ID=ERZ2271866.1-NODE-1-length-21396-cov-5.122534;viphog=ViPhOG1;viphog_taxonomy=Phaeovirus
                annotation = f'ID={contig_name};viphog={viphog};viphog_taxonomy={row["Label"]}'
                #   start with: ERZ2271866.1-NODE-1-length-21396-cov-5.122534	ViPhOG	proviral_region	1020	2050	.	-	.
                gff.write(f'{contig_name}\t{viphog}\tviral_sequence\t{row["Start"]}\t{row["End"]}\t.\t{direction}'
                          f'\t.\t{annotation}\n')
    return contigs


def write_metadata(checkv_files, taxonomy_files, sample_prefix, virify_contigs, ena_mapping=None):
    if ena_mapping:
        ena_assembly_accession = list(ena_mapping.values())[0].split('.')[0]
        output_filename = f'{ena_assembly_accession}_virify_contig_viewer_metadata.tsv'
    else:
        output_filename = f'{sample_prefix}_virify_contig_viewer_metadata.tsv'
    headers = 'sequence_id\tcontig\tvirify_taxonomy\tstart_of_first_viphog\tend_of_last_viphog\tcheckv_provirus\t' \
              'checkv_quality\tmiuvig_quality\n'
    checkv_dict, taxonomy_dict = {}, {}

    #   parse checkv for quality
    for cfile in checkv_files:
        checkv_df = pd.read_csv(cfile, sep="\t")
        for index, row in checkv_df.iterrows():
            if row["contig_id"] in virify_contigs:
                checkv_type = row["provirus"]
                checkv_dict[row["contig_id"]] = {'checkv_type': checkv_type, 'checkv_quality': row["checkv_quality"], 
                                                 'miuvig_quality': row["miuvig_quality"]}

    #   parse taxonomic lineage when available
    for tfile in taxonomy_files:
        taxonomy_df = pd.read_csv(tfile, sep='\t')
        for index, row in taxonomy_df.iterrows():
            if row["contig_ID"] in virify_contigs:
                contig_lineage = []
                for lineage in [row["order"], row["family"], row["subfamily"], row["genus"]]:
                    if '.' in str(lineage) or pd.isna(lineage):
                        contig_lineage.append('')
                    else:
                        contig_lineage.append(lineage)
                joined_lineage = ';'.join(contig_lineage)
                #set to unclassified if all levels are empty
                if joined_lineage == ';;;':
                    taxonomy_dict[row["contig_ID"]] = 'unclassified'
                else:
                    taxonomy_dict[row["contig_ID"]] = joined_lineage

    with open(output_filename, 'w') as metadata:
        metadata.write(headers)
        for contig in virify_contigs:
            #   change contig name if ena mapping required
            if ena_mapping:
                contig_name = f'{ena_mapping[contig]}-{contig}'
            else:
                contig_name = contig
            virify_taxonomy = taxonomy_dict[contig]
            sequence_start = virify_contigs[contig]['start']
            sequence_end = virify_contigs[contig]['end']
            sequence_id = f'{contig_name}-start-{sequence_start}-end-{sequence_end}'
            checkv_type = checkv_dict[contig]['checkv_type']
            checkv_quality = checkv_dict[contig]['checkv_quality']
            miuvig_quality = checkv_dict[contig]['miuvig_quality']
            metadata.write("\t".join([sequence_id,
                                      contig_name,
                                      virify_taxonomy,
                                      str(sequence_start),
                                      str(sequence_end),
                                      checkv_type,
                                      str(checkv_quality),
                                      str(miuvig_quality)]) + '\n')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate GFF and corresponding from VIRify output files" )
    parser.add_argument("-v", "--virify-folder", dest="virify_folder", help="Path to virify output folders",
                        required=True)
    parser.add_argument("-c", "--checkv-folder", dest="checkv_folder",
                        help="Path to checkV results folder, defaults to virify folder", required=False)
    parser.add_argument("-t", "--taxonomy-folder", dest="taxonomy_folder",
                        help="Path to checkV results folder, defaults to virify folder", required=False)
    parser.add_argument("-sv", "--suffix_virify", dest="virify_ext", help="file extension for virify outputs",
                        required=True)
    parser.add_argument("-sc", "--suffix_checkv", dest="checkv_ext", help="file extension for checkv outputs",
                        required=True)
    parser.add_argument("-st", "--suffix_taxonomy", dest="taxonomy_ext", help="file extension for taxonomy outputs",
                        required=True)
    parser.add_argument("-s", "--sample-id", dest="sample_id", help="sample_id to prefix output file name. "
                                                                    "Ignored with --rename-contigs option",
                        required=True)
    parser.add_argument("--rename-contigs", help="True if contigs needs renaming from ERR to ERZ", required=False,
                        action='store_true', default=False)
    parser.add_argument("--ena-contigs", dest="ena_contigs", help="Path to ENA contig file if renaming needed",
                        required=False)

    args = parser.parse_args()

    #    validate arguments
    if not args.checkv_folder:
        args.checkv_folder = args.virify_folder
    if not args.taxonomy_folder:
        args.taxonomy_folder = args.virify_folder

    if args.rename_contigs and not args.ena_contigs:
        logging.error('Contig renaming selected but no contig file provided. Provide path to ENA contig '
                      'file with --ena-contigs')

    virify_files = glob.glob(os.path.join(args.virify_folder, '*' + args.virify_ext))
    checkv_files = glob.glob(os.path.join(args.checkv_folder, '*' + args.checkv_ext))
    taxonomy_files = glob.glob(os.path.join(args.taxonomy_folder, '*' + args.taxonomy_ext))

    logging.info(f'found virify files: {virify_files}')
    logging.info(f'found checkV files: {checkv_files}')
    logging.info(f'found taxonomy files: {taxonomy_files}')

    if args.rename_contigs:
        logging.warning('Provided sample ID is ignored with --rename-contigs option. ENA ERZ accession will be used')
        ena_mapping = get_ena_contig_mapping(args.ena_contigs)
    else:
        ena_mapping = None

    logging.info('Generating GFF')
    virify_contigs = write_gff(virify_files, args.sample_id, ena_mapping=ena_mapping)
    logging.info('Generating metadata')
    write_metadata(checkv_files, taxonomy_files, args.sample_id, virify_contigs, ena_mapping=ena_mapping)
