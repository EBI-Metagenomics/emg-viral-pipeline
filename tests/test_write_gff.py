#!/bin/env python3

import os
from pathlib import Path
import unittest
from unittest.mock import patch
import glob
import pytest

from bin.parse_viral_pred import Record
from bin.write_viral_gff import (
    write_gff,
    get_contig_lengths_per_contig,
    get_annotation_results,
    get_proteins_from_gff,
    define_virify_quality,
    get_checkv_results,
    get_taxonomy_results,
    get_sequence_regions,
)


def _build_gff_inputs(annotation_files, checkv_files, gff_files, contigs_len_dict):
    """Replace the old aggregate_annotations: derive virify_quality, cds_best_hits, viral_sequences, cds_annotations."""
    virify_quality = define_virify_quality(checkv_files)
    cds_best_hits = get_annotation_results(annotation_files, contigs_len_dict)
    viral_sequences, cds_annotations = get_proteins_from_gff(
        gff_files, contigs_len_dict, cds_best_hits
    )
    return viral_sequences, cds_annotations, virify_quality


class TestWriteGFF(unittest.TestCase):
    def _build_path(self, folder):
        return os.path.abspath("/" + os.path.dirname(__file__) + folder)

    def test_record_clean_method(self):
        inputs = [
            "pos.phage.0|prophage-21696:135184_3",
            "justAtest**3,x|prophage-21:184_888",
            "NODE_1_length_79063_cov_13.902377",
            "NODE_2_length_876543_cov_16.902388|phage-circular",
            "NODE_3_length_637829_cov_11.42453|prophage-100:500",
            "NODE_3_length_637829_cov_11.42453|prophage-21696:135184",
        ]
        expected = [
            "pos.phage.0_3",
            "justAtest**3,x_888",
            "NODE_1_length_79063_cov_13.902377",
            "NODE_2_length_876543_cov_16.902388",
            "NODE_3_length_637829_cov_11.42453",
            "NODE_3_length_637829_cov_11.42453",
        ]
        inputs_cleaned = map(Record.remove_prophage_from_contig, inputs)
        self.assertListEqual(list(inputs_cleaned), expected)

    def test_record_prophage_metadata_extract(self):
        inputs = [
            "pos.phage.0|prophage-21696:135184_3",
            "justAtest**3,x|prophage-21:184_888",
            "NODE_1_length_79063_cov_13.902377",
            "NODE_2_length_876543_cov_16.902388|phage-circular",
            "NODE_3_length_637829_cov_11.42453|prophage-100:500",
            "NODE_3_length_637829_cov_11.42453|prophage-21696:135184",
        ]
        expected = [
            (21696, 135184, False),
            (21, 184, False),
            (None, None, False),
            (None, None, True),
            (100, 500, False),
            (21696, 135184, False),
        ]
        extraction = map(Record.get_prophage_metadata_from_contig, inputs)
        self.assertListEqual(list(extraction), expected)

    def test_gff_making(self):
        annotation_files = glob.glob(
            self._build_path("/write_viral_gff/simple_test/annotations") + "/*.tsv"
        )
        checkv_files = glob.glob(
            self._build_path("/write_viral_gff/simple_test/checkv") + "/*.tsv"
        )
        taxonomy_files = glob.glob(
            self._build_path("/write_viral_gff/simple_test/taxonomy") + "/*.tsv"
        )
        gff_files = glob.glob(
            self._build_path("/write_viral_gff/simple_test/gff") + "/*.gff"
        )
        assembly_file = self._build_path("/write_viral_gff/simple_test") + "/assembly.fasta"

        contigs_len_dict = get_contig_lengths_per_contig(assembly_file)
        viral_sequences, cds_annotations, virify_quality = _build_gff_inputs(
            annotation_files, checkv_files, gff_files, contigs_len_dict
        )
        sequence_regions = get_sequence_regions(viral_sequences, contigs_len_dict)
        checkv_dict = get_checkv_results(checkv_files, sequence_regions)
        taxonomy_dict = get_taxonomy_results(taxonomy_files)

        write_gff(
            checkv_dict,
            taxonomy_dict,
            "pos.phage.0",
            viral_sequences,
            cds_annotations,
            virify_quality,
            contigs_len_dict,
            sequence_regions,
        )

        with open("pos.phage.0_virify.gff") as f:
            content = f.read()

        # Mobile element records present for all categories
        self.assertIn("pos.phage.1\tVIRify\tviral_sequence", content)
        self.assertIn("pos.phage.0\tVIRify\tprophage", content)
        self.assertIn("pos.phage.3\tVIRify\tviral_sequence", content)

        # Quality labels reflect HC/LC/PP annotation files
        self.assertIn("virify_quality=HC", content)
        self.assertIn("virify_quality=LC", content)
        self.assertIn("virify_quality=PP", content)

        # CheckV attributes present
        self.assertIn("checkv_quality=High-quality", content)
        self.assertIn("checkv_quality=Medium-quality", content)

        # ViPhOG hits present in CDS records
        self.assertIn("viphog=ViPhOG1981", content)
        self.assertIn("viphog=ViPhOG1204", content)

        # Taxonomy present
        self.assertIn("taxonomy=Viruses", content)

        # All proteins appear (new behaviour), not just ViPhOG-hit ones
        total_cds = content.count("\tCDS\t")
        hit_cds = sum(1 for line in content.splitlines() if "viphog=" in line)
        self.assertGreater(total_cds, hit_cds)

        if os.path.exists("pos.phage.0_virify.gff"):
            os.unlink("pos.phage.0_virify.gff")

    def test_prophage_coordinate_truncation_in_gff(self):
        """Test that prophage coordinates exceeding contig length are truncated in GFF output."""

        assembly_fasta = (
            self._build_path("/write_viral_gff/circular_visorter2_fixtures")
            + "/assembly.fasta"
        )
        annotations_tsv = (
            self._build_path("/write_viral_gff/circular_visorter2_fixtures")
            + "/annotations.tsv"
        )
        annotations_gff = (
            self._build_path("/write_viral_gff/circular_visorter2_fixtures")
            + "/annotations.gff"
        )
        checkv_tsv = (
            self._build_path("/write_viral_gff/circular_visorter2_fixtures") + "/checkv.tsv"
        )
        taxonomy_tsv = (
            self._build_path("/write_viral_gff/circular_visorter2_fixtures") + "/taxonomy.tsv"
        )

        contigs_len_dict = get_contig_lengths_per_contig(assembly_fasta)

        viral_sequences, cds_annotations, virify_quality = _build_gff_inputs(
            [annotations_tsv], [checkv_tsv], [annotations_gff], contigs_len_dict
        )

        # Verify that prophage coordinates were truncated in the viral_sequences.
        # Clarification -> the prophage annotation from VirSorter2 will have the contig name test_contig|prophage-500:1200
        # which contains the overhanging annotation, we shouldn't change this, users are warned about this in the README
        # But we do change this in the GFF otherwise is invalid
        self.assertIn("test_contig|prophage-500:1200", viral_sequences)
        prophage_types = list(viral_sequences["test_contig|prophage-500:1200"])
        # Should contain the truncated coordinates, not the original ones
        self.assertTrue(any("prophage-500:1000" in s for s in prophage_types))
        self.assertFalse(any("prophage-500:1200" in s for s in prophage_types))

        sequence_regions = get_sequence_regions(viral_sequences, contigs_len_dict)
        checkv_dict = get_checkv_results([checkv_tsv], sequence_regions)
        taxonomy_dict = get_taxonomy_results([taxonomy_tsv])

        write_gff(
            checkv_dict,
            taxonomy_dict,
            "test_sample",
            viral_sequences,
            cds_annotations,
            virify_quality,
            contigs_len_dict,
            sequence_regions,
        )

        # Read the generated GFF and verify prophage coordinates were truncated
        with open("test_sample_virify.gff", "r") as gff_file:
            gff_content = gff_file.read()
            # The prophage end coordinate should be truncated from 1200 to 1000
            self.assertIn("prophage-500:1000", gff_content)
            self.assertTrue("prophage-500:1000_2", gff_content)
            self.assertNotIn("prophage-500:1200", gff_content)

        # Clean up
        if os.path.exists("test_sample_virify.gff"):
            os.unlink("test_sample_virify.gff")


def test_phage_circular_checkv_key_normalization(tmp_path):
    """CheckV contig_id with |phage-circular suffix is correctly matched to
    the cleaned contig name used for the assembly lookup.

    Regression test for KeyError when checkV stores contig_id as
    'contig1|phage-circular' but write_gff looks up by the cleaned name
    'contig1'. The checkv_dict must be indexed by the cleaned name so that
    the lookup at the mobile-element attribute stage succeeds.
    """
    fixtures = Path(__file__).parent / "write_viral_gff/phage_circular_checkv_fixtures"
    assembly_fasta = fixtures / "assembly.fasta"
    annotation_tsv = fixtures / "annotations.tsv"
    annotation_gff = fixtures / "annotations.gff"
    checkv_tsv = fixtures / "checkv.tsv"
    taxonomy_tsv = fixtures / "taxonomy.tsv"

    contigs_len_dict = get_contig_lengths_per_contig(str(assembly_fasta))

    viral_sequences, cds_annotations, virify_quality = _build_gff_inputs(
        [str(annotation_tsv)], [str(checkv_tsv)], [str(annotation_gff)], contigs_len_dict
    )

    assert "contig1|phage-circular" in viral_sequences

    sample_prefix = str(tmp_path / "test_phage_circular")

    sequence_regions = get_sequence_regions(viral_sequences, contigs_len_dict)
    checkv_dict = get_checkv_results([str(checkv_tsv)], sequence_regions)
    taxonomy_dict = get_taxonomy_results([str(taxonomy_tsv)])

    # Must not raise KeyError
    write_gff(
        checkv_dict,
        taxonomy_dict,
        sample_prefix,
        viral_sequences,
        cds_annotations,
        virify_quality,
        contigs_len_dict,
        sequence_regions,
    )

    output_gff = tmp_path / "test_phage_circular_virify.gff"
    gff_content = output_gff.read_text()

    # The seqid column (col 1) must use the clean base name; the |phage-circular
    # suffix may still appear in CDS ID attributes, but never as a seqid.
    data_lines = [
        l for l in gff_content.splitlines() if l.strip() and not l.startswith("#")
    ]
    assert data_lines, "GFF output contains no data lines"
    seqids = {line.split("\t")[0] for line in data_lines}
    assert seqids == {"contig1"}, f"Unexpected seqids: {seqids}"
    # CheckV attributes must appear in the output
    assert "checkv_quality=High-quality" in gff_content


def test_no_checkv_match_raises_error():
    """get_checkv_results raises ValueError when no GFF contig has a CheckV result.

    This defensive bit of code is to prevent silent mismatches
    where the checkv file contains different contig names to the viral annotation output.
    """
    fixtures = Path(__file__).parent / "write_viral_gff/no_checkv_match"
    assembly = fixtures / "assembly.fasta"
    annotation = fixtures / "annotation.tsv"
    gff = fixtures / "annotation.gff"
    checkv = fixtures / "checkv.tsv"

    contigs_len_dict = get_contig_lengths_per_contig(str(assembly))
    viral_sequences, cds_annotations, virify_quality = _build_gff_inputs(
        [str(annotation)], [str(checkv)], [str(gff)], contigs_len_dict
    )
    sequence_regions = get_sequence_regions(viral_sequences, contigs_len_dict)

    with pytest.raises(ValueError, match="None of the.*GFF contigs"):
        get_checkv_results([str(checkv)], sequence_regions)


def test_partial_checkv_results_warns(tmp_path):
    """get_checkv_results logs a warning when some GFF contigs have no CheckV results.

    Ensures silent NA fallback is surfaced as a visible warning so uses (may)
    detect partial checkv runs or naming inconsistencies.
    """
    assembly = tmp_path / "assembly.fasta"
    assembly.write_text(">contig1\n" + "A" * 1000 + "\n>contig2\n" + "A" * 500 + "\n")

    CHECKV_HEADER = "\t".join(
        [
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
    )
    ANNOTATION_HEADER = "\t".join(
        [
            "Contig",
            "CDS_ID",
            "Start",
            "End",
            "Direction",
            "Best_hit",
            "Abs_Evalue_exp",
            "Label",
        ]
    )
    TAXONOMY_HEADER = "\t".join(
        [
            "contig_ID",
            "superkingdom",
            "kingdom",
            "phylum",
            "subphylum",
            "class",
            "order",
            "suborder",
            "family",
            "subfamily",
            "genus",
        ]
    )

    annotation = tmp_path / "annotation.tsv"
    annotation.write_text(
        ANNOTATION_HEADER
        + "\n"
        + "\t".join(["contig1", "contig1_1", "1", "100", "1", "No hit", "NA", ""])
        + "\n"
        + "\t".join(["contig2", "contig2_1", "1", "100", "1", "No hit", "NA", ""])
        + "\n"
    )

    gff = tmp_path / "annotation.gff"
    gff.write_text(
        "##gff-version 3\n"
        "contig1\tProdigal\tCDS\t1\t100\t.\t+\t0\tID=contig1_1\n"
        "contig2\tProdigal\tCDS\t1\t100\t.\t+\t0\tID=contig2_1\n"
    )

    # CheckV only covers contig1; contig2 is absent
    checkv = tmp_path / "checkv.tsv"
    checkv.write_text(
        CHECKV_HEADER
        + "\n"
        + "\t".join(
            [
                "contig1",
                "1000",
                "No",
                "NA",
                "2",
                "1",
                "0",
                "High-quality",
                "High-quality",
                "90.0",
                "HMM-based",
                "0.0",
                "1.0",
                "",
            ]
        )
        + "\n"
    )

    taxonomy = tmp_path / "taxonomy.tsv"
    taxonomy.write_text(TAXONOMY_HEADER + "\n")

    contigs_len_dict = get_contig_lengths_per_contig(str(assembly))
    viral_sequences, cds_annotations, virify_quality = _build_gff_inputs(
        [str(annotation)], [str(checkv)], [str(gff)], contigs_len_dict
    )
    sequence_regions = get_sequence_regions(viral_sequences, contigs_len_dict)

    with patch("logging.warning") as mock_warn:
        checkv_dict = get_checkv_results([str(checkv)], sequence_regions)
        taxonomy_dict = get_taxonomy_results([str(taxonomy)])
        write_gff(
            checkv_dict,
            taxonomy_dict,
            str(tmp_path / "test_partial_checkv"),
            viral_sequences,
            cds_annotations,
            virify_quality,
            contigs_len_dict,
            sequence_regions,
        )

    warned_messages = [str(call) for call in mock_warn.call_args_list]
    assert any(
        "1 viral contigs have no CheckV results" in msg for msg in warned_messages
    ), f"Expected partial checkv warning, got: {warned_messages}"


def test_contig_missing_from_assembly_is_skipped_with_warning(tmp_path):
    """Contig present in annotation TSV but absent from the assembly FASTA is skipped.

    Regression test for KeyError: '<contig_name>' when a contig in the
    annotation file has no matching entry in contigs_len_dict.
    Both the sequence-region header, the mobile-element record, and any
    associated CDS records for the missing contig must be omitted from the
    output GFF, and a WARNING must be emitted reporting the count.
    """

    fixtures = Path(__file__).parent / "write_viral_gff/missing_contig_fixtures"
    assembly_fasta = fixtures / "assembly.fasta"
    annotation_tsv = fixtures / "high_confidence_viral_contigs_annotation.tsv"
    annotation_gff = fixtures / "high_confidence_viral_contigs.gff"
    checkv_tsv = fixtures / "high_confidence_viral_contigs_quality_summary.tsv"
    taxonomy_tsv = fixtures / "high_confidence_viral_contigs_annotation_taxonomy.tsv"

    contigs_len_dict = get_contig_lengths_per_contig(str(assembly_fasta))

    viral_sequences, cds_annotations, virify_quality = _build_gff_inputs(
        [str(annotation_tsv)], [str(checkv_tsv)], [str(annotation_gff)], contigs_len_dict
    )

    # Both contigs appear in annotation output before write_gff filtering
    assert "valid_contig" in viral_sequences
    assert "missing_contig" in viral_sequences

    # Passing a full path as sample_prefix directs the output GFF into tmp_path
    sample_prefix = str(tmp_path / "test_missing_contig")

    with patch("logging.warning") as mock_warn:
        sequence_regions = get_sequence_regions(viral_sequences, contigs_len_dict)
        checkv_dict = get_checkv_results([str(checkv_tsv)], sequence_regions)
        taxonomy_dict = get_taxonomy_results([str(taxonomy_tsv)])
        write_gff(
            checkv_dict,
            taxonomy_dict,
            sample_prefix,
            viral_sequences,
            cds_annotations,
            virify_quality,
            contigs_len_dict,
            sequence_regions,
        )

    warned_messages = [str(call) for call in mock_warn.call_args_list]
    assert any(
        "1 contigs were not found in the assembly and were skipped" in msg
        for msg in warned_messages
    )

    output_gff = tmp_path / "test_missing_contig_virify.gff"
    gff_content = output_gff.read_text()
    assert "valid_contig" in gff_content
    assert "missing_contig" not in gff_content


def test_missing_annotation_file(tmp_path):
    """Contigs with no viral genes detected by CheckV are excluded; contigs with no
    annotation TSV get unclassified taxonomy; protein count in output matches input.

    ERZ27225067_9986 has viral_genes=0 and checkv_quality=Not-determined, so it must
    be absent from the final GFF.  ERZ27225067_9983 is HC with no annotation TSV, so
    it must appear with taxonomy=unclassified.  For every contig that does appear in
    the output, all CDS records from the input GFF files must be present.
    """
    fixtures = Path(__file__).parent / "write_viral_gff/missing_annotation_file"
    assembly = fixtures / "ERZ27225067_subseq_renamed_original.fasta"
    hc_gff = fixtures / "high_confidence_viral_contigs_split.gff"
    lc_gff = fixtures / "low_confidence_viral_contigs_split.gff"
    lc_annotation = fixtures / "low_confidence_viral_contigs_split_annotation.tsv"
    hc_checkv = fixtures / "high_confidence_viral_contigs_quality_summary.tsv"
    lc_checkv = fixtures / "low_confidence_viral_contigs_quality_summary.tsv"
    lc_taxonomy = fixtures / "low_confidence_viral_contigs_split_annotation_taxonomy.tsv"

    contigs_len_dict = get_contig_lengths_per_contig(str(assembly))

    gff_files = [str(hc_gff), str(lc_gff)]
    checkv_files = [str(hc_checkv), str(lc_checkv)]

    # Count CDS per contig in the input GFF files before running write_gff
    input_cds_per_contig: dict[str, int] = {}
    for gff_path in gff_files:
        with open(gff_path) as fh:
            for line in fh:
                if line.startswith("#"):
                    continue
                cols = line.strip().split("\t")
                if len(cols) == 9 and cols[2] == "CDS":
                    input_cds_per_contig[cols[0]] = input_cds_per_contig.get(cols[0], 0) + 1

    viral_sequences, cds_annotations, virify_quality = _build_gff_inputs(
        [str(lc_annotation)], checkv_files, gff_files, contigs_len_dict
    )
    sequence_regions = get_sequence_regions(viral_sequences, contigs_len_dict)
    checkv_dict = get_checkv_results(checkv_files, sequence_regions)
    taxonomy_dict = get_taxonomy_results([str(lc_taxonomy)])

    sample_prefix = str(tmp_path / "ERZ27225067")
    write_gff(
        checkv_dict,
        taxonomy_dict,
        sample_prefix,
        viral_sequences,
        cds_annotations,
        virify_quality,
        contigs_len_dict,
        sequence_regions,
    )

    content = (tmp_path / "ERZ27225067_virify.gff").read_text()

    # 9986 must be absent: CheckV found no viral genes, so it is filtered
    assert "ERZ27225067_9986" not in content

    # 9983 has no annotation TSV → taxonomy falls back to unclassified
    assert "ERZ27225067_9983" in content
    mobile_element_lines_9983 = [
        l for l in content.splitlines()
        if l.startswith("ERZ27225067_9983") and "viral_sequence" in l
    ]
    assert mobile_element_lines_9983, "9983 mobile-element record missing from output"
    assert any("taxonomy=unclassified" in l for l in mobile_element_lines_9983)

    # Protein count: every CDS from an included contig must appear in the output
    output_cds = content.count("\tCDS\t")
    expected_cds = sum(
        count for contig, count in input_cds_per_contig.items()
        if "ERZ27225067_9986" not in contig
    )
    assert output_cds == expected_cds, (
        f"CDS count mismatch: output has {output_cds}, expected {expected_cds} "
        f"(input counts per contig: {input_cds_per_contig})"
    )
