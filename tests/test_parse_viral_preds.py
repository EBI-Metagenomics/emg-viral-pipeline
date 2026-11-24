import csv
import hashlib
import os
import shutil
import tempfile
import unittest

import pytest

from bin.parse_viral_pred import (
    CALL_COLUMNS,
    _parse_virsorter_metadata,
    main,
    merge_annotations,
    parse_virus_finder,
    parse_virus_sorter,
    parse_virus_sorter2,
)


class ParseViralPredictions(unittest.TestCase):

    def _build_path(self, folder):
        return os.path.abspath(
            "/" + os.path.dirname(__file__) + "/parse_viral_fixtures" + folder
        )

    def test_clean_virsoter_name(self):
        # clean_name, circular, prange
        assertions = [
            (
                "VIRSorter_contig_1101:1_0-41663_0-cat_2",
                ("contig_1101:1_0-41663_0", False, None),
            ),
            (
                "VIRSorter_)(*&^contig!£$%^&3301:1_0-41663_0-cat_2",
                (")(*&^contig!£$%^&3301:1_0-41663_0", False, None),
            ),
            ("VIRSorter_X", ("X", False, None)),
            (
                "VIRSorter_NODE_1_length_79063_cov_13_902377",
                ("NODE_1_length_79063_cov_13_902377", False, None),
            ),
            (
                "VIRSorter_NODE_306_length_14315_cov_22_151052_gene_1_gene_12-0-9235-cat_5",
                ("NODE_306_length_14315_cov_22_151052", False, ["0", "9235"]),
            ),
            (
                "VIRSorter_NODE_306_length_14315_cov_22_151052_gene_1_gene_12-0-9235-cat_5",
                ("NODE_306_length_14315_cov_22_151052", False, ["0", "9235"]),
            ),
            (
                "VIRSorter_)(*&^contig!£$%^&3301:_gene_1_gene_12-0-9235-cat_5",
                (")(*&^contig!£$%^&3301:", False, ["0", "9235"]),
            ),
            ("VIRSorter_seq124-circular-cat_1", ("seq124", True, None)),
            ("VIRSorter_tig!£$%^&330-circular-cat_2", ("tig!£$%^&330", True, None)),
            (
                "VIRSorter_seq1_gene_448_gene_516-475020-518621-cat_5",
                ("seq1", False, ["475020", "518621"]),
            ),
            (
                "VIRSorter_ig!£$%^&33_gene_32_gene_81-42857-81154-cat_5",
                ("ig!£$%^&33", False, ["42857", "81154"]),
            ),
        ]
        for inp, expected in assertions:
            self.assertTupleEqual(_parse_virsorter_metadata(inp), expected)

    def test_parsing_virsorter(self):
        """For virsorter => virsorter_finder_test_data/input.fasta the expected is:"""
        path = self._build_path("/base_fixtures/virsorter/")
        hc, lc, p = parse_virus_sorter(
            [os.path.join(path, f) for f in os.listdir(path)]
        )

        self.assertSetEqual(
            {r.seq_id for _, r in hc.items()}, {"pos_phage_2", "pos_phage_1"}
        )
        self.assertSetEqual({r.seq_id for _, r in lc.items()}, set())
        self.assertSetEqual({r[0].seq_id for _, r in p.items()}, {"pos_phage_0"})

    def test_parsing_virsorter2(self):
        VS_CUTOFF = 0.9
        path = self._build_path("/base_fixtures/virsorter2/VS2")
        hc, lc, p = parse_virus_sorter2(
            [os.path.join(path, f) for f in os.listdir(path)], VS_CUTOFF
        )
        self.assertSetEqual(
            {r.seq_id for _, r in hc.items()},
            {"seq3", "seq4", "seq5", "seq6", "seq7"},
        )
        self.assertSetEqual({r.seq_id for _, r in lc.items()}, {"seq8"})
        self.assertSetEqual({r[0].seq_id for _, r in p.items()}, {"seq1", "seq2"})

    def test_parsing_virfinder(self):
        """For virfinder => virsorter_finder_test_data/input.fasta the expected is:"""
        path = self._build_path("/base_fixtures/virfinder_output.tsv")
        hc, lc = parse_virus_finder(path)

        self.assertSetEqual(hc, {"pos.phage.0", "pos.phage.3"})
        self.assertSetEqual(lc, {"pos.phage.1", "pos.phage.2"})

    def test_parsing_with_dups(self):
        """Test that no duplicates are reported"""
        test_dir = tempfile.mkdtemp()
        pprmeta_path = self._build_path("/kleiner2015/pprmeta.csv")
        vf_path = self._build_path("/kleiner2015/virfinder.txt")
        vs_path = self._build_path("/kleiner2015/predicted_viral_sequences")
        assembly = self._build_path("/kleiner2015/kleiner_2015_renamed.fasta")

        vs_files = [os.path.join(vs_path, f) for f in os.listdir(vs_path)]

        hc, lc, pp, *_ = merge_annotations(
            pprmeta_path, vf_path, vs_files, None, assembly, 0.9, test_dir
        )

        hc_ids = {high.id for high in hc}
        lc_ids = {low.id for low in lc}
        pp_ids = {proph.id for proph in pp}

        self.assertEqual(13, len(hc_ids))
        self.assertEqual(40, len(lc_ids))
        self.assertEqual(5, len(pp_ids))

        self.assertEqual(False, bool(hc_ids & lc_ids))
        self.assertEqual(False, bool(hc_ids & pp_ids))
        self.assertEqual(False, bool(lc_ids & pp_ids))

        assert os.path.exists(f"{test_dir}/sanity_check_failed_contigs.txt")
        with open(f"{test_dir}/sanity_check_failed_contigs.txt", "r") as file_in:
            output = file_in.readlines()
            assert len(output) == 1
            assert "seq23948" in "\t".join(output)

    def test_full(self):
        """Test output files"""
        pprmeta_path = self._build_path("/kleiner2015/pprmeta.csv")
        vf_path = self._build_path("/kleiner2015/virfinder.txt")
        vs_path = self._build_path("/kleiner2015/predicted_viral_sequences")
        assembly = self._build_path("/kleiner2015/kleiner_2015_renamed.fasta")
        test_dir = tempfile.mkdtemp()

        vs_files = [os.path.join(vs_path, f) for f in os.listdir(vs_path)]

        print(test_dir)

        main(pprmeta_path, vf_path, vs_files, None, assembly, test_dir, 0.9)

        with open(test_dir + "/high_confidence_viral_contigs.fna", "rb") as hc_f, open(
            self._build_path(
                "/kleiner2015/expected/" "high_confidence_putative_viral_contigs.fna"
            ),
            "rb",
        ) as hc_e:
            self.assertEqual(
                hashlib.md5(hc_f.read()).hexdigest(),
                hashlib.md5(hc_e.read()).hexdigest(),
            )

        with open(test_dir + "/low_confidence_viral_contigs.fna", "rb") as lc_f, open(
            self._build_path(
                "/kleiner2015/expected/" "low_confidence_putative_viral_contigs.fna"
            ),
            "rb",
        ) as lc_e:
            self.assertEqual(
                hashlib.md5(lc_f.read()).hexdigest(),
                hashlib.md5(lc_e.read()).hexdigest(),
            )

        with open(test_dir + "/prophages.fna", "rb") as p_f, open(
            self._build_path("/kleiner2015/expected/" "putative_prophages.fna"), "rb"
        ) as p_e:
            self.assertEqual(
                hashlib.md5(p_f.read()).hexdigest(), hashlib.md5(p_e.read()).hexdigest()
            )

        with open(test_dir + "/virsorter_metadata.tsv", "rb") as vs_f:
            # sort the lines as the script doesn't guarantee order
            obtained = str(sorted(vs_f.readlines()))
            with open(
                self._build_path("/kleiner2015/expected/" "/virsorter_metadata.tsv"),
                "rb",
            ) as vs_e:
                expected = str(sorted(vs_e.readlines()))
            self.assertEqual(
                hashlib.md5(obtained.encode("utf-8")).hexdigest(),
                hashlib.md5(expected.encode("utf-8")).hexdigest(),
            )

        shutil.rmtree(test_dir)

    def test_virsorter_precedence(self):
        """VirSorter results take precedence over the other tools"""
        pprmeta_path = self._build_path("/virsorter_precedence/pprmeta.csv")
        vf_path = self._build_path("/virsorter_precedence/virfinder.txt")
        vs_path = self._build_path("/virsorter_precedence/predicted_viral_sequences")
        assembly = self._build_path(
            "/virsorter_precedence/assembly_renamed_filt1500bp.fasta"
        )

        test_dir = tempfile.mkdtemp()

        sorter_files = [os.path.join(vs_path, f) for f in os.listdir(vs_path)]

        main(pprmeta_path, vf_path, sorter_files, None, assembly, test_dir, 0.9)

        with open(test_dir + "/high_confidence_viral_contigs.fna", "rb") as hc_f, open(
            self._build_path(
                "/virsorter_precedence/expected/"
                "/high_confidence_putative_viral_contigs.fna"
            ),
            "rb",
        ) as hc_e:
            self.assertEqual(
                hashlib.md5(hc_f.read()).hexdigest(),
                hashlib.md5(hc_e.read()).hexdigest(),
            )

        with open(test_dir + "/low_confidence_viral_contigs.fna", "rb") as lc_f:
            content = lc_f.readlines()
            self.assertEqual(">seq1\n" in content, False)
            lc_f.seek(0)
            with open(
                self._build_path(
                    "/virsorter_precedence/expected/"
                    "/low_confidence_putative_viral_contigs.fna"
                ),
                "rb",
            ) as lc_e:
                self.assertEqual(
                    hashlib.md5(lc_f.read()).hexdigest(),
                    hashlib.md5(lc_e.read()).hexdigest(),
                )

        with open(test_dir + "/prophages.fna", "rb") as p_f:
            self.assertEqual(p_f.readline(), b">seq1|prophage-21696:135184\n")
            p_f.seek(0)
            with open(
                self._build_path(
                    "/virsorter_precedence/expected/" "/putative_prophages.fna"
                ),
                "rb",
            ) as p_e:
                self.assertEqual(
                    hashlib.md5(p_f.read()).hexdigest(),
                    hashlib.md5(p_e.read()).hexdigest(),
                )

        # seq1 has to be in prophages and not in low_confidence
        with open(test_dir + "/virsorter_metadata.tsv", "rb") as vs_f:
            # sort the lines as the script doesn't guarantee order
            obtained = str(sorted(vs_f.readlines()))
            with open(
                self._build_path(
                    "/virsorter_precedence/expected/" "/virsorter_metadata.tsv"
                ),
                "rb",
            ) as vs_e:
                expected = str(sorted(vs_e.readlines()))
            self.assertEqual(
                hashlib.md5(obtained.encode("utf-8")).hexdigest(),
                hashlib.md5(expected.encode("utf-8")).hexdigest(),
            )

        shutil.rmtree(test_dir)

    def test_virsorter2_precedence(self):
        """VirSorter2 results should take precedence over the other tools"""
        pprmeta_path = self._build_path("/base_fixtures/virsorter2/b14_07_pprmeta.csv")
        vf_path = self._build_path("/base_fixtures/virsorter2/b14_07.txt")
        vs_path = self._build_path("/base_fixtures/virsorter2/VS2")
        assembly = self._build_path(
            "/base_fixtures/virsorter2/b14_07_renamed_filt1500bp.fasta"
        )

        test_dir = tempfile.mkdtemp()

        sorter_files = [os.path.join(vs_path, f) for f in os.listdir(vs_path)]

        main(pprmeta_path, vf_path, None, sorter_files, assembly, test_dir, 0.9)

        with open(test_dir + "/high_confidence_viral_contigs.fna", "rb") as hc_f, open(
            self._build_path(
                "/virsorter_precedence/expected_vs2/"
                "/high_confidence_viral_contigs.fna"
            ),
            "rb",
        ) as hc_e:
            self.assertEqual(
                hashlib.md5(hc_f.read()).hexdigest(),
                hashlib.md5(hc_e.read()).hexdigest(),
            )

        assert not os.path.exists(test_dir + "/low_confidence_viral_contigs.fna")

        with open(test_dir + "/prophages.fna", "rb") as p_f:
            self.assertEqual(p_f.readline(), b">seq1|prophage-1665815:1723488\n")
            p_f.seek(0)
            with open(
                self._build_path(
                    "/virsorter_precedence/expected_vs2/" "/prophages.fna"
                ),
                "rb",
            ) as p_e:
                self.assertEqual(
                    hashlib.md5(p_f.read()).hexdigest(),
                    hashlib.md5(p_e.read()).hexdigest(),
                )

        # seq1 has to be in prophages and not in low_confidence
        with open(test_dir + "/virsorter_metadata.tsv", "rb") as vs_f:
            # sort the lines as the script doesn't guarantee order
            obtained = str(sorted(vs_f.readlines()))
            with open(
                self._build_path(
                    "/virsorter_precedence/expected_vs2/" "/virsorter_metadata.tsv"
                ),
                "rb",
            ) as vs_e:
                expected = str(sorted(vs_e.readlines()))
            self.assertEqual(
                hashlib.md5(obtained.encode("utf-8")).hexdigest(),
                hashlib.md5(expected.encode("utf-8")).hexdigest(),
            )

        shutil.rmtree(test_dir)


def _write_rows(path, rows, delimiter="\t"):
    """Write rows (lists of fields) to a delimited file and return the path."""
    path.write_text("".join(delimiter.join(row) + "\n" for row in rows))
    return str(path)


def _read_calls(path):
    """Read the detection calls table as a list of dicts."""
    with open(path) as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def test_detection_calls_for_contig_in_low_confidence_and_prophage(tmp_path):
    """A contig that is LC (VirFinder) and has a VirSorter2 prophage call.

    The table has one row per category, with the rule and the VirSorter2 values.
    """
    contig_length = 6015
    assembly = tmp_path / "assembly.fasta"
    assembly.write_text(">seq1\n" + "ACGT" * (contig_length // 4) + "ACG\n")

    virfinder = _write_rows(
        tmp_path / "virfinder.tsv",
        [["name", "length", "score", "pvalue"], ["seq1", "6015", "0.98", "0.001"]],
    )
    pprmeta = _write_rows(
        tmp_path / "pprmeta.csv",
        [
            ["Header", "Length", "phage_score", "Possible_source"],
            ["seq1", "6015", "0.91", "phage"],
        ],
        delimiter=",",
    )
    vs2_score = _write_rows(
        tmp_path / "final-viral-score.tsv",
        [
            ["seqname", "max_score", "max_score_group", "length"],
            ["seq1||0_partial", "0.95", "ssDNA", "1491"],
        ],
    )
    vs2_boundary = _write_rows(
        tmp_path / "final-viral-boundary.tsv",
        [
            [
                "seqname",
                "trim_orf_index_start",
                "trim_orf_index_end",
                "trim_bp_start",
                "trim_bp_end",
                "trim_pr",
                "partial",
                "pr_full",
                "hallmark_cnt",
                "group",
                "shape",
                "seqname_new",
            ],
            [
                "seq1",
                "2",
                "3",
                "3367",
                "4857",
                "0.95",
                "1",
                "0.4",
                "1",
                "ssDNA",
                "circular",
                "seq1||0_partial",
            ],
        ],
    )
    vs2_fasta = tmp_path / "final-viral-combined.fa"
    vs2_fasta.write_text(">seq1||0_partial\n" + "ACGT" * 372 + "ACG\n")
    outdir = tmp_path / "out"
    main(
        pprmeta,
        virfinder,
        None,
        [vs2_score, vs2_boundary, str(vs2_fasta)],
        str(assembly),
        outdir,
        0.9,
    )

    rows = _read_calls(outdir / "detection_calls.tsv")
    assert list(rows[0].keys()) == CALL_COLUMNS
    rows_by_quality = {row["virify_quality"]: row for row in rows}
    assert set(rows_by_quality) == {"LC", "PP"}

    assert rows_by_quality["LC"] == {
        "sequence_id": "seq1",
        "contig": "seq1",
        "virify_quality": "LC",
        "rule": "virfinder_score_0.9",
        "prophage_start": "NA",
        "prophage_end": "NA",
        "circular": "False",
        "virsorter_category": "NA",
        "virsorter2_max_score": "NA",
        "virsorter2_max_score_group": "NA",
        "virsorter2_shape": "NA",
    }
    # VIRify sets the prophage to linear, but the table keeps the VirSorter2 shape
    # of the contig (circular), so users can see the conflict.
    assert rows_by_quality["PP"] == {
        "sequence_id": "seq1|prophage-3367:4857",
        "contig": "seq1",
        "virify_quality": "PP",
        "rule": "virsorter2_prophage",
        "prophage_start": "3367",
        "prophage_end": "4857",
        "circular": "False",
        "virsorter_category": "NA",
        "virsorter2_max_score": "0.95",
        "virsorter2_max_score_group": "ssDNA",
        "virsorter2_shape": "circular",
    }


def _virfinder_only_run(tmp_path, name, virfinder_score):
    """Run main with VirFinder and PPR-Meta only, for one 2 kb contig."""
    assembly = tmp_path / "assembly.fasta"
    assembly.write_text(f">{name}\n" + "ACGT" * 500 + "\n")
    virfinder = _write_rows(
        tmp_path / "virfinder.tsv",
        [
            ["name", "length", "score", "pvalue"],
            [name, "2000", virfinder_score, "0.01"],
        ],
    )
    pprmeta = _write_rows(
        tmp_path / "pprmeta.csv",
        [
            ["Header", "Length", "phage_score", "Possible_source"],
            [name, "2000", "0.1", "chromosome"],
        ],
        delimiter=",",
    )
    outdir = tmp_path / "out"
    try:
        main(pprmeta, virfinder, [], None, str(assembly), outdir, 0.9)
    except SystemExit:
        pass  # main exits when no sequence is viral
    return _read_calls(outdir / "detection_calls.tsv")


def test_detection_calls_written_when_no_sequence_is_viral(tmp_path):
    """The table has only the header when no sequence is viral."""
    assert _virfinder_only_run(tmp_path, "seq1", "0.1") == []


@pytest.mark.parametrize("name", ["sample-phage-circular-01", "seq1|phage-circular"])
def test_detection_calls_circular_only_from_suffix(tmp_path, name):
    """A contig name that contains "phage-circular" does not make the call circular.

    Only a suffix that VIRify adds after the contig name counts.
    """
    rows = _virfinder_only_run(tmp_path, name, "0.95")
    assert [(row["sequence_id"], row["circular"]) for row in rows] == [(name, "False")]


def test_detection_calls_without_score_group(tmp_path):
    """A VirSorter2 score table without max_score_group gives the same categories.

    The calls table has NA for the group. Fixture: tests/parse/ (the PARSE nf-test).
    """
    fixtures = os.path.join(os.path.dirname(__file__), "parse")
    score_file = tmp_path / "final-viral-score.tsv"
    with open(os.path.join(fixtures, "virsorter2", "final-viral-score.tsv")) as handle:
        rows = [line.rstrip("\n").split("\t") for line in handle]
    group = rows[0].index("max_score_group")
    _write_rows(score_file, [row[:group] + row[group + 1 :] for row in rows])
    outdir = tmp_path / "out"

    main(
        os.path.join(fixtures, "pprmeta.csv"),
        os.path.join(fixtures, "virfinder.tsv"),
        None,
        [
            os.path.join(fixtures, "virsorter2", "final-viral-boundary.tsv"),
            os.path.join(fixtures, "virsorter2", "final-viral-combined.fa"),
            str(score_file),
        ],
        os.path.join(fixtures, "assembly.fasta"),
        outdir,
        0.9,
    )

    calls = _read_calls(outdir / "detection_calls.tsv")
    assert [(row["sequence_id"], row["virify_quality"]) for row in calls] == [
        ("seq3", "HC"),
        ("seq7|phage-circular", "HC"),
        ("seq8", "LC"),
    ]
    assert {row["virsorter2_max_score_group"] for row in calls} == {"NA"}


if __name__ == "__main__":
    unittest.main()
