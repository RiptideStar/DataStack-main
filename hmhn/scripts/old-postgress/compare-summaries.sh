#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 2 ] ; then
    echo "Usage: $SCRIPT_NAME <schema1> <schema2>"
    exit 1
fi


S1=$1
S2=$2

$(dirname "${BASH_SOURCE[0]}")/run-query.sh $1 <<EOF
select 
  s1.label "Label", 
  lpad(to_char(s1.count, 'FM999,999,999'), 11) "$S1 Total", 
  round(cast(s1.percent as numeric), 1) "%",
  lpad(to_char(s2.count, 'FM999,999,999'), 11) "$S2 Total", 
  round(cast(s2.percent as numeric), 1) "%",
  lpad(to_char(s2.count-s1.count, 'PLFM999,999,999'), 11) "Delta"
from 
  $S1.summary s1 left outer join $S2.summary s2 using(label)
EOF




