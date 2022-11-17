#!/bin/bash

# emg-viral-pipeline CWL specific

while getopts "if:o:" opt; do
  case $opt in 
    i)
        echo "singularity ignored."
        ;;
    f)
        FASTA="$OPTARG"
        if [ ! -f "$FASTA" ];
        then
            echo "ERROR -f: $FASTA does not exist." >&2
            usage;
            exit 1
        fi
        ;;
    o)
        OUT_FILE="$OPTARG"
        ;;
    :)
        usage;
        exit 1
        ;;
    \?)
        echo "Invalid option -$OPTARG" >&2
        usage;
        exit 1;
    ;;
  esac
done

if ((OPTIND == 1));
then
    usage;
    exit 1;
fi

# Copy PPR-Meta files to the output folder
OUT_DIR=$(dirname "${OUT_FILE}")

# PPR-Meta patch
cp /PPR-Meta-1.1/* "${OUT_DIR}"

PPR_Meta "${FASTA}" "${OUT_FILE}"