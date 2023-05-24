#!/bin/bash

if [ $# -lt 2 ] ; then
   echo "Usage: pat_table_insertion.shn <ml_dataset> <pat_dataset>"
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

# ideally, use a 'declare' statement at the beginning of files to put the values into SQL variables
# used by pat_egfr_ckd.sql
export PAT_EGFR_MAX_YEARS=3    # max age of egfr test results to consider

# used by pat_dx_ckd.sql
export PAT_DX_CKD_EXCLUDE_N_CODES=true # excludes 18.9  (does not exclude 18.6)
export PAT_DX_CKD_ONLY_PROBLEM_OR_DX=true # only take diagnosis from problem_list or medical_hx  (excludes pat_enc_dx and har_dx)

# used by pat_all_flt_ckd.sql
export PAT_ALL_FLT_NO_USE_UACR=true

# either unset ... or in the form  yyyy-mm-dd.  this parses as midnight ... so ... if you want till the end of today, use the next days date
export UNTIL_DATE=
cbq --dataset=$PAT_DATASET --ML=$ML_DATASET "$@" test.sql
