#!/bin/bash

set -euo pipefail

COMMON=mlg_common2
EGFR=mlg_egfr2
ASTHMA=mlg_asthma2

cbq utils/utils.sql "$@"
./base-table-insertion.sh $COMMON --NUMBER_PATIENTS=10 "$@"
./ml-table-insertion.sh $COMMON "$@"
./pat-ckd-table-insertion.sh $COMMON $EGFR "$@"
./pat-asthma-table-insertion.sh $COMMON $ASTHMA "$@"


