<common_dataset>
   dataset that contains all data common to ML and flat patient analysis generation
   consists of 'base tables' and 'ml tables'
   does include 'base tables' which have all the hospital data
   does include ml tables for all types of projects (e.g. ckd and asthma)
   does not contain flat patient summary tables (e.g cohorts)
   does not limit 'end date'
   ideally, there should be no 'conditional' data generation as there might be for the pat tables <below>

<asthma_dataset>
   asthma flat patient

<ckd_dataset>  (or bpa_dataset)
   ckd flat patient (the cohorts)


put hmhn/scripts folder on your path
  (source hmhn/scripts/bashrc)
  
cbq = wrapper script around 'bq'.  does variable substitution
   must install and configure 'bq'  instructions in the wiki

list-datasets
delete-datasets
table-sizes




<cbqargs>
   --generate-script
   --variable=value  (overrides the 'default' variable settings)


In the carenostics_ml_bigquery folder

./create-everything.sh <common_dataset> <bpa_dataset> <asthma_dataset>


./common-table-insertion.sh <common_dataset> <cbqargs> ...
   recreate the <common_dataset> and create all base and ml tables
   same as /base-table-insertion.sh followed by ml-table-insertion.sh


./pat-ckd-table-insertion.sh <commmon_dataset> <pat_dataset> <cbqargs> ...
   - run 'flat patient' analysis and generate cohort_a1 etc saving to <pat_dataset>
   --PAT_EGFR_MAX_YEARS=3    # max age of egfr test results to consider
   --PAT_DX_CKD_EXCLUDE_N_CODES=true # excludes 18.9  (does not exclude 18.6)
   --PAT_DX_CKD_ONLY_PROBLEM_OR_DX=true # only take diagnosis from problem_list or medical_hx  (excludes pat_enc_dx and har_dx)
   --PAT_ALL_FLT_NO_USE_UACR=true
   --UNTIL_DATE=    # only consider data till this date. form is yyyy-mm-dd

./pat-asthma-table-insertion.sh <commmon_dataset> <pat_dataset> <cbqargs> ...
   --UNTIL_DATE=    # only consider data till this date. form is yyyy-mm-dd


to run one 'common' file
./file-insertion.sh <dataset> file


-- helpers.  if you want to run just pieces of the full analysis


# run just one script.  you might need to add variables
# assumes cbq is on the path
# you can get that, and any other shell environment by
source ./hmhn/scripts/bashrc
cbq --dataset=mlg_common  common/asthma_analysis.sql


./base-table-insertion.sh <common_dataset> <cbqargs> ...   - recreate common_dataset and do base table insertion
   # these variable will rarely change
   --HMHN=hmh-datalake-dev.CLARITY
   --NUMNBER_PATIENTS=1000000
   --CONDITIONS_IGNORE_PROBLEM_STATUS_3=true

./ml-table-insertion.sh <common_dataset> <cbqargs> ....    - do the ml table insertion (replacing any existing ml tables)
   no variables
