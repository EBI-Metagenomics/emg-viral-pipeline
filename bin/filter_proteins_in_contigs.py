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

from __future__ import annotations

import argparse
import logging
import re
import sys
from pathlib import Path

from Bio import SeqIO


logger = logging.getLogger(__name__)

# Matches the Prodigal coordinate block in a protein header description:
# <gene_num> # <start> # <stop> # <strand> #
# e.g. "NODE_1_1 # 2 # 232 # 1 # ID=1_1;partial=00;..."
_PRODIGAL_PATTERN = re.compile(r"#\s*\d+\s*#\s*\d+\s*#\s*[+-]?1\s*#")


def parse_args(argv: list[str]) -> argparse.Namespace:
    """Parse command-line arguments.

    :param argv: list of command-line argument strings
    :type argv: list[str]
    :return: parsed arguments namespace
    :rtype: argparse.Namespace
    """
    parser = argparse.ArgumentParser(
        description=(
            "Filter a proteins FAA file, keeping only proteins that belong "
            "to contigs present in the given contigs FASTA file."
        )
    )
    parser.add_argument(
        "-p",
        "--proteins",
        required=True,
        type=Path,
        help="Input proteins FASTA (.faa), optionally gzipped",
    )
    parser.add_argument(
        "-c",
        "--contigs",
        required=True,
        type=Path,
        help="Contigs FASTA whose IDs define the allowed set",
    )
    parser.add_argument(
        "-o",
        "--output",
        required=True,
        type=Path,
        help="Output proteins FASTA (.faa)",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        default=False,
        help="Enable debug logging",
    )
    return parser.parse_args(argv)


def get_contig_ids(contigs_fasta: Path) -> set[str]:
    """Parse a FASTA file and return the set of contig IDs.

    The ID is the part of the header before the first whitespace character,
    with the leading '>' stripped.

    :param contigs_fasta: path to the contigs FASTA file
    :type contigs_fasta: Path
    :return: set of contig IDs
    :rtype: set[str]
    """
    return {record.id for record in SeqIO.parse(str(contigs_fasta), "fasta")}


def protein_belongs_to_contigs(protein_id: str, contig_ids: set[str]) -> bool:
    """Determine whether a protein belongs to one of the given contigs.

    A protein is considered to belong to a contig when its ID starts with
    ``<contig_id>_``.  This is consistent with Prodigal-style headers.

    Underscore suffixes are checked from the longest possible contig match
    (all underscores) down to the shortest, to handle contig names that
    themselves contain underscores.

    :param protein_id: the protein sequence identifier (no leading '>')
    :type protein_id: str
    :param contig_ids: set of allowed contig identifiers
    :type contig_ids: set[str]
    :return: True if the protein belongs to a contig in *contig_ids*
    :rtype: bool
    """
    parts = protein_id.split("_")
    # Try every possible split point from longest prefix to shortest
    for i in range(len(parts) - 1, 0, -1):
        candidate = "_".join(parts[:i])
        if candidate in contig_ids:
            return True
    return False


def filter_proteins(
    proteins_fasta: Path,
    contig_ids: set[str],
    output_fasta: Path,
) -> tuple[int, int, int]:
    """Filter out the proteins that do not belong to the contig_ids, this is done
    by using the Prodigal/Pyrodigal metadata in the proteins.

    :param proteins_fasta: path to the input proteins FASTA
    :type proteins_fasta: Path
    :param contig_ids: set of contig IDs to keep proteins for
    :type contig_ids: set[str]
    :param output_fasta: path to the output proteins FASTA
    :type output_fasta: Path
    :return: tuple of (total proteins seen, proteins written, non-prodigal skipped)
    :rtype: tuple[int, int, int]
    """
    total = 0
    written = 0
    non_prodigal = 0
    with open(output_fasta, "w") as out_fh:
        for record in SeqIO.parse(str(proteins_fasta), "fasta"):
            total += 1
            if not protein_belongs_to_contigs(record.id, contig_ids):
                logger.debug(f"Skipping {record.id} (protein not in filtered assembly)")
                continue
            if not _PRODIGAL_PATTERN.search(record.description):
                logger.debug(f"Skipping {record.id} (not Prodigal format)")
                non_prodigal += 1
                continue
            SeqIO.write(record, out_fh, "fasta")
            written += 1
    return total, written, non_prodigal


def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv if argv is not None else sys.argv[1:])

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)s - %(message)s",
    )

    logger.info(f"Loading contig IDs from {args.contigs}")
    contig_ids = get_contig_ids(args.contigs)
    logger.info(f"Found {len(contig_ids)} contigs")

    if not contig_ids:
        raise ValueError(f"No contigs found in {args.contigs} — output will be empty")

    logger.info(f"Filtering proteins from {args.proteins}")

    total, written, non_prodigal = filter_proteins(
        args.proteins, contig_ids, args.output
    )

    if written == 0:
        raise ValueError("No proteins after the filtering step.")

    removed_contig = total - written - non_prodigal

    logger.info(
        f"Kept {written} / {total} proteins "
        f"(removed {removed_contig} from filtered-out contigs, {non_prodigal} non-Prodigal format)"
    )
    if non_prodigal:
        logger.warning(
            f"{non_prodigal} proteins were removed because their headers lack Prodigal coordinate metadata"
        )


if __name__ == "__main__":
    main()
