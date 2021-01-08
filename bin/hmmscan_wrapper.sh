#!/bin/bash

set -e

# hmmscan wrapper
# will output an empty tsv file if the sequence file is empty

# the file is in the ninth position
if [ ! -f "$9" ] || [ ! -s "$9" ];
then
  touch "empty_hmmscan.tbl"
  exit 0
fi

hmmscan "$@"