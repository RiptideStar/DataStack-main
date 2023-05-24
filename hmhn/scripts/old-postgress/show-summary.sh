#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 1 ] ; then
    echo "Usage: $SCRIPT_NAME <schema>"
    exit 1
fi



$(dirname "${BASH_SOURCE[0]}")/run-query.sh $1 <<EOF
select label "Label", lpad(to_char(count, 'FM999,999,999'), 11) "Total", round(cast(percent as numeric), 1) "%"
from summary ;
EOF




