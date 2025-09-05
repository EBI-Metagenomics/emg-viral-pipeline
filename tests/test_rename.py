#!/bin/env python3

import os
import unittest
from collections import namedtuple

from bin.rename_fasta import rename, restore


class RenameTests(unittest.TestCase):
    def _build_path(self, folder):
        return os.path.abspath("/" + os.path.dirname(__file__) + folder)

    def test_rename(self):
        """Test rename"""
        fasta = self._build_path("/rename_fixtures/original.fasta")
        renamed = self._build_path("/rename_fixtures/renamed.fasta")
        mapfile = self._build_path("/rename_fixtures/map.tsv")

        input_args_rename = namedtuple("input_args", "prefix input output map")
        input_args_restore = namedtuple("input_args", "prefix input output map from_restore to_restore")

        rename(input_args_rename(prefix="test.", input=fasta, output=renamed, map=mapfile))

        obtained = []
        with open(renamed, "r") as output_file:
            lines = 0
            for line in output_file:
                if line.startswith(">"):
                    obtained.append(line.replace(">", "").strip())
                lines += 1
            self.assertEqual(20, lines)

        expected = ["test.1", "test.2", "test.3", "test.4", "test.5"]

        self.assertListEqual(obtained, expected)

        output_restored = self._build_path("/rename_fixtures/restored.fasta")

        restore(
            input_args_restore(
                prefix="not-used", 
                input=renamed, 
                output=output_restored, 
                map=mapfile, 
                from_restore="temporary", 
                to_restore="original"
            )
        )

        obtained = []
        with open(output_restored, "r") as restored_file:
            lines = 0
            for line in restored_file:
                if line.startswith(">"):
                    obtained.append(line.replace(">", "").strip())
                lines += 1
            self.assertEqual(20, lines)

        expected = [
            "NODE_1_length_79063_cov_13.902377",
            "NODE_2_length_876543_cov_16.902377",
            "NODE_3_length_637829_cov_11.42453",
            "NODE_3_length_637829_cov_11.99",
            "NODE_3_length_637829_cov_11.100",
        ]

        self.assertListEqual(obtained, expected)

        # clean
        os.remove(renamed)
        os.remove(mapfile)
        os.remove(output_restored)

    def test_rename_with_virsorter_metadata(self):
        """Test rename with a virsorter metadata"""
        renamed = self._build_path("/rename_fixtures/virsorter_renamed.fasta")
        mapfile = self._build_path("/rename_fixtures/virsorter_map.tsv")

        output_restored = self._build_path("/rename_fixtures/restored.fasta")

        input_args = namedtuple("input_args", "prefix input output map from_restore to_restore")

        restore(
            input_args(
                prefix="not-used", 
                input=renamed, 
                output=output_restored, 
                map=mapfile, 
                from_restore="temporary", 
                to_restore="short"
            )
        )

        obtained = []
        with open(output_restored, "r") as restored_file:
            lines = 0
            for line in restored_file:
                if line.startswith(">"):
                    obtained.append(line.replace(">", "").strip())
                lines += 1
            self.assertEqual(24, lines)

        expected = [
            "ERZ1.1",
            "ERZ1.2|phage-circular",
            "ERZ1.3|prophage-21696:135184",
            "ERZ1.3|prophage-100:500",
            "ERZ1.4|prophage-100:500|prophage-500:700",
            "ERZ1.5|phage-circular|prophage-100:500|prophage-500:700",
        ]

        self.assertListEqual(sorted(obtained), sorted(expected))

        # clean
        os.remove(output_restored)


if __name__ == "__main__":
    unittest.main()
