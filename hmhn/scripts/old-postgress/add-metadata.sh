#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

SCHEMA=$1
ATR=$2
VAL=$3
BRANCH=$4

if [ -r ~/.db_setup.sh ] ; then
    source ~/.db_setup.sh
fi

if [ -z ${PGPASSWORD+x} ] ; then
    echo "PGPASSWORD not set.  Either do 'export PGPASSWORD=xxxxx' or have it in ~/.db_setup.sh"
    exit 1
fi



#set -x

conn="host=10.152.17.12 sslmode=disable dbname=postgres user=postgres options=--search_path=$SCHEMA"


psql "$conn" -v ON_ERROR_STOP=1  &>/dev/null <<EOF
create table if not exists metadata (
  label text not null,
  value text not null,
  branch text not null,
  username  text not null,
  time timestamp default(now()) not null
) ;
EOF


psql "$conn" -v ON_ERROR_STOP=1 -c "insert into metadata(label, value, username, branch) values('$ATR', '$VAL', '$USER','$BRANCH')" &>/dev/null

