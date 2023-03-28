#!/bin/env python3

import hashlib
import os
import shutil
import tempfile
import unittest

from bin.parse_viral_pred import (_parse_virsorter_metadata, main,
                                  merge_annotations, parse_virus_finder,
                                  parse_virus_sorter)


class ParseViralPredictions(unittest.TestCase):

    def _build_path(self, folder):
        return os.path.abspath("/" + os.path.dirname(__file__) + "/parse_viral_fixtures" + folder)

    def test_clean_virsoter_name(self):
        # clean_name, circular, prange
        assertions = [
            ("VIRSorter_contig_1101:1_0-41663_0-cat_2", (
                "contig_1101:1_0-41663_0", False, None
            )),
            ("VIRSorter_)(*&^contig!£$%^&3301:1_0-41663_0-cat_2", (
                ")(*&^contig!£$%^&3301:1_0-41663_0",
                False,
                None
            )),
            ("VIRSorter_X", ("X", False, None)),
            ("VIRSorter_NODE_1_length_79063_cov_13_902377", (
                "NODE_1_length_79063_cov_13_902377",
                False,
                None
            )),
            ("VIRSorter_NODE_306_length_14315_cov_22_151052_gene_1_gene_12-0-9235-cat_5", (
                "NODE_306_length_14315_cov_22_151052",
                False,
                ['0', '9235']
            )),
            ("VIRSorter_NODE_306_length_14315_cov_22_151052_gene_1_gene_12-0-9235-cat_5", (
                "NODE_306_length_14315_cov_22_151052",
                False,
                ['0', '9235']
            )),
            ("VIRSorter_)(*&^contig!£$%^&3301:_gene_1_gene_12-0-9235-cat_5", (
                ")(*&^contig!£$%^&3301:",
                False,
                ['0', '9235']
            )),
            ("VIRSorter_seq124-circular-cat_1", (
                "seq124",
                True,
                None
            )),
            ("VIRSorter_tig!£$%^&330-circular-cat_2", (
                "tig!£$%^&330",
                True,
                None
            )),
            ("VIRSorter_seq1_gene_448_gene_516-475020-518621-cat_5", (
                "seq1",
                False,
                ['475020', '518621']
            )),
            ("VIRSorter_ig!£$%^&33_gene_32_gene_81-42857-81154-cat_5", (
                "ig!£$%^&33",
                False,
                ['42857', '81154']
            )),
        ]
        for inp, expected in assertions:
            self.assertTupleEqual(_parse_virsorter_metadata(inp), expected)

    def test_parsing_virsorter(self):
        """For virsorter => virsorter_finder_test_data/input.fasta the expected is:
        """
        path = self._build_path("/base_fixtures/virsorter/")
        hc, lc, p = parse_virus_sorter([os.path.join(path, f) for f in os.listdir(path)])

        self.assertSetEqual(set([r.seq_id for _, r in hc.items()]),
                            set(["pos_phage_2", "pos_phage_1"]))
        self.assertSetEqual(set([r.seq_id for _, r in lc.items()]), set())
        self.assertSetEqual(set([r[0].seq_id for _, r in p.items()]), set(["pos_phage_0"]))

    def test_parsing_virfinder(self):
        """For virfinder => virsorter_finder_test_data/input.fasta the expected is:
        """
        path = self._build_path("/base_fixtures/virfinder_output.tsv")
        hc, lc = parse_virus_finder(path)

        self.assertSetEqual(hc, set(["pos.phage.0", "pos.phage.3"]))
        self.assertSetEqual(lc, set(["pos.phage.1", "pos.phage.2"]))

    def test_parsing_with_dups(self):
        """Test that no duplicates are reported
        """
        pprmeta_path = self._build_path("/kleiner2015/pprmeta.csv")
        vf_path = self._build_path("/kleiner2015/virfinder.txt")
        vs_path = self._build_path("/kleiner2015/predicted_viral_sequences")
        assembly = self._build_path("/kleiner2015/kleiner_2015_renamed.fasta")

        vs_files = [os.path.join(vs_path, f) for f in os.listdir(vs_path)]

        hc, lc, pp, *_ = merge_annotations(pprmeta_path, vf_path, vs_files, assembly)

        hc_ids = set([h.id for h in hc])
        lc_ids = set([l.id for l in lc])
        pp_ids = set([p.id for p in pp])

        self.assertEqual(13, len(hc_ids))
        self.assertEqual(40, len(lc_ids))
        self.assertEqual(5, len(pp_ids))

        self.assertEqual(False, bool(hc_ids & lc_ids))
        self.assertEqual(False, bool(hc_ids & pp_ids))
        self.assertEqual(False, bool(lc_ids & pp_ids))

    def test_full(self):
        """Test output files
        """
        pprmeta_path = self._build_path("/kleiner2015/pprmeta.csv")
        vf_path = self._build_path("/kleiner2015/virfinder.txt")
        vs_path = self._build_path("/kleiner2015/predicted_viral_sequences")
        assembly = self._build_path("/kleiner2015/kleiner_2015_renamed.fasta")
        test_dir = tempfile.mkdtemp()

        vs_files = [os.path.join(vs_path, f) for f in os.listdir(vs_path)]

        print(test_dir)

        main(pprmeta_path, vf_path, vs_files, assembly, test_dir)

        with open(test_dir + "/high_confidence_viral_contigs.fna", "rb") as hc_f:
            with open(
                self._build_path("/kleiner2015/expected/"
                                 "high_confidence_putative_viral_contigs.fna"), "rb") as hc_e:
                self.assertEqual(hashlib.md5(hc_f.read()).hexdigest(),
                                 hashlib.md5(hc_e.read()).hexdigest())

        with open(test_dir + "/low_confidence_viral_contigs.fna", "rb") as lc_f:
            with open(
                self._build_path("/kleiner2015/expected/"
                                 "low_confidence_putative_viral_contigs.fna"), "rb") as lc_e:
                self.assertEqual(hashlib.md5(lc_f.read()).hexdigest(),
                                 hashlib.md5(lc_e.read()).hexdigest())

        with open(test_dir + "/prophages.fna", "rb") as p_f:
            with open(
                self._build_path("/kleiner2015/expected/"
                                 "putative_prophages.fna"), "rb") as p_e:
                self.assertEqual(hashlib.md5(p_f.read()).hexdigest(),
                                 hashlib.md5(p_e.read()).hexdigest())

        with open(test_dir + "/virsorter_metadata.tsv", "rb") as vs_f:
            # sort the lines as the script doesn't guarantee order
            obtained = str(sorted(vs_f.readlines()))
            with open(
                self._build_path("/kleiner2015/expected/"
                                 "/virsorter_metadata.tsv"), "rb") as vs_e:
                expected = str(sorted(vs_e.readlines()))
            self.assertEqual(hashlib.md5(obtained.encode("utf-8")).hexdigest(),
                             hashlib.md5(expected.encode("utf-8")).hexdigest())

        shutil.rmtree(test_dir)

    def test_virsorter_precedence(self):
        """VirSorter results take precedence over the other tools
        """
        pprmeta_path = self._build_path("/virsorter_precedence/pprmeta.csv")
        vf_path = self._build_path("/virsorter_precedence/virfinder.txt")
        vs_path = self._build_path("/virsorter_precedence/predicted_viral_sequences")
        assembly = self._build_path("/virsorter_precedence/assembly_renamed_filt1500bp.fasta")

        test_dir = tempfile.mkdtemp()

        sorter_files = [os.path.join(vs_path, f) for f in os.listdir(vs_path)]

        main(pprmeta_path, vf_path, sorter_files, assembly, test_dir)

        with open(test_dir + "/high_confidence_viral_contigs.fna", "rb") as hc_f:
            with open(
                self._build_path("/virsorter_precedence/expected/"
                                 "/high_confidence_putative_viral_contigs.fna"), "rb") as hc_e:
                self.assertEqual(hashlib.md5(hc_f.read()).hexdigest(),
                                 hashlib.md5(hc_e.read()).hexdigest())

        with open(test_dir + "/low_confidence_viral_contigs.fna", "rb") as lc_f:
            content = lc_f.readlines()
            self.assertEqual(">seq1\n" in content, False)
            lc_f.seek(0)
            with open(
                self._build_path("/virsorter_precedence/expected/"
                                 "/low_confidence_putative_viral_contigs.fna"), "rb") as lc_e:
                self.assertEqual(hashlib.md5(lc_f.read()).hexdigest(),
                                 hashlib.md5(lc_e.read()).hexdigest())

        with open(test_dir + "/prophages.fna", "rb") as p_f:
            self.assertEqual(p_f.readline(), b">seq1|prophage-21696:135184\n")
            p_f.seek(0)
            with open(
                self._build_path("/virsorter_precedence/expected/"
                                 "/putative_prophages.fna"), "rb") as p_e:
                self.assertEqual(hashlib.md5(p_f.read()).hexdigest(),
                                 hashlib.md5(p_e.read()).hexdigest())

        # seq1 has to be in prophages and not in low_confidence
        with open(test_dir + "/virsorter_metadata.tsv", "rb") as vs_f:
            # sort the lines as the script doesn't guarantee order
            obtained = str(sorted(vs_f.readlines()))
            with open(
                self._build_path("/virsorter_precedence/expected/"
                                 "/virsorter_metadata.tsv"), "rb") as vs_e:
                expected = str(sorted(vs_e.readlines()))
            self.assertEqual(hashlib.md5(obtained.encode("utf-8")).hexdigest(),
                             hashlib.md5(expected.encode("utf-8")).hexdigest())

        shutil.rmtree(test_dir)


if __name__ == "__main__":
    unittest.main()
