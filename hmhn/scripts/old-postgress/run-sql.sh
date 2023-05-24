#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

SCHEMA=
SHOW_USAGE=0
OPT_N=0

VARS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --schema=*|--s=*)
        SCHEMA="${1#*=}"
        shift
        ;;
    -h | --help | -\? | --?)
        SHOW_USAGE=1
        break
        ;;
    -n | --noexec )
	OPT_N=1
	shift
	;;
    --*=*)
      VARS+=("${1#--}")
      shift
      ;;
    --*)
        echo Unrecognized option: "$1"
        SHOW_USAGE=1
        break
        ;;
    *)
      break
      ;;
  esac
done

if [ $# -ne 1 ] ; then
    SHOW_USAGE=1
fi

if [ $SHOW_USAGE -eq 1 ] ; then
    echo "Usage: $SCRIPT_NAME -n --s[chema]=<schema> --variable=value ...   file.sql"
    echo " The variable --debug=false is used if not specified"
  exit 0
fi


if [ -r ~/.db_setup.sh ] ; then
    source ~/.db_setup.sh
fi

if [ -z ${PGPASSWORD+x} ] ; then
    echo "PGPASSWORD not set.  Either do 'export PGPASSWORD=xxxxx' or have it in ~/.db_setup.sh"
    exit 1
fi

schemaFile=$1
origFile=$1

if [ ! -e "$schemaFile" ] ; then
    echo "$schemaFile not found"
    exit 1
fi


# need to learn bash associative array
HAVE_DEBUG=0
for value in "${VARS[@]}" ; do
  nm=${value/=*/}
  val=${value/*=/}
  if [ $nm == "debug" ] ; then
     HAVE_DEBUG=1
  fi
done

if [ $HAVE_DEBUG -eq 0 ] ; then
  VARS+=("debug=false")
fi

# need to copy ALL .sql files ... including 'includes'

TMPFOLDER=./tmpqueries
INCLUDED=$(sed -nE "s/.include_relative '(.*)'/\\1/p" $schemaFile)
ALL_FILES="$schemaFile $INCLUDED"
rm -rf $TMPFOLDER
mkdir $TMPFOLDER

cp $ALL_FILES $TMPFOLDER

if [ ${#VARS[@]} -ne 0 ] ; then
    for value in "${VARS[@]}" ; do
      nm=${value/=*/}
      val=${value/*=/}
      echo "Replace {$nm} with $val"
      sed -i "s/[{]$nm[}]/$val/g" $TMPFOLDER/*
    done
fi

if grep -q "{" $TMPFOLDER/* ; then
    echo All variables not replaced
    sed -nE 's/.*([{].*[}]).*/\1/p' $TMPFOLDER/* | sort -u
    exit 1
fi


conn="host=10.152.17.12 sslmode=disable dbname=postgres user=postgres"


if [ -n "$SCHEMA" ] ; then
  ok=$(psql "$conn" -t -c "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = '$SCHEMA');")
  if [ $ok == "f" ] ; then
      if [ $OPT_N -ne 1 ] ; then
        echo "Schema '$SCHEMA' does not exit"
        exit 1
      fi
  fi
fi


# can't get this to work :-(
# PGOPTIONS='-c client_min_messages=WARNING'

start=`date +%s`
N=
if [ $OPT_N -eq 1 ] ; then
   N="echo "
fi
echo "---- Start $origFile ----"
${N}psql "$conn options=--search_path=$SCHEMA" -v ON_ERROR_STOP=1  -f "$TMPFOLDER/$(basename $schemaFile)" -P pager=off --quiet 
end=`date +%s`
echo "---- Ran $origFile in $((end-start)) seconds ----"

branch=$(cd $(dirname $schemaFile); git rev-parse --abbrev-ref HEAD)

if [ -n "$SCHEMA" ] ; then 
  ${N}$SCRIPT_DIR/add-metadata.sh $SCHEMA "run-sql" "$(realpath $schemaFile)" "$branch"
fi

