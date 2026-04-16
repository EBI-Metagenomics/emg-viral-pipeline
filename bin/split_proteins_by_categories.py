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
from Bio import SeqIO


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
        self.protein_id_re = re.compile(r"^(?P<contig_name>.+)_(?P<protein_number>\d+)$")
        self.setup_logging()
        self.logger = logging.getLogger(__name__)

    def setup_logging(self):
        # Configure logging
        logging.basicConfig(
            level=logging.DEBUG if self.verbose else logging.INFO,
            format='%(asctime)s %(levelname)s - %(message)s'
        )
        
    def check_coordinates(self, prodigal_info, prophage_info):
        start_protein, finish_protein, start_prophage, finish_prophage = [None for _ in range(4)]
        # ger coords for protein
        match_prodigal = re.search(r"_(\d+)\s*#\s*(\d+)\s*#\s*(\d+)\s*#*", prodigal_info)
        if match_prodigal:
            start_protein = int(match_prodigal.group(2))
            finish_protein = int(match_prodigal.group(3))
            protein_length = finish_protein - start_protein + 1
        else:
            self.logger.error('incorrect protein info')
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
        
    def grep_proteins(self):
        contigs = SeqIO.parse(self.input_file, 'fasta')
        protein_sequences = SeqIO.parse(self.proteins, 'fasta')
        proteins = {}
        proteins_by_contig = defaultdict(list)
        for seq in protein_sequences:
            protein_id = seq.id
            proteins[protein_id] = seq
            # Expected Prodigal protein id examples:
            # ERZ21830300_185216_2719 # 3320783 # 3379543 # -1 # ID=195062_2719;partial=00;start_type=GTG;rbs_motif=None;rbs_spacer=None;gc_cont=0.731
            # NODE_6_length_273677_cov_7.926969_6 # 2328 # 3188 # 1 # ID=1_6;partial=00;start_type=ATG;rbs_motif=GGA/GAG/AGG;rbs_spacer=5-10bp;gc_cont=0.237
            match = self.protein_id_re.match(protein_id)
            if not match:
                raise ValueError(f"Invalid protein id format: {protein_id}")
            contig_name = match.group('contig_name')
            proteins_by_contig[contig_name].append(protein_id)

        already_added_protein_ids = set()
        written_records = 0
        with open(self.output_file, 'w') as out_file:
            for contig in contigs:
                contig_name = contig.id.split('|')[0]   # ex. NODE_3_length_498519_cov_223.607530
                contig_id_parts = contig.id.split('|', 1)
                prophage_addition = contig_id_parts[1] if len(contig_id_parts) > 1 else None

                matching_protein_ids = proteins_by_contig.get(contig_name, [])
                if not matching_protein_ids:
                    self.logger.info(f'No proteins found for {contig_name}')
                
                for protein_id in matching_protein_ids:
                    record = deepcopy(proteins[protein_id])  # ex. >NODE_6_length_273677_cov_7.926969_6 # 2328 # 3188 # 1 # ID=1_6;partial=00;start_type=ATG;rbs_motif=GGA/GAG/AGG;rbs_spacer=5-10bp;gc_cont=0.237
                    protein_info = record.description.split(contig_name)[1]  # 2328 # 3188 # 1 # ID=1_6;partial=00;start_type=ATG;rbs_motif=GGA/GAG/AGG;rbs_spacer=5-10bp;gc_cont=0.237
                    protein_number = protein_info.split(' ')[0]
                    # TODO: If we want to simulate proper Prodigal naming scheme we need to change proteinID
                    # to new numbers starting with 1. Otherwise we have some skipped numbers in the output fasta
                    if prophage_addition:
                        if not self.check_coordinates(protein_info, prophage_addition):
                            continue
                        record.description = f'{contig_name}|{prophage_addition}{protein_info}'
                        record.id = f'{contig_name}|{prophage_addition}{protein_number}'
                    
                    if protein_id in already_added_protein_ids:
                        raise RuntimeError(f"Protein added more than once: {protein_id}")
                    
                    SeqIO.write(record, out_file, "fasta")
                    already_added_protein_ids.add(protein_id)
                    written_records += 1

        if written_records == 0:
            raise RuntimeError(
                'No proteins matched contigs from input fasta. '
                'Check contig naming between input fasta and proteins fasta.'
            )


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
