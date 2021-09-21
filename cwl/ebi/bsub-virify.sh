#!/bin/bash
#BSUB -n 1
#BSUB -R "rusage[mem=4096]"
#BSUB -J virify
#BSUB -o output.txt
#BSUB -e error.txt

# CONSTANTS
# Wrapper for Virify.shs

# Production scripts and env
VIRIFY_SH="/nfs/production/rdf/metagenomics/pipelines/prod/emg-viral-pipeline/cwl/virify.sh"
ENV_FILE="/nfs/production/rdf/metagenomics/pipelines/prod/emg-viral-pipeline/cwl/ebi/virify-env.sh"

set -e

usage () {
    echo ""
    echo "Virify pipeline BSUB"
    echo "Example:"
    echo ""
    echo "bsub-virify.sh -n test-run -i input_fasta -o /data/results/"
    echo ""
    echo "NOTE:"
    echo "- The results folder will be /data/results/{job_name}."
    echo "- The logs will be stored in /data/results/{job_name}/logs"
    echo ""
    echo "Settings files and executable scripts:"
    echo "- toil work dir: ${WORKDIR} * toil will create a folder in this path"
    echo "- virify.sh: ${VIRIFY_SH}"
    echo "- virify env: ${ENV_FILE}"
    echo ""
}

# PARAMS
NAME=""
CONTIGS=""
RESULTS_FOLDER=""
LEN_FILTER="1.0"

while getopts "n:i:o:f:h" opt; do
  case $opt in
    n)
        NAME="$OPTARG"
        ;;
    i)
        CONTIGS="$OPTARG"
        ;;
    o)
        RESULTS_FOLDER="$OPTARG"
        ;;
    f)
        LEN_FILTER="$OPTARG"
        ;;
    h)
        usage;
        exit 0
        ;;
    :)
        usage;
        exit 1
        ;;
    \?)
        usage;
        exit 1;
    ;;
  esac
done

if ((OPTIND == 1))
then
    echo ""
    echo "ERROR! No options specified"
    usage;
    exit 1
fi

${VIRIFY_SH} \
-e ${ENV_FILE} \
-n "${NAME}" \
-j "${JOB_STORE}" \
-o "${RESULTS_FOLDER}" \
-f "${LEN_FILTER}" \
-p CODON \
-c 1 -m 12000 \
-i "${CONTIGS}"
