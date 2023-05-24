#!/bin/bash

set -euo pipefail
if [ $# -eq 0 ] ; then
   echo "Usage: ml_table_insertion dataset <additional bq2 options>"
   exit 1
fi

DATASET=$1
shift

# if you add a variable, update base_table_metadata
# add varibles so that 'false' corresponds to original behavior (when possible)
# avoid adding any conditional behavior here unless you are really sure the new behavior is correct for both ML and BPA

cbq --dataset=$DATASET "$@"  \
 common/uacr_analysis.sql \
 common/egfr_analysis.sql \
 common/ckd_analysis.sql \
 common/asthma_dx_analysis.sql \
 common/asthma_med_analysis.sql \
 common/asthma_yearly_ocs.sql \
 common/ml_meta_data.sql \
 shared/table_sizes.sql

