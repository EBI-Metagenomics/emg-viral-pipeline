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


import sys
import argparse
import re
import logging
from collections import defaultdict
from copy import deepcopy
from typing import Dict, Iterable, List, Optional, Tuple

from Bio import SeqIO
from Bio.SeqRecord import SeqRecord


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Grep proteins corresponding to input subset of contigs and add prophage annotations to protein headers (if present)")
    parser.add_argument("-i", "--input", dest="input", help="Input fasta file with subset of assembly contigs", required=True)
    parser.add_argument("-p", "--proteins-faa", dest="proteins_faa", help="Input fasta file with all assembly proteins", required=True)
    parser.add_argument("-g", "--proteins-gff", dest="proteins_gff", help="Input gff file with all assembly proteins",
                        required=True)
    parser.add_argument("-o", "--output", dest="output", help="Output file to write filtered proteins", required=True)
    parser.add_argument("-v", "--verbose", dest="verbose", help="Enable verbose logging mode", required=False,
                        action='store_true')
    return parser.parse_args(argv)


class SplitProteins:
    def __init__(
        self,
        input_file: str,
        proteins_faa: str,
        proteins_gff: str,
        output_file: str,
        verbose: bool,
    ):
        self.input_file = input_file
        self.proteins_faa = proteins_faa
        self.proteins_gff = proteins_gff
        self.output_file = output_file
        self.verbose = verbose
        self.setup_logging()
        self.logger = logging.getLogger(__name__)

    def setup_logging(self) -> None:
        """Configure root logger level and message format."""
        logging.basicConfig(
            level=logging.DEBUG if self.verbose else logging.INFO,
            format='%(asctime)s %(levelname)s - %(message)s'
        )

    def check_coordinates(self, protein_id: str, start_protein: int, finish_protein: int, prophage_info: str) -> bool:
        """Check whether a protein sufficiently overlaps a prophage interval.

        A protein is accepted if either protein or prophage coverage is > 90%.
        Circular prophages are always accepted.
        
        :param protein_id: Protein name for logging
        :param start_protein: Start coordinate
        :param finish_protein: Stop coordinate
        :param prophage_info: Prophage descriptor, e.g. prophage-100:200 or phage-circular.
        :return: True if protein should be retained, otherwise False.
        """
        if start_protein is None or finish_protein is None:
            raise ValueError(f"Incorrect protein info format: {protein_id}")

        protein_length = finish_protein - start_protein + 1

        # get coords for prophage
        if 'circular' in prophage_info:
            self.logger.debug("Circular phage found")
            return True

        coords = prophage_info.split('-')[1]
        start_prophage, finish_prophage = coords.split(':')
        start_prophage = int(start_prophage)
        finish_prophage = int(finish_prophage)
        prophage_length = finish_prophage - start_prophage + 1

        # Calculate overlap
        overlap_start = max(start_protein, start_prophage)
        overlap_end = min(finish_prophage, finish_protein)
        intersection = max(0, overlap_end - overlap_start + 1)

        # Make decision about protein
        if intersection:
            prophage_cov = intersection / prophage_length
            protein_cov = intersection / protein_length
            
            if prophage_cov > 0.9 or protein_cov > 0.9:
                self.logger.debug(f"Protein {protein_id} more than 90% inside {prophage_info}")
                return True
            else:
                self.logger.debug(f"Protein {protein_id} intersects {prophage_info}")
                return False
        else:
            self.logger.debug(f'---- Protein {protein_id} is not in {prophage_info}')
            return False

    @staticmethod
    def _parse_contig_id(contig_id: str) -> Tuple[str, Optional[str]]:
        """
        Split full contig id into base contig name and optional prophage suffix.
        
        Examples of expected contig id formats:
        NODE_3_length_498519_cov_223.607530
        ERZ21830300_185216_2719|prophage-100:200
        NODE_3_length_498519_cov_223.607530|phage-circular

        :param contig_id: Full contig identifier, potentially containing prophage info.
        :return: Tuple (contig_name, prophage_addition) where prophage_addition is None if not present.     
        """
        contig_name = contig_id.split('|')[0]
        contig_id_parts = contig_id.split('|', 1)
        prophage_addition = contig_id_parts[1] if len(contig_id_parts) > 1 else None
        return contig_name, prophage_addition

    def _parse_protein_id(self, record_description: str, contig_name: str, record_id: str) -> Tuple[str, str]:
        """Extract protein metadata suffix and protein number from record description.

        Examples of expected description formats:
        ERZ21830300_185216_2719 # 3320783 # 3379543 # -1 # ID=195062_2719;partial=00;start_type=GTG;rbs_motif=None;rbs_spacer=None;gc_cont=0.731
        NODE_6_length_273677_cov_7.926969_6 # 2328 # 3188 # 1 # ID=1_6;partial=00;start_type=ATG;rbs_motif=GGA/GAG/AGG;rbs_spacer=5-10bp;gc_cont=0.237
        MGYG000495417_00766 hypothetical protein
        
        Return:
        # 3320783 # 3379543 # -1 # ID=195062_2719;partial=00;start_type=GTG;rbs_motif=None;rbs_spacer=None;gc_cont=0.731, 2719
        # 2328 # 3188 # 1 # ID=1_6;partial=00;start_type=ATG;rbs_motif=GGA/GAG/AGG;rbs_spacer=5-10bp;gc_cont=0.237, _6
        hypothetical protein, ''

        :param record_description: Full FASTA description line.
        :param contig_name: Contig name expected inside description.
        :param record_id: FASTA ID from protein header.
        :return: Tuple (protein_info_suffix, protein_number_token).
        """
        split_description = record_description.split(contig_name, 1)
        if len(split_description) != 2:
            self.logger.debug(
                f"Contig '{contig_name}' not found in record description: {record_description}. "
                f"Will use originl protein name"
            )
            protein_id = record_id
            protein_info = record_description.split(record_id)[1].strip()
            protein_number = ""
        else:
            protein_id = contig_name
            protein_info = ' '.join(split_description[1].split(' ')[1:])
            protein_number = split_description[1].split(' ')[0]
        return protein_id, protein_info, protein_number

    def _parse_attrs(self, attrs_str):
        """Return (dict, ordered-key-list) from a GFF column-9 string."""
        attrs, order = {}, []
        for part in attrs_str.rstrip(";").split(";"):
            part = part.strip()
            if "=" in part:
                k, v = part.split("=", 1)
                if k not in attrs:
                    order.append(k)
                attrs[k] = v
        return attrs, order

    def _read_gff(
        self,
        protein_gff: str,
        protein_records: Iterable[SeqRecord],
    ) -> Dict[str, List[SeqRecord]]:
        """
        Build protein lookup table keyed by contig name. Build protein lookup for coordinates
        
        :param protein_gff: GFF input file corresponding to protein fasta sequences
        :param protein_records: Iterable of SeqRecord objects representing proteins.
        :return: Dictionary mapping contig names to lists of associated protein records.
                 Dictionary mapping protein ID with start and stop coordinates
        """
        self.logger.debug("Mapping proteins to contigs using GFF...")
        protein_stats = {}
        proteins_by_contig = defaultdict(list)
        with open(protein_gff, 'r') as file_in:
            for line in file_in:
                if line.startswith('#'):
                    continue
                line = line.strip().split('\t')
                if len(line) == 9:
                    record = line[2]
                    if record != 'CDS':
                        continue
                    contig = line[0]
                    start = line[3]
                    end = line[4]
                    strand = line[6]
                    attrs, _ = self._parse_attrs(line[8])
                    protein_id = attrs.get("ID", "").strip()
                    protein_stats[protein_id] = {"start": int(start), "end": int(end), "strand": strand, "contig": contig}
                    
        self.logger.debug("Mapping protein sequences to contigs using FAA...")
        for record in protein_records:
            protein_id = record.id
            if protein_id in protein_stats:
                contig_name = protein_stats[protein_id]["contig"]
                proteins_by_contig[contig_name].append(record)
        return proteins_by_contig, protein_stats

    def grep_proteins(self) -> None:
        """Write proteins that belong to input contigs, with optional prophage filtering.

        :raises ValueError: If input identifiers do not conform to expected formats.
            Also raised if no proteins are written or duplicate protein ids are detected.
        """
        self.logger.info("Parsing input contigs FASTA file...")
        contig_records = SeqIO.parse(self.input_file, 'fasta')
        self.logger.info("Parsing input proteins FASTA file...")
        protein_records = SeqIO.parse(self.proteins_faa, 'fasta')
        self.logger.info("Parsing input proteins GFF file...")
        proteins_by_contig, protein_stats = self._read_gff(self.proteins_gff, protein_records)

        self.logger.info("Filtering and writing matching proteins...")
        already_added_protein_ids = set()
        written_records = 0
        with open(self.output_file, 'w') as out_file:
            for contig_record in contig_records:
                contig_name, prophage_addition = self._parse_contig_id(contig_record.id)

                matching_proteins = proteins_by_contig.get(contig_name, [])
                if not matching_proteins:
                    self.logger.info(f'No proteins found for {contig_name}')
                
                for protein_record in matching_proteins:
                    protein_id = protein_record.id

                    # TODO: If we want to simulate proper Prodigal naming scheme we need to change proteinID
                    # to new numbers starting with 1. Otherwise we have some skipped numbers in the output fasta
                    if prophage_addition:
                        self.logger.debug(f"Checking coordinates for protein {protein_id} against prophage info {prophage_addition}")
                        protein_id_short, protein_info, protein_number = self._parse_protein_id(protein_record.description, contig_name, protein_id)
                        stats = protein_stats.get(protein_id)
                        if not self.check_coordinates(protein_id, stats["start"] if stats else None, stats["end"] if stats else None, prophage_addition):
                            continue
                        print(protein_info)
                        record = deepcopy(protein_record)
                        record.description = f'{protein_info}'
                        if protein_number:
                            record.id = f'{protein_id_short.split()[0]}|{prophage_addition}{protein_number}'
                        else:
                            record.id = f'{protein_id_short.split()[0]}|{prophage_addition}'
                    else:
                        record = protein_record

                    if protein_id in already_added_protein_ids:
                        raise ValueError(f"Protein added more than once: {protein_id}")
                    
                    SeqIO.write(record, out_file, "fasta")
                    already_added_protein_ids.add(protein_id)
                    written_records += 1

        if written_records == 0:
            self.logger.warning(
                'No proteins matched contigs from input fasta. '
                'Check contig naming between input fasta and proteins fasta.'
            )
        self.logger.info(f"Finished writing {written_records} proteins to {self.output_file}")


def main():
    args = parse_args(sys.argv[1:])
    splitter = SplitProteins(
        input_file=args.input,
        proteins_faa=args.proteins_faa,
        proteins_gff=args.proteins_gff,
        output_file=args.output,
        verbose=args.verbose,
    )
    splitter.grep_proteins()


if __name__ == "__main__":
    main()
