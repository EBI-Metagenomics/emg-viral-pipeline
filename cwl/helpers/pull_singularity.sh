#!/bin/bash

DIR=$1

for IMG in  emg-viral-pipeline-python3:v1 \
            virsorter:1.0.6 \
            prodigal:v2.6.3 \
            krona:v2.7.1 \
            blast:v2.9.0 \
            virfinder:v1.1__eb8032e \
            mashmap:2.0 \
            hmmer:v3.1b2
do
    singularity pull \
    --name ${DIR}/docker.io_microbiomeinformatics_${IMG}.sif \
    docker://microbiomeinformatics/${IMG}
done