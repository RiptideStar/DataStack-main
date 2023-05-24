#!/bin/bash

set -euo pipefail

if [ $# -lt 2 ] ; then
   echo "Usage: file-insertion <dataset> <file> <additional bq2 options>"
   exit 1
fi

DATASET=$1
FILE=$2
shift 2


export HMHN=hmh-datalake-dev.CLARITY    # hmh-datalake-dev.poc_dev
export NUMBER_PATIENTS=10000000
export CONDITIONS_IGNORE_PROBLEM_STATUS_3=true

cbq --dataset=$DATASET "$@" $FILE
