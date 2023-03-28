#!/bin/env python3

import os
import unittest
import glob
import hashlib

from bin.parse_viral_pred import Record
from bin.write_viral_gff import aggregate_annotations, write_gff


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

        viral_sequences, cds_annotations = aggregate_annotations(annotation_files)

        write_gff(
            checkv_files,
            taxonomy_files,
            "pos.phage.0",
            assembly_file,
            viral_sequences,
            cds_annotations,
        )

        # The file generated will be called: "pos.phage.0_virify.gff"
        # 8c2452a3f7f46c88471da8faad8ec027 -> expected checksum

        with open("pos.phage.0_virify.gff", "rb") as generated_fh, open(
            self._build_path("/write_gff_fixtures/expected/pos.phage.0_virify.gff"),
            "rb",
        ) as exptected_fh:
            generated = str(sorted(generated_fh.readlines()))
            exptected = str(sorted(exptected_fh.readlines()))

        self.assertEqual(
            hashlib.md5(generated.encode("utf-8")).hexdigest(),
            hashlib.md5(exptected.encode("utf-8")).hexdigest(),
        )

        if os.path.exists("pos.phage.0_virify.gff"):
            os.unlink("pos.phage.0_virify.gff")
