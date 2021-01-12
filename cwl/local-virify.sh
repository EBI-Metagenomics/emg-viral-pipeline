#!/bin/bash

source "$(conda info --base)"/bin/activate

conda activate viral_pipeline

# virify scripts
export PATH="$(dirname $(dirname $(realpath "$0")))/bin":${PATH}

DIR=$(dirname "$0")
DATABASES="${DIR}/databases"

# virify dbs
export VIRSORTER_DATA="${DATABASES}/virsorter-data-v2"
export ADDITIONAL_HMMS_DATA="${DATABASES}/additional_data_vpHMMs_v1.tsv"
export HMMSCAN_DATABASE_DIRECTORY="${DATABASES}/hmmer_databases/vpHMM_database_v3"
export NCBI_TAX_DB_FILE="${DATABASES}/ete3_ncbi_tax.sqlite"
export IMGVR_BLAST_DB="${DATABASES}/IMG_VR_2018-07-01_4"
export VIRFINDER_MODEL="${DATABASES}/virfinder/VF.modEPV_k8.rda"

# singularity images
export PPRMETA_SIMG="${DIR}/simgs/pprmeta.simg"

export TMPDIR="$(pwd)/tmp"