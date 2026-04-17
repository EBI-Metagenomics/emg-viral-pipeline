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
    parser = argparse.ArgumentParser(description="Grep corresponding proteins")
    parser.add_argument("-i", "--input", dest="input", help="Input fasta file", required=True)
    parser.add_argument("-p", "--proteins", dest="proteins", help="Input proteins file", required=True)
    parser.add_argument("-o", "--output", dest="output", help="Output file", required=True)
    parser.add_argument("-v", "--verbose", dest="verbose", help="Print more logging", required=False,
                        action='store_true')
    return parser.parse_args(argv)


class SplitProteins:
    def __init__(
        self,
        input_file: str,
        proteins: str,
        output_file: str,
        verbose: bool,
    ):
        self.input_file = input_file
        self.proteins = proteins
        self.output_file = output_file
        self.verbose = verbose
        self.protein_id_re = re.compile(
            r"^(?P<contig_name>.+)_(?P<protein_number>\d+)$"
        )
        self.prodigal_coords_re = re.compile(r"_(\d+)\s*#\s*(\d+)\s*#\s*(\d+)\s*#*")
        self.setup_logging()
        self.logger = logging.getLogger(__name__)

    def setup_logging(self) -> None:
        """Configure root logger level and message format."""
        logging.basicConfig(
            level=logging.DEBUG if self.verbose else logging.INFO,
            format='%(asctime)s %(levelname)s - %(message)s'
        )

    def check_coordinates(self, prodigal_info: str, prophage_info: str) -> bool:
        """Check whether a protein sufficiently overlaps a prophage interval.

        A protein is accepted if either protein or prophage coverage is > 90%.
        Circular prophages are always accepted.

        :param prodigal_info: Prodigal annotation substring containing coordinates.
        :param prophage_info: Prophage descriptor, e.g. prophage-100:200 or phage-circular.
        :return: True if protein should be retained, otherwise False.
        """
        # get coords for protein
        match_prodigal = self.prodigal_coords_re.search(prodigal_info)
        if match_prodigal:
            start_protein = int(match_prodigal.group(2))
            finish_protein = int(match_prodigal.group(3))
            protein_length = finish_protein - start_protein + 1
        else:
            raise ValueError(f"Incorrect protein info format: {prodigal_info}")

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
                self.logger.debug(f"Protein {prodigal_info[4:20]} more than 90% inside {prophage_info}")
                return True
            else:
                self.logger.debug(f"Protein {prodigal_info[4:20]} intersects {prophage_info}")
                return False
        else:
            self.logger.debug(f'---- Protein {prodigal_info[4:20]} is not in {prophage_info}')
            return False

    def _get_contig_name_from_protein_id(self, protein_id: str) -> str:
        """Extract contig id from a protein id using regex matching.

        Examples of expected protein id format:
        ERZ21830300_185216_2719 -> contig id is ERZ21830300_185216
        NODE_6_length_273677_cov_7.926969_6 -> contig id is NODE_6_length_273677_cov_7.926969

        :param protein_id: Protein identifier in <contig_id>_<number> format.
        :return: Contig id component.
        """
        match = self.protein_id_re.match(protein_id)
        if not match:
            raise ValueError(f"Invalid protein id format: {protein_id}")
        return match.group('contig_name')

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

    @staticmethod
    def _parse_protein_id(record_description: str, contig_name: str) -> Tuple[str, str]:
        """Extract protein metadata suffix and protein number from record description.

        Examples of expected description formats:
        ERZ21830300_185216_2719 # 3320783 # 3379543 # -1 # ID=195062_2719;partial=00;start_type=GTG;rbs_motif=None;rbs_spacer=None;gc_cont=0.731
        NODE_6_length_273677_cov_7.926969_6 # 2328 # 3188 # 1 # ID=1_6;partial=00;start_type=ATG;rbs_motif=GGA/GAG/AGG;rbs_spacer=5-10bp;gc_cont=0.237

        :param record_description: Full FASTA description line.
        :param contig_name: Contig name expected inside description.
        :return: Tuple (protein_info_suffix, protein_number_token).
        """
        split_description = record_description.split(contig_name, 1)
        if len(split_description) != 2:
            raise ValueError(
                f"Unable to extract protein info for contig '{contig_name}' from record: {record_description}"
            )
        protein_info = split_description[1]
        protein_number = protein_info.split(' ')[0]
        return protein_info, protein_number

    def _map_proteins_to_contig(
        self,
        protein_records: Iterable[SeqRecord],
    ) -> Dict[str, List[SeqRecord]]:
        """
        Build protein lookup table keyed by contig name.
        
        :param protein_records: Iterable of SeqRecord objects representing proteins.
        :return: Dictionary mapping contig names to lists of associated protein records.
        """
        self.logger.debug("Mapping proteins to contigs...")
        proteins_by_contig = defaultdict(list)
        for record in protein_records:
            protein_id = record.id
            contig_name = self._get_contig_name_from_protein_id(protein_id)
            proteins_by_contig[contig_name].append(record)
        return proteins_by_contig

    def grep_proteins(self) -> None:
        """Write proteins that belong to input contigs, with optional prophage filtering.

        :raises ValueError: If input identifiers do not conform to expected formats.
            Also raised if no proteins are written or duplicate protein ids are detected.
        """
        self.logger.info("Parsing input contigs FASTA file...")
        contig_records = SeqIO.parse(self.input_file, 'fasta')
        self.logger.info("Parsing input proteins FASTA file...")
        protein_records = SeqIO.parse(self.proteins, 'fasta')
        proteins_by_contig = self._map_proteins_to_contig(protein_records)

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
                    record = deepcopy(protein_record)
                    protein_info, protein_number = self._parse_protein_id(record.description, contig_name)

                    # TODO: If we want to simulate proper Prodigal naming scheme we need to change proteinID
                    # to new numbers starting with 1. Otherwise we have some skipped numbers in the output fasta
                    if prophage_addition:
                        self.logger.debug(f"Checking coordinates for protein {protein_id} against prophage info {prophage_addition}")
                        if not self.check_coordinates(protein_info, prophage_addition):
                            continue
                        record.description = f'{contig_name}|{prophage_addition}{protein_info}'
                        record.id = f'{contig_name}|{prophage_addition}{protein_number}'
                    
                    if protein_id in already_added_protein_ids:
                        raise ValueError(f"Protein added more than once: {protein_id}")
                    
                    SeqIO.write(record, out_file, "fasta")
                    already_added_protein_ids.add(protein_id)
                    written_records += 1

        if written_records == 0:
            raise ValueError(
                'No proteins matched contigs from input fasta. '
                'Check contig naming between input fasta and proteins fasta.'
            )
        self.logger.info(f"Finished writing {written_records} proteins to {self.output_file}")


def main():
    args = parse_args(sys.argv[1:])
    splitter = SplitProteins(
        input_file=args.input,
        proteins=args.proteins,
        output_file=args.output,
        verbose=args.verbose,
    )
    splitter.grep_proteins()


if __name__ == "__main__":
    main()
