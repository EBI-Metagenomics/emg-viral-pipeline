import csv

import pytest

from bin.write_detection_evidence import (
    EVIDENCE_COLUMNS,
    read_rows,
    restore_sequence_id,
    write_detection_evidence,
)

CALL_COLUMNS = [
    "sequence_id",
    "contig",
    "virify_quality",
    "rule",
    "prophage_start",
    "prophage_end",
    "circular",
    "virsorter_category",
    "virsorter2_max_score",
    "virsorter2_max_score_group",
    "virsorter2_shape",
]
CHECKV_COLUMNS = [
    "contig_id",
    "contig_length",
    "provirus",
    "proviral_length",
    "gene_count",
    "viral_genes",
    "host_genes",
    "checkv_quality",
    "miuvig_quality",
    "completeness",
    "completeness_method",
    "contamination",
    "kmer_freq",
    "warnings",
]


def _write_rows(path, rows, delimiter="\t", encoding="utf-8"):
    """Write rows (lists of fields) to a delimited file and return the path."""
    path.write_text(
        "".join(delimiter.join(row) + "\n" for row in rows), encoding=encoding
    )
    return path


def _read_evidence(path):
    """Read the detection evidence table as a list of dicts."""
    with open(path) as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def _call(sequence_id, contig, quality, rule, **values):
    """Make a row of the detection calls table, with NA for the values not given."""
    row = {
        "sequence_id": sequence_id,
        "contig": contig,
        "virify_quality": quality,
        "rule": rule,
        **values,
    }
    return [row.get(column, "NA") for column in CALL_COLUMNS]


def _checkv(contig_id, quality, completeness):
    """Make a row of a CheckV quality summary."""
    row = {
        "contig_id": contig_id,
        "checkv_quality": quality,
        "miuvig_quality": quality,
        "completeness": completeness,
        "completeness_method": "AAI-based (high-confidence)",
        "contamination": "0.0",
    }
    return [row.get(column, "") for column in CHECKV_COLUMNS]


def _tool_tables(tmp_path, contig, virfinder_rows=None):
    """Write a VirFinder and a PPR-Meta table, with an extra contig that is not called."""
    virfinder = _write_rows(
        tmp_path / "virfinder.tsv",
        [
            ["name", "length", "score", "pvalue"],
            *(virfinder_rows or [[contig, "6015", "0.98", "0.001"]]),
            ["seq99", "2000", "0.10", "0.50"],
        ],
    )
    pprmeta = _write_rows(
        tmp_path / "pprmeta.csv",
        [
            ["Header", "Length", "phage_score", "Possible_source"],
            [contig, "6015", "0.91", "phage"],
            ["seq99", "2000", "0.01", "chromosome"],
        ],
        delimiter=",",
    )
    return virfinder, pprmeta


def test_evidence_for_contig_in_low_confidence_and_prophage(tmp_path):
    """A contig that is LC (VirFinder) and has a VirSorter2 prophage call.

    The table has one row per category, with the short names of the map file, the
    values of each tool and the CheckV row of each sequence.
    """
    calls = _write_rows(
        tmp_path / "detection_calls.tsv",
        [
            CALL_COLUMNS,
            _call("seq1", "seq1", "LC", "virfinder_score_0.9", circular="False"),
            _call(
                "seq1|prophage-3367:4857",
                "seq1",
                "PP",
                "virsorter2_prophage",
                prophage_start="3367",
                prophage_end="4857",
                circular="False",
                virsorter2_max_score="0.95",
                virsorter2_max_score_group="ssDNA",
                virsorter2_shape="circular",
            ),
        ],
    )
    virfinder, pprmeta = _tool_tables(tmp_path, "seq1")
    map_file = _write_rows(
        tmp_path / "map.tsv",
        [
            ["original", "temporary", "short"],
            ["ERZ1_1674 length=6015", "seq1", "ERZ1_1674"],
            ["ERZ1_99", "seq99", "ERZ1_99"],
        ],
    )
    checkv_lc = _write_rows(
        tmp_path / "low_confidence_viral_contigs_quality_summary.tsv",
        [CHECKV_COLUMNS, _checkv("ERZ1_1674", "Complete", "100.0")],
    )
    checkv_pp = _write_rows(
        tmp_path / "prophages_quality_summary.tsv",
        [CHECKV_COLUMNS, _checkv("ERZ1_1674|prophage-3367:4857", "Low-quality", "")],
    )
    output = tmp_path / "evidence.tsv"

    row_count = write_detection_evidence(
        calls, virfinder, pprmeta, [checkv_lc, checkv_pp], map_file, output
    )

    rows = _read_evidence(output)
    assert row_count == 2
    assert list(rows[0].keys()) == EVIDENCE_COLUMNS
    tool_values = {
        "contig": "ERZ1_1674",
        "virfinder_score": "0.98",
        "virfinder_pvalue": "0.001",
        "pprmeta_possible_source": "phage",
        "pprmeta_phage_score": "0.91",
        "virsorter_category": "NA",
        "completeness_method": "AAI-based (high-confidence)",
        "contamination": "0.0",
    }
    assert rows == [
        {
            **tool_values,
            "sequence_id": "ERZ1_1674",
            "virify_quality": "LC",
            "rule": "virfinder_score_0.9",
            "prophage_start": "NA",
            "prophage_end": "NA",
            "circular": "False",
            "virsorter2_max_score": "NA",
            "virsorter2_max_score_group": "NA",
            "virsorter2_shape": "NA",
            "checkv_quality": "Complete",
            "miuvig_quality": "Complete",
            "completeness": "100.0",
        },
        {
            **tool_values,
            "sequence_id": "ERZ1_1674|prophage-3367:4857",
            "virify_quality": "PP",
            "rule": "virsorter2_prophage",
            "prophage_start": "3367",
            "prophage_end": "4857",
            "circular": "False",
            "virsorter2_max_score": "0.95",
            "virsorter2_max_score_group": "ssDNA",
            "virsorter2_shape": "circular",
            "checkv_quality": "Low-quality",
            "miuvig_quality": "Low-quality",
            # CheckV writes an empty completeness when it cannot estimate it
            "completeness": "NA",
        },
    ]


def test_evidence_matches_checkv_row_of_circular_contig(tmp_path):
    """The sequence_id gets the RESTORE format, so it matches the CheckV contig_id."""
    calls = _write_rows(
        tmp_path / "detection_calls.tsv",
        [
            CALL_COLUMNS,
            _call("seq7|phage-circular", "seq7", "HC", "virsorter2_high_confidence"),
        ],
    )
    virfinder, pprmeta = _tool_tables(tmp_path, "seq7")
    map_file = _write_rows(
        tmp_path / "map.tsv",
        [["original", "temporary", "short"], ["ERZ1_7", "seq7", "ERZ1_7"]],
    )
    checkv = _write_rows(
        tmp_path / "high_confidence_viral_contigs_quality_summary.tsv",
        [CHECKV_COLUMNS, _checkv("ERZ1_7|phage-circular", "Complete", "100.0")],
    )
    output = tmp_path / "evidence.tsv"

    write_detection_evidence(calls, virfinder, pprmeta, [checkv], map_file, output)

    rows = _read_evidence(output)
    assert [(row["sequence_id"], row["checkv_quality"]) for row in rows] == [
        ("ERZ1_7|phage-circular", "Complete")
    ]


def test_evidence_without_checkv_has_na(tmp_path):
    """A sample without CheckV results (no proteins left) gets NA in the CheckV columns."""
    calls = _write_rows(
        tmp_path / "detection_calls.tsv",
        [CALL_COLUMNS, _call("seq1", "seq1", "LC", "virfinder_score_0.9")],
    )
    virfinder, pprmeta = _tool_tables(tmp_path, "seq1")
    output = tmp_path / "evidence.tsv"

    write_detection_evidence(calls, virfinder, pprmeta, [], None, output)

    (row,) = _read_evidence(output)
    assert row["sequence_id"] == "seq1"
    assert row["virfinder_score"] == "0.98"
    assert [row[column] for column in EVIDENCE_COLUMNS[-5:]] == ["NA"] * 5


def test_evidence_without_calls_does_not_read_tool_tables(tmp_path):
    """Without calls the table has only the header, and the tool tables are not read.

    The VirFinder table has two rows for one contig. A read would raise an error.
    """
    calls = _write_rows(tmp_path / "detection_calls.tsv", [CALL_COLUMNS])
    virfinder, pprmeta = _tool_tables(
        tmp_path,
        "seq1",
        [["seq1", "2000", "0.95", "0.01"], ["seq1", "2000", "0.20", "0.50"]],
    )
    output = tmp_path / "evidence.tsv"

    row_count = write_detection_evidence(calls, virfinder, pprmeta, [], None, output)

    assert row_count == 0
    assert output.read_text() == "\t".join(EVIDENCE_COLUMNS) + "\n"


def test_evidence_rejects_duplicate_tool_rows(tmp_path):
    """Two VirFinder rows for a called contig give an error, not the values of one row."""
    calls = _write_rows(
        tmp_path / "detection_calls.tsv",
        [CALL_COLUMNS, _call("seq1", "seq1", "LC", "virfinder_score_0.9")],
    )
    virfinder, pprmeta = _tool_tables(
        tmp_path,
        "seq1",
        [["seq1", "2000", "0.95", "0.01"], ["seq1", "2000", "0.20", "0.50"]],
    )

    with pytest.raises(ValueError, match="More than one row for seq1"):
        write_detection_evidence(
            calls, virfinder, pprmeta, [], None, tmp_path / "evidence.tsv"
        )


def test_read_rows_keeps_only_given_ids_and_removes_bom(tmp_path):
    """Only the rows of the given IDs are kept, and a byte-order mark is removed."""
    virfinder = _write_rows(
        tmp_path / "virfinder.tsv",
        [
            ["name", "length", "score", "pvalue"],
            ["seq1", "2000", "0.95", "0.01"],
            ["seq2", "2000", "0.10", "0.50"],
        ],
        encoding="utf-8-sig",
    )

    kept = read_rows(virfinder, "name", "\t", {"seq1"})

    assert list(kept) == ["seq1"]
    assert kept["seq1"]["score"] == "0.95"


def test_restore_sequence_id():
    """With a map, RESTORE puts phage-circular first. Without a map, the ID is kept."""
    names = {"seq7": "ERZ1_7"}
    assert (
        restore_sequence_id("seq7|phage-circular", "seq7", names)
        == "ERZ1_7|phage-circular"
    )
    assert (
        restore_sequence_id("seq7|prophage-10:500|phage-circular", "seq7", names)
        == "ERZ1_7|phage-circular|prophage-10:500"
    )
    assert restore_sequence_id("seq9", "seq9", names) == "seq9"
    # Without a map file the full ID is kept, so IDs with "|" stay unique
    assert restore_sequence_id("seq1|sampleA", "seq1|sampleA", {}) == "seq1|sampleA"
    assert restore_sequence_id("seq1|sampleB", "seq1|sampleB", {}) == "seq1|sampleB"


def test_evidence_matches_checkv_row_without_circular_suffix(tmp_path):
    """A CheckV contig_id without |phage-circular also matches, as in write_viral_gff.py.

    The prophage coordinates stay in the key, so the PP row keeps its own CheckV row.
    """
    calls = _write_rows(
        tmp_path / "detection_calls.tsv",
        [
            CALL_COLUMNS,
            _call("seq7|phage-circular", "seq7", "HC", "virsorter2_high_confidence"),
            _call("seq8|prophage-10:500", "seq8", "PP", "virsorter2_prophage"),
        ],
    )
    virfinder, pprmeta = _tool_tables(tmp_path, "seq7")
    map_file = _write_rows(
        tmp_path / "map.tsv",
        [
            ["original", "temporary", "short"],
            ["ERZ1_7", "seq7", "ERZ1_7"],
            ["ERZ1_8", "seq8", "ERZ1_8"],
        ],
    )
    checkv = _write_rows(
        tmp_path / "quality_summary.tsv",
        [
            CHECKV_COLUMNS,
            _checkv("ERZ1_7", "Complete", "100.0"),
            _checkv("ERZ1_8", "High-quality", "95.0"),
            _checkv("ERZ1_8|prophage-10:500", "Low-quality", "20.0"),
        ],
    )
    output = tmp_path / "evidence.tsv"

    write_detection_evidence(calls, virfinder, pprmeta, [checkv], map_file, output)

    rows = _read_evidence(output)
    assert [(row["sequence_id"], row["checkv_quality"]) for row in rows] == [
        ("ERZ1_7|phage-circular", "Complete"),
        ("ERZ1_8|prophage-10:500", "Low-quality"),
    ]


def test_evidence_with_bar_in_temporary_name(tmp_path):
    """A temporary name with "|" gets its short name. Only the text after it has suffixes."""
    calls = _write_rows(
        tmp_path / "detection_calls.tsv",
        [CALL_COLUMNS, _call("seq1|x", "seq1|x", "LC", "virfinder_score_0.9")],
    )
    virfinder, pprmeta = _tool_tables(tmp_path, "seq1|x")
    map_file = _write_rows(
        tmp_path / "map.tsv",
        [["original", "temporary", "short"], ["ERZ1_1", "seq1|x", "ERZ1_1"]],
    )
    output = tmp_path / "evidence.tsv"

    write_detection_evidence(calls, virfinder, pprmeta, [], map_file, output)

    (row,) = _read_evidence(output)
    assert (row["sequence_id"], row["contig"]) == ("ERZ1_1", "ERZ1_1")
