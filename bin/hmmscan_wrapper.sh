#!/bin/bash

set -e

# hmmscan wrapper
# will output an empty tsv file if the sequence file is empty

if [ ! -s "$7" ]; # the file is in the seventh position
then
  touch "empty_hmmscan.tbl"
  exit 0
fi

hmmscan "$@" > /dev/null 2> /dev/null
