#!/usr/bin/env python3
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
import csv
import logging
import sys

from Bio import SeqIO


def parse_args(argv: list[str]) -> argparse.Namespace:
    """Parse and return command-line arguments."""
    parser = argparse.ArgumentParser(
        description=(
            "Discard assembly contigs that have no CDS features in the proteins GFF, "
            "so they never reach the viral prediction tools."
        )
    )
    parser.add_argument(
        "-i",
        "--input",
        dest="input",
        help="Input assembly FASTA with temporary contig names (seq1, seq2, ...)",
        required=True,
    )
    parser.add_argument(
        "-m",
        "--map",
        dest="mapfile",
        help="Mapping TSV produced by rename_fasta.py (original/temporary/short)",
        required=True,
    )
    parser.add_argument(
        "-g",
        "--proteins-gff",
        dest="proteins_gff",
        help="Input GFF file with all assembly proteins, in short contig-name space",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--output",
        dest="output",
        help="Output FASTA with the protein-less contigs removed",
        required=True,
    )
    parser.add_argument(
        "--dropped-report",
        dest="dropped_report",
        help="Output TSV listing the discarded contigs",
        required=False,
        default=None,
    )
    parser.add_argument(
        "-v",
        "--verbose",
        dest="verbose",
        help="Enable verbose logging mode",
        required=False,
        action="store_true",
    )
    return parser.parse_args(argv)


class FilterContigsNoProteins:
    def __init__(
        self,
        input_file: str,
        mapfile: str,
        proteins_gff: str,
        output_file: str,
        verbose: bool,
        dropped_report: str | None = None,
    ) -> None:
        """Initialise the FilterContigsNoProteins instance.

        :param input_file: Path to the assembly FASTA using temporary contig names.
        :param mapfile: Path to the rename_fasta.py mapping TSV.
        :param proteins_gff: Path to the GFF3 file with CDS features for all assembly proteins.
        :param output_file: Path for the filtered FASTA output.
        :param verbose: Enable DEBUG-level logging when True.
        :param dropped_report: Optional path for the TSV report of discarded contigs.
        """
        self.input_file = input_file
        self.mapfile = mapfile
        self.proteins_gff = proteins_gff
        self.output_file = output_file
        self.verbose = verbose
        self.dropped_report = dropped_report
        self.setup_logging()
        self.logger = logging.getLogger(__name__)

    def setup_logging(self) -> None:
        """Configure root logger level and message format."""
        logging.basicConfig(
            level=logging.DEBUG if self.verbose else logging.INFO,
            format="%(asctime)s %(levelname)s - %(message)s",
        )

    def _contigs_with_cds(self) -> set[str]:
        """Collect the names of contigs carrying at least one CDS feature.

        Names are in the short name space, matching the assembly the proteins were
        called on.  Comment lines are skipped, so a contig declared only by a
        ``##sequence-region`` header or a prodigal ``# Sequence Data:`` comment does
        not count as having proteins.

        :return: Set of contig names with one or more CDS records.
        """
        contigs = set()
        with open(self.proteins_gff, "r") as file_in:
            for line in file_in:
                if line.startswith("#"):
                    continue
                if line.startswith(">"):
                    # The FASTA section of a combined GFF; no features beyond this point.
                    break
                cols = line.rstrip("\n").split("\t")
                if len(cols) == 9 and cols[2] == "CDS":
                    contigs.add(cols[0])
        self.logger.info(f"Found {len(contigs)} contigs with at least one CDS")
        return contigs

    def _read_mapping(self) -> dict[str, tuple[str, str]]:
        """Read the rename mapping.

        :return: Mapping of temporary contig name to (short name, original name).
        """
        mapping = {}
        with open(self.mapfile, "r") as map_tsv:
            for row in csv.DictReader(map_tsv, delimiter="\t"):
                mapping[row["temporary"]] = (row["short"], row["original"])
        self.logger.info(f"Read {len(mapping)} contig name mappings")
        return mapping

    def _write_dropped_report(self, dropped_contigs: list[str]) -> None:
        """Write a TSV listing the discarded contigs, using their original names.

        The file is always created, empty apart from its header when nothing was
        dropped, so the calling process can declare it as a non-optional output.

        :param dropped_contigs: Original names of the contigs that were discarded.
        """
        with open(self.dropped_report, "w") as report_out:
            print("contig\treason", file=report_out)
            for contig in dropped_contigs:
                print(f"{contig}\tno CDS on contig", file=report_out)

    def filter_contigs(self) -> None:
        """Write the input assembly without the contigs that have no CDS."""
        self.logger.info("Parsing input proteins GFF file...")
        contigs_with_cds = self._contigs_with_cds()

        self.logger.info("Parsing contig name mapping...")
        mapping = self._read_mapping()

        self.logger.info("Filtering contigs...")
        kept, dropped_contigs = 0, []

        with open(self.output_file, "w") as out_file:
            for record in SeqIO.parse(self.input_file, "fasta"):
                short_name, original_name = mapping.get(
                    record.id, (record.id, record.id)
                )
                if record.id not in mapping:
                    # Keep anything we cannot resolve rather than dropping it silently.
                    self.logger.warning(
                        f"Contig {record.id} is missing from the mapping file; keeping it"
                    )
                elif short_name not in contigs_with_cds:
                    self.logger.debug(f"Discarding {original_name}: no CDS on contig")
                    dropped_contigs.append(original_name)
                    continue

                SeqIO.write(record, out_file, "fasta")
                kept += 1

        if self.dropped_report:
            self._write_dropped_report(dropped_contigs)

        if dropped_contigs:
            self.logger.warning(
                f"Discarded {len(dropped_contigs)} contigs with no proteins"
            )
        if kept == 0:
            self.logger.warning(
                "No contigs left after filtering; this assembly has no contigs with proteins."
            )
        self.logger.info(f"Finished writing {kept} contigs to {self.output_file}")


def main() -> None:
    """Entry point: parse arguments and run FilterContigsNoProteins."""
    args = parse_args(sys.argv[1:])
    contig_filter = FilterContigsNoProteins(
        input_file=args.input,
        mapfile=args.mapfile,
        proteins_gff=args.proteins_gff,
        output_file=args.output,
        verbose=args.verbose,
        dropped_report=args.dropped_report,
    )
    contig_filter.filter_contigs()


if __name__ == "__main__":
    main()
