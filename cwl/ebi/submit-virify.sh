#!/bin/bash
#BSUB -n 1
#BSUB -M 8192

# CONSTANTS
# Wrapper for Virify.sh
WORKDIR="/hps/nobackup/production/metagenomics/toil-workdir"

# Production
# virify.sh
VIRIFY_SH="/nfs/production/metagenomics/pipelines/virify/scripts/virify.sh"
# ENV
ENV_FILE="/nfs/production/metagenomics/pipelines/virify/scripts/ebi-env.sh"

set -e

usage () {
    echo ""
    echo "Virify pipeline BSUB"
    echo ""
    echo "-n the name for the job *a timestamp will be added to folder* [mandatory]"
    echo "-i contigs input fasta [mandatory]"
    echo "-o output folder [mandatory]"
    echo ""
    echo "Example:"
    echo ""
    echo "bsub-virify.sh -n test-run -i input_fasta -o /data/results/"
    echo ""
    echo "NOTE:"
    echo "- The results folder will be /data/results/{job_name}."
    echo "- The logs will be stored in /data/results/{job_name}/logs"
    echo ""
    echo "PARAMETERS:"
    echo "- toil work dir: ${WORKDIR} * toil will create a folder in this path"
    echo "- virify.sh: ${VIRIFY_SH}"
    echo "- virify env: ${ENV_FILE}"
    echo ""
}

# PARAMS
NAME=""
CONTIGS=""
RESULTS_FOLDER=""

while getopts "n:i:o:h" opt; do
  case $opt in
    n)
        NAME="$OPTARG"
        ;;
    i)
        CONTIGS="$OPTARG"
        # if [ ! -f "$NAME_RUN" ];
        # then
        #     echo ""
        #     echo "ERROR '${OPTARG}' doesn't exist." >&2
        #     usage;
        #     exit 1
        # fi
        ;;
    o)
        RESULTS_FOLDER="$OPTARG"
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
-n ${NAME} \
-j ${WORKDIR} \
-o ${RESULTS_FOLDER} \
-c 1 -m 8192 \
-i ${CONTIGS}
