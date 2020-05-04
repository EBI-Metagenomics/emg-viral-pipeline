#!/usr/bin/env python3.7

import argparse
import os
import re
import sys

from Bio import SeqIO


def filter_contigs(**kwargs):
	seq_records = SeqIO.parse(kwargs["contig_file"], "fasta")
	if kwargs["output_dir"] == ".":
		outdir = os.getcwd()
	else:
		outdir = kwargs["output_dir"]
	#dataset_ident = kwargs["ident"]
	#outname = "%s_filt%skb.fasta" % (dataset_ident, kwargs["thres"])
	#if kwargs["thres"] < 1:
	#	outname = re.split(r"\.[a-z]+$", os.path.basename(kwargs["contig_file"]))[0] + "_filt%sbp.fasta" % int(kwargs["thres"] * 1000)
	#else:
	#	outname = re.split(r"\.[a-z]+$", os.path.basename(kwargs["contig_file"]))[0] + "_filt%skb.fasta" % int(kwargs["thres"])
	outname = re.split(r"\.[a-z]+$", os.path.basename(kwargs["contig_file"]))[0] + "_filt%sbp.fasta" % int(kwargs["thres"] * 1000)
	final_records = []
	if kwargs["run_id"] is None:
		for record in seq_records:
			if len(record) >= kwargs["thres"]*1000:
				final_records.append(record)
	else:
		counter = 1
		for record in seq_records:
			if len(record) >= kwargs["thres"]*1000:
				record.description = "%s_%s" % (kwargs["run_id"], counter)
				counter += 1
				final_records.append(record)
	SeqIO.write(final_records, os.path.join(outdir, outname), "fasta")


if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="Extract sequences at least X kb long")
	parser.add_argument("-f", dest="fasta_file", help="Relative or absolute path to input fasta file", required=True)
	parser.add_argument("-l", dest="length", help="Length threshold in kb of selected sequences (default: 5kb)", type=float, default="5.0")
	parser.add_argument("-o", dest="outdir", help="Relative or absolute path to directory where you want to store output (default: cwd)", default=".")
	parser.add_argument("-i", dest="ident", help="Dataset identifier or accession number. Should only be introduced if you want to add it to each sequence header, along with a sequential number", default = None)
	if len(sys.argv) == 1 :
		parser.print_help()
		sys.exit(1)
	else:
		args = parser.parse_args()
		filter_contigs(contig_file=args.fasta_file, thres=args.length, output_dir=args.outdir, run_id = args.ident)