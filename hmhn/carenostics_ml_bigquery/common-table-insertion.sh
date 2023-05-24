#!/bin/bash

set -euo pipefail

if [ $# -eq 0 ] ; then
   echo "Usage: common-table-insertion <dataset> <additional bq2 options>"
   exit 1
fi


./base-table-insertion.sh "$@"
./ml-table-insertion.sh "$@"
