#/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

errorHappened() {
  echo "Error on $SCRIPT_NAME line $1"
  exit 1
}

trap "errorHappened \$LINENO" ERR

RAW_DATA=hmhn_raw_2023_02_22
NORMALIZED=
SHOW_USAGE=0
FORCE=0
OPT_N=

while [ "$#" -gt 0 ]; do
  case "$1" in
    --raw-data=*|-r=*)
        RAW_DATA="${1#*=}"
        shift
        ;;
    --normalized=*|-n=*)
        NORMALIZED="${1#*=}"
        shift
        ;;
    --force)
	FORCE=1
        shift ;;
    -n)
        OPT_N=-n
        shift ;;
    *)
        SHOW_USAGE=1
	break
	;;
  esac
done

if [ -z "$NORMALIZED" ] ; then
    echo "--normalized is required"
    exit 1;
fi

if [ $SHOW_USAGE -eq 1 ] ; then
  echo "Usage: $SCRIPT_NAME  [--raw-data=<schema>] [--normalized=<schema>] [--force]"
  exit 1
fi

if [ $FORCE -eq 0 ] ; then
    read -p "Really create '$NORMALIZED' from '$RAW_DATA' ? (y/n) " -r
else
    REPLY=y
fi

if [ "$REPLY" != "y" ] ; then
  exit 1
fi

LOGTM=$(TZ=UTC date +"%Y%m%d_%H%M%S")
LOGFILE=$SCRIPT_DIR/../logs/${LOGTM}-$NORMALIZED-create.log
mkdir -p $(dirname $LOGFILE) 
echo "Logging to $(realpath $LOGFILE)"

set -x
(cd $SCRIPT_DIR; ../scripts/run-sql.sh $OPT_N --newSchema=$NORMALIZED ../scripts/recreate-empty-schema.sql) &> $LOGFILE
(cd $SCRIPT_DIR; ../scripts/run-sql.sh $OPT_N --schema=$NORMALIZED --sourceSchema=$RAW_DATA ./copy-tables-to-normalized.sql) &>> $LOGFILE
(cd $SCRIPT_DIR; ../scripts/run-sql.sh $OPT_N --schema=constant --normalized=$NORMALIZED ./update-patient-mapping.sql) &>> $LOGFILE
