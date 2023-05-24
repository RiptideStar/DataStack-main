#!/bin/bash

set -euo pipefail

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ $# -ne 2 ] ; then
    echo "Usage: $SCRIPT_NAME <schema1> <schema2>"
    exit 1
fi


s1=$1
s2=$2

$(dirname "${BASH_SOURCE[0]}")/run-query.sh $1 <<EOF
SELECT schemaname,relname "Table",to_char(n_live_tup,'FM999,999,999,999') "Approx. Rows"
  FROM pg_stat_user_tables 
where 
  schemaname in ('$s1', '$s2')
  and relname = 'egfr_analysis'
ORDER BY n_live_tup DESC;


select count(*) "just in $s1"
from $s1.pat_all_flt_ckd s1 join $s2.pat_all_flt_ckd s2 using (entity_id)
where 
  s1.ckd_egfr and not s2.ckd_egfr;

select entity_id "just in $s1"
from $s1.pat_all_flt_ckd s1 join $s2.pat_all_flt_ckd s2 using (entity_id)
where 
  s1.ckd_egfr and not s2.ckd_egfr
order by entity_id
limit 10;



select count(*) "just in $s2"
from $s1.pat_all_flt_ckd s1 join $s2.pat_all_flt_ckd s2 using (entity_id)
where 
  not s1.ckd_egfr and s2.ckd_egfr;

select entity_id "just in $s2"
from $s1.pat_all_flt_ckd s1 join $s2.pat_all_flt_ckd s2 using (entity_id)
where 
  not s1.ckd_egfr and s2.ckd_egfr
order by entity_id
limit 10;


select count(*) "in $s1 and $s2"
from $s1.pat_all_flt_ckd s1 join $s2.pat_all_flt_ckd s2 using (entity_id)
where 
  s1.ckd_egfr and s2.ckd_egfr;


select * from $s1.egfr_analysis
where 
  entity_id in ('1422')
order by event_dttm
;



select * from $s2.egfr_analysis
where 
  entity_id in ('1422');
order by event_dttm
;

EOF




