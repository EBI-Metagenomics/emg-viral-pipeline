#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem 8G
#SBATCH --output="%x_virify.out"
#SBATCH --error="%x_virify.err"

set -e

usage() {
    echo ""
    echo "Wrapper script to run the virify workflow using toil-cwl-runner."
    echo ""
    echo "Results will be stored in the output folder,"
    echo "under a subfolder named '<job_name>_<timestamp>/'"
    echo "-n Job name [mandatory]."
    echo "-i Input fasta file (full path) [mandatory]."
    echo "-o Output [mandatory]."
    echo "-f Length filter (default 1.0)."
    echo ""
}

# Defaults
CORES=4
MEMORY=8000 # 8GB
LEN_FILTER=1.0

while getopts "n:i:o:f:h" opt; do
    case $opt in
    n)
        NAME_RUN="$OPTARG"
        if [ -z "$NAME_RUN" ]; then
            echo ""
            echo "ERROR -n cannot be empty." >&2
            usage
            exit 1
        fi
        ;;
    i)
        INPUT_FASTA="${OPTARG}"
        if [ -z "${INPUT_FASTA}" ]; then
            echo ""
            echo "ERROR -i cannot be empty." >&2
            usage
            exit 1
        fi
        ;;
    o)
        OUTDIR="$OPTARG"
        if [ -z "$OUTDIR" ]; then
            echo ""
            echo "ERROR -o cannot be empty." >&2
            usage
            exit 1
        fi
        mkdir -p "$OUTDIR"
        ;;
    f)
        LEN_FILTER="${OPTARG}"
        ;;
    h)
        usage
        exit 0
        ;;
    :)
        usage
        exit 1
        ;;
    \?)
        echo ""
        echo "Invalid option -${OPTARG}" >&2
        usage
        exit 1
        ;;
    esac
done

if ((OPTIND == 1)); then
    echo ""
    echo "ERROR: No options specified"
    usage
    exit 1
fi

shift $((OPTIND - 1))

# mandatory params
if [ -z "${NAME_RUN}" ] ||
    [ -z "${INPUT_FASTA}" ] ||
    [ -z "${OUTDIR}" ]; then
    echo ""
    echo "ERROR: Missing mandatory parameter."
    usage
    exit 1
fi

# Embassy env specifics
WORKDIR="/home/virify/workdir"

echo "Submitting the job."
echo "Workdir: ${WORKDIR}"
echo "Outdir: ${OUTDIR}/${NAME_RUN}"
echo ""

/home/virify/emg-viral-pipeline/cwl/virify.sh \
    -e /home/virify/scripts/emg-virify-env.sh \
    -n "${NAME_RUN}" \
    -j "${WORKDIR}" \
    -o "${OUTDIR}" \
    -f "${LEN_FILTER}" \
    -c "${CORES}" \
    -m "${MEMORY}" \
    -i "${INPUT_FASTA}" \
    -p embassy
