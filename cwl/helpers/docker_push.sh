#!/usr/bin/env bash
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

docker push mgnify/virfinder_viral:latest

docker push mgnify/annotation_viral_contigs:latest

docker push mgnify/assign_taxonomy:latest

docker push mgnify/cwl_length_filter_docker:latest

docker push mgnify/mapping_viral_predictions:latest

docker push mgnify/cwl_parse_pred:latest

docker push mgnify/prodigal_viral:latest

docker push mgnify/ratio_evalue:latest

docker push mgnify/sed_docker:latest