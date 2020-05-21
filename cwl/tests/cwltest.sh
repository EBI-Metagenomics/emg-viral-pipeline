#!/bin/bash

# scripts path
SCRIPTS_PATHS=$(readlink -f "../../bin")
PATH="$SCRIPTS_PATHS":$PATH

cwltest "$@" --tool cwltool -- --enable-dev --no-container
