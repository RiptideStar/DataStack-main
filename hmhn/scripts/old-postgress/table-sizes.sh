#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 1 ] ; then
    echo "Usage: $SCRIPT_NAME <schema>"
    exit 1
fi


$SCRIPT_DIR/run-query.sh <<EOF
SELECT schemaname,relname "Table",to_char(n_live_tup,'FM999,999,999,999') "Approx. Rows"
  FROM pg_stat_user_tables 
  where schemaname ='$1'
ORDER BY n_live_tup DESC;
EOF
