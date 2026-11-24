#!/usr/bin/env python3
# Copyright 2026 EMBL - European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Write the detection evidence table: one row per HC, LC or PP sequence.

The table joins the detection calls of parse_viral_pred.py (the rule and the VirSorter
values) with the VirFinder, PPR-Meta and CheckV values of each sequence. It uses the
short contig names of the GFF, so users can compare the calls of a contig that is in
more than one category.
"""

from __future__ import annotations

import argparse
import csv
import logging
from collections.abc import Callable, Iterable
from pathlib import Path

logger = logging.getLogger(__name__)

CHECKV_COLUMNS = [
    "checkv_quality",
    "miuvig_quality",
    "completeness",
    "completeness_method",
    "contamination",
]
EVIDENCE_COLUMNS = [
    "sequence_id",
    "contig",
    "virify_quality",
    "rule",
    "prophage_start",
    "prophage_end",
    "circular",
    "virfinder_score",
    "virfinder_pvalue",
    "pprmeta_possible_source",
    "pprmeta_phage_score",
    "virsorter_category",
    "virsorter2_max_score",
    "virsorter2_max_score_group",
    "virsorter2_shape",
    *CHECKV_COLUMNS,
]
MISSING_VALUE = "NA"


def get_checkv_key(sequence_id: str) -> str:
    """Return the key that links a sequence to its CheckV row.

    The key is the sequence ID without the phage-circular suffix, with the prophage
    coordinates. write_viral_gff.py uses the same key, so a CheckV contig_id with or
    without the suffix matches.

    :param sequence_id: Sequence ID or CheckV contig_id.
    :return: The CheckV key.
    """
    return sequence_id.replace("|phage-circular", "")


def read_rows(
    file_name: Path | None,
    id_column: str,
    delimiter: str,
    ids: set[str],
    get_key: Callable[[str], str] = str,
) -> dict[str, dict[str, str]]:
    """Read a result table as text, indexed by the ID column.

    The values are kept as text, so that the evidence table has the values of the tool.
    Only the rows of the given IDs are kept, to keep the memory use low.

    :param file_name: Path to the result table. None or a missing file gives no rows.
    :param id_column: Name of the column with the ID.
    :param delimiter: Column delimiter of the table.
    :param ids: IDs to keep, as given by get_key.
    :param get_key: Function that makes the index key from the value of the ID column.
    :return: Dictionary mapping the key to its row (column name to value).
    :raises ValueError: If the table has more than one row for a kept key.
    """
    rows = {}
    if not file_name or not Path(file_name).is_file():
        return rows
    # utf-8-sig removes a byte-order mark, as pandas does in parse_viral_pred.py
    with open(file_name, encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle, delimiter=delimiter):
            row_id = get_key(row[id_column])
            if row_id not in ids:
                continue
            if row_id in rows:
                raise ValueError(f"More than one row for {row_id} in {file_name}")
            rows[row_id] = row
    return rows


def read_checkv_rows(
    checkv_files: Iterable[Path], sequence_ids: set[str]
) -> dict[str, dict[str, str]]:
    """Read the CheckV quality summaries of all categories, indexed by CheckV key.

    :param checkv_files: Paths to the CheckV quality_summary.tsv files.
    :param sequence_ids: Sequence IDs to keep (short names, with the suffixes).
    :return: Dictionary mapping the CheckV key (see get_checkv_key) to its CheckV row.
    :raises ValueError: If more than one row has the same CheckV key.
    """
    keys = {get_checkv_key(sequence_id) for sequence_id in sequence_ids}
    rows = {}
    for checkv_file in checkv_files:
        file_rows = read_rows(checkv_file, "contig_id", "\t", keys, get_checkv_key)
        for key, row in file_rows.items():
            if key in rows:
                raise ValueError(f"More than one CheckV row for {key}")
            rows[key] = row
    return rows


def read_contig_names(map_file: Path | None, contigs: set[str]) -> dict[str, str]:
    """Read the temporary to short contig names from the RENAME map file.

    :param map_file: Path to the map file (columns original, temporary, short), or None.
    :param contigs: Temporary contig names to keep.
    :return: Dictionary mapping temporary name to short name. Empty without a map file.
    """
    if not map_file:
        return {}
    with open(map_file) as handle:
        return {
            row["temporary"]: row["short"]
            for row in csv.DictReader(handle, delimiter="\t")
            if row["temporary"] in contigs
        }


def restore_sequence_id(
    sequence_id: str, contig: str, contig_names: dict[str, str]
) -> str:
    """Return the sequence ID with the short contig name, as RESTORE writes it.

    The format is the same as the category FASTA after RESTORE, so it is also the
    CheckV contig_id. Without contig names, the sequence ID is returned unchanged.

    :param sequence_id: Sequence ID: the temporary contig name and the VIRify suffixes.
    :param contig: The temporary contig name. Only the text after it has suffixes.
    :param contig_names: Mapping of temporary name to short name.
    :return: The sequence ID with the short contig name.
    """
    if not contig_names:
        return sequence_id
    suffixes = sequence_id[len(contig) :].split("|")[1:]
    # RESTORE (rename_fasta._parse_name) writes phage-circular before prophage-<start>:<end>
    suffixes.sort(key=lambda suffix: suffix != "phage-circular")
    return "|".join([contig_names.get(contig, contig), *suffixes])


def get_evidence_rows(
    calls: list[dict[str, str]],
    virfinder_rows: dict[str, dict[str, str]],
    pprmeta_rows: dict[str, dict[str, str]],
    checkv_rows: dict[str, dict[str, str]],
    contig_names: dict[str, str],
) -> list[list[str]]:
    """Build the rows of the detection evidence table.

    :param calls: Rows of the detection calls table (temporary contig names).
    :param virfinder_rows: VirFinder rows indexed by temporary contig name.
    :param pprmeta_rows: PPR-Meta rows indexed by temporary contig name.
    :param checkv_rows: CheckV rows indexed by contig_id (short names).
    :param contig_names: Mapping of temporary name to short name.
    :return: List of rows (lists of text values), in the order of EVIDENCE_COLUMNS.
    """
    rows = []
    for call in calls:
        contig = call["contig"]
        sequence_id = restore_sequence_id(call["sequence_id"], contig, contig_names)
        virfinder = virfinder_rows.get(contig, {})
        pprmeta = pprmeta_rows.get(contig, {})
        checkv = checkv_rows.get(get_checkv_key(sequence_id), {})
        values = {
            **call,
            "sequence_id": sequence_id,
            "contig": contig_names.get(contig, contig),
            "virfinder_score": virfinder.get("score"),
            "virfinder_pvalue": virfinder.get("pvalue"),
            "pprmeta_possible_source": pprmeta.get("Possible_source"),
            "pprmeta_phage_score": pprmeta.get("phage_score"),
            **{column: checkv.get(column) for column in CHECKV_COLUMNS},
        }
        rows.append(
            [
                MISSING_VALUE if values.get(column) in (None, "") else values[column]
                for column in EVIDENCE_COLUMNS
            ]
        )
    return rows


def write_detection_evidence(
    calls_file: Path,
    virfinder_file: Path | None,
    pprmeta_file: Path | None,
    checkv_files: Iterable[Path],
    map_file: Path | None,
    output_file: Path,
) -> int:
    """Write the detection evidence table.

    :param calls_file: The detection_calls.tsv file of parse_viral_pred.py.
    :param virfinder_file: The VirFinder result table (tab-separated).
    :param pprmeta_file: The PPR-Meta result table (comma-separated).
    :param checkv_files: The CheckV quality summaries of the categories.
    :param map_file: The RENAME map file, or None to keep the temporary names.
    :param output_file: Path of the TSV file to write.
    :return: The number of rows that the function writes.
    """
    with open(calls_file) as handle:
        calls = list(csv.DictReader(handle, delimiter="\t"))

    rows = []
    # Without calls, the tool tables are not read: they can have millions of rows
    if calls:
        contigs = {call["contig"] for call in calls}
        contig_names = read_contig_names(map_file, contigs)
        sequence_ids = {
            restore_sequence_id(call["sequence_id"], call["contig"], contig_names)
            for call in calls
        }
        rows = get_evidence_rows(
            calls,
            read_rows(virfinder_file, "name", "\t", contigs),
            read_rows(pprmeta_file, "Header", ",", contigs),
            read_checkv_rows(checkv_files, sequence_ids),
            contig_names,
        )

    with open(output_file, "w") as handle:
        tsv_writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        tsv_writer.writerow(EVIDENCE_COLUMNS)
        tsv_writer.writerows(rows)
    return len(rows)


def main() -> None:
    """Parse the arguments and write the detection evidence table."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--calls", type=Path, required=True, help="detection_calls.tsv of PARSE"
    )
    parser.add_argument("--virfinder", type=Path, help="VirFinder result table (TSV)")
    parser.add_argument("--pprmeta", type=Path, help="PPR-Meta result table (CSV)")
    parser.add_argument(
        "--checkv",
        type=Path,
        nargs="*",
        default=[],
        help="CheckV quality_summary.tsv files of the categories",
    )
    parser.add_argument(
        "--map",
        dest="map_file",
        type=Path,
        help="RENAME map file (columns original, temporary, short), for the short names",
    )
    parser.add_argument("--output", type=Path, required=True, help="Output TSV file")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    row_count = write_detection_evidence(
        args.calls,
        args.virfinder,
        args.pprmeta,
        args.checkv,
        args.map_file,
        args.output,
    )
    logger.info("Wrote %d rows to %s", row_count, args.output)


if __name__ == "__main__":
    main()
