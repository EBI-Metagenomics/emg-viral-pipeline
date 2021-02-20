#!/bin/bash

# prodigal wrapper
# will exit with error if the file is empty

if [ ! -s "$2" ];
then
  echo "The input fasta file is empty. File: $2";
  echo "Usage: prodigal_wrapper.sh -i file.fna <other prodigal params>"
  touch "empty_predicted_cds.faa"
  exit 0
fi

prodigal "$@"
