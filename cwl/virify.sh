#!/usr/bin/env bash

set -e

usage () {
    echo ""
    echo "Wrapper script to run the virify workflow using toil-cwl-runner."
    echo ""
    echo "-e Environemnt init script [mandatory]: "
    echo "   * conda env activation"
    echo "   * Add scripts folder to PATH"
    echo "   * Full paths for:"
    echo "      . VIRSORTER_DATA"
    echo "      . ADDITIONAL_HMMS_DATA"
    echo "      . HMMSCAN_DATABASE_DIRECTORY"
    echo "      . NCBI_TAX_DB_FILE"
    echo "      . IMGVR_BLAST_DB"
    echo "      . PPRMETA_SIMG"
    echo "      . VIRFINDER_MODEL"
    echo "-n the name for the job *a timestamp will be added to folder* [mandatory]"
    echo "-j toil job store folder path [mandatory]"
    echo "-o output folder [mandatory]"
    echo "-c number of cores for the job [mandatory]"
    echo "-m memory in *megabytes* [mandatory]"
    echo "-i intput fasta contigs [mandatory]"
    echo "-v virome mode for virsorter (default if OFF)"
    echo "-s mashmap reference file fasta or fastq (.gz) (optional)"
    echo "-r Restart workdir path. "
    echo "   Path to the job work dir for restart.Toil will raise an expection if the work directory doesn't exist"
    echo "-l Run the worklfow locally using containters (singularity) for dev purposes"
    echo ""
    echo "Example:
            virify.sh -e init.sh -n test-run -m 1024 -c 12 -j JOB_DIR_path -o /data/results/ -i input.fasta
          NOTE:
          - The results folder will be /data/results/{job_name}.
          - The logs will be stored in /data/results/{job_name}/logs"
    echo ""
}

# mandatory
NAME_RUN=""
JOB_DIR=""
OUT_DIR=""
CORES=""
MEMORY=""
INPUT_FASTA=""
VIROME=""
MASHMAP_REFERENCE=""
ENV_SCRIPT=""
RESTART=""
MODE="EBI"

while getopts "e:n:j:o:c:m:i:vs:r:lh" opt; do
  case $opt in
    e)
        ENV_SCRIPT="$OPTARG"
        if [ ! -f "$ENV_SCRIPT" ];
        then
            echo ""
            echo "ERROR -e cannot be empty." >&2
            usage;
            exit 1
        fi
        ;;
    n)
        NAME_RUN="$OPTARG"
        if [ ! -n "$NAME_RUN" ];
        then
            echo ""
            echo "ERROR -n cannot be empty." >&2
            usage;
            exit 1
        fi
        ;;
    j)
        JOB_DIR="$OPTARG"
        ;;
    o)
        OUT_DIR="$OPTARG"
        if [ ! -n "$OUT_DIR" ];
        then
            echo ""
            echo "ERROR -o cannot be empty." >&2
            usage;
            exit 1
        fi
        mkdir -p "$OUT_DIR"
        ;;
    c)
        CORES="$OPTARG"
        if ! [[ "$CORES" =~ ^[0-9]+$ ]]
        then
            echo "" 
            echo "ERROR (-c): $CORES is not a number." >&2
            usage;
            exit 1
        fi
        ;;
    m)
        MEMORY="$OPTARG"
        if ! [[ "$MEMORY" =~ ^[0-9]+$ ]]
        then
            echo ""
            echo "ERROR (-m): $MEMORY is not a number." >&2
            usage;
            exit 1
        fi
        ;;
    i)
        INPUT_FASTA="${OPTARG}"
        if [ ! -n "${INPUT_FASTA}" ];
        then
            echo ""
            echo "ERROR -i cannot be empty." >&2
            usage;
            exit 1
        fi        
        ;;
    v)
        VIROME="-v true"
        ;;
    s)
        if [ ! -n "${OPTARG}" ];
        then
            echo ""
            echo "ERROR mashmap (-s) cannot be empty." >&2
            usage;
            exit 1
        fi
        MASHMAP_REFERENCE="${OPTARG}" 
        ;;
    h)
        usage;
        exit 0
        ;;
    r)
        RESTART="${OPTARG}"
        ;;
    l)
        MODE="LOCAL"
        ;;
    :)
        usage;
        exit 1
        ;;
    \?)
        echo ""
        echo "Invalid option -${OPTARG}" >&2
        usage;
        exit 1;
    ;;
  esac
done

if ((OPTIND == 1))
then
    echo ""
    echo "ERROR: No options specified"
    usage;
    exit 1
fi

shift $((OPTIND - 1))

# mandatory params
if [ -z "${NAME_RUN}" ] || \
   [ -z "${JOB_DIR}" ] || \
   [ -z "${OUT_DIR}" ] || \
   [ -z "${CORES}" ] || \
   [ -z "${MEMORY}" ] || \
   [ -z "${INPUT_FASTA}" ] || \
   [ -z "${ENV_SCRIPT}" ]
then
    echo ""
    echo "ERROR: Missing mandatory parameter."
    usage;
    exit 1
fi

# shellcheck source=/dev/null
source "${ENV_SCRIPT}"

set -u

YML_INPUT=""
LOG_DIR=""

if [ -z "${RESTART}" ];
then
    echo "Configuration and folders"

    set -x

    TS="$(date +"%Y-%m-%d_%H-%M-%S")"

    # Prefix the path to make it easier to clean
    TMPDIR="${TMPDIR:-/scratch}/${NAME_RUN}_${TS}"
    JOB_DIR="${JOB_DIR}/${NAME_RUN}_${TS}"
    LOG_DIR="${OUT_DIR}/${NAME_RUN}_${TS}/logs"
    OUT_DIR="${OUT_DIR}/${NAME_RUN}_${TS}"

    # Prepare folders
    mkdir -p "${TMPDIR}"
    mkdir -p "${LOG_DIR}"
    mkdir -p "${OUT_DIR}"

    set +x

    # Prepare the yaml file
    YML_INPUT="${NAME_RUN}_${TS}_input.yaml"

    CWL_PARAMS=(
        -i "${INPUT_FASTA}"
        -s "${VIRSORTER_DATA}"
        -a "${ADDITIONAL_HMMS_DATA}"
        -j "${HMMSCAN_DATABASE_DIRECTORY}"
        -n "${NCBI_TAX_DB_FILE}"
        -b "${IMGVR_BLAST_DB}"
        -p "${PPRMETA_SIMG}"
        -f "${VIRFINDER_MODEL}"
        -o "${YML_INPUT}"
    )

    if [ ! -z "${MASHMAP_REFERENCE}" ];
    then
        CWL_PARAMS+=(-m "${MASHMAP_REFERENCE}")
    fi

    if [ ! -z "${VIROME}" ];
    then
        CWL_PARAMS+=("${VIROME}")
    fi

    set -x
    cwl_input.py "${CWL_PARAMS[@]}"
    set +x
fi

# assume CWL is src/pipeline.cwl relative to this script
SCRIPT_DIR="$(dirname "$0")"

TOIL_PARAMS=(
    "--cleanWorkDir=onSuccess"
    "--clean=never"
    --defaultCores "$CORES"
    --defaultMemory "$MEMORY"M
    --retryCount 0
    --disableProgress
)

if [ "${MODE}" = "EBI" ];
then
    TOIL_PARAMS+=(
        --no-container
        --batchSystem LSF
        --disableCaching
    )
fi

if [ "${MODE}" = "LOCAL" ];
then
    # TOIL_PARAMS+=(--singularity)
    TOIL_PARAMS+=(--no-container)
fi

if [ -z "${RESTART}" ];
then
    # regular execution
    TOIL_PARAMS+=(
        --stats
        --logWarning
        --writeLogs "${LOG_DIR}"
        --maxLogFileSize 50000000
        --clusterStats "${LOG_DIR}/stats.json"
        --outdir "${OUT_DIR}"
        --logFile "${LOG_DIR}/${NAME_RUN}.log"
        --rotatingLogging
        --jobStore "${JOB_DIR}"
        --enable-dev
        "${SCRIPT_DIR}/src/pipeline.cwl"
        "${YML_INPUT}"
    )
else
    # restart previuos job
    TOIL_PARAMS+=(
        --jobStore "${RESTART}"
        --restart
        --enable-dev
        "${RESTART}"
    )
fi

set -x

toil-cwl-runner "${TOIL_PARAMS[@]}"
