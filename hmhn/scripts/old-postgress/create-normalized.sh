#!/bin/bash

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 1 ] ; then
    echo "Usage:  $SCRIPT_NAME <normalized_schema_name>"
    exit 1
fi

NORM=$1

$SCRIPT_DIR/../hmhn_raw_to_normalized/create-hmhn-normalized.sh -n=$NORM



