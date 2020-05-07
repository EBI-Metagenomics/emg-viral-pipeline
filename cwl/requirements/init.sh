#!/usr/bin/env bash

# CONDA
source /path-to/miniconda3/bin/activate # activate base conda
source activate /path-to/viral_pipeline/ # activate env by path

# set PATH
PATH="<path to tools folder>:${PATH}" # repo tools folder

export PATH

# set PERL5LIB
PERL5LIB="<path to perl in env>:${PERL5LIB}"

export PERL5LIB

# set environment variable for default NCBI taxonomy database location
DEFTAXDIR="/nfs/production/interpro/metagenomics/viral_annotation/databases"

export DEFTAXDIR
