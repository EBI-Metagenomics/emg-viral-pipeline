#!/bin/env python3

import os
import unittest
from pathlib import Path
from collections import namedtuple

from bin.contig_taxonomic_assign import main as contig_taxonomic_assign_main


class TestContigTaxonomicAssignation(unittest.TestCase):
    @property
    def _project_folder(self):
        file_path = os.path.dirname(__file__)
        return Path(file_path).parent

    @property
    def _fixtures_folder(self):
        return Path(os.path.dirname(__file__)) / "contig_taxonomic_assign"

    def test_correct_assignation(self):

        input_args = namedtuple(
            "input_args", "input_file ncbi_db factor outdir tax_thres"
        )

        args = {
            "input_file": str(self._fixtures_folder / "input_taxonomic_assignment.tsv"),
            "ncbi_db": str(self._fixtures_folder / "ete3_ncbi_tax_11_2022_lite.sqlite"),
            "factor": str(
                self._project_folder
                / "references/viphogs_cds_per_taxon_cummulative.csv"
            ),
            "outdir": str(self._fixtures_folder),
            "tax_thres": 0.6,
        }

        contig_taxonomic_assign_main(input_args(**args))

        # Compare file contents
        expected_file_content = []
        with open(self._fixtures_folder / "expected_assignment_taxonomy.tsv") as eh:
            expected_file_content = sorted(eh.readlines())

        output_file_content = []
        with open(
            self._fixtures_folder / "input_taxonomic_assignment_taxonomy.tsv"
        ) as oh:
            output_file_content = sorted(oh.readlines())

        self.assertListEqual(expected_file_content, output_file_content)

        Path(self._fixtures_folder / "input_taxonomic_assignment_taxonomy.tsv").unlink
