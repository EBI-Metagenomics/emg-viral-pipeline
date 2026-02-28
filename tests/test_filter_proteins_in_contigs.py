#!/bin/env python3

from pathlib import Path

import pytest

from bin.filter_proteins_in_contigs import (
    _PRODIGAL_PATTERN,
    filter_proteins,
    get_contig_ids,
    protein_belongs_to_contigs,
)


FIXTURES = Path(__file__).parent / "filter_proteins_in_contigs"

# Loaded once at collection time for the large parametrized tests
_CONTIG_SAMPLE: set[str] = set(
    (FIXTURES / "contigs_sample.txt").read_text().splitlines()
)
_MATCHING_PROTEINS: list[str] = [
    line.split("\t")[0]
    for line in (FIXTURES / "matching_proteins.txt").read_text().splitlines()
    if line.strip()
]
_NON_MATCHING_PROTEINS: list[str] = [
    line.split("\t")[0]
    for line in (FIXTURES / "non_matching_proteins.txt").read_text().splitlines()
    if line.strip()
]


@pytest.fixture
def contig_ids():
    return get_contig_ids(FIXTURES / "contigs_filtered.fasta")


@pytest.mark.parametrize(
    "protein_id, contig_ids",
    [
        ("NODE_1_length_100_cov_10_1", {"NODE_1_length_100_cov_10"}),
        ("NODE_1_length_100_cov_10_2", {"NODE_1_length_100_cov_10"}),
        (
            "NODE_1_length_100_cov_10_1_100_200_+",
            {"NODE_1_length_100_cov_10"},
        ),  # FGS-style
    ],
)
def test_protein_belongs_to_contigs(protein_id, contig_ids):
    assert protein_belongs_to_contigs(protein_id, contig_ids)


@pytest.mark.parametrize(
    "protein_id, contig_ids",
    [
        (
            "NODE_2_length_100_cov_10_1",
            {"NODE_1_length_100_cov_10"},
        ),  # different contig
        ("NODE_10_1", {"NODE_1"}),  # NODE_1 must not match NODE_10
        ("NODE_1_1", set()),  # empty allowed set
    ],
)
def test_protein_not_belongs_to_contigs(protein_id, contig_ids):
    assert not protein_belongs_to_contigs(protein_id, contig_ids)


@pytest.mark.parametrize("protein_id", _MATCHING_PROTEINS)
def test_matching_proteins_from_real_data(protein_id):
    assert protein_belongs_to_contigs(protein_id, _CONTIG_SAMPLE)


@pytest.mark.parametrize("protein_id", _NON_MATCHING_PROTEINS)
def test_non_matching_proteins_from_real_data(protein_id):
    assert not protein_belongs_to_contigs(protein_id, _CONTIG_SAMPLE)


@pytest.mark.parametrize(
    "description",
    [
        "NODE_1_1 # 1 # 100 # 1 # ID=1_1;partial=00;start_type=ATG",  # + strand
        "NODE_1_2 # 200 # 300 # -1 # ID=1_2;partial=00",  # - strand
    ],
)
def test_prodigal_pattern_matches(description):
    assert _PRODIGAL_PATTERN.search(description)


@pytest.mark.parametrize(
    "description",
    [
        "NODE_1_1_100_200_+",  # FGS-style, no coordinate block
        "NODE_1_1",  # bare ID, no description
    ],
)
def test_prodigal_pattern_no_match(description):
    assert not _PRODIGAL_PATTERN.search(description)


def test_get_contig_ids(contig_ids):
    ids = get_contig_ids(FIXTURES / "contigs_filtered.fasta")
    assert ids == {
        "NODE_1_length_1501440_cov_27.559008",
        "NODE_3_length_498519_cov_223.607530",
    }


def test_filters_by_contig_and_prodigal_format(contig_ids, tmp_path):
    """Proteins from filtered-out contigs and non-Prodigal headers are removed."""
    total, written, non_prodigal = filter_proteins(
        FIXTURES / "proteins.faa", contig_ids, tmp_path / "filtered.faa"
    )
    assert total == 5
    assert written == 3  # NODE_1×2 + NODE_3×1
    assert non_prodigal == 1  # NODE_3_2 has no coordinate block


def test_non_prodigal_proteins_all_removed(contig_ids, tmp_path):
    """FGS-format proteins are all removed even when their contigs pass filtering."""
    total, written, non_prodigal = filter_proteins(
        FIXTURES / "proteins_fgs.faa", contig_ids, tmp_path / "filtered_fgs.faa"
    )
    assert total == 3
    assert written == 0
    assert non_prodigal == 2  # NODE_1 and NODE_3 proteins in FGS format, NODE_2 is missing from contigs_ids
