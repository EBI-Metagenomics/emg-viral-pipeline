#!/bin/bash

# CONSTANTS
# Wrapper for Virify.shs

# Production scripts and env
VIRIFY_SH="/nfs/production/rdf/metagenomics/pipelines/prod/emg-viral-pipeline/cwl/virify.sh"
ENV_FILE="/nfs/production/rdf/metagenomics/pipelines/prod/emg-viral-pipeline/cwl/ebi/codon-virify-env.sh"
WORKDIR="/hps/nobackup/rdf/metagenomics/toil-jobstore"

set -e

# PARAMS
NAME=""
CONTIGS=""
RESULTS_FOLDER=""
LEN_FILTER="1.0"
BSUB_ERROR=""
BSUB_OUTPUT=""
BSUB_USER=""

usage () {
    echo "
Virify pipeline BSUB

Usage.

bsub-virify.sh -n test-run -i input_fasta -o /data/results/ [-f ${LEN_FILTER}] [-e] [-x] [-u]

Script arguments.
  -n                  Job name, used for the folders and bsub -J
  -i                  -i intput fasta file with contigs
  -o                  -o output folder prefix, a folder using the job name will be created
  -f                  -f Length threshold in kb of selected sequences [default: ${LEN_FILTER}]

  -e                  bsub -e
  -x                  bsub -o
  -u                  bsub -u

NOTE:
- The results folder will be /data/results/{job_name}.
- The logs will be stored in /data/results/{job_name}/logs

Settings files and executable scripts:
- toil work dir: ${WORKDIR} * toil will create a folder in this path
- virify.sh: ${VIRIFY_SH}
- virify env: ${ENV_FILE}
"
}

while getopts "n:i:o:f:e:x:u:h" opt; do
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
    e)
        BSUB_ERROR="$OPTARG"
        ;;
    x)
        BSUB_OUTPUT="$OPTARG"
        ;;
    u)
        BSUB_USER="$OPTARG"
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


BSUB_PARAMS=(
    -n 1
    -R "rusage[mem=4096]"
    -J "${NAME}"
)

if [ -n "${BSUB_ERROR}" ]; then
    BSUB_PARAMS+=(
        -e "${BSUB_ERROR}"
    )
fi

if [ -n "${BSUB_OUTPUT}" ]; then
    BSUB_PARAMS+=(
        -o "${BSUB_OUTPUT}"
    )
fi

if [ -n "${BSUB_USER}" ]; then
      BSUB_PARAMS+=(
        -u "${BSUB_USER}"
    )  
fi


# virify #
BSUB_PARAMS+=(
    "${VIRIFY_SH}"
    -e "${ENV_FILE}"
    -n "${NAME}"
    -j "${WORKDIR}"
    -o "${RESULTS_FOLDER}"
    -f "${LEN_FILTER}"
    -p CODON
    -c 1
    -m 12000
    -i "${CONTIGS}"
)

bsub "${BSUB_PARAMS[@]}"
