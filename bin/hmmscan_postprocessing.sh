#!/bin/bash

set -e

# Format the table and add the header

if [ ! -s "$1" ];
then
  echo "Formatting error, the file is empty. File: $1" 1>&2;
  echo "Usage: hmmscan_postprocessing.sh table_in.tsv outfile_name"
  exit 1
fi

if [ -z "$2" ];
then
  echo "Please, provide an output file name." 1>&2;
  echo "Usage: hmmscan_postprocessing.sh table_in.tsv outfile_name"
  exit 1
fi

touch "$2.tsv"

printf "target name\ttarget accession\ttlen\tquery name\tquery accession\tqlen\tfull sequence E-value\tfull sequence score\tfull sequence bias\t#\tof\tc-Evalue\ti-Evalue\tdomain score\tdomain bias\thmm coord from\thmm coord to\tali coord from\tali coord to\tenv coord from\tenv coord to\tacc\tdescription of target\n" > "$2.tsv"

sed '/^#/d; s/ \\+/\\t/g' "$1" >> "$2.tsv"