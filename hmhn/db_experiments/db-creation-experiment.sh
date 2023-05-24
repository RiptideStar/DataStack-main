#!/bin/bash

set -euo pipefail

if [ $# -ne 1 ] ; then
    echo "Usage: bl <experimentName>"
    exit 1
fi
    

VERS=$1
TRY=(100 1000 10000 100000 200000 1000000)
NORM=mlg_normalized
#TRY=(1000000)
#TRY=(1000 10000 100000)
#TRY=(100)

LOGTM=$(TZ=UTC date +"%Y%m%d_%H%M%S")

for PTS in ${TRY[@]}; do	   
  start=`date +%s`
  DB=${VERS}_$PTS
  echo Start $DB at $(date)
  ../carenostics_ml/create_ml.sh --ml=$DB --normalized=$NORM --number-patients=$PTS --timestamp=$LOGTM --force
  end=`date +%s`
  echo "End $DB at $(date) in $((end-start)) seconds "
done
