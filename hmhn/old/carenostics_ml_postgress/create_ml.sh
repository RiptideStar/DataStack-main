#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")


errorHappened() {
  echo "Error on line $1"
  exit 1
}

trap "errorHappened \$LINENO" ERR


LOGTM=$(TZ=UTC date +"%Y%m%d_%H%M%S")

ML=
NUM_PATIENTS=1000
NORMALIZED=hmhn_normalized_latest
SHOW_USAGE=0
FORCE=0
OPT_N=
CREATE_SCHEMA=0
CREATE_BASE=0
CREATE_ML=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ml=*|-m=*)
        ML="${1#*=}"
        shift
        ;;
    --normalized=*|-n=*)
        NORMALIZED="${1#*=}"
        shift
        ;;
    --number-patients=*|-n=*)
        NUM_PATIENTS="${1#*=}"
        shift
        ;;
    --timestamp=*|-t=*)
        LOGTM="${1#*=}"
        shift
        ;;
    --force)
        FORCE=1
        shift ;;
    --schema)
        CREATE_SCHEMA=1 
        shift ;;
    --base-tables)
        CREATE_BASE=1   
        shift ;;
    --ml-tables)
        CREATE_ML=1     
        shift ;;
    --all)
        CREATE_SCHEMA=1
        CREATE_BASE=1
        CREATE_ML=1
        shift ;;
    -n)
        OPT_N=-n
        shift ;;
    *)
        echo "Unknown options: $1"
        SHOW_USAGE=1
        break
        ;;
  esac
done


if [ $SHOW_USAGE -eq 1 ] ; then
    echo "Usage: $SCRIPT_NAME [--ml=<schema>] [--normalized=<schema>] [--number-patients=<n>] [-n] [--all] [--schema] [--base-tables] [--ml-tables] [--force]"
    echo "  --ml=<schema>          Name of the ml schema to create/update"
    echo "  --normalized=<schema>  Name of the normalized schema to read from.  Default: hmhn_normalized_latest"
    echo "  --schema               Delete and create the ml schema"
    echo "  --base-tables          Delete and recreate the base tables taking --number-patients worth of data from the --normalized schema"
    echo "  --ml-tables            Delete and recreate the ml tables"
    echo "  --all                  Same as --schema --base --ml.  This is implicitly set if --schema, --base, and --ml are not set"
    echo "  --number-patients <n>  Number of patient to use when creating the --base tables.  Default: 1000.  'all' can be used for 'all patients'"
    echo "  --force                Do not ask for confirmation when --schema is specified"
    echo "  -n                     Echo what would be done"
  exit 1
fi

if [ $((CREATE_SCHEMA+CREATE_BASE+CREATE_ML)) -eq 0 ] ; then
    CREATE_SCHEMA=1
    CREATE_BASE=1
    CREATE_ML=1
fi

if [ -z "$ML" ] ; then
    echo "--ml must be specified"
    exit 1
fi


if [ $CREATE_SCHEMA -eq 1 -a $FORCE -eq 0 ] ; then
    read -p "Really create '$ML' from '$NORMALIZED' for $NUM_PATIENTS patients ? " -r
else
    REPLY=y
fi

if [ "$REPLY" != "y" ] ; then
  exit 1
fi

cd $SCRIPT_DIR

LOGFILE=../logs/${LOGTM}-$ML-create.log
mkdir -p $(dirname $LOGFILE) 
echo "Logging to $(realpath $LOGFILE)"


touch $LOGFILE
start=`date +%s`
echo "Started create_ml.sh schema=$CREATE_SCHEMA base=$CREATE_BASE ml=$CREATE_ML at $(date)"

if [ $CREATE_SCHEMA -eq 1 ] ; then
  ../scripts/run-sql.sh $OPT_N --newSchema=$ML ../scripts/recreate-empty-schema.sql &>> $LOGFILE
fi

if [ $CREATE_BASE -eq 1 ] ; then
  ../scripts/run-sql.sh $OPT_N --schema=$ML ./base_table_creation.sql  &>> $LOGFILE
  if [ "$NUM_PATIENTS" == "all" ] ; then
     NUM_PATIENTS=50000000
  fi
  ../scripts/run-sql.sh $OPT_N --schema=$ML --sourceSchema=$NORMALIZED --numberpatients=$NUM_PATIENTS ./base_table_insertion.sql  &>> $LOGFILE
fi

if [ $CREATE_ML -eq 1 ] ; then
  ../scripts/run-sql.sh $OPT_N --schema=$ML ./ml_table_insertion.sql &>> $LOGFILE
  echo
  if [ "$OPT_N" != "-n"  ] ; then
    sed -n '/Label.*Total/,${p;/rows/q}' $LOGFILE | grep -v '1 row'
    echo
  fi
fi

end=`date +%s`

echo "Finished create_ml.sh schema=$CREATE_SCHEMA base=$CREATE_BASE ml=$CREATE_ML at $(date) in $(((end-start)/60)) minutes ----"

