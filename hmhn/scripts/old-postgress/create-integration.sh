#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 0 ] ; then
    echo "Usage:  $SCRIPT_NAME"
    exit 1
fi

NORM=hmhn_integration
ML=ml_integration
PTS=all

$SCRIPT_DIR/../hmhn_raw_to_normalized/create-hmhn-normalized.sh --normalized=$NORM
$SCRIPT_DIR/../carenostics_ml/create_ml.sh  --ml=${ML} --normalized=${NORM} --number-patients=$PTS --all --force



