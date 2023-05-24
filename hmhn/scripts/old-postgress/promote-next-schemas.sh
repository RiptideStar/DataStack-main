#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 0 ] ; then
    echo "Usage: $SCRIPT_NAME"
    exit 1
fi

HMHN_NEXT=hmhn_normalized_next
HMHN_LATEST=hmhn_normalized_latest
HMHN_PREVIOUS=hmhn_normalized_previous

ML_NEXT=ml_next
ML_LATEST=ml_latest
ML_PREVIOUS=ml_previous

$(dirname "${BASH_SOURCE[0]}")/run-query.sh <<EOF
select 
       not exists(SELECT FROM information_schema.schemata WHERE schema_name = '$HMHN_LATEST') not_$HMHN_LATEST,
       not exists(SELECT FROM information_schema.schemata WHERE schema_name = '$ML_LATEST') not_$ML_LATEST,
       not exists(SELECT FROM information_schema.schemata WHERE schema_name = '$HMHN_NEXT') not_$HMHN_NEXT,
       not exists(SELECT FROM information_schema.schemata WHERE schema_name = '$ML_NEXT') not_$ML_NEXT,
       not exists(SELECT FROM information_schema.schemata WHERE schema_name = '$HMHN_PREVIOUS') not_$HMHN_PREVIOUS,
       not exists(SELECT FROM information_schema.schemata WHERE schema_name = '$ML_PREVIOUS') not_$ML_PREVIOUS

\gset
\if :not_$HMHN_LATEST
  \echo '$HMHN_LATEST does not exist'
  \quit
\endif

\if :not_$ML_LATEST
  \echo '$ML_LATEST does not exist'
  \quit
\endif

\if :not_$HMHN_PREVIOUS
  \echo '$HMHN_PREVIOUS does not exist'
  \quit
\endif

\if :not_$ML_PREVIOUS
  \echo '$ML_PREVIOUS does not exist'
  \quit
\endif


\if :not_$HMHN_NEXT
  \echo '$HMHN_NEXT does not exist'
  \quit
\endif

\if :not_$ML_NEXT
  \echo '$ML_NEXT does not exist'
  \quit
\endif



\echo drop schema if exists $ML_PREVIOUS cascade;
\echo drop schema if exists $HMHN_PREVIOUS cascade;

\echo alter schema $ML_LATEST rename to $ML_PREVIOUS;
\echo alter schema $HMHN_LATEST rename to $HMHN_PREVIOUS;

\echo alter schema $ML_NEXT rename to $ML_LATEST;
\echo alter schema $HMHN_NEXT rename to $HMHN_LATEST;

EOF
