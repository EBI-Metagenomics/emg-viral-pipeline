#!/bin/bash

# scripts path
SCRIPTS_PATHS=$(readlink -f "../../bin")
PATH="$SCRIPTS_PATHS":$PATH

cwltest --test tests.yml "$@" --basedir /home/mbc/projects --tool toil-cwl-runner -- --disableProgress --singularity
