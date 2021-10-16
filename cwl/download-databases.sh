#!/bin/bash

set -e

usage () {
    echo ""
    echo "Download VIRify DBs for the CWL version"
    echo "* requires rsyncimgvr_blast_swf.cwl"
    echo ""
    echo "-f Output folder [mandatory]"
    echo " "
}

OUTPUT=""

while getopts "f:h" opt; do
  case $opt in
    f)
        OUTPUT="$OPTARG"
        if [ -z "$OUTPUT" ];
        then
            echo ""
            echo "ERROR -f cannot be empty." >&2
            usage;
            exit 1
        fi
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

mkdir -p "${OUTPUT}"

set -u

BASE="rsync://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/"

mkdir -p "${OUTPUT}"

echo "Fetching and decompressing the files"

echo "Virsorter data v2"

rsync -ahrv --progress --partial "${BASE}"virsorter-data-v2.tar.gz "${OUTPUT}"
tar xvzf "${OUTPUT}"/virsorter-data-v2.tar.gz --directory "${OUTPUT}"

echo "vpHMM_database_v3"

rsync -ahrv --progress --partial "${BASE}"/hmmer_databases/vpHMM_database_v3.tar.gz "${OUTPUT}"
mkdir -p "${OUTPUT}"/hmmer_databases
tar xvzf "${OUTPUT}"/vpHMM_database_v3.tar.gz --directory "${OUTPUT}"/hmmer_databases

echo "ete3_ncbi_tax"
rsync -ahrv --progress --partial "${BASE}"/2020-07-01_ete3_ncbi_tax.sqlite.gz "${OUTPUT}"
gunzip "${OUTPUT}"/2020-07-01_ete3_ncbi_tax.sqlite.gz

echo "IMG_VR_2018-07-01_4"
rsync -ahrv --progress --partial "${BASE}"/IMG_VR_2018-07-01_4.tar.gz "${OUTPUT}"
tar xvzf "${OUTPUT}"/IMG_VR_2018-07-01_4.tar.gz --directory "${OUTPUT}"

echo "VirFinder metadata"
rsync -ahrv --progress --partial "${BASE}"/virfinder/* "${OUTPUT}/virfinder"

echo "Additional Metadata version 2"
rsync -ahrv --progress --partial "${BASE}"/additional_data_vpHMMs_v2.tsv "${OUTPUT}/additional_data_vpHMMs_v2.tsv"

echo "CheckV database"
wget https://portal.nersc.gov/CheckV/checkv-db-v1.0.tar.gz
tar -zxvf checkv-db-v1.0.tar.gz

echo "Completed."
