#!/usr/bin/env python3

import argparse
import re
import sys
import csv
from copy import copy
from os.path import isfile
from pathlib import Path

from Bio import SeqIO

import pandas as pd


class Record:
    """Simple class to aggregate the results"""

    def __init__(self, seq_record, category, circular=None, prange=None):
        """Record class.
        Parameters:
        - biopython SeqRecord instance
        - category: high_confidence, low_confidence or prophage
        - circular: bool or None
        - prange: prophage range
        """
        self.seq_id = seq_record.id
        self.category = category
        self.seq_record = seq_record
        self.circular = circular
        # applies to prophages only
        self.prange = prange or []

    def to_tsv(self):
        return [self.seq_id, self.category, self.circular, *self.prange]

    def get_seq_record(self):
        """Get the SeqRecord with the category and prange encoded in the header.
        """
        seq_record = copy(self.seq_record)
        if self.category == "prophage" and len(self.prange):
            seq_record.id += f" prophage-{self.prange[0]}:{self.prange[1]}"
        if self.circular:
            seq_record.id += " phage-circular"
        # clean
        seq_record.description = ""
        return seq_record

    def __hash__(self):
        return hash(self.seq_id)

    def __eq__(self, other):
        return self.seq_id == other


def parse_pprmeta(file_name):
    """Extract phage hits from PPR-Meta.
    """
    lc_ids = set()

    if isfile(file_name):
        result_df = pd.read_csv(file_name, sep=",")

        lc_ids = set(result_df[
            (result_df["Possible_source"] == "phage")
        ]["Header"].values)

    print(f"PPR-Meta found {len(lc_ids)} low confidence contigs.")

    return lc_ids


def parse_virus_finder(file_name):
    """Extract high and low confidence contigs from virus finder results.
    """
    hc_ids = set()
    lc_ids = set()

    if isfile(file_name):
        result_df = pd.read_csv(file_name, sep="\t")

        hc_ids = set(
            result_df[(result_df["pvalue"] < 0.05) &
                      (result_df["score"] >= 0.90)]["name"].values)

        lc_ids = set(result_df[
            (result_df["pvalue"] < 0.05) &
            (result_df["score"] >= 0.70) &
            (result_df["score"] < 0.9)
        ]["name"].values)

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
    high_confidence = dict()
    low_confidence = dict()
    prophages = dict()

    for file in sorter_files or []:
        if not isfile(file) or ".fasta" not in file:
            continue
        for record in SeqIO.parse(file, "fasta"):
            category = record.id[-1:]
            clean_name, circular, prange = _parse_virsorter_metadata(record.id)
            record.id = clean_name
            if category in ["1", "2"]:
                high_confidence[record.id] = Record(record, "high_confidence", circular)
            elif category == "3":
                low_confidence[record.id] = Record(record, "low_confidence", circular)
            elif category in ["4", "5"]:
                # add the prophage position within the contig
                prophages.setdefault(record.id, []).append(
                    Record(record, "prophage", circular, prange))
            else:
                print(f"Contig has an invalid category : {category}")

    print(f"Virus Sorter found {len(high_confidence)} high confidence contigs.")
    print(f"Virus Sorter found {len(low_confidence)} low confidence contigs.")
    print(f"Virus Sorter found {len(prophages)} putative prophages contigs.")

    return high_confidence, low_confidence, prophages


def merge_annotations(pprmeta, finder, sorter, assembly):
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
    Returns high conf., low and prophage SeqRecords and
            virsorter high conf., low conf. and prophage Records
    """
    hc_predictions_contigs = []
    lc_predictions_contigs = []
    prophage_predictions_contigs = []

    pprmeta_lc = parse_pprmeta(pprmeta)
    finder_lc, finder_lowestc = parse_virus_finder(finder)
    sorter_hc, sorter_lc, sorter_prophages = parse_virus_sorter(sorter)

    for seq_record in SeqIO.parse(assembly, "fasta"):
        # HC
        if seq_record.id in sorter_hc:
            hc_predictions_contigs.append(sorter_hc.get(seq_record.id).get_seq_record())
        # Pro
        elif seq_record.id in sorter_prophages:
            # a contig may have several prophages
            # for prophages write the record as it holds the
            # sliced fasta
            for record in sorter_prophages.get(seq_record.id):
                prophage_predictions_contigs.append(record.get_seq_record())
        # LC
        elif seq_record.id in finder_lc:
            lc_predictions_contigs.append(seq_record)
        elif seq_record.id in sorter_lc and seq_record.id in finder_lowestc:
            lc_predictions_contigs.append(sorter_lc.get(seq_record.id).get_seq_record())
        elif seq_record.id in pprmeta_lc and seq_record.id in finder_lowestc:
            lc_predictions_contigs.append(seq_record)

    return hc_predictions_contigs, lc_predictions_contigs, prophage_predictions_contigs, \
        sorter_hc, sorter_lc, sorter_prophages


def main(pprmeta, finder, sorter, assembly, outdir, prefix=False):
    """Parse VirSorter, VirFinder and PPR-Meta outputs and merge the results.
    """
    hc_contigs, lc_contigs, prophage_contigs, sorter_hc, sorter_lc, sorter_prophages = \
        merge_annotations(pprmeta, finder, sorter, assembly)

    at_least_one = False
    name_prefix = ""
    if prefix:
        name_prefix = Path(assembly).stem + "_"

    outdir_path = Path(outdir)

    if len(hc_contigs):
        SeqIO.write(hc_contigs, 
            outdir / Path(name_prefix + "high_confidence_viral_contigs.fna"), "fasta")
        at_least_one = True
    if len(lc_contigs):
        SeqIO.write(lc_contigs, 
            outdir / Path(name_prefix + "low_confidence_viral_contigs.fna"), "fasta")
        at_least_one = True
    if len(prophage_contigs):
        SeqIO.write(prophage_contigs,
            outdir / Path(name_prefix + "prophages.fna"), "fasta")
        at_least_one = True

    # VirSorter provides some metadata on each annotation
    # - is circular
    # - prophage start and end within a contig
    if sorter_hc or sorter_lc or sorter_prophages:
        with open(outdir_path / Path("virsorter_metadata.tsv"), "w") as pm_tsv_file:
            header = ["contig", "category", "circular",
                      "prophage_start", "prophage_end"]
            tsv_writer = csv.writer(pm_tsv_file, delimiter="\t")
            tsv_writer.writerow(header)
            tsv_writer.writerows([shc.to_tsv() for _, shc in sorter_hc.items()])
            tsv_writer.writerows([slc.to_tsv() for _, slc in sorter_lc.items()])
            for _, plist in sorter_prophages.items():
                tsv_writer.writerows([ph.to_tsv() for ph in plist])

    if not at_least_one:
        print("Overall, no putative _viral contigs or prophages were detected"
              " in the analysed metagenomic assembly", file=sys.stderr)
        exit(1)


if __name__ == "__main__":
    """Merge and convert VIRSorter and VIRFinder output contigs into:
    - high confidence viral contigs
    - low confidence viral contigs
    - putative prophages
    """
    parser = argparse.ArgumentParser(
        description="Write fasta files with predicted _viral contigs sorted in "
                    "categories and putative prophages")
    parser.add_argument("-a", "--assemb", dest="assembly",
                        help="Metagenomic assembly fasta file", required=True)
    parser.add_argument("-f", "--vfout", dest="finder", help="Absolute or "
                        "relative path to VirFinder output file",
                        required=False)
    parser.add_argument("-s", "--vsfiles", dest="sorter", nargs='+',
                        help="VirSorter .fasta files (i.e. VIRSorter_cat-1.fasta)"
                        " VirSorter output", required=False)
    parser.add_argument("-p", "--pmout", dest="pprmeta",
                        help="Absolute or relative path to PPR-Meta output file"
                        " PPR-Meta output", required=False)
    parser.add_argument("-r", "--prefix", dest="prefix",
                        help="Use the assembly filename as prefix for the outputs",
                        action="store_true")
    parser.add_argument("-o", "--outdir", dest="outdir",
                        help="Absolute or relative path of directory where output"
                        " _viral prediction files should be stored (default: cwd)",
                        default=".")
    args = parser.parse_args()

    main(args.pprmeta, args.finder, args.sorter, args.assembly, args.outdir, prefix=args.prefix)
