#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright 2024-2026 EMBL - European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import gzip
import logging
import sys
import re
from typing import IO

from constants import PRODIGAL_RENAMED_ID_REGEXP
from utils import parse_attrs

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")


def parse_args(argv: list[str]) -> argparse.Namespace:
    """Parse and return command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Change protein IDs from short format into Contig_ID"
    )
    parser.add_argument(
        "-p",
        "--proteins-faa",
        dest="proteins_faa",
        help="Input fasta file with all assembly proteins",
        required=True,
    )
    parser.add_argument(
        "-g",
        "--proteins-gff",
        dest="proteins_gff",
        help="Input gff file with all assembly proteins",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--output",
        dest="output",
        help="Output GFF file with long names",
        required=True,
    )
    return parser.parse_args(argv)


def open_file(filename: str) -> IO[str]:
    """Open a file, handling both gzipped and plain text formats.

    :param filename: Path to file (.gz or uncompressed).
    :return: Text-mode file handle.
    """
    if filename.endswith(".gz"):
        return gzip.open(filename, "rt")
    return open(filename, "r")


def read_faa(proteins: str) -> set[str]:
    protein_names = set()
    with open_file(proteins) as file_in:
        for line in file_in:
            if not line.startswith(">"):
                continue
            protein_id = line.strip().split(" ")[0].replace(">", "")
            protein_names.add(protein_id)
    return protein_names


def rename_proteins_in_gff(gff: str, protein_names: set[str], output: str) -> None:
    """
    Function renames ID in prodigal gff from digit_digit to protein name in prodigal header in faa file
    Example, 
    gff: ID=1_1;partial=00;start_type=ATG...
    faa: >MGYG000495417_3|prophage-23410:59937_1 # 1 # 498 # -1 # ID=1_1;partial=00
    output gff: ID=MGYG000495417_3|prophage-23410:59937_1;partial=00;start_type=ATG ...
    :param gff: prodigal gff
    :param protein_names: list of unique protein headers from prodigal faa 
    :param output: output corrected gff
    :return: -
    """
    with open_file(gff) as file_in, open(output, "w") as file_out:
        for line in file_in:
            if line.startswith("#"):
                file_out.write(line)
                continue
            fields = line.strip().split("\t")
            if len(fields) > 9:
                raise ValueError(f"Incorrect number of records in gff {fields}")
            if len(fields) != 9:
                file_out.write("\t".join(fields) + "\n")
                continue
            contig_id = fields[0]
            if fields[2] != "CDS":
                file_out.write("\t".join(fields) + "\n")
                continue
            attrs, _ = parse_attrs(fields[8])
            protein_id = attrs.get("ID")
            if not protein_id:
                logging.warning("No ID in: %s", "\t".join(fields))
                file_out.write("\t".join(fields) + "\n")
                continue
            if not re.fullmatch(PRODIGAL_RENAMED_ID_REGEXP, protein_id):
                # prodigal renames IDs in gff attributes to shorter format like 1_1
                # if ID is already in long format or unrecognised pattern; pass through
                file_out.write("\t".join(fields) + "\n")
                continue
            protein_suffix = protein_id.rsplit("_", 1)[-1]
            new_protein = f"{contig_id}_{protein_suffix}"
            if new_protein not in protein_names:
                logging.warning("%s was not found in FAA", new_protein)
                file_out.write("\t".join(fields) + "\n")
                continue
            new_attr = fields[8].replace(f"ID={protein_id}", f"ID={new_protein}")
            file_out.write("\t".join(fields[:8] + [new_attr]) + "\n")


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    protein_names = read_faa(args.proteins_faa)
    rename_proteins_in_gff(args.proteins_gff, protein_names, args.output)
