import os

import pandas as pd

from bin.viral_contigs_annotation import extract_annotations, parse_gff

FIXTURES = os.path.join(os.path.dirname(__file__), "viral_contigs_annotation_fixtures")


def fixture(filename):
    return os.path.join(FIXTURES, filename)


class TestParseGff:
    def test_basic(self):
        gff_data = parse_gff(fixture("test.gff"))

        assert len(gff_data) == 4
        assert "contig1_1" in gff_data
        assert "contig1_2" in gff_data
        assert "contig2_1" in gff_data
        assert "contig2_2" in gff_data

    def test_entry_fields(self):
        gff_data = parse_gff(fixture("test.gff"))
        entry = gff_data["contig1_1"]

        assert entry["contig"] == "contig1"
        assert entry["start"] == "1"
        assert entry["end"] == "100"
        assert entry["strand"] == "+"

    def test_ignores_non_cds_records(self, tmp_path):
        gff = tmp_path / "mixed.gff"
        gff.write_text(
            "##gff-version 3\n"
            "contig1\t.\tregion\t1\t1000\t.\t.\t.\tID=contig1\n"
            "contig1\tProdigal\tCDS\t1\t100\t.\t+\t0\tID=contig1_1\n"
        )
        gff_data = parse_gff(str(gff))

        assert len(gff_data) == 1
        assert "contig1_1" in gff_data

    def test_ignores_comment_lines(self, tmp_path):
        gff = tmp_path / "comments.gff"
        gff.write_text(
            "##gff-version 3\n"
            "##sequence-region contig1 1 1000\n"
            "contig1\tProdigal\tCDS\t1\t100\t.\t+\t0\tID=contig1_1\n"
        )
        gff_data = parse_gff(str(gff))

        assert len(gff_data) == 1

    def test_empty_gff(self, tmp_path):
        gff = tmp_path / "empty.gff"
        gff.write_text("##gff-version 3\n")
        gff_data = parse_gff(str(gff))

        assert gff_data == {}

    def test_prophage_seqid_preserved(self):
        gff_data = parse_gff(fixture("prophage.gff"))

        assert (
            gff_data["contig1|prophage-1000:2000_5"]["contig"]
            == "contig1|prophage-1000:2000"
        )
        assert (
            gff_data["contig1|prophage-1000:2000_6"]["contig"]
            == "contig1|prophage-1000:2000"
        )
        assert gff_data["MGYG000495417_00791"]["contig"] == "contig3|prophage-2:220"


class TestExtractAnnotations:
    def _to_df(self, annotations):
        return pd.DataFrame(
            annotations,
            columns=[
                "Contig",
                "CDS_ID",
                "Start",
                "End",
                "Direction",
                "Best_hit",
                "Abs_Evalue_exp",
                "Label",
            ],
        )

    def test_basic_all_hits(self):
        gff_data = parse_gff(fixture("test.gff"))
        annotations = extract_annotations(fixture("test_ratio_evalue.tsv"), gff_data)
        df = self._to_df(annotations)

        assert len(df) == 4

        assert df.iloc[0]["Contig"] == "contig1"
        assert df.iloc[0]["CDS_ID"] == "contig1_1"
        assert df.iloc[0]["Start"] == "1"
        assert df.iloc[0]["End"] == "100"
        assert df.iloc[0]["Direction"] == "+"
        assert df.iloc[0]["Best_hit"] == "VPHOG_0001"
        assert df.iloc[0]["Abs_Evalue_exp"] == 1e-10
        assert df.iloc[0]["Label"] == "Caudo"

        assert df.iloc[1]["CDS_ID"] == "contig1_2"
        assert df.iloc[1]["Best_hit"] == "VPHOG_0002"
        assert df.iloc[1]["Label"] == "Herelle"

    def test_no_hit_proteins_included(self):
        gff_data = parse_gff(fixture("test.gff"))
        annotations = extract_annotations(
            fixture("test_ratio_evalue_mixed.tsv"), gff_data
        )
        df = self._to_df(annotations)

        # all 4 proteins appear regardless of hit status
        assert len(df) == 4

        hits = df[df["Best_hit"] != "No hit"]
        no_hits = df[df["Best_hit"] == "No hit"]

        assert len(hits) == 3
        assert len(no_hits) == 1
        assert no_hits.iloc[0]["Abs_Evalue_exp"] == "NA"
        assert no_hits.iloc[0]["Label"] == ""

    def test_multiple_hits_picks_best_evalue(self):
        gff_data = parse_gff(fixture("multiple_hits.gff"))
        annotations = extract_annotations(fixture("multiple_hits_ratio.tsv"), gff_data)
        df = self._to_df(annotations)

        assert len(df) == 1
        # max Abs_Evalue_exp wins (1e-10 > 1e-20)
        assert df.iloc[0]["Best_hit"] == "VPHOG_0001"
        assert df.iloc[0]["Abs_Evalue_exp"] == 1e-10

    def test_contig_id_comes_from_gff_seqid(self):
        gff_data = parse_gff(fixture("contig_id_extraction.gff"))
        annotations = extract_annotations(
            fixture("contig_id_extraction_ratio.tsv"), gff_data
        )
        df = self._to_df(annotations)

        assert len(df) == 3
        contigs = set(df["Contig"])
        assert "contig1" in contigs
        assert "contig2" in contigs
        assert "NODE_1_length_1000_cov_5" in contigs

    def test_prophage_seqid_preserved_in_contig_column(self):
        gff_data = parse_gff(fixture("prophage.gff"))
        annotations = extract_annotations(fixture("prophage_ratio.tsv"), gff_data)
        df = self._to_df(annotations)

        assert len(df) == 6
        contig1_rows = df[df["Contig"] == "contig1|prophage-1000:2000"]
        contig2_rows = df[df["Contig"] == "contig2|prophage-1:2000"]
        contig3_rows = df[df["Contig"] == "contig3|prophage-2:220"]
        assert len(contig1_rows) == 2
        assert len(contig2_rows) == 2
        assert len(contig3_rows) == 2
        assert all(contig1_rows["Best_hit"] != "No hit")
        assert all(contig2_rows["Best_hit"] != "No hit")

    def test_empty_gff_data_returns_empty(self):
        annotations = extract_annotations(fixture("test_ratio_evalue.tsv"), {})

        assert annotations == []

    def test_coordinates_come_from_gff(self):
        gff_data = parse_gff(fixture("test.gff"))
        annotations = extract_annotations(fixture("test_ratio_evalue.tsv"), gff_data)
        df = self._to_df(annotations)

        # coordinates and strand are taken directly from GFF columns
        row = df[df["CDS_ID"] == "contig1_2"].iloc[0]
        assert row["Start"] == "101"
        assert row["End"] == "200"
        assert row["Direction"] == "-"
