#!/bin/bash

# scripts path
SCRIPTS_PATHS=$(readlink -f "../../bin")
PATH="$SCRIPTS_PATHS":$PATH

cwltest --test tests.yml "$@" --tool cwltool -- --singularity --leave-container
 