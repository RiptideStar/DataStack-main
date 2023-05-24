#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 1 ] ; then
    echo "Usage: $SCRIPT_NAME <schema>"
    exit 1
fi


$(dirname "${BASH_SOURCE[0]}")/run-query.sh $1 <<EOF
select * from metadata
EOF




