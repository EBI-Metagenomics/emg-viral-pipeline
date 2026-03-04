#!/bin/env python3

import os
import unittest
from pathlib import Path
from collections import namedtuple

import pandas as pd

from bin.contig_taxonomic_assign import main as contig_taxonomic_assign_main
from bin.contig_taxonomic_assign import contig_tax


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
            "input_args", "input_file ncbi_db factor outdir tax_thres version4"
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
            "version4": True,
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

    def test_50_50_tie_leaves_subfamily_unassigned(self):
        """A perfect 50/50 tie between two subfamilies must leave the rank empty.

        When two taxa each contribute one hit and neither crosses the 0.6
        threshold, both share an identical hit_diff. Picking the first one
        encountered would make the result depend on file-ordering (which
        differs between use_proteins and non-use_proteins runs). The fix
        leaves the rank unassigned instead.
        """
        output_taxa_order = [
            "contig_ID",
            "superkingdom",
            "kingdom",
            "phylum",
            "subphylum",
            "class",
            "order",
            "suborder",
            "family",
            "subfamily",
            "genus",
        ]

        # One hit to Sepvirinae, one hit to Guernseyvirinae — exact 50/50 tie.
        # Both taxa are present in the lite test NCBI database (verified by the
        # existing test fixtures).  With tax_thres=0.6 each has prop_hits=0.5
        # and hit_diff=1, so they are genuinely tied.
        annot_df = pd.DataFrame(
            {
                "Contig": ["CONTIG_TIE", "CONTIG_TIE"],
                "Best_hit": ["ViPhOG_A.faa", "ViPhOG_B.faa"],
                "Label": ["Sepvirinae", "Guernseyvirinae"],
            }
        )

        results = list(
            contig_tax(
                annot_df=annot_df,
                ncbi_db=str(
                    self._fixtures_folder / "ete3_ncbi_tax_11_2022_lite.sqlite"
                ),
                tax_thres=0.6,
                taxon_factor_dict={},
                output_taxa_order=output_taxa_order,
                exclude_deprecated_taxa=False,
            )
        )

        self.assertEqual(len(results), 1)

        result_dict = dict(zip(output_taxa_order, results[0]))

        self.assertEqual(result_dict["contig_ID"], "CONTIG_TIE")
        self.assertEqual(
            result_dict["subfamily"],
            "",
            "A 50/50 tie must leave subfamily unassigned to avoid file-order artefacts",
        )

    def test_under_thres_selects_smaller_hit_diff(self):
        """When all candidates fall below threshold, the one with the smallest hit_diff wins.

        Two hits to Sepvirinae, one to Guernseyvirinae, tax_thres=0.9:
        - Sepvirinae:     prop=2/3 ≈ 0.67, hit_diff = ceil(0.9*3) - 2 = 1
        - Guernseyvirinae: prop=1/3 ≈ 0.33, hit_diff = ceil(0.9*3) - 1 = 2

        Sepvirinae is uniquely closest to the threshold so it should be selected,
        not left unassigned.
        """
        output_taxa_order = [
            "contig_ID",
            "superkingdom",
            "kingdom",
            "phylum",
            "subphylum",
            "class",
            "order",
            "suborder",
            "family",
            "subfamily",
            "genus",
        ]

        annot_df = pd.DataFrame(
            {
                "Contig": ["CONTIG_WINNER"] * 3,
                "Best_hit": ["ViPhOG_A.faa", "ViPhOG_B.faa", "ViPhOG_C.faa"],
                "Label": ["Sepvirinae", "Sepvirinae", "Guernseyvirinae"],
            }
        )

        results = list(
            contig_tax(
                annot_df=annot_df,
                ncbi_db=str(
                    self._fixtures_folder / "ete3_ncbi_tax_11_2022_lite.sqlite"
                ),
                tax_thres=0.9,
                taxon_factor_dict={},
                output_taxa_order=output_taxa_order,
                exclude_deprecated_taxa=False,
            )
        )

        self.assertEqual(len(results), 1)
        # contig_lineage is built in reversed-rank order (genus first) so we
        # cannot zip with output_taxa_order; assertIn on the raw row is sufficient.
        self.assertIn(
            "Sepvirinae",
            results[0],
            "Candidate with smaller hit_diff (Sepvirinae) should be selected",
        )
        self.assertNotIn(
            "Guernseyvirinae",
            results[0],
            "Candidate with larger hit_diff (Guernseyvirinae) must not appear",
        )
