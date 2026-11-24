#!/usr/bin/env python3

import argparse
import csv
import os
import re
import sys
from copy import copy
from os.path import isfile
from pathlib import Path

import pandas as pd
from Bio import SeqIO

MAX_N_PCT = 50


class Record:
    """Simple class to aggregate the results"""

    def __init__(self, seq_record, category, circular=None, prange=None, evidence=None):
        """Record class.
        Parameters:
        - biopython SeqRecord instance
        - category: high_confidence, low_confidence or prophage
        - circular: bool or None
        - prange: prophage range
        - evidence: VirSorter values for the detection calls table
          (column name to value, see CALL_COLUMNS)
        """
        self.seq_id = seq_record.id
        self.category = category
        self.seq_record = seq_record
        self.circular = circular
        # applies to prophages only
        self.prange = prange or []
        self.evidence = evidence or {}

    def to_tsv(self):
        return [self.seq_id, self.category, self.circular, *self.prange]

    def get_seq_record(self):
        """Get the SeqRecord with the category and prange encoded in the header."""
        seq_record = copy(self.seq_record)
        if self.category == "prophage" and len(self.prange):
            seq_record.id += f"|prophage-{int(self.prange[0])}:{int(self.prange[1])}"
        if self.circular:
            seq_record.id += "|phage-circular"
        # clean
        seq_record.description = ""
        return seq_record

    def with_contig_sequence(self, contig_record):
        """Return a copy of this Record with the full assembly contig as sequence.

        VirSorter2 trims "full" viral sequences: it removes partial genes at the ends,
        the duplicated end of circular contigs and low-score ends. The trimmed record keeps
        the contig name, but the rest of VIRify works on the full contig (the proteins,
        the ViPhOG annotation and the GFF region cover the whole contig). Without this,
        the category FASTA has the contig name with only a part of the contig sequence.

        The VirSorter2 metadata (category, circular, prophage range) is kept.

        :param contig_record: The SeqRecord of the contig from the assembly
        :return: A new Record that holds the assembly sequence
        """
        return Record(
            contig_record, self.category, self.circular, self.prange, self.evidence
        )

    @staticmethod
    def get_prophage_metadata_from_contig(contig_header):
        """Obtain the prophage start and end positions.
        As well as if the prophage is circular.
        This method returns None,None,None if the header doesn't
        have a prophage.
        :param contig_header: A fasta header
        :return: (int) start, (int) end, (bool) circular
        """
        circular = "phage-circular" in contig_header
        if "prophage" in contig_header:
            prange = contig_header.split("prophage-")[1]
            match = re.search(
                r"(?P<start>\d+):(?P<end>\d+)", prange, re.IGNORECASE
            ).groupdict()
            start = int(match["start"])
            end = int(match["end"])
            return start, end, circular
        return None, None, circular

    @staticmethod
    def remove_prophage_from_contig(contig_header):
        """Remove any prophage annotations from a contig header

        :param contig_header: The contig header
        :return: The same contig header without prophage annotations
        """
        if "prophage" in contig_header:
            contig_header = re.sub(r"\|prophage\-\d+\:\d+", "", contig_header)
        if "phage-circular" in contig_header:
            contig_header = contig_header.replace("|phage-circular", "")
        return contig_header.replace("|", "")

    def __hash__(self):
        return hash(self.seq_id)

    def __eq__(self, other):
        return self.seq_id == other


def parse_pprmeta(file_name):
    """Extract phage hits from PPR-Meta."""
    lc_ids = set()

    if isfile(file_name):
        result_df = pd.read_csv(file_name, sep=",")

        lc_ids = set(
            result_df[(result_df["Possible_source"] == "phage")]["Header"].values
        )

    print(f"PPR-Meta found {len(lc_ids)} low confidence contigs.")

    return lc_ids


def parse_virus_finder(file_name):
    """Extract high and low confidence contigs from virus finder results."""
    hc_ids = set()
    lc_ids = set()

    if isfile(file_name):
        result_df = pd.read_csv(file_name, sep="\t")

        hc_ids = set(
            result_df[(result_df["pvalue"] < 0.05) & (result_df["score"] >= 0.90)][
                "name"
            ].values
        )

        lc_ids = set(
            result_df[
                (result_df["pvalue"] < 0.05)
                & (result_df["score"] >= 0.70)
                & (result_df["score"] < 0.9)
            ]["name"].values
        )

    print(f"Virus Finder found {len(hc_ids)} high confidence contigs.")
    print(f"Virus Finder found {len(lc_ids)} low confidence contigs.")

    return hc_ids, lc_ids


def _parse_virsorter_metadata(name):
    """Extract the fasta header metadata. Each fasta sequence has information encoded in the header.
    Virsorter format header has 3 flavors:
    - non-prophage: VIRSorter_seq124-circular-cat_1
                    VIRSorter_seq247-cat_2
    - prophage:     VIRSorter_NODE_306_length_14315_cov_22_151052_gene_1_gene_12-0-9235-cat_5
    Returns seq name (with no virsoter data), circular bool, prophage range as start:end
    """
    name = name.replace("VIRSorter_", "")
    # re to remove all the metadata from the header
    clean_re = r"(?:_gene_\d+_gene_\d+-\d+-\d+)?(?:-circular)?-cat_\d+$"
    clean_name = re.sub(clean_re, "", name)
    # prophage range
    match = re.search(r"\d+-(?P<start>\d+)-(?P<end>\d+)?(?:-circular)?-cat_\d+$", name)
    prange = None
    if match:
        prange = [match.group("start"), match.group("end")]
    return clean_name, "circular" in name, prange


def parse_virus_sorter(sorter_files):
    """Extract high, low and prophages confidence Records from virus sorter results.
    High confidence are contigs in the categories 1 and 2
    Low confidence are contigs in the category 3
    Putative prophages are in categories 4 and 5
    (which correspond to VirSorter confidence categories 1 and 2)
    """
    high_confidence = {}
    low_confidence = {}
    prophages = {}

    for file in sorter_files or []:
        if not isfile(file) or ".fasta" not in file:
            continue
        with open(file) as handle:
            for record in SeqIO.parse(handle, "fasta"):
                category = record.id[-1:]
                clean_name, circular, prange = _parse_virsorter_metadata(record.id)
                record.id = clean_name
                evidence = {"virsorter_category": category}
                if category in ["1", "2"]:
                    high_confidence[record.id] = Record(
                        record, "high_confidence", circular, evidence=evidence
                    )
                elif category == "3":
                    low_confidence[record.id] = Record(
                        record, "low_confidence", circular, evidence=evidence
                    )
                elif category in ["4", "5"]:
                    # add the prophage position within the contig
                    prophages.setdefault(record.id, []).append(
                        Record(record, "prophage", circular, prange, evidence)
                    )
                else:
                    print(f"Contig has an invalid category : {category}")

    print(f"Virus Sorter found {len(high_confidence)} high confidence contigs.")
    print(f"Virus Sorter found {len(low_confidence)} low confidence contigs.")
    print(f"Virus Sorter found {len(prophages)} putative prophages contigs.")

    return high_confidence, low_confidence, prophages


def parse_virus_sorter2(sorter_files, vs_cutoff):
    """Extract high, low and prophages confidence Records from virus sorter results.
    High confidence are contigs with confidence score >= confidence cutoff (0.9 per default).
    Low confidence are contigs with confidence score < confidence cutoff and > 0.5.
    Putative prophages are contigs with partial viral sequences. According to the VirSorter2 author
    partial viral sequences can only occur as prophages, full viral sequences can occur due to prophages or other origins though.

    VirSorter2 NOTE
    Note that suffix ||full, ||lt2gene and ||{i}_partial ({i} can be numbers starting from 0 to max number
    of viral fragments found in that contig) have been added to original sequence names to differentiate
    sub-sequences in case of multiple viral subsequences found in one contig.
    Partial sequences can be treated as proviruses since they are extracted from longer host sequences.
    Full sequences, however, can be proviruses or free virus since it can be a short fragment sequenced from
    a provirus region. Moreover, "full" sequences are just sequences with strong viral signal as a whole
    ("nearly full" is more accurate). They might be trimmed due to partial gene overhang at ends,
    duplicate segments from circular genomes, and an end trimming step for all identified viral sequences
    to find the optimal viral segments (longest within 95% of peak score by default). Again, the "full" sequences
    trimmed by the end trimming step should not be interpreted as provirus, since genes that have low impact on score,
    such as unknown gene or genes shared by host and virus, could be trimmed. If you prefer the full sequences
    (ending with ||full) not to be trimmed and leave it to specialized tools such as checkV,
    you can use --keep-original-seq option.
    """

    boundary_dtypes = {
        "seqname": "object",
        "trim_orf_index_start": "int64",
        "trim_orf_index_end": "int64",
        "trim_bp_start": "int64",
        "trim_bp_end": "int64",
        "trim_pr": "float64",
        "partial": "int64",
        "pr_full": "float64",
        "hallmark_cnt": "int64",
        "group": "object",
        "shape": "object",
        "seqname_new": "object",
    }

    high_confidence = {}
    low_confidence = {}
    prophages = {}

    final_boundary_file, final_score_file, final_combined_fa_file = "", "", ""
    for sorter_results_file in sorter_files:
        if "final-viral-boundary.tsv" in sorter_results_file:
            final_boundary_file = sorter_results_file
        elif "final-viral-score.tsv" in sorter_results_file:
            final_score_file = sorter_results_file
        elif "final-viral-combined.fa" in sorter_results_file:
            final_combined_fa_file = sorter_results_file
        else:
            print(
                "ERROR: The result files of VirSorter2 are incomplete. The code expects the files final-viral-{boundary,score}.tsv and final-viral-combined.fa.",
                file=sys.stderr,
            )
            return high_confidence, low_confidence, prophages

    boundary_df = pd.read_csv(
        final_boundary_file,
        sep="\t",
        usecols=list(boundary_dtypes.keys()),
        dtype=boundary_dtypes,
    )
    boundary_df.set_index("seqname_new", inplace=True)

    score_df = pd.read_csv(final_score_file, sep="\t")
    score_df.set_index("seqname", inplace=True)

    meta = score_df.merge(
        boundary_df,
        left_index=True,
        right_index=True,
        how="left",
        suffixes=("_score", "_boundary"),
    ).dropna(subset=["shape"])

    with open(final_combined_fa_file) as handle:
        for record in SeqIO.parse(handle, "fasta"):
            clean_name = record.id.split("|")[0]
            record_name = record.id  # does include ||
            max_score = meta["max_score"].get(record_name, None)
            circular = meta["shape"].get(record_name, None)
            prange = [
                meta["trim_bp_start"].get(record_name, None),
                meta["trim_bp_end"].get(record_name, None),
            ]

            if not circular or not max_score:
                continue
            # Keep the VirSorter2 values for the detection calls table. The shape is
            # kept as VirSorter2 wrote it: VIRify sets partial sequences to linear (below).
            # The score group is only evidence: a table without it gives NA
            score_group = (
                meta["max_score_group"].get(record_name)
                if "max_score_group" in meta
                else None
            )
            evidence = {
                "virsorter2_max_score": max_score,
                "virsorter2_max_score_group": score_group,
                "virsorter2_shape": circular,
            }
            circular = circular.startswith("circular")

            if "partial" in record.id:
                record.id = clean_name
                # In VirSorter2 records inherit "circular" label from the contig, which is incorrect for partial sequences
                # as they are extracted from the contig and might not be circular themselves.
                # https://github.com/jiarong/VirSorter2/issues/251
                # We rewrite "circular" to linear for partial sequences to avoid misinterpretation of the results.
                circular = False
                # add the prophage position within the contig
                prophages.setdefault(clean_name, []).append(
                    Record(record, "prophage", circular, prange, evidence)
                )
            else:
                record.id = clean_name
                if float(max_score) >= float(vs_cutoff):
                    high_confidence[clean_name] = Record(
                        record, "high_confidence", circular, evidence=evidence
                    )
                else:
                    low_confidence[clean_name] = Record(
                        record, "low_confidence", circular, evidence=evidence
                    )
    number_of_phages = sum([len(prophages[i]) for i in prophages])
    print(f"Virus Sorter2 found {len(high_confidence)} high confidence contigs.")
    print(f"Virus Sorter2 found {len(low_confidence)} low confidence contigs.")
    print(f"Virus Sorter2 found {number_of_phages} putative prophages contigs.")

    return high_confidence, low_confidence, prophages


def sanity_check_sequence(sequence):
    sequence = sequence.upper()
    # checking percentage of N-s in sequence
    n_pct = sequence.count("N") / len(sequence) * 100
    return n_pct < MAX_N_PCT


def merge_annotations(pprmeta, finder, sorter, sorter2, assembly, vs_cutoff, outdir):
    """Parse VirSorter, VirFinder and PPR-Meta outputs and merge the results.
    High confidence viral contigs:
    -  VirSorter reported as categories 1 and 2
    Low confidence viral contigs:
    - VirFinder reported p < 0.05 and score >= 0.9
    - OR ( VirFinder reported p < 0.05 and 0.7 <= score < 0.9 AND
      ( VirSorter reported as category 3 or PPR-Meta reported as phage)) )
    Putative prophages are prophages:
    - VirSorter reported as categories 4 and 5
      (which correspond to VirSorter confidence categories 1 and 2).
    Returns high conf., low and prophage SeqRecords,
            virsorter high conf., low conf. and prophage Records, and
            the assignments (one dict per written sequence, with the rule that
            put it in its category) for the detection calls table
    """
    hc_predictions_contigs = []
    lc_predictions_contigs = []
    prophage_predictions_contigs = []
    # One entry per written sequence, for the detection calls table
    assignments = []

    pprmeta_lc = parse_pprmeta(pprmeta)
    finder_lc, finder_lowestc = parse_virus_finder(finder)
    sorter_hc, sorter_lc, sorter_prophages = (
        parse_virus_sorter(sorter)
        if sorter is not None
        else parse_virus_sorter2(sorter2, vs_cutoff)
    )
    vs = "virsorter" if sorter else "virsorter2"

    def add(predictions, seq_record, contig, quality, rule, sorter_record=None):
        """Write a sequence to a category and record why it is in that category."""
        predictions.append(seq_record)
        assignments.append(
            {
                "sequence_id": seq_record.id,
                "contig": contig,
                "virify_quality": quality,
                "rule": rule,
                "sorter_record": sorter_record,
            }
        )

    skipped_contigs = []
    with open(assembly) as handle:
        for seq_record in SeqIO.parse(handle, "fasta"):
            contig = seq_record.id
            if not sanity_check_sequence(seq_record.seq):
                skipped_contigs.append(contig)
                continue
            # VirSorter record of the whole contig, if any (for the calls table)
            sorter_contig = sorter_hc.get(contig) or sorter_lc.get(contig)
            if sorter:
                # VirSorter1
                if contig in sorter_hc:
                    add(
                        hc_predictions_contigs,
                        sorter_hc.get(contig).get_seq_record(),
                        contig,
                        "HC",
                        f"{vs}_high_confidence",
                        sorter_hc.get(contig),
                    )
                    # Pro
                elif contig in sorter_prophages:
                    # a contig may have several prophages
                    # for prophages write the record as it holds the
                    # sliced fasta
                    for record in sorter_prophages.get(contig):
                        add(
                            prophage_predictions_contigs,
                            record.get_seq_record(),
                            contig,
                            "PP",
                            f"{vs}_prophage",
                            record,
                        )
                    # LC
                elif contig in finder_lc:
                    add(
                        lc_predictions_contigs,
                        seq_record,
                        contig,
                        "LC",
                        "virfinder_score_0.9",
                        sorter_contig,
                    )
                elif contig in sorter_lc and contig in finder_lowestc:
                    add(
                        lc_predictions_contigs,
                        sorter_lc.get(contig).get_seq_record(),
                        contig,
                        "LC",
                        f"{vs}_low_confidence_and_virfinder_score_0.7",
                        sorter_lc.get(contig),
                    )
                elif contig in pprmeta_lc and contig in finder_lowestc:
                    add(
                        lc_predictions_contigs,
                        seq_record,
                        contig,
                        "LC",
                        "pprmeta_phage_and_virfinder_score_0.7",
                        sorter_contig,
                    )
            else:
                # VirSorter2
                # Pro
                if contig in sorter_prophages:
                    # a contig may have several prophages
                    # for prophages write the record as it holds the
                    # sliced fasta
                    for record in sorter_prophages.get(contig):
                        add(
                            prophage_predictions_contigs,
                            record.get_seq_record(),
                            contig,
                            "PP",
                            f"{vs}_prophage",
                            record,
                        )
                # HC and LC: write the assembly contig, not the trimmed VirSorter2
                # sequence (see Record.with_contig_sequence). Prophages above keep the
                # VirSorter2 sequence, as the header has the prophage coordinates.
                # HC
                if contig in sorter_hc:
                    add(
                        hc_predictions_contigs,
                        sorter_hc.get(contig)
                        .with_contig_sequence(seq_record)
                        .get_seq_record(),
                        contig,
                        "HC",
                        f"{vs}_high_confidence",
                        sorter_hc.get(contig),
                    )
                # LC
                elif contig in finder_lc:
                    add(
                        lc_predictions_contigs,
                        seq_record,
                        contig,
                        "LC",
                        "virfinder_score_0.9",
                        sorter_contig,
                    )
                elif contig in sorter_lc and contig in finder_lowestc:
                    add(
                        lc_predictions_contigs,
                        sorter_lc.get(contig)
                        .with_contig_sequence(seq_record)
                        .get_seq_record(),
                        contig,
                        "LC",
                        f"{vs}_low_confidence_and_virfinder_score_0.7",
                        sorter_lc.get(contig),
                    )
                elif contig in pprmeta_lc and contig in finder_lowestc:
                    add(
                        lc_predictions_contigs,
                        seq_record,
                        contig,
                        "LC",
                        "pprmeta_phage_and_virfinder_score_0.7",
                        sorter_contig,
                    )

    print(f"Number of skipped contigs {len(skipped_contigs)}")
    # report skipped contigs
    if skipped_contigs:
        output_file = os.path.join(outdir, "sanity_check_failed_contigs.txt")
        with open(output_file, "w") as file_out:
            file_out.write("\n".join(skipped_contigs))
            print("Skipped contigs were written to {}")

    return (
        hc_predictions_contigs,
        lc_predictions_contigs,
        prophage_predictions_contigs,
        sorter_hc,
        sorter_lc,
        sorter_prophages,
        assignments,
    )


# Columns of detection_calls.tsv. write_detection_evidence.py adds the values of
# VirFinder, PPR-Meta and CheckV, and the short contig names.
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
MISSING_VALUE = "NA"


def is_circular(sequence_id, contig):
    """Return True if VIRify added the phage-circular suffix to the contig name.

    Only the suffixes after the contig name count, so a contig name that contains
    "phage-circular" does not make the call circular.

    :param sequence_id: The written sequence ID (contig name and VIRify suffixes).
    :param contig: The contig name of the assembly.
    :return: True for a circular call.
    """
    return "phage-circular" in sequence_id[len(contig) :].split("|")[1:]


def get_call_rows(assignments):
    """Build the rows of the detection calls table.

    :param assignments: Assignments from merge_annotations (one per written sequence).
    :return: List of rows (lists of text values), in the order of CALL_COLUMNS.
    """
    rows = []
    for assignment in assignments:
        sorter_record = assignment["sorter_record"]
        evidence = sorter_record.evidence if sorter_record else {}

        prophage_start = prophage_end = None
        if assignment["virify_quality"] == "PP" and sorter_record.prange:
            prophage_start, prophage_end = (int(pos) for pos in sorter_record.prange)

        values = {
            "sequence_id": assignment["sequence_id"],
            "contig": assignment["contig"],
            "virify_quality": assignment["virify_quality"],
            "rule": assignment["rule"],
            "prophage_start": prophage_start,
            "prophage_end": prophage_end,
            "circular": is_circular(assignment["sequence_id"], assignment["contig"]),
            **evidence,
        }
        rows.append(
            [
                MISSING_VALUE if values.get(column) is None else str(values[column])
                for column in CALL_COLUMNS
            ]
        )
    return rows


def write_detection_calls(assignments, output_file):
    """Write the detection calls table: one row per HC, LC or PP sequence.

    Each row has the rule that put the sequence in its category and the VirSorter (or
    VirSorter2) values. Only this script knows the rule, so it writes this table.

    :param assignments: Assignments from merge_annotations.
    :param output_file: Path of the TSV file to write.
    """
    with open(output_file, "w") as handle:
        tsv_writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        tsv_writer.writerow(CALL_COLUMNS)
        tsv_writer.writerows(get_call_rows(assignments))


def main(pprmeta, finder, sorter, sorter2, assembly, outdir, vs_cutoff, prefix=False):
    """Parse VirSorter, VirFinder and PPR-Meta outputs and merge the results."""
    outdir_path = Path(outdir)
    (
        hc_contigs,
        lc_contigs,
        prophage_contigs,
        sorter_hc,
        sorter_lc,
        sorter_prophages,
        assignments,
    ) = merge_annotations(pprmeta, finder, sorter, sorter2, assembly, vs_cutoff, outdir)

    at_least_one = False
    name_prefix = ""
    if prefix:
        name_prefix = Path(assembly).stem + "_"

    if not os.path.exists(outdir_path):
        os.mkdir(outdir_path)

    if len(hc_contigs):
        SeqIO.write(
            hc_contigs,
            outdir / Path(name_prefix + "high_confidence_viral_contigs.fna"),
            "fasta",
        )
        at_least_one = True
    else:
        print("No high confidence viral contigs found, skipping output file.")

    if len(lc_contigs):
        SeqIO.write(
            lc_contigs,
            outdir / Path(name_prefix + "low_confidence_viral_contigs.fna"),
            "fasta",
        )
        at_least_one = True
    else:
        print("No low confidence viral contigs found, skipping output file.")

    if len(prophage_contigs):
        SeqIO.write(
            prophage_contigs, outdir / Path(name_prefix + "prophages.fna"), "fasta"
        )
        at_least_one = True
    else:
        print("No prophage contigs found, skipping output file.")

    # VirSorter provides some metadata on each annotation
    # - is circular
    # - prophage start and end within a contig
    if sorter_hc or sorter_lc or sorter_prophages:
        with open(outdir_path / Path("virsorter_metadata.tsv"), "w") as pm_tsv_file:
            header = [
                "contig",
                "category",
                "circular",
                "prophage_start",
                "prophage_end",
            ]
            tsv_writer = csv.writer(pm_tsv_file, delimiter="\t")
            tsv_writer.writerow(header)
            tsv_writer.writerows([shc.to_tsv() for _, shc in sorter_hc.items()])
            tsv_writer.writerows([slc.to_tsv() for _, slc in sorter_lc.items()])
            for plist in sorter_prophages.values():
                tsv_writer.writerows([ph.to_tsv() for ph in plist])

    # Written also when no sequence is viral, so that the output always exists
    write_detection_calls(
        assignments, outdir_path / Path(name_prefix + "detection_calls.tsv")
    )

    if not at_least_one:
        print(
            "Overall, no putative _viral contigs or prophages were detected"
            " in the analysed metagenomic assembly",
            file=sys.stderr,
        )
        sys.exit(0)


if __name__ == "__main__":
    """Merge and convert VIRSorter and VIRFinder output contigs into:
    - high confidence viral contigs
    - low confidence viral contigs
    - putative prophages
    """
    parser = argparse.ArgumentParser(
        description="Write fasta files with predicted _viral contigs sorted in "
        "categories and putative prophages"
    )
    parser.add_argument(
        "-a",
        "--assemb",
        dest="assembly",
        help="Metagenomic assembly fasta file",
        required=True,
    )
    parser.add_argument(
        "-f",
        "--vfout",
        dest="finder",
        help="Absolute or " "relative path to VirFinder output file",
        required=False,
    )
    parser.add_argument(
        "-s",
        "--vsfiles",
        dest="sorter",
        nargs="+",
        help="VirSorter .fasta files (i.e. VIRSorter_cat-1.fasta)" " VirSorter output",
        required=False,
    )
    parser.add_argument(
        "-z",
        "--vs2files",
        dest="sorter2",
        nargs="+",
        help="VirSorter2 .tsv files (i.e. final-viral-{boundary,score}.tsv, final-viral-combined.fa)"
        " VirSorter2 output",
        required=False,
    )
    parser.add_argument(
        "-p",
        "--pmout",
        dest="pprmeta",
        help="Absolute or relative path to PPR-Meta output file" " PPR-Meta output",
        required=False,
    )
    parser.add_argument(
        "-y",
        "--vs_cutoff",
        dest="vs_cutoff",
        help="Cutoff to categorize sequences identified by VirSorter2 to high or low confidence (default: 0.9).",
        default=0.9,
        type=float,
    )
    parser.add_argument(
        "-r",
        "--prefix",
        dest="prefix",
        help="Use the assembly filename as prefix for the outputs",
        action="store_true",
    )
    parser.add_argument(
        "-o",
        "--outdir",
        dest="outdir",
        help="Absolute or relative path of directory where output"
        " _viral prediction files should be stored (default: cwd)",
        default=".",
    )
    args = parser.parse_args()

    main(
        args.pprmeta,
        args.finder,
        args.sorter,
        args.sorter2,
        args.assembly,
        args.outdir,
        args.vs_cutoff,
        prefix=args.prefix,
    )
