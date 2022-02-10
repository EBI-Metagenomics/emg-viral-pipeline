#!/bin/bash

set -e

# EMG-Viral pipeline ENV script
. /hps/software/users/rdf/metagenomics/service-team/repos/mi-automation/team_environments/codon/mitrc.sh

mitload virify env

# virify scripts
_addpath "/nfs/production/rdf/metagenomics/pipelines/prod/emg-viral-pipeline/bin/"

DATABASES="/nfs/production/rdf/metagenomics/pipelines/prod/emg-viral-pipeline/cwl/databases"

export VIRSORTER_DATA="${DATABASES}/virsorter-data"
export ADDITIONAL_HMMS_DATA="${DATABASES}/additional_data_vpHMMs_v2.tsv"
export HMMSCAN_DATABASE="${DATABASES}/hmmer_databases/vpHMM_database_v3/vpHMM_database_v3.hmm"
export NCBI_TAX_DB_FILE="${DATABASES}/2020-07-01_ete3_ncbi_tax.sqlite"
export IMGVR_BLAST_DB="${DATABASES}/IMG_VR_2018-07-01_4"
export VIRFINDER_MODEL="${DATABASES}/virfinder/VF.modEPV_k8.rda"
export CHECKV_DB="${DATABASES}/checkv-db-v1.0"

export TMPDIR="/hps/scratch/rdf/metagenomics/pipelines-tmp"

module load singularity-3.7.0-gcc-9.3.0-dp5ffrp
