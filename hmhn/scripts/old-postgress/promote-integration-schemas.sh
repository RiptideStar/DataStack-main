#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 0 ] ; then
    echo "Usage: $SCRIPT_NAME"
    exit 1
fi

HMHN_NEXT=hmhn_normalized_next
HMHN_INTEGRATION=hmhn_integration

ML_NEXT=ml_next
ML_INTEGRATION=ml_integration

$(dirname "${BASH_SOURCE[0]}")/run-query.sh <<EOF
select 
       not exists(SELECT FROM information_schema.schemata WHERE schema_name = '$HMHN_INTEGRATION') not_$HMHN_INTEGRATION,
       not exists(SELECT FROM information_schema.schemata WHERE schema_name = '$ML_INTEGRATION') not_$ML_INTEGRATION
\gset
\if :not_$HMHN_INTEGRATION
  \echo '$HMHN_INTEGRATION does not exist'
  \quit
\endif

\if :not_$ML_INTEGRATION
  \echo '$ML_INTEGRATION does not exist'
  \quit
\endif


drop schema if exists $ML_NEXT cascade;
drop schema if exists $HMHN_NEXT cascade;

alter schema $ML_INTEGRATION rename to $ML_NEXT;

alter schema $HMHN_INTEGRATION rename to $HMHN_NEXT;

EOF
