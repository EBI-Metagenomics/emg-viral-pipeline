import os
import subprocess
from pathlib import Path
import hashlib
import tempfile
import unittest

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
    
        result = subprocess.run(cmd, capture_output=True, text=True, env=SUBPROCESS_ENV)
    
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

        result = subprocess.run(cmd, capture_output=True, text=True, env=SUBPROCESS_ENV)

        assert result.returncode == 0, result.stderr
        # file exists
        assert output.exists()
        content = output.read_text()
        # does NOT contain
        assert "prophage" not in content
        assert "NODE_8_length_94004_cov_7.597888_118" in content  # protein coordinates are in prophage region
        assert "NODE_8_length_94004_cov_7.597888_119" not in content  # protein coordinates are not in prophage region
        assert "NODE_8_length_94004_cov_7.597888_123" in content  # protein coordinates are in prophage region
        assert "NODE_8_length_94004_cov_7.597888_120" not in content  # protein coordinates are not in prophage region
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

        result = subprocess.run(cmd, capture_output=True, text=True, env=SUBPROCESS_ENV)

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

        result = subprocess.run(cmd, capture_output=True, text=True, env=SUBPROCESS_ENV)

        assert result.returncode == 0, result.stderr
        # file exists
        assert output.exists()
        content = output.read_text()

        # should rely only on protein identifiers ignoring annotation like hypothetical protein
        assert "prophage" not in content
        # doesn't fit in prophage coords
        assert "MGYG000495417_00791" not in content 
        # does fit in prophage coords
        assert "MGYG000495417_00789" in content  
        assert "MGYG000495417_00790" in content  
        # doesn't belong to contig MGYG000495417_3
        assert "MGYG000495417_00001" not in content 
        # line count
        assert len(content.splitlines()) == 14
        # FASTA sequence count
        assert content.count(">") == 2
        assert md5sum(output) == "a18fa79872eb0ddd371b9f9570c28d0c"


if __name__ == "__main__":
    unittest.main()
