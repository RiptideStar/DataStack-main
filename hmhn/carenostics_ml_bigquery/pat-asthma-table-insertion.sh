#!/bin/bash

set -euo pipefail

if [ $# -lt 2 ] ; then
   echo "Usage: pat_asthma_insertion.shn <ml_dataset> <pat_dataset>"
   exit 1
fi

ML_DATASET=$1
shift
PAT_DATASET=$1
shift

if [ "$ML_DATASET" == "$PAT_DATASET" ] ; then
  echo "The ml and pat datasets must be different"
  exit 1
fi

# add varibles so that 'false' corresponds to original behavior (when possible)

# either unset ... or in the form  yyyy-mm-dd.  this parses as midnight ... so ... if you want till the end off today, use the next days date
export UNTIL_DATE=


cbq --dataset=$PAT_DATASET --ML=$ML_DATASET "$@"  \
       shared/recreate_dataset.sql \
       asthma/pat_asthma_dx.sql

