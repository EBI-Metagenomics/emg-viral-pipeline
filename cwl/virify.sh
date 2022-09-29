#!/usr/bin/env bash

set -e

usage () {
    echo ""
    echo "Wrapper script to run the virify workflow using toil-cwl-runner."
    echo ""
    echo "-e Environemnt init script [mandatory]: "
    echo "   * conda env activation"
    echo "   * Batch system (lsf or slurm)"
    echo "   * Add scripts folder to PATH"
    echo "   * Full paths for:"
    echo "      . VIRSORTER_DATA"
    echo "      . ADDITIONAL_HMMS_DATA"
    echo "      . HMMSCAN_DATABASE * aux files need to be in the same directory"
    echo "      . NCBI_TAX_DB_FILE"
    echo "      . IMGVR_BLAST_DB"
    echo "      . VIRFINDER_MODEL"
    echo "      . CHECKV_DB"
    echo "   * CLUSTER_BATCH_SYSTEM: The cluster batch system (default slurm)"
    echo "-n the name for the job *a timestamp will be added to folder* [mandatory]"
    echo "-j toil job store folder path [mandatory]"
    echo "-o output folder [mandatory]"
    echo "-c number of cores for the job [mandatory]"
    echo "-m memory in *megabytes* [mandatory]"
    echo "-i intput fasta contigs [mandatory]"
    echo "-f Length threshold in kb of selected sequences [default: 1.0]"
    echo "-v virome mode for virsorter (default if OFF)"
    echo "-s mashmap reference file fasta or fastq (.gz) (optional)"
    echo "-r Restart workdir path. "
    echo "   Path to the job work dir for restart.Toil will raise an expection if the work directory doesn't exist"
    echo "-p Execution profile:"
    echo " LOCAL to run the pipeline locally with no batch scheduler."
    echo " EMBASSY to run it using Slurm and Docker"
    echo " CODON to run it using LSF and Singularity"
    echo ""
    echo ""
    echo "-t Use cwltool to run the pipeline."
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
LEN_FILTER="1.0"
RESTART=""
PROFILE=""
CWLTOOL=false

while getopts "e:n:j:o:c:m:i:vs:r:f:p:th" opt; do
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
        if [ -z "$NAME_RUN" ];
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
        if [ -z "$OUT_DIR" ];
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
        if [ -z "${INPUT_FASTA}" ];
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
        if [ -z "${OPTARG}" ];
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
    f)
        LEN_FILTER="${OPTARG}"
        ;;
    r)
        RESTART="${OPTARG}"
        ;;
    p)
        PROFILE="${OPTARG^^}"
        if [[ "${PROFILE}" =~ ^(LOCAL|EMBASSY|CODON)$ ]]; then
            echo "Profile selected: ${PROFILE}"
        else
            echo "Invalid profile, please select one of LOCAL, EMBASSY or CODON"
            usage;
            exit 1;
        fi
        ;;
    t)
        CWLTOOL=true
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

    TS="$(date +"%Y-%m-%d_%H-%M")"

    # Prefix the path to make it easier to clean
    TMPDIR="${TMPDIR:-/scratch}/${NAME_RUN}_${TS}"
    JOB_DIR="${JOB_DIR}/${NAME_RUN}_${TS}"
    LOG_DIR="${OUT_DIR}/${NAME_RUN}_${TS}/logs"
    OUT_DIR="${OUT_DIR}/${NAME_RUN}_${TS}"

    # Prepare folders
    mkdir -p "${LOG_DIR}"
    mkdir -p "${OUT_DIR}"

    set +x

    # Prepare the yaml file
    YML_INPUT="${OUT_DIR}/${NAME_RUN}_${TS}_input.yaml"

    CWL_PARAMS=(
        -i "${INPUT_FASTA}"
        -f "${LEN_FILTER}"
        -s "${VIRSORTER_DATA}"
        -a "${ADDITIONAL_HMMS_DATA}"
        -j "${HMMSCAN_DATABASE}"
        -n "${NCBI_TAX_DB_FILE}"
        -b "${IMGVR_BLAST_DB}"
        -cv "${CHECKV_DB}"
        -d "${VIRFINDER_MODEL}"
        -o "${YML_INPUT}"
    )

    if [ -n "${MASHMAP_REFERENCE}" ];
    then
        CWL_PARAMS+=(-m "${MASHMAP_REFERENCE}")
    fi

    if [ -n "${VIROME}" ];
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

# Profiles #
if [ "${PROFILE}" = "EMBASSY" ];
then
    TOIL_PARAMS+=(
        --batchSystem slurm
        --disableCaching
    )
fi

if [ "${PROFILE}" = "CODON" ];
then
    TOIL_PARAMS+=(
        --singularity
        --batchSystem lsf
        --disableCaching
    )
fi

if [ "${PROFILE}" = "LOCAL" ];
then
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

if [ "${CWLTOOL}" = true ];
then
    echo "CWL tool runner."
    cwltool \
    --preserve-entire-environment \
    --leave-container \
    --timestamps \
    --disable-color \
    --outdir "${OUT_DIR}" \
    "${SCRIPT_DIR}/src/pipeline.cwl" \
    "${YML_INPUT}" | tee "${LOG_DIR}"/"${NAME_RUN}".log
else
    echo "Toil runner"
    toil-cwl-runner "${TOIL_PARAMS[@]}"
fi