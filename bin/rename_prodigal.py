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
import logging
import sys
import re

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


def parse_attrs(attrs_str: str) -> tuple[dict[str, str], list[str]]:
    """Parse a GFF3 column-9 attributes string into a dict and an ordered key list.

    :param attrs_str: Semicolon-separated key=value attribute string from GFF column 9.
    :return: Tuple of (attrs dict, list of keys in original order).
    """
    attrs, order = {}, []
    for part in attrs_str.rstrip(";").split(";"):
        part = part.strip()
        if "=" in part:
            k, v = part.split("=", 1)
            if k not in attrs:
                order.append(k)
            attrs[k] = v
    return attrs, order


def read_faa(proteins: str) -> set[str]:
    protein_names = set()
    with open(proteins, "r") as file_in:
        for line in file_in:
            if not line.startswith(">"):
                continue
            protein_id = line.strip().split(" ")[0].replace(">", "")
            protein_names.add(protein_id)
    return protein_names


def rename_proteins_in_gff(gff: str, protein_names: set[str], output: str) -> None:
    with open(gff, "r") as file_in, open(output, "w") as file_out:
        for line in file_in:
            if line.startswith("#"):
                file_out.write(line)
                continue
            fields = line.strip().split("\t")
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
            if not re.fullmatch(r"\d+_\d+", protein_id):
                # ID is already in long format or unrecognised pattern; pass through
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
