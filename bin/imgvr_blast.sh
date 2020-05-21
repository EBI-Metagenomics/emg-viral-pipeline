#!/bin/bash

# IMG/VR Blast

set -e

usage () {
    echo ""
    echo "IMG/VR blastn."
    echo "The output are 2 files: outfile.blast and outfile.filtered.blast (alignment length >= 80%) "
    echo "-c number of cores for blastn"
    echo "-d path to the dir with the file IMG_VR_2018-07-01_4/IMGVR_all_nucleotides.fna"
    echo "-q query fasta file"
    echo "-o output file name"
    echo ""
}

while getopts "c:d:q:o:" opt; do
  case $opt in
    c)
        CORES="$OPTARG"
        if ! [[ "$CORES" =~ ^[0-9]+$ ]]
        then
            echo "ERROR Cores: $CORES is not a number." >&2
            usage;
            exit 1
        fi
        ;;
    d)
        DB="$OPTARG/IMGVR_all_nucleotides.fna"
        if [ ! -f "$DB" ];
        then
            echo "ERROR DB: $DB does not exist." >&2
            usage;
            exit 1
        fi
        ;;    
    q)
        QUERY="$OPTARG"
        if [ ! -s "$QUERY" ];
        then
            echo "Skipping Query: $QUERY does not exist." >&2
            # empty files (CWL.)
            touch "empty_imgvr_blast.tsv"
            touch "empty_imgvr_blast_filtered.tsv"
            exit 0
        fi
        ;;
    o)
        OUT_FILE="$OPTARG"
        ;;
    :)
        exit 1
        ;;
    \?)
        echo "Invalid option -$OPTARG" >&2
        usage;
    ;;
  esac
done

if [ ! -s "$QUERY" ];
then
    echo "Skipping Query: $QUERY does not exist." >&2
    # empty files (CWL.)
    touch "empty_imgvr_blast.tsv"
    touch "empty_imgvr_blast_filtered.tsv"
    exit 0
fi

BLAST_FORMAT="6 qseqid sseqid pident length mismatch gapopen qstart qend qlen sstart send evalue bitscore slen"

HEADER_BLAST="qseqid\\tsseqid\\tpident\\tlength\\tmismatch\\tgapopen\\tqstart\\tqend\\tqlen\\tsstart\\tsend\\tevalue\\tbitscore\\tslen" 

echo -e $HEADER_BLAST > "$OUT_FILE".tsv

echo "Starting blastn"

set -x

blastn -task blastn \
    -num_threads "$CORES" \
    -query "$QUERY" \
    -db "$DB" \
    -evalue 1e-10 \
    -outfmt "$BLAST_FORMAT" >> "$OUT_FILE".tsv

set +x

echo "blastn completed"

echo "Filtering"

echo -e $HEADER_BLAST > "$OUT_FILE"_filtered.tsv

# keep the matches with an alignment length >= 80%
tail -n +2 "$OUT_FILE".tsv | awk '{ if ($4>=0.8*$9) { print $0 }}' >> "$OUT_FILE"_filtered.tsv
