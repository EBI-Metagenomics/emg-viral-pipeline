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
    echo "-n the name for the job *a timestamp will be added to folder* [mandatory]"
    echo "-j toil job store folder path [mandatory]"
    echo "-o output folder [mandatory]"
    echo "-c number of cores for the job [mandatory]"
    echo "-m memory in *megabytes* [mandatory]"
    echo "-i intput fasta contigs [mandatory]"
    echo "-v virome mode for virsorter (default if OFF)"
    echo "-s mashmap reference file fasta or fastq (.gz) (optional)"
    echo ""
    echo "Example:
            virify.sh -e init.sh -n test-run -m 1024 -c 12 -j job_folder_path -o /data/results/ -i input.fasta
          NOTE:
          - The results folder will be /data/results/{job_name}.
          - The logs will be stored in /data/results/{job_name}/LOGS"
    echo ""
}

# mandatory
NAME_RUN=""
JOB_FOLDER=""
OUT_DIR=""
CORES=""
MEMORY=""
INPUT_FASTA=""
VIROME=""
MASHMAP_REFERENCE=""
ENV_SCRIPT=""

while getopts "e:n:j:o:c:m:i:vs:h" opt; do
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
        JOB_FOLDER="$OPTARG"
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
        INPUT_FASTA="$OPTARG"
        if [ ! -n "$INPUT_FASTA" ];
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
        if [ ! -n "$OPTARG" ];
        then
            echo ""
            echo "ERROR mashmap (-s) cannot be empty." >&2
            usage;
            exit 1
        fi
        MASHMAP_REFERENCE="-m ${OPTARG}" 
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
        echo ""
        echo "Invalid option -$OPTARG" >&2
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
if [ -z "$NAME_RUN" ] || \
   [ -z "$JOB_FOLDER" ] || \
   [ -z "$OUT_DIR" ] || \
   [ -z "$CORES" ] || \
   [ -z "$MEMORY" ] || \
   [ -z "$INPUT_FASTA" ] || \
   [ -z "$ENV_SCRIPT" ]
then
    echo ""
    echo "ERROR: Missing mandatory parameter."
    usage;
    exit 1
fi

# shellcheck source=/dev/null
source "${ENV_SCRIPT}"

set -u

TS="$(date +"%Y-%m-%d_%H-%M-%S")"

# Prefix the path to make it easier to clean
TMPDIR="${TMPDIR:-/scratch}/${NAME_RUN}_${TS}"

JOB_FOLDER="${JOB_FOLDER}/${NAME_RUN}_${TS}"
LOG_DIR="${OUT_DIR}/${NAME_RUN}_${TS}/LOGS"
OUT="${OUT_DIR}/${NAME_RUN}_${TS}"

# print
set -x

# Prepare folders
mkdir -p "$LOG_DIR"
mkdir -p "$TMPDIR"
mkdir -p "$OUT"

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
    -o "${YML_INPUT}"
)

if [ ! -z "$MASHMAP_REFERENCE" ];
then
    CWL_PARAMS+=("${MASHMAP_REFERENCE}")
fi

if [ ! -z "$VIROME" ];
then
    CWL_PARAMS+=("${VIROME}")
fi

cwl_input.py "${CWL_PARAMS[@]}"

# assume CWL is src/pipeline.cwl relative to this script
SCRIPT_DIR="$(dirname "$0")"

toil-cwl-runner \
--no-container \
--batchSystem LSF \
--disableCaching \
--logDebug \
--maxLogFileSize 0 \
--cleanWorkDir never \
--defaultCores "$CORES" \
--defaultMemory "$MEMORY"M \
--jobStore "$JOB_FOLDER" \
--stats \
--clusterStats "$LOG_DIR/stats.json" \
--outdir "$OUT" \
--writeLogs "$LOG_DIR" \
--retryCount 0  \
--logFile "$LOG_DIR/${NAME_RUN}.log" \
--enable-dev \
"${SCRIPT_DIR}/src/pipeline.cwl" \
"${YML_INPUT}"
