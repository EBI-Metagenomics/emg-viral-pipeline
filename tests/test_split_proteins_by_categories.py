import hashlib
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

# The script is run as a subprocess below, so it needs "bin" on its PYTHONPATH
# to resolve its bare `from constants import ...` / `from utils import ...`
# imports, mirroring the `pythonpath = . bin` setting in pytest.ini used for
# in-process test imports.
SUBPROCESS_ENV = {**os.environ, "PYTHONPATH": os.path.join(os.getcwd(), "bin")}


def md5sum(path):
    return hashlib.md5(path.read_bytes()).hexdigest()


class SplitProteins(unittest.TestCase):
    def test_split_proteins_by_categories_simple(self):
        test_dir = tempfile.mkdtemp()
        output = Path(test_dir) / "simple.faa"

        cmd = [
            "python",
            "-m",
            "bin.split_proteins_by_categories",
            "-i",
            "tests/split_proteins/simple_input.fasta",
            "-p",
            "tests/split_proteins/simple_proteins.faa",
            "-g",
            "tests/split_proteins/simple_proteins.gff",
            "-o",
            str(output),
        ]

        result = subprocess.run(
            cmd, capture_output=True, text=True, env=SUBPROCESS_ENV, check=False
        )

        assert result.returncode == 0, result.stderr
        # file exists
        assert output.exists()
        content = output.read_text()
        # does NOT contain
        assert "prophage" not in content
        # line count
        assert len(content.splitlines()) == 6
        # FASTA sequence count
        assert content.count(">") == 3
        assert md5sum(output) == "0a97d555d64f08537679df9de1ebd5f3"

    def test_split_proteins_by_categories_prophages(self):
        test_dir = tempfile.mkdtemp()
        output = Path(test_dir) / "test_prophages_split.faa"

        cmd = [
            "python",
            "-m",
            "bin.split_proteins_by_categories",
            "-i",
            "tests/split_proteins/test_prophages.fna",
            "-p",
            "tests/split_proteins/test_prophages.faa",
            "-g",
            "tests/split_proteins/test_prophages.gff",
            "-o",
            str(output),
        ]

        result = subprocess.run(
            cmd, capture_output=True, text=True, env=SUBPROCESS_ENV, check=False
        )

        assert result.returncode == 0, result.stderr
        # file exists
        assert output.exists()
        content = output.read_text()
        # does NOT contain
        assert "prophage" not in content
        assert (
            "NODE_8_length_94004_cov_7.597888_118" in content
        )  # protein coordinates are in prophage region
        assert (
            "NODE_8_length_94004_cov_7.597888_119" not in content
        )  # protein coordinates are not in prophage region
        assert (
            "NODE_8_length_94004_cov_7.597888_123" in content
        )  # protein coordinates are in prophage region
        assert (
            "NODE_8_length_94004_cov_7.597888_120" not in content
        )  # protein coordinates are not in prophage region
        # line count
        assert len(content.splitlines()) == 329
        # FASTA sequence count
        assert content.count(">") == 113
        assert md5sum(output) == "c141afa518b4d5dcddae73481b652be6"

    def test_split_proteins_by_categories_ambiguity(self):
        test_dir = tempfile.mkdtemp()
        output = Path(test_dir) / "prefix_ambiguity_split.faa"

        cmd = [
            "python",
            "-m",
            "bin.split_proteins_by_categories",
            "-i",
            "tests/split_proteins/prefix_ambiguity.fna",
            "-p",
            "tests/split_proteins/prefix_ambiguity.faa",
            "-g",
            "tests/split_proteins/prefix_ambiguity.gff",
            "-o",
            str(output),
        ]

        result = subprocess.run(
            cmd, capture_output=True, text=True, env=SUBPROCESS_ENV, check=False
        )

        assert result.returncode == 0, result.stderr
        # file exists
        assert output.exists()
        content = output.read_text()
        # (bug 1 - garbled IDs)
        # Regression for substring-check bug:
        # contig ERZ23434430_1 must NOT match proteins from ERZ23434430_114
        # contig ERZ23434430_7 must NOT match ERZ23434430_759_1 (bug 2 - duplicate CDS rows).
        # Only the 3 correct proteins should appear in the output, each exactly once.
        # does NOT contain
        assert "circular" not in content
        assert "ERZ23434430_114" not in content
        assert "ERZ23434430_759" in content
        assert "ERZ23434430_1" in content
        assert "ERZ23434430_7_" in content
        # line count
        assert len(content.splitlines()) == 6
        # FASTA sequence count
        assert content.count(">") == 3
        assert md5sum(output) == "78e956f5c00a1fbe88196f4a4424c969"

    def test_split_proteins_by_categories_mags(self):
        test_dir = tempfile.mkdtemp()
        output = Path(test_dir) / "mag_prophage.faa"

        cmd = [
            "python",
            "-m",
            "bin.split_proteins_by_categories",
            "-i",
            "tests/split_proteins/mag.fasta",
            "-p",
            "tests/split_proteins/mag.faa",
            "-g",
            "tests/split_proteins/mag.gff",
            "-o",
            str(output),
        ]

        result = subprocess.run(
            cmd, capture_output=True, text=True, env=SUBPROCESS_ENV, check=False
        )

        assert result.returncode == 0, result.stderr
        # file exists
        assert output.exists()
        content = output.read_text()

        # should rely only on protein identifiers ignoring annotation like hypothetical protein
        assert "prophage" not in content
        # doesn't fit in prophage coords (between the two prophage regions on the same contig)
        assert "MGYG000495417_00791" not in content
        assert "MGYG000495417_00792" not in content
        # does fit in prophage coords (first prophage region: 23410-59937)
        assert "MGYG000495417_00789" in content
        assert "MGYG000495417_00790" in content
        # does fit in prophage coords (second prophage region on the same contig: 70000-80000)
        assert "MGYG000495417_00793" in content
        # doesn't belong to contig MGYG000495417_3
        assert "MGYG000495417_00001" not in content
        # line count
        assert len(content.splitlines()) == 21
        # FASTA sequence count
        assert content.count(">") == 3
        assert md5sum(output) == "506f1159b743ebaa187595b40cdadda7"

    def test_output_gff_written_when_proteins_are_found(self):
        """The GFF carries the CDS records of the retained proteins."""
        test_dir = Path(tempfile.mkdtemp())
        output = test_dir / "mag_prophage.faa"
        output_gff = test_dir / "mag_prophage.gff"

        cmd = [
            "python",
            "-m",
            "bin.split_proteins_by_categories",
            "-i",
            "tests/split_proteins/mag.fasta",
            "-p",
            "tests/split_proteins/mag.faa",
            "-g",
            "tests/split_proteins/mag.gff",
            "-o",
            str(output),
            "--output-gff",
            str(output_gff),
        ]

        result = subprocess.run(
            cmd, capture_output=True, text=True, env=SUBPROCESS_ENV, check=False
        )

        assert result.returncode == 0, result.stderr
        assert output_gff.exists()
        gff_content = output_gff.read_text()
        assert gff_content.startswith("##gff-version 3")
        # the prophage suffix is carried into the GFF seqid
        assert "MGYG000495417_3|prophage-23410:59937" in gff_content
        assert "\tCDS\t" in gff_content

    def test_no_cds_on_contig_still_writes_gff(self):
        """A contig with no CDS must not leave the GFF unwritten.

        Regression: the GFF was previously only written when at least one protein
        matched, so SPLIT_PROTEINS failed with a missing output file.
        """
        test_dir = Path(tempfile.mkdtemp())
        output = test_dir / "no_cds_contig.faa"
        output_gff = test_dir / "no_cds_contig.gff"
        report = test_dir / "no_cds_contig_report.tsv"

        cmd = [
            "python",
            "-m",
            "bin.split_proteins_by_categories",
            "-i",
            "tests/split_proteins/no_cds_contig.fna",
            "-p",
            "tests/split_proteins/mag.faa",
            "-g",
            "tests/split_proteins/mag.gff",
            "-o",
            str(output),
            "--output-gff",
            str(output_gff),
            "--dropped-report",
            str(report),
        ]

        result = subprocess.run(
            cmd, capture_output=True, text=True, env=SUBPROCESS_ENV, check=False
        )

        assert result.returncode == 0, result.stderr
        # both outputs exist even though nothing matched
        assert output.exists()
        assert output_gff.exists()
        assert output.read_text() == ""
        assert output_gff.read_text() == "##gff-version 3\n"
        # and the contig is reported with the reason that applies to it
        assert report.exists()
        report_lines = report.read_text().splitlines()
        assert report_lines[0] == "contig\treason"
        assert report_lines[1] == "MGYG000495417_9\tno CDS on contig"

    def test_no_cds_within_prophage_still_writes_gff(self):
        """A prophage interval containing no CDS hits the same path as a bare contig.

        MGYG000495417_3 has CDS at 23410-24000, 28618-29562, 59940-59980, 65000-65300
        and 72000-73000, so the interval 30000-59000 contains none of them even though
        the contig itself is protein-rich. This case cannot be caught upstream of
        DETECT because prophage intervals do not exist until PARSE has run.
        """
        test_dir = Path(tempfile.mkdtemp())
        output = test_dir / "prophage_no_cds.faa"
        output_gff = test_dir / "prophage_no_cds.gff"
        report = test_dir / "prophage_no_cds_report.tsv"

        cmd = [
            "python",
            "-m",
            "bin.split_proteins_by_categories",
            "-i",
            "tests/split_proteins/prophage_no_cds.fna",
            "-p",
            "tests/split_proteins/mag.faa",
            "-g",
            "tests/split_proteins/mag.gff",
            "-o",
            str(output),
            "--output-gff",
            str(output_gff),
            "--dropped-report",
            str(report),
        ]

        result = subprocess.run(
            cmd, capture_output=True, text=True, env=SUBPROCESS_ENV, check=False
        )

        assert result.returncode == 0, result.stderr
        assert output.exists()
        assert output_gff.exists()
        assert output.read_text() == ""
        assert output_gff.read_text() == "##gff-version 3\n"
        # the reason distinguishes this from a contig with no genes at all
        report_lines = report.read_text().splitlines()
        assert (
            report_lines[1]
            == "MGYG000495417_3|prophage-30000:59000\tno CDS within prophage interval"
        )


if __name__ == "__main__":
    unittest.main()
