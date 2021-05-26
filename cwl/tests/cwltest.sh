#!/bin/bash

# scripts path
SCRIPTS_PATHS=$(readlink -f "../../bin")
PATH="$SCRIPTS_PATHS":$PATH

cwltest --test tests.yml "$@" --tool toil-cwl-runner -- --disableProgress --enable-dev
