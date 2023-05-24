#!/bin/bash

set -euo pipefail

if [ $# -lt 3 ] ; then
   echo "Usage: create-everything <common_dataset> <egfr_dataset> <asthma_dataset> <additional bq2 options>"
   exit 1
fi

COMMON=$1
EGFR=$2
ASTHMA=$3
shift 3

cbq  "$@" utils/utils.sql
./base-table-insertion.sh $COMMON "$@"
./ml-table-insertion.sh $COMMON "$@"
./pat-ckd-table-insertion.sh $COMMON $EGFR "$@"
./pat-asthma-table-insertion.sh $COMMON $ASTHMA "$@"


