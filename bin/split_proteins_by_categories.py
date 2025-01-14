#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright 2024 EMBL - European Bioinformatics Institute
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
"""
    Script to get proteins corresponding to fasta file
"""

import sys
import argparse
import re
import logging
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
        if start_prophage <= start_protein <= finish_prophage <= finish_protein \
            or start_protein <= start_prophage <= finish_protein <= finish_prophage \
            or start_prophage < start_protein <= finish_protein <= finish_prophage:
            if start_prophage <= start_protein <= finish_protein <= finish_prophage:
                self.logger.debug(f"Protein {prodigal_info[4:20]} inside {prophage_info}")
                return True
            else:
                self.logger.debug(f"Protein {prodigal_info[4:20]} intersects {prophage_info}")
                return False
        else:
            self.logger.debug(f'---- Protein {prodigal_info[4:20]} is not in {prophage_info}')
            return False
        
    def grep_proteins(self):
        fna_sequences = SeqIO.parse(self.input_file, 'fasta')
        protein_sequences = SeqIO.parse(self.proteins, 'fasta')
        proteins = {}
        for seq in protein_sequences:
            proteins[str(seq.id)] = seq
        already_added_protein_ids = {}
        with open(self.output_file, 'w') as out_file:
            for fna in fna_sequences:
                id, prophage_addition = None, None
                contig_name = fna.id.split('|')[0]   # ex. NODE_3_length_498519_cov_223.607530
                for i in proteins.keys():
                    if contig_name in i:
                        # if prophage
                        if len(fna.id.split('|')) > 1:  # ex. NODE_3_length_498519_cov_223.607530|prophage-81521:94004 or NODE_3_length_498519_cov_223.607530|phage-circular
                            prophage_addition = fna.id.split('|')[1]  # prophage-81521:94004 or phage-circular
                        id = i
                        already_added_protein_ids.setdefault(id, 0)
                        record = deepcopy(proteins[id])  # ex. >NODE_6_length_273677_cov_7.926969_6 # 2328 # 3188 # 1 # ID=1_6;partial=00;start_type=ATG;rbs_motif=GGA/GAG/AGG;rbs_spacer=5-10bp;gc_cont=0.237
                        protein_info = record.description.split(contig_name)[1]  #_6 # 2328 # 3188 # 1 # ID=1_6;partial=00;start_type=AT etc
                        protein_number = protein_info.split(' ')[0]
                        """
                        If we want to simulate proper prodigal work we need to change proteinID 
                        to new numbers starting with 1. Otherwise we have some skipping values from original faa
                        """
                        if prophage_addition:
                            if not self.check_coordinates(protein_info, prophage_addition):
                                continue
                            record.description = f'{contig_name}|{prophage_addition}{protein_info}'
                            record.id = f'{contig_name}|{prophage_addition}{protein_number}'
                            already_added_protein_ids[id] += 1
                        SeqIO.write(record, out_file, "fasta")
                if not id:
                    self.logger.info(f'No proteins found for {contig_name}')
        # for checking - that should not output anything
        for i in already_added_protein_ids:
            if already_added_protein_ids[i] > 1:
                self.logger.info(f'Added twice {i}')

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
