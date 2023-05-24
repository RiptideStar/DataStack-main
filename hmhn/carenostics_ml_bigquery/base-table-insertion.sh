#!/bin/bash

set -euo pipefail

if [ $# -eq 0 ] ; then
   echo "Usage: base_table_insertion dataset <additional bq2 options>"
   exit 1
fi

DATASET=$1
shift

# same as adding a variable definition on the command line
# the command line settings take precedence

# if you add a variable, update base_meta_data
export HMHN=hmh-datalake-dev.CLARITY    # hmh-datalake-dev.poc_dev
export NUMBER_PATIENTS=10000000

# avoid adding any conditional behavior here unless you are really sure the new behavior is correct for both ML and BPA

# add varibles so that 'false' corresponds to original behavior (when possible)
# if true, only use PROBLEM_STATUS_C = 3 
export CONDITIONS_IGNORE_PROBLEM_STATUS_3=true

cbq --dataset=$DATASET "$@" \
 shared/recreate_dataset.sql \
 common/update_patient_mapping.sql \
 common/cohort.sql \
 common/all_races.sql \
 common/all_genders.sql \
 common/all_ethnicity.sql \
 common/all_marital_status.sql \
 common/demographics.sql \
 common/conditions.sql \
 common/encounters.sql \
 common/labs.sql \
 common/medications.sql \
 common/concepts.sql \
 common/vitals.sql \
 common/procedures.sql \
 common/base_meta_data.sql \
 shared/table_sizes.sql
