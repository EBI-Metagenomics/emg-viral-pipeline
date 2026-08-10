import gzip
import os
import tempfile
import unittest
from pathlib import Path

from bin.check_proteins_compatibility import (
    MATCHED,
    NOT_MATCHED,
    REQUIRE_RENAME,
    check_compatibility,
    write_status,
)


def _write_tmp(content: str, suffix: str = "") -> str:
    with tempfile.NamedTemporaryFile(mode="w", suffix=suffix, delete=False) as tmp:
        tmp.write(content)
    return tmp.name


class TestCheckCompatibility(unittest.TestCase):
    def setUp(self):
        self._to_remove = []

    def tearDown(self):
        for path in self._to_remove:
            if os.path.exists(path):
                os.unlink(path)

    def _files(self, fasta: str, faa: str, gff: str) -> tuple[str, str, str]:
        fasta_path = _write_tmp(fasta, ".fasta")
        faa_path = _write_tmp(faa, ".faa")
        gff_path = _write_tmp(gff, ".gff")
        self._to_remove.extend([fasta_path, faa_path, gff_path])
        return fasta_path, faa_path, gff_path

    def test_already_renamed_long_format_is_matched(self):
        fasta = ">contig_1 description\nACGTACGTACGT\n"
        faa = (
            ">contig_1_1 # 1 # 100 # +1 # ID=1_1;partial=00\n"
            "MKV*\n"
            ">contig_1_2 # 101 # 200 # +1 # ID=1_2;partial=00\n"
            "MKV*\n"
        )
        gff = (
            "##gff-version 3\n"
            "contig_1\tProdigal\tCDS\t1\t100\t.\t+\t0\tID=contig_1_1;partial=00\n"
            "contig_1\tProdigal\tCDS\t101\t200\t.\t+\t0\tID=contig_1_2;partial=00\n"
        )
        fasta_path, faa_path, gff_path = self._files(fasta, faa, gff)
        self.assertEqual(check_compatibility(fasta_path, faa_path, gff_path), MATCHED)

    def test_plain_short_format_requires_rename(self):
        fasta = ">contig_1 description\nACGTACGTACGT\n"
        faa = (
            ">1_1 # 1 # 100 # +1 # ID=1_1;partial=00\n"
            "MKV*\n"
            ">1_2 # 101 # 200 # +1 # ID=1_2;partial=00\n"
            "MKV*\n"
        )
        gff = (
            "##gff-version 3\n"
            "contig_1\tProdigal\tCDS\t1\t100\t.\t+\t0\tID=1_1;partial=00\n"
            "contig_1\tProdigal\tCDS\t101\t200\t.\t+\t0\tID=1_2;partial=00\n"
        )
        fasta_path, faa_path, gff_path = self._files(fasta, faa, gff)
        self.assertEqual(
            check_compatibility(fasta_path, faa_path, gff_path), REQUIRE_RENAME
        )

    def test_short_format_but_unknown_gff_contig_is_not_matched(self):
        """gff/faa look like short-format prodigal output, but the gff contig
        isn't one of the fasta's contigs, so renaming can't be trusted."""
        fasta = ">contig_1 description\nACGTACGTACGT\n"
        faa = ">1_1 # 1 # 100 # +1 # ID=1_1;partial=00\nMKV*\n"
        gff = (
            "##gff-version 3\n"
            "unknown_contig\tProdigal\tCDS\t1\t100\t.\t+\t0\tID=1_1;partial=00\n"
        )
        fasta_path, faa_path, gff_path = self._files(fasta, faa, gff)
        self.assertEqual(
            check_compatibility(fasta_path, faa_path, gff_path), NOT_MATCHED
        )

    def test_unrelated_files_are_not_matched(self):
        fasta = ">assembly_A description\nACGTACGTACGT\n"
        faa = ">zzz_9_9 # 1 # 100 # +1 # ID=9_9;partial=00\nMKV*\n"
        gff = (
            "##gff-version 3\n"
            "other_contig\tProdigal\tCDS\t1\t100\t.\t+\t0\tID=9_9;partial=00\n"
        )
        fasta_path, faa_path, gff_path = self._files(fasta, faa, gff)
        self.assertEqual(
            check_compatibility(fasta_path, faa_path, gff_path), NOT_MATCHED
        )

    def test_dots_and_undersore(self):
        fasta = ">assembly.A\nACGTACGTACGT\n"
        faa = ">assembly_A_1 # 1 # 100 # +1 # ID=9_9;partial=00\nMKV*\n"
        gff = (
            "##gff-version 3\n"
            "assembly_A\tProdigal\tCDS\t1\t100\t.\t+\t0\tID=assembly_A_1;partial=00\n"
        )
        fasta_path, faa_path, gff_path = self._files(fasta, faa, gff)
        self.assertEqual(
            check_compatibility(fasta_path, faa_path, gff_path), NOT_MATCHED
        )

    def test_empty_gff_is_not_matched(self):
        fasta = ">contig_1 description\nACGTACGTACGT\n"
        faa = ">contig_1_1 # 1 # 100 # +1 # ID=1_1;partial=00\nMKV*\n"
        gff = "##gff-version 3\n"
        fasta_path, faa_path, gff_path = self._files(fasta, faa, gff)
        self.assertEqual(
            check_compatibility(fasta_path, faa_path, gff_path), NOT_MATCHED
        )

    def test_mag_with_genome_wide_protein_numbering_is_matched(self):
        """Regression test for a real MAG (MGYG000495417) with pre-annotated,
        already long-format proteins.

        Unlike the small hand-written fixtures above, this genome has multiple
        contigs (MGYG000495417_1, MGYG000495417_2, ...) and protein IDs that
        are numbered sequentially across the whole genome rather than per
        contig (MGYG000495417_00001, MGYG000495417_00002, ...), so a protein
        ID does not embed its contig's ID as a prefix.

        The original implementation compared contig_ids against faa_headers
        (instead of gff_contig_ids against contig_ids), which happened to
        work for the single-contig "contig_N_M" style fixtures above but
        returned NOT_MATCHED for this genome, since no fasta contig ID is a
        substring of any protein header.
        """
        fixtures = Path(__file__).parent / "test_data"
        fasta_path = str(fixtures / "MGYG000495417.fna")
        faa_path = str(fixtures / "MGYG000495417.faa")
        gff_path = str(fixtures / "MGYG000495417.gff")
        self.assertEqual(check_compatibility(fasta_path, faa_path, gff_path), MATCHED)

    def test_gzipped_inputs_are_supported(self):
        fasta = ">contig_1 description\nACGTACGTACGT\n"
        faa = ">1_1 # 1 # 100 # +1 # ID=1_1;partial=00\nMKV*\n"
        gff = (
            "##gff-version 3\n"
            "contig_1\tProdigal\tCDS\t1\t100\t.\t+\t0\tID=1_1;partial=00\n"
        )

        with tempfile.NamedTemporaryFile(suffix=".fasta.gz", delete=False) as f:
            fasta_path = f.name
        with tempfile.NamedTemporaryFile(suffix=".faa.gz", delete=False) as f:
            faa_path = f.name
        with tempfile.NamedTemporaryFile(suffix=".gff.gz", delete=False) as f:
            gff_path = f.name
        self._to_remove.extend([fasta_path, faa_path, gff_path])

        with gzip.open(fasta_path, "wt") as f:
            f.write(fasta)
        with gzip.open(faa_path, "wt") as f:
            f.write(faa)
        with gzip.open(gff_path, "wt") as f:
            f.write(gff)

        self.assertEqual(
            check_compatibility(fasta_path, faa_path, gff_path), REQUIRE_RENAME
        )


class TestWriteStatus(unittest.TestCase):
    def test_creates_named_marker_file(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            write_status(tmp_dir, MATCHED)
            self.assertTrue(os.path.exists(os.path.join(tmp_dir, MATCHED)))

    def test_creates_output_dir_if_missing(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            nested = os.path.join(tmp_dir, "nested", "dir")
            write_status(nested, REQUIRE_RENAME)
            self.assertTrue(os.path.exists(os.path.join(nested, REQUIRE_RENAME)))


if __name__ == "__main__":
    unittest.main()
