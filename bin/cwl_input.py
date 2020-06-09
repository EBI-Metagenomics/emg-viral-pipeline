#!/usr/bin/env python

import yaml
import argparse


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate the input.yaml for the CWL pipeline")
    parser.add_argument("-i", dest="input_fasta",
                        required=True, help="Import contigs fasta file")
    parser.add_argument("-s", dest="virsorter_dir",
                        required=True, help="VirSorter data")
    parser.add_argument("-f", dest="virfinder_model",
                        required=True, help="VirFinder model")
    parser.add_argument("-a", dest="add_hmms_tsv",
                        required=True, help="additiona_hmms_metadata.tsv")
    parser.add_argument("-j", dest="hmmscan_db",
                        required=True, help="HMMSCAN database directory")
    parser.add_argument("-n", dest="ncbi_db",
                        required=True, help="NCBI Taxonomy database")
    parser.add_argument("-b", dest="img_db",
                        required=True, help="IMG/VR database directory")
    parser.add_argument("-p", dest="pprmeta_simg",
                        required=True, help="PPR-Meta singularity image")
    parser.add_argument("-v", dest="virome",
                        required=False,
                        help="Virome mode for virsorter")
    parser.add_argument("-m", dest="mashmap_ref",
                        required=False, help="Mashmap reference file")
    parser.add_argument("-o", dest="output_file",
                        required=True, help="Input yaml to generate.")
    args = parser.parse_args()

    with open(args.output_file, 'w') as file:
        file_content = {
            "input_fasta_file": {
                "class": "File",
                "path": args.input_fasta,
                "format": "http://edamontology.org/format_1929"
            },
            "virsorter_data_dir": {
                "class": "Directory",
                "path": args.virsorter_dir
            },
            "virfinder_model": {
                "class": "File",
                "format": "http://edamontology.org/format_2330",
                "path": args.virfinder_model
            },
            "add_hmms_tsv": {
                "class": "File",
                "path": args.add_hmms_tsv,
                "format": "http://edamontology.org/format_3475"
            },
            "hmmscan_database_dir": {
                "class": "Directory",
                "path": args.hmmscan_db
            },
            "ncbi_tax_db_file": {
                "class": "File",
                "path": args.ncbi_db
            },
            "img_blast_database_dir": {
                "class": "Directory",
                "path": args.img_db
            },
            "pprmeta_simg": {
                "class": "File",
                "path": args.pprmeta_simg
            }
        }
        if args.mashmap_ref:
            file_content["mashmap_reference_file"] = {
                "class": "File",
                "path": args.mashmap_ref
            }
        if args.virome:
            file_content["virsorter_virome"] = True
        yaml.dump(file_content, file)
