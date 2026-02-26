#!/bin/env python3

import os
import pandas as pd

from bin.viral_contigs_annotation import extract_annotations


class TestViralContigsAnnotation:
    """Test class for viral contigs annotation functionality."""

    @staticmethod
    def _build_path(folder):
        """Build absolute path to test fixtures."""
        return os.path.abspath("/" + os.path.dirname(__file__) + folder)

    def test_extract_annotations_basic(self):
        """Test basic functionality with all proteins having hits"""
        protein_file = self._build_path(
            "/viral_contigs_annotation_fixtures/test_proteins.faa"
        )
        ratio_file = self._build_path(
            "/viral_contigs_annotation_fixtures/test_ratio_evalue.tsv"
        )

        annotations = extract_annotations(protein_file, ratio_file)
        result_df = pd.DataFrame(
            annotations,
            columns=[
                "Contig",
                "CDS_ID",
                "Start",
                "End",
                "Direction",
                "Best_hit",
                "Abs_Evalue_exp",
                "Label",
            ],
        )

        # Check that we have the expected columns
        expected_columns = [
            "Contig",
            "CDS_ID",
            "Start",
            "End",
            "Direction",
            "Best_hit",
            "Abs_Evalue_exp",
            "Label",
        ]
        assert list(result_df.columns) == expected_columns

        # Check that we have 4 rows (one for each protein)
        assert len(result_df) == 4

        # Check specific values
        assert result_df.iloc[0]["Contig"] == "contig1"
        assert result_df.iloc[0]["CDS_ID"] == "contig1_1"
        assert result_df.iloc[0]["Start"] == "1"
        assert result_df.iloc[0]["End"] == "100"
        assert result_df.iloc[0]["Direction"] == "200"
        assert result_df.iloc[0]["Best_hit"] == "VPHOG_0001"
        assert result_df.iloc[0]["Abs_Evalue_exp"] == 1e-10
        assert result_df.iloc[0]["Label"] == "Caudo"

        # Check second protein
        assert result_df.iloc[1]["Contig"] == "contig1"
        assert result_df.iloc[1]["CDS_ID"] == "contig1_2"
        assert result_df.iloc[1]["Start"] == "2"
        assert result_df.iloc[1]["End"] == "200"
        assert result_df.iloc[1]["Direction"] == "400"
        assert result_df.iloc[1]["Best_hit"] == "VPHOG_0002"
        assert result_df.iloc[1]["Label"] == "Herelle"

    def test_extract_annotations_mixed_hits(self):
        """Test functionality with some proteins having hits and some not"""
        protein_file = self._build_path(
            "/viral_contigs_annotation_fixtures/test_proteins_mixed.faa"
        )
        ratio_file = self._build_path(
            "/viral_contigs_annotation_fixtures/test_ratio_evalue_mixed.tsv"
        )

        annotations = extract_annotations(protein_file, ratio_file)
        result_df = pd.DataFrame(
            annotations,
            columns=[
                "Contig",
                "CDS_ID",
                "Start",
                "End",
                "Direction",
                "Best_hit",
                "Abs_Evalue_exp",
                "Label",
            ],
        )

        # Check that we have 4 rows
        assert len(result_df) == 4

        # Check proteins with hits
        assert result_df.iloc[0]["Best_hit"] == "VPHOG_0001"
        assert result_df.iloc[1]["Best_hit"] == "VPHOG_0002"
        assert result_df.iloc[2]["Best_hit"] == "VPHOG_0005"

        # Check protein without hit (should have "No hit")
        assert result_df.iloc[3]["Best_hit"] == "No hit"
        assert result_df.iloc[3]["Abs_Evalue_exp"] == "NA"
        assert result_df.iloc[3]["Label"] == ""

    def test_extract_annotations_empty_protein_file(self, tmp_path):
        """Test functionality with empty protein file"""
        temp_protein = tmp_path / "empty_proteins.faa"
        temp_protein.write_text("")

        ratio_file = self._build_path(
            "/viral_contigs_annotation_fixtures/test_ratio_evalue.tsv"
        )

        annotations = extract_annotations(str(temp_protein), ratio_file)
        result_df = pd.DataFrame(
            annotations,
            columns=[
                "Contig",
                "CDS_ID",
                "Start",
                "End",
                "Direction",
                "Best_hit",
                "Abs_Evalue_exp",
                "Label",
            ],
        )

        # Should return empty DataFrame with correct columns
        assert len(result_df) == 0
        expected_columns = [
            "Contig",
            "CDS_ID",
            "Start",
            "End",
            "Direction",
            "Best_hit",
            "Abs_Evalue_exp",
            "Label",
        ]
        assert list(result_df.columns) == expected_columns

    def test_extract_annotations_multiple_hits_same_protein(self):
        """Test functionality when a protein has multiple hits (should pick best evalue)"""
        protein_file = self._build_path(
            "/viral_contigs_annotation_fixtures/multiple_hits_proteins.faa"
        )
        ratio_file = self._build_path(
            "/viral_contigs_annotation_fixtures/multiple_hits_ratio.tsv"
        )

        annotations = extract_annotations(protein_file, ratio_file)
        result_df = pd.DataFrame(
            annotations,
            columns=[
                "Contig",
                "CDS_ID",
                "Start",
                "End",
                "Direction",
                "Best_hit",
                "Abs_Evalue_exp",
                "Label",
            ],
        )

        # Should have one row
        assert len(result_df) == 1

        # Should pick the hit with best evalue (script uses max, so 1e-10 > 1e-20)
        assert result_df.iloc[0]["Best_hit"] == "VPHOG_0001"
        assert result_df.iloc[0]["Abs_Evalue_exp"] == 1e-10
        assert result_df.iloc[0]["Label"] == "Caudo"

    def test_extract_annotations_protein_description_parsing(self):
        """Test that protein description is parsed correctly"""
        protein_file = self._build_path(
            "/viral_contigs_annotation_fixtures/description_parsing_proteins.faa"
        )
        ratio_file = self._build_path(
            "/viral_contigs_annotation_fixtures/description_parsing_ratio.tsv"
        )

        annotations = extract_annotations(protein_file, ratio_file)
        result_df = pd.DataFrame(
            annotations,
            columns=[
                "Contig",
                "CDS_ID",
                "Start",
                "End",
                "Direction",
                "Best_hit",
                "Abs_Evalue_exp",
                "Label",
            ],
        )

        # Should parse description correctly
        assert len(result_df) == 1
        assert result_df.iloc[0]["CDS_ID"] == "contig1_1"
        assert result_df.iloc[0]["Start"] == "1"
        assert result_df.iloc[0]["End"] == "100"
        assert result_df.iloc[0]["Direction"] == "200"

    def test_extract_annotations_contig_id_extraction(self):
        """Test that contig ID is extracted correctly from protein ID"""
        protein_file = self._build_path(
            "/viral_contigs_annotation_fixtures/contig_id_extraction_proteins.faa"
        )
        ratio_file = self._build_path(
            "/viral_contigs_annotation_fixtures/contig_id_extraction_ratio.tsv"
        )

        annotations = extract_annotations(protein_file, ratio_file)
        result_df = pd.DataFrame(
            annotations,
            columns=[
                "Contig",
                "CDS_ID",
                "Start",
                "End",
                "Direction",
                "Best_hit",
                "Abs_Evalue_exp",
                "Label",
            ],
        )

        # Check contig ID extraction
        assert result_df.iloc[0]["Contig"] == "contig1"
        assert result_df.iloc[1]["Contig"] == "contig2"
        assert result_df.iloc[2]["Contig"] == "NODE_1_length_1000_cov_5"

    def test_extract_annotations_empty_proteins_file(self, tmp_path):
        """Test functionality with an empty proteins FASTA file (no protein sequences)"""

        temp_protein = tmp_path / "empty_proteins.faa"
        # Write empty FASTA file (just headers, no sequences)
        temp_protein.write_text("")

        ratio_file = self._build_path(
            "/viral_contigs_annotation_fixtures/test_ratio_evalue.tsv"
        )

        # Since extract_annotations now returns a list, we need to create DataFrame for testing
        annotations = extract_annotations(str(temp_protein), ratio_file)

        # Should return empty list (no proteins to process)
        assert len(annotations) == 0
        assert annotations == []

        # Verify it's a list, not a DataFrame
        assert isinstance(annotations, list)

    def test_extract_annotations_fragenescan_proteins_excluded(self):
        """Test that frageneScan proteins (without # delimiter) are excluded from output"""
        protein_file = self._build_path(
            "/viral_contigs_annotation_fixtures/with_fragenescan_proteins/mixed_proteins.faa"
        )
        ratio_file = self._build_path(
            "/viral_contigs_annotation_fixtures/with_fragenescan_proteins/mixed_ratio.tsv"
        )

        annotations = extract_annotations(protein_file, ratio_file)
        result_df = pd.DataFrame(
            annotations,
            columns=[
                "Contig",
                "CDS_ID",
                "Start",
                "End",
                "Direction",
                "Best_hit",
                "Abs_Evalue_exp",
                "Label",
            ],
        )

        # Should only have 2 rows (Prodigal format proteins), not 4
        assert len(result_df) == 2

        # Check that only Prodigal proteins are included
        assert result_df.iloc[0]["CDS_ID"] == "contig1_1"
        assert result_df.iloc[1]["CDS_ID"] == "contig3_1"

        # Check that frageneScan proteins are excluded
        excluded_ids = ["contig2_gene1", "contig4_gene2"]
        for cds_id in result_df["CDS_ID"]:
            assert cds_id not in excluded_ids
