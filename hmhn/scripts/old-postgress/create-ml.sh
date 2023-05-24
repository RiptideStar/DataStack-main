#!/bin/bash

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 3 ] ; then
    echo "Usage:  $SCRIPT_NAME <ml_schema_name> <normalized_schema_name> <numberPatients>"
    exit 1
fi

ML=$1
NORM=$2
PTS=$3

$SCRIPT_DIR/../carenostics_ml/create_ml.sh  --ml=${ML}_$PTS --normalized=${NORM} --number-patients=$PTS --all




