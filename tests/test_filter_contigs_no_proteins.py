import os
import subprocess
import tempfile
import unittest
from pathlib import Path

# The script is run as a subprocess below, so it needs "bin" on its PYTHONPATH,
# mirroring the `pythonpath = . bin` setting in pytest.ini used for in-process
# test imports.
SUBPROCESS_ENV = {**os.environ, "PYTHONPATH": os.path.join(os.getcwd(), "bin")}

FIXTURES = "tests/filter_no_proteins"


def run_filter(output, report=None, proteins_gff=f"{FIXTURES}/proteins.gff"):
    cmd = [
        "python",
        "-m",
        "bin.filter_contigs_no_proteins",
        "-i",
        f"{FIXTURES}/assembly.fasta",
        "-m",
        f"{FIXTURES}/map.tsv",
        "-g",
        proteins_gff,
        "-o",
        str(output),
    ]
    if report:
        cmd += ["--dropped-report", str(report)]
    return subprocess.run(
        cmd, capture_output=True, text=True, env=SUBPROCESS_ENV, check=False
    )


class FilterContigsNoProteins(unittest.TestCase):
    def test_drops_contig_without_cds(self):
        """contig_two is declared in the GFF but has no CDS, so it must be removed.

        The assembly uses temporary names (seq1..seq3) while the GFF uses short
        names, so this also covers the mapfile translation.
        """
        test_dir = Path(tempfile.mkdtemp())
        output = test_dir / "filtered.fasta"
        report = test_dir / "no_proteins.tsv"

        result = run_filter(output, report)

        assert result.returncode == 0, result.stderr
        content = output.read_text()
        # temporary names are preserved, since DETECT consumes this file
        assert ">seq1" in content
        assert ">seq3" in content
        # contig_two -> seq2 has no CDS and is dropped
        assert ">seq2" not in content
        assert content.count(">") == 2

    def test_report_uses_original_contig_names(self):
        """The report is for humans, so it names contigs as they appear in the input."""
        test_dir = Path(tempfile.mkdtemp())
        output = test_dir / "filtered.fasta"
        report = test_dir / "no_proteins.tsv"

        result = run_filter(output, report)

        assert result.returncode == 0, result.stderr
        report_lines = report.read_text().splitlines()
        assert report_lines[0] == "contig\treason"
        assert report_lines[1] == "contig_two some description\tno CDS on contig"
        assert len(report_lines) == 2

    def test_report_written_when_nothing_is_dropped(self):
        """The report is a declared process output, so it exists even when empty."""
        test_dir = Path(tempfile.mkdtemp())
        output = test_dir / "filtered.fasta"
        report = test_dir / "no_proteins.tsv"
        gff = test_dir / "all_with_cds.gff"
        gff.write_text(
            "##gff-version 3\n"
            "contig_one\tProdigal\tCDS\t1\t30\t.\t+\t0\tID=contig_one_1\n"
            "contig_two\tProdigal\tCDS\t1\t30\t.\t+\t0\tID=contig_two_1\n"
            "contig_three\tProdigal\tCDS\t5\t40\t.\t-\t0\tID=contig_three_1\n"
        )

        result = run_filter(output, report, proteins_gff=str(gff))

        assert result.returncode == 0, result.stderr
        assert output.read_text().count(">") == 3
        assert report.read_text() == "contig\treason\n"

    def test_comment_only_gff_entry_does_not_count_as_proteins(self):
        """Pyrodigal announces gene-less contigs with a comment, not a CDS record.

        A `# Sequence Data:` comment must not be mistaken for evidence of proteins,
        otherwise pipeline-predicted proteins would slip past this checkpoint.
        """
        test_dir = Path(tempfile.mkdtemp())
        output = test_dir / "filtered.fasta"
        gff = test_dir / "prodigal_style.gff"
        gff.write_text(
            "##gff-version 3\n"
            '# Sequence Data: seqnum=1;seqlen=50;seqhdr="contig_one"\n'
            "contig_one\tProdigal\tCDS\t1\t30\t.\t+\t0\tID=contig_one_1\n"
            '# Sequence Data: seqnum=2;seqlen=50;seqhdr="contig_two"\n'
            '# Sequence Data: seqnum=3;seqlen=50;seqhdr="contig_three"\n'
        )

        result = run_filter(output, proteins_gff=str(gff))

        assert result.returncode == 0, result.stderr
        content = output.read_text()
        assert ">seq1" in content
        assert ">seq2" not in content
        assert ">seq3" not in content

    def test_unmapped_contig_is_kept(self):
        """A contig missing from the mapping is kept rather than silently discarded."""
        test_dir = Path(tempfile.mkdtemp())
        output = test_dir / "filtered.fasta"
        mapfile = test_dir / "partial_map.tsv"
        mapfile.write_text(
            "original\ttemporary\tshort\n"
            "contig_one some description\tseq1\tcontig_one\n"
        )

        cmd = [
            "python",
            "-m",
            "bin.filter_contigs_no_proteins",
            "-i",
            f"{FIXTURES}/assembly.fasta",
            "-m",
            str(mapfile),
            "-g",
            f"{FIXTURES}/proteins.gff",
            "-o",
            str(output),
        ]
        result = subprocess.run(
            cmd, capture_output=True, text=True, env=SUBPROCESS_ENV, check=False
        )

        assert result.returncode == 0, result.stderr
        content = output.read_text()
        # seq2 and seq3 are unmapped here, so they survive
        assert content.count(">") == 3
        assert "missing from the mapping file" in result.stderr


if __name__ == "__main__":
    unittest.main()
