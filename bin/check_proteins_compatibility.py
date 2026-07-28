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
import os
import re
import sys
from typing import IO

from constants import PRODIGAL_RENAMED_ID_REGEXP
from utils import parse_attrs

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

MATCHED = "matched"
REQUIRE_RENAME = "require_rename"
NOT_MATCHED = "not_matched"


def parse_args(argv: list[str]) -> argparse.Namespace:
    """Parse and return command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Check whether a user-supplied fasta/faa/gff triplet is "
        "internally consistent, and whether the faa/gff still use prodigal's "
        "short-format protein IDs and therefore need renaming."
    )
    parser.add_argument(
        "-f",
        "--fasta",
        dest="fasta",
        help="Assembly fasta file the proteins were predicted from",
        required=True,
    )
    parser.add_argument(
        "-p",
        "--proteins-faa",
        dest="proteins_faa",
        help="Prodigal-format fasta file with predicted proteins",
        required=True,
    )
    parser.add_argument(
        "-g",
        "--proteins-gff",
        dest="proteins_gff",
        help="Prodigal-format gff file with predicted proteins",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--output-dir",
        dest="output_dir",
        help="Directory in which the status marker file (matched, "
        "require_rename or not_matched) will be created",
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


def read_fasta_headers(fasta: str) -> set[str]:
    """Read a fasta file and return the first whitespace-token of every header."""
    headers = set()
    with open_file(fasta) as file_in:
        for line in file_in:
            if not line.startswith(">"):
                continue
            headers.add(line.strip()[1:].split()[0])
    return headers


def read_faa_headers(proteins: str) -> list[str]:
    """Read a prodigal-format faa file and return the full header lines
    (without the leading ">"), so they can be searched for substrings.
    """
    headers = []
    with open_file(proteins) as file_in:
        for line in file_in:
            if not line.startswith(">"):
                continue
            headers.append(line.strip()[1:])
    return headers


def read_gff_cds(gff: str) -> list[tuple[str, str]]:
    """Read a prodigal-format gff file and return (contig_id, protein_id)
    for every CDS record that has an ID attribute.
    """
    entries = []
    with open_file(gff) as file_in:
        for line in file_in:
            if line.startswith("#"):
                continue
            fields = line.strip().split("\t")
            if len(fields) != 9 or fields[2] != "CDS":
                continue
            attrs, _ = parse_attrs(fields[8])
            protein_id = attrs.get("ID")
            if not protein_id:
                logging.warning("No ID in: %s", "\t".join(fields))
                continue
            entries.append((fields[0], protein_id))
    return entries


def is_short_format(protein_ids: set[str]) -> bool:
    """Return True if every protein ID matches prodigal's short ID format."""
    return bool(protein_ids) and all(
        re.fullmatch(PRODIGAL_RENAMED_ID_REGEXP, protein_id)
        for protein_id in protein_ids
    )


def check_compatibility(fasta: str, proteins_faa: str, proteins_gff: str) -> str:
    """Determine whether the fasta/faa/gff triplet is already fully
    consistent (matched), consistent but still using prodigal's short-format
    IDs (require_rename), or inconsistent (not_matched).

    :return: One of MATCHED, REQUIRE_RENAME or NOT_MATCHED.
    """
    contig_ids = read_fasta_headers(fasta)
    faa_headers = read_faa_headers(proteins_faa)
    faa_protein_ids = {header.split()[0] for header in faa_headers}
    gff_entries = read_gff_cds(proteins_gff)
    gff_ids = {protein_id for _, protein_id in gff_entries}
    gff_contig_ids = {contig_id for contig_id, _ in gff_entries}

    if not contig_ids or not faa_headers or not gff_entries:
        logging.warning("One of fasta/faa/gff is empty")
        return NOT_MATCHED

    if is_short_format(faa_protein_ids) and is_short_format(gff_ids):
        contigs_correspond = gff_contig_ids <= contig_ids
        ids_correspond = gff_ids == faa_protein_ids
        if contigs_correspond and ids_correspond:
            return REQUIRE_RENAME
        return NOT_MATCHED

    contigs_included = all(
        any(contig_id in header for header in faa_headers) for contig_id in contig_ids
    )
    gff_ids_included = all(
        any(protein_id in header for header in faa_headers) for protein_id in gff_ids
    )
    if contigs_included and gff_ids_included:
        return MATCHED

    return NOT_MATCHED


def write_status(output_dir: str, status: str) -> None:
    """Create an empty marker file named after the status in output_dir."""
    os.makedirs(output_dir, exist_ok=True)
    open(os.path.join(output_dir, status), "w").close()


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    result = check_compatibility(args.fasta, args.proteins_faa, args.proteins_gff)
    logging.info("Compatibility check result: %s", result)
    write_status(args.output_dir, result)
