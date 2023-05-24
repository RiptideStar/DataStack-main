#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

SCHEMA_OPT=""
if [ $# -eq 1 ] ; then
    SCHEMA_OPT="options=--search_path=$1"
fi    

if [ -r ~/.db_setup.sh ] ; then
    source ~/.db_setup.sh
fi

if [ -z ${PGPASSWORD+x} ] ; then
    echo "PGPASSWORD not set.  Either do 'export PGPASSWORD=xxxxx' or have it in ~/.db_setup.sh"
    exit 1
fi

psql "host=10.152.17.12 sslmode=disable dbname=postgres user=postgres $SCHEMA_OPT" -v ON_ERROR_STOP=1 -P pager=off --quiet






