#!/bin/env python3

import gzip
import os
import re
import tempfile
import unittest

from bin.rename_prodigal import parse_attrs, read_faa, rename_proteins_in_gff

TEST_DATA = os.path.join(os.path.dirname(__file__), "rename_prodigal")

_GFF_COLS = "contig\tsource\tCDS\t1\t100\t.\t+\t0\t"


def _write_tmp(content: str) -> str:
    tmp = tempfile.NamedTemporaryFile(mode="w", suffix=".gff", delete=False)
    tmp.write(content)
    tmp.close()
    return tmp.name


class TestParseAttrs(unittest.TestCase):
    def test_simple_attrs(self):
        attrs, order = parse_attrs("ID=1_1;partial=00;start_type=ATG")
        self.assertEqual(attrs["ID"], "1_1")
        self.assertEqual(attrs["partial"], "00")
        self.assertEqual(attrs["start_type"], "ATG")
        self.assertEqual(order, ["ID", "partial", "start_type"])

    def test_trailing_semicolon(self):
        attrs, order = parse_attrs("ID=foo;bar=baz;")
        self.assertEqual(attrs["ID"], "foo")
        self.assertEqual(attrs["bar"], "baz")
        self.assertEqual(order, ["ID", "bar"])

    def test_no_id(self):
        attrs, order = parse_attrs("partial=00;start_type=ATG")
        self.assertNotIn("ID", attrs)
        self.assertEqual(order, ["partial", "start_type"])

    def test_duplicate_key_keeps_last(self):
        attrs, order = parse_attrs("ID=first;ID=second")
        self.assertEqual(attrs["ID"], "second")
        self.assertEqual(order, ["ID"])


class TestReadFaa(unittest.TestCase):
    def test_reads_protein_names(self):
        faa = os.path.join(TEST_DATA, "prophages_prodigal.faa")
        names = read_faa(faa)
        self.assertIn("MGYG000495417_3|prophage-23410:59937_1", names)
        self.assertIn("MGYG000495417_4|prophage-587472:685913_1", names)

    def test_does_not_include_sequence_lines(self):
        faa = os.path.join(TEST_DATA, "prophages_prodigal.faa")
        names = read_faa(faa)
        for name in names:
            self.assertFalse(name.startswith(">"))

    def test_reads_gzipped_faa(self):
        faa = os.path.join(TEST_DATA, "prophages_prodigal.faa")
        with open(faa) as f:
            content = f.read()

        gz_path = tempfile.NamedTemporaryFile(suffix=".faa.gz", delete=False).name
        try:
            with gzip.open(gz_path, "wt") as f:
                f.write(content)
            names = read_faa(gz_path)
            self.assertIn("MGYG000495417_3|prophage-23410:59937_1", names)
            self.assertIn("MGYG000495417_4|prophage-587472:685913_1", names)
        finally:
            os.unlink(gz_path)


class TestRenameProteinsInGff(unittest.TestCase):
    def test_output_matches_expected(self):
        gff = os.path.join(TEST_DATA, "prophages_prodigal.gff")
        faa = os.path.join(TEST_DATA, "prophages_prodigal.faa")
        expected_gff = os.path.join(TEST_DATA, "expected", "renamed.gff")

        protein_names = read_faa(faa)
        output_path = _write_tmp("")
        try:
            rename_proteins_in_gff(gff, protein_names, output_path)
            with open(output_path) as got, open(expected_gff) as exp:
                self.assertEqual(got.read(), exp.read())
        finally:
            os.unlink(output_path)

    def test_output_matches_expected_with_gzipped_inputs(self):
        gff = os.path.join(TEST_DATA, "prophages_prodigal.gff")
        faa = os.path.join(TEST_DATA, "prophages_prodigal.faa")
        expected_gff = os.path.join(TEST_DATA, "expected", "renamed.gff")

        with open(gff) as f:
            gff_content = f.read()
        with open(faa) as f:
            faa_content = f.read()

        gff_gz_path = tempfile.NamedTemporaryFile(suffix=".gff.gz", delete=False).name
        faa_gz_path = tempfile.NamedTemporaryFile(suffix=".faa.gz", delete=False).name
        output_path = _write_tmp("")
        try:
            with gzip.open(gff_gz_path, "wt") as f:
                f.write(gff_content)
            with gzip.open(faa_gz_path, "wt") as f:
                f.write(faa_content)

            protein_names = read_faa(faa_gz_path)
            rename_proteins_in_gff(gff_gz_path, protein_names, output_path)
            with open(output_path) as got, open(expected_gff) as exp:
                self.assertEqual(got.read(), exp.read())
        finally:
            for p in (gff_gz_path, faa_gz_path, output_path):
                os.unlink(p)

    def test_comment_lines_pass_through(self):
        gff = os.path.join(TEST_DATA, "prophages_prodigal.gff")
        faa = os.path.join(TEST_DATA, "prophages_prodigal.faa")
        protein_names = read_faa(faa)

        output_path = _write_tmp("")
        try:
            rename_proteins_in_gff(gff, protein_names, output_path)
            with open(output_path) as f:
                lines = f.readlines()
            comment_lines = [line for line in lines if line.startswith("#")]
            self.assertTrue(len(comment_lines) > 0)
        finally:
            os.unlink(output_path)

    def test_ids_are_renamed_to_long_format(self):
        gff = os.path.join(TEST_DATA, "prophages_prodigal.gff")
        faa = os.path.join(TEST_DATA, "prophages_prodigal.faa")
        protein_names = read_faa(faa)

        output_path = _write_tmp("")
        try:
            rename_proteins_in_gff(gff, protein_names, output_path)
            with open(output_path) as f:
                for line in f:
                    if line.startswith("#") or not line.strip():
                        continue
                    fields = line.strip().split("\t")
                    if len(fields) == 9 and fields[2] == "CDS":
                        attrs, _ = parse_attrs(fields[8])
                        protein_id = attrs.get("ID", "")
                        self.assertFalse(
                            re.fullmatch(r"\d+_\d+", protein_id),
                            f"Short-format ID found in output: {protein_id}",
                        )
        finally:
            os.unlink(output_path)

    def test_cds_with_unrecognised_id_passes_through(self):
        """CDS whose ID is already in long format must be written unchanged."""
        long_id = "CONTIG_1|prophage-100:200_5"
        gff_content = _GFF_COLS + f"ID={long_id};partial=00\n"
        gff_path = _write_tmp(gff_content)
        faa_path = _write_tmp("")
        output_path = _write_tmp("")
        try:
            rename_proteins_in_gff(gff_path, set(), output_path)
            with open(output_path) as f:
                result = f.read()
            self.assertIn(f"ID={long_id}", result)
        finally:
            for p in (gff_path, faa_path, output_path):
                os.unlink(p)

    def test_cds_not_in_faa_passes_through_with_original_id(self):
        """CDS whose renamed protein is absent from FAA must be written with its original ID."""
        gff_content = _GFF_COLS + "ID=1_3;partial=00\n"
        gff_path = _write_tmp(gff_content)
        output_path = _write_tmp("")
        try:
            rename_proteins_in_gff(gff_path, set(), output_path)
            with open(output_path) as f:
                result = f.read()
            self.assertIn("ID=1_3", result)
        finally:
            for p in (gff_path, output_path):
                os.unlink(p)

    def test_cds_without_id_passes_through(self):
        """CDS line with no ID attribute must still appear in output."""
        gff_content = _GFF_COLS + "partial=00;start_type=ATG\n"
        gff_path = _write_tmp(gff_content)
        output_path = _write_tmp("")
        try:
            rename_proteins_in_gff(gff_path, set(), output_path)
            with open(output_path) as f:
                result = f.read()
            self.assertIn("partial=00", result)
        finally:
            for p in (gff_path, output_path):
                os.unlink(p)


if __name__ == "__main__":
    unittest.main()
