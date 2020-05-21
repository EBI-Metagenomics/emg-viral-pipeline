#!/usr/bin/env bash

#########################################
## hoelzer.martin@gmail.com
#
# configure everything on the EBI cluster

#ln -s /homes/mhoelzer/data/nextflow-databases/virsorter/virsorter-data /homes/mhoelzer/backuped/git/CWL_viral_pipeline/CWL/Tools/VirSorter

DIR=/hps/nobackup2/singularity/mhoelzer/build
mkdir -p $DIR/.singularity
mkdir -p $DIR/.singularity/tmp
mkdir -p $DIR/.singularity/pull
mkdir -p $DIR/.singularity/scratch
export SINGULARITY_CACHEDIR=$DIR/.singularity
export SINGULARITY_TMPDIR=$DIR/.singularity/tmp
export SINGULARITY_LOCALCACHEDIR=$DIR/singularity/tmp
export SINGULARITY_PULLFOLDER=$DIR/.singularity/pull
export SINGULARITY_BINDPATH=$DIR/.singularity/scratch

for name in 'cwl_length_filter_docker' 'annotation_viral_contigs' 'assign_taxonomy' 'hmmscan' 'mapping_viral_predictions' 'sed_docker' 'cwl_parse_pred' 'prodigal_viral' 'ratio_evalue' 'virfinder_viral'; do
    singularity_image="mhoelzer-$(echo ${name} | sed 's/_/-/g')-0.1"
    docker_image="mhoelzer/${name}:0.1"
    CMD="singularity build /hps/nobackup2/singularity/mhoelzer/${singularity_image}.img docker://${docker_image}"
    $CMD
done
