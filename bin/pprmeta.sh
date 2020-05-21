#!/bin/bash

# PPR-Meta docker runtime wrapper

set -e
set -u

usage () {
    echo ""
    echo "PPR-Meta "
    echo "This script wraps PPR-Meta docker container."
    echo ""
    echo "-i singularity image (simg)"
    echo "-f fasta file with the contigs"
    echo "-o output file name with path (.csv)"
    echo ""
}

while getopts "i:f:o:" opt; do
  case $opt in 
    i)
        PPRMETA_SINGULARITY_IMG="$OPTARG"
        if [ ! -f "$PPRMETA_SINGULARITY_IMG" ];
        then
            echo "ERROR -i: $PPRMETA_SINGULARITY_IMG does not exist." >&2
            usage;
            exit 1
        fi
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

# needed for the singularity image
# PPR-Meta writes everyting in the /data folder
# so it's necesary the result file to the expected folder (the outfile folder)

# toil workaround, copy the file to a tmp file and then delete
TMP_FOLDER=$(mktemp -d)
cp "${FASTA}" "${TMP_FOLDER}"

# BASE_PATH="$(dirname "$(readlink -f "${FASTA}")")"
FASTA_BASENAME="$(basename "${FASTA}")"

OUTPUT_PATH="$(pwd)" # same folder for CWL runners
OUTPUT_BASENAME="$(basename "${OUT_FILE}")"

set -x

singularity run \
    --cleanenv \
    --pwd /data \
    --bind "${TMP_FOLDER}":/data \
    "${PPRMETA_SINGULARITY_IMG}" \
    /data/"${FASTA_BASENAME}" \
    /data/"${OUTPUT_BASENAME}"

set +x

echo "Moving the result file."

echo "From: ${TMP_FOLDER}/${OUTPUT_BASENAME}"
echo "To: ${OUTPUT_PATH}/${OUTPUT_BASENAME}"

# copy the output
mv "${TMP_FOLDER}/${OUTPUT_BASENAME}" "${OUTPUT_PATH}/${OUTPUT_BASENAME}"

# clean
rm -r "${TMP_FOLDER}"