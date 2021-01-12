#!/bin/bash

set -e

DIRECTORY="$(pwd)"/databases
ENDPOINT="rsync://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/"

mkdir -p "${DIRECTORY}"

echo "Fetching the files"

rsync -ahrv "${ENDPOINT}" "${DIRECTORY}"

echo "Done, now decompressing"

tar xvzf "${DIRECTORY}"/virsorter-data-v2.tar.gz --directory "${DIRECTORY}"

tar xvzf "${DIRECTORY}"/hmmer_databases/vpHMM_database_v3.tar.gz --directory "${DIRECTORY}"/hmmer_databases

tar xvzf "${DIRECTORY}"/2020-07-01_ete3_ncbi_tax.sqlite.gz --directory "${DIRECTORY}"

tar xvzf "${DIRECTORY}"/IMG_VR_2018-07-01_4.tar.gz --directory "${DIRECTORY}"

echo "Completed."
