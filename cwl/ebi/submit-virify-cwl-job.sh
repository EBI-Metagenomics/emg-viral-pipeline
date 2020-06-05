#!/bin/bash

#BSUB -n 8
#BSUB -M 8192

export TOIL_LSF_ARGS="-R rusage[scratch=30720]"

RESULTS_DIR="/hps/research/finn/aalmeida/virify_benchmarking/virify_cwl/out-dir/"
WORK_DIR="/hps/research/finn/aalmeida/virify_benchmarking/virify_cwl/work-dir/"

usage () {
    echo ""
    echo "Simple wrapper script for virify.sh"
    echo ""
    echo "Usage:"
    echo "submit-virify-job.sh <job_name> <input.fasta>"
    echo ""
    echo "Results will be stored: ${RESULTS_DIR}/<job_name>_timestamp"
    echo "Logs will be stored:    ${RESULTS_DIR}/<job_name>_timestamp/logs"
    echo "Workdir parent folder:  ${WORK_DIR}/<job_name>_timestamp"
}

if [ -z "${1}" ] || [ ! -f "${2}" ];
then
    usage;
    exit 1
fi

/nfs/production/interpro/metagenomics/virify_pipeline/emg-viral-pipeline/cwl/virify.sh \
-e /nfs/production/interpro/metagenomics/virify_pipeline/init.sh \
-n "${1}" \
-j "${WORK_DIR}" \
-o "${RESULTS_DIR}" \
-c 8 \
-m 8192 \
-i "${2}"