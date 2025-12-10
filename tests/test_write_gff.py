#!/bin/env python3

import os
import unittest
import glob
import hashlib

from bin.parse_viral_pred import Record
from bin.write_viral_gff import (
    aggregate_annotations,
    write_gff,
    get_contig_lengths_per_contig,
)


class TestWriteGFF(unittest.TestCase):
    def _build_path(self, folder):
        return os.path.abspath("/" + os.path.dirname(__file__) + folder)

    def test_record_clean_method(self):
        inputs = [
            "pos.phage.0|prophage-21696:135184_3",
            "justAtest**3,x|prophage-21:184_888",
            "NODE_1_length_79063_cov_13.902377",
            "NODE_2_length_876543_cov_16.902388|phage-circular",
            "NODE_3_length_637829_cov_11.42453|prophage-100:500",
            "NODE_3_length_637829_cov_11.42453|prophage-21696:135184",
        ]
        expected = [
            "pos.phage.0_3",
            "justAtest**3,x_888",
            "NODE_1_length_79063_cov_13.902377",
            "NODE_2_length_876543_cov_16.902388",
            "NODE_3_length_637829_cov_11.42453",
            "NODE_3_length_637829_cov_11.42453",
        ]
        inputs_cleaned = map(Record.remove_prophage_from_contig, inputs)
        self.assertListEqual(list(inputs_cleaned), expected)

    def test_record_prophage_metadata_extract(self):
        inputs = [
            "pos.phage.0|prophage-21696:135184_3",
            "justAtest**3,x|prophage-21:184_888",
            "NODE_1_length_79063_cov_13.902377",
            "NODE_2_length_876543_cov_16.902388|phage-circular",
            "NODE_3_length_637829_cov_11.42453|prophage-100:500",
            "NODE_3_length_637829_cov_11.42453|prophage-21696:135184",
        ]
        expected = [
            (21696, 135184, False),
            (21, 184, False),
            (None, None, False),
            (None, None, True),
            (100, 500, False),
            (21696, 135184, False),
        ]
        extraction = map(Record.get_prophage_metadata_from_contig, inputs)
        self.assertListEqual(list(extraction), expected)

    def test_gff_making(self):
        annotation_files = glob.glob(
            self._build_path("/write_gff_fixtures/annotations") + "/*.tsv"
        )
        checkv_files = glob.glob(
            self._build_path("/write_gff_fixtures/checkv") + "/*.tsv"
        )
        taxonomy_files = glob.glob(
            self._build_path("/write_gff_fixtures/taxonomy") + "/*.tsv"
        )
        assembly_file = self._build_path("/write_gff_fixtures") + "/assembly.fasta"

        # Load contig lengths for the test
        contigs_len_dict = get_contig_lengths_per_contig(assembly_file)

        viral_sequences, cds_annotations, virify_quality = aggregate_annotations(
            annotation_files, contigs_len_dict
        )

        write_gff(
            checkv_files,
            taxonomy_files,
            "pos.phage.0",
            assembly_file,
            viral_sequences,
            cds_annotations,
            virify_quality,
            contigs_len_dict,
        )

        # The file generated will be called: "pos.phage.0_virify.gff"
        # 8c2452a3f7f46c88471da8faad8ec027 -> expected checksum

        with (
            open("pos.phage.0_virify.gff", "rb") as generated_fh,
            open(
                self._build_path("/write_gff_fixtures/expected/pos.phage.0_virify.gff"),
                "rb",
            ) as exptected_fh,
        ):
            generated = str(sorted(generated_fh.readlines()))
            exptected = str(sorted(exptected_fh.readlines()))

        self.assertEqual(
            hashlib.md5(generated.encode("utf-8")).hexdigest(),
            hashlib.md5(exptected.encode("utf-8")).hexdigest(),
        )

        if os.path.exists("pos.phage.0_virify.gff"):
            os.unlink("pos.phage.0_virify.gff")

    def test_prophage_coordinate_truncation_in_gff(self):
        """Test that prophage coordinates exceeding contig length are truncated in GFF output."""

        assembly_fasta = (
            self._build_path("/write_gff_circular_visorter2_fixtures")
            + "/assembly.fasta"
        )
        annotations_tsv = (
            self._build_path("/write_gff_circular_visorter2_fixtures")
            + "/annotations.tsv"
        )
        checkv_tsv = (
            self._build_path("/write_gff_circular_visorter2_fixtures") + "/checkv.tsv"
        )
        taxonomy_tsv = (
            self._build_path("/write_gff_circular_visorter2_fixtures") + "/taxonomy.tsv"
        )

        # Load contig lengths for testing
        contigs_len_dict = get_contig_lengths_per_contig(assembly_fasta)

        # Test the aggregate_annotations function with contig lengths (new functionality)
        viral_sequences, cds_annotations, virify_quality = aggregate_annotations(
            [annotations_tsv], contigs_len_dict, False
        )

        # Verify that prophage coordinates were truncated in the viral_sequences
        # Clarification -> the prophage annotation from VirSorter2 will have the contig name test_contig|prophage-500:1200
        # which contains the overhanging annotation, we shouldn't change this, users are warned about this in the README
        # But we do change this in the GFF otheriwse is invalid
        self.assertIn("test_contig|prophage-500:1200", viral_sequences)
        prophage_types = list(viral_sequences["test_contig|prophage-500:1200"])
        # Should contain the truncated coordinates, not the original ones
        self.assertTrue(any("prophage-500:1000" in s for s in prophage_types))
        self.assertFalse(any("prophage-500:1200" in s for s in prophage_types))

        # Test write_gff function
        write_gff(
            [checkv_tsv],
            [taxonomy_tsv],
            "test_sample",
            assembly_fasta,
            viral_sequences,
            cds_annotations,
            virify_quality,
            contigs_len_dict,
        )

        # Read the generated GFF and verify prophage coordinates were truncated
        with open("test_sample_virify.gff", "r") as gff_file:
            gff_content = gff_file.read()
            # The prophage end coordinate should be truncated from 1200 to 1000
            self.assertIn("prophage-500:1000", gff_content)
            self.assertNotIn("prophage-500:1200", gff_content)

        # Clean up
        if os.path.exists("test_sample_virify.gff"):
            os.unlink("test_sample_virify.gff")
