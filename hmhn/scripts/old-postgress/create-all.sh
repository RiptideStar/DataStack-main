#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 2 ] ; then
    echo "Usage:  $SCRIPT_NAME  <normalized_schema_name> <ml_schema_name>"
    exit 1
fi

NORM=$1
ML=$2
PTS=all

$SCRIPT_DIR/../hmhn_raw_to_normalized/create-hmhn-normalized.sh --normalized=$NORM
$SCRIPT_DIR/../carenostics_ml/create_ml.sh  --ml=${ML} --normalized=${NORM} --number-patients=$PTS --all --force



