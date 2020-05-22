#!/usr/bin/env bash

set -e

# ENV script
# This script defines:
# - CWL file
# - conda env
# - TMPDIR => to prevent using the user TMP FOLDER
# - Add scripts folder to PATH
# - export databases variables:
#   - VIRSORTER_DATA 
#   - HMMS_SERIALIZED_FILE
#   - HMMSCAN_DATABASE_DIRECTORY
#   - NCBI_TAX_DB_FILE
#   - IMGVR_BLAST_DB
# - Add PERL5LIB point to conda site_perl path 
# - exports $CWL with the full path to the pipeline.cwl

# source /nfs/production/interpro/metagenomics/virify_pipeline/init.sh  # /path/to/init.sh

set -u

usage () {
    echo ""
    echo "Wrapper script to run the virify workflow using toil-cwl-runner."
    echo "-n job_name [mandatory]"
    echo "-j toil job store folder path [mandatory]"
    echo "-o output folder [mandatory]"
    echo "-c number of cores for the job [mandatory]"
    echo "-m memory in *megabytes* [mandatory]"
    echo "-i intput fasta contigs [mandatory]"
    echo "-v virome mode for virsorter (default if OFF)"
    echo "Example:
            virify.sh -n XX -m 1024 -c 12 -j job_folder_path -o /data/results/ -i input.fasta
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

while getopts ":n:j:o:c:m:i:v:h" opt; do
  case $opt in
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
        VIROME="--virsorter_virome"
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
   [ -z "$INPUT_FASTA" ]
then
    echo ""
    echo "ERROR: Missing mandatory parameter."
    usage;
    exit 1
fi

# Prefix the path to make it easier to clean
TMPDIR=${TMPDIR}/${NAME_RUN}

JOB_FOLDER="${JOB_FOLDER}/${NAME_RUN}"
LOG_DIR="${OUT_DIR}/${NAME_RUN}/LOGS"
OUT="${OUT_DIR}/${NAME_RUN}"

# print
set -x

# Prepare folders
rm -rf "${JOB_FOLDER}"
rm -rf "${OUT}"
rm -rf "${LOG_DIR}"

mkdir -p "$LOG_DIR"
mkdir -p "$TMPDIR"
mkdir -p "$OUT"

toil-cwl-runner \
  --no-container \
  --batchSystem LSF \
  --disableCaching \
  --logDebug \
  --maxLogFileSize 0 \
  --cleanWorkDir=never \
  --defaultCores "$CORES" \
  --defaultMemory "$MEMORY"M \
  --jobStore "$JOB_FOLDER" \
  --stats \
  --clusterStats "$LOG_DIR/stats.json" \
  --outdir "$OUT" \
  --writeLogs "$LOG_DIR" \
  --retryCount 0  \
  --logFile "$LOG_DIR/${NAME_RUN}.log" \
  "$CWL" \
  --virsorter_data_dir "$VIRSORTER_DATA" \
  --hmms_serialized_file "$HMMS_SERIALIZED_FILE" \
  --hmmscan_database_directory "$HMMSCAN_DATABASE_DIRECTORY" \
  --ncbi_tax_db_file "$NCBI_TAX_DB_FILE" \
  --input_fasta_file "$INPUT_FASTA"  \
  --img_blast_database_dir "$IMGVR_BLAST_DB" \
  --pprmeta_singularity_simg "$PPRMETA_SIMG" \
  ${VIROME}