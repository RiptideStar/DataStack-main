/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to perform the EGFR analysis and update the values to the
                    efgr_analysis table.
                    
Author:             Michael Greenberg
***************************************************************************************************/  

\timing on

--------------egfr_analysis table--------------

-- use SQL functions to be able to inline
drop function if exists computeCleanEgfr;
create function
computeCleanEgfr(event_value_numeric bigint, event_value_string text) returns real
as $$
  select
  case
     when 0 <= event_value_numeric and event_value_numeric < 10000 then event_value_numeric
     when event_value_string like '<%' then 59
     when event_value_string like '>%' then 9999
     else null -- not usable value
  end 
$$
language SQL;



drop table if exists egfr_analysis;

\echo 'create table egfr_analysis'
create table egfr_analysis(
  	entity_id bigint not null,
  	visit_id bigint null,
  	event_dttm timestamp(0) null, 
  	component_id bigint null, 
  	event_code text null, 
  	event_code_vocabulary text null, 
  	event_unit text null, 
  	clean_value real not null,
  	is_abnormal boolean not null,
	base_name text null, -- the clarity_component.base_name
  	event_name text null -- the clarity_component.common_name

) ;

\echo 'create index on egfr_analysis(entity_id)'
create index on egfr_analysis(entity_id);
\echo 'create index on egfr_analysis(event_dttm)'
create index on egfr_analysis(event_dttm);
\echo 'create index on egfr_analysis(component_id)'
create index on egfr_analysis(component_id);


\echo 'drop table if exists pat_egfr_ckd'
drop table if exists pat_egfr_ckd;
\echo 'create table pat_egfr_ckd'
create table pat_egfr_ckd(
  	entity_id bigint primary key,
  	ckd_last_normal_egfr_date timestamp(0) null,
	
 	ckd_first_abn_egfr_date timestamp(0) null,
	ckd_first_abn_egfr_value real null,

  	ckd_last_abn_egfr_date timestamp(0) null, 
  	ckd_last_abn_egfr_value real null,


 	ckd_last_egfr_date timestamp(0) null,
  	ckd_last_egfr_value real null,

  	number_of_egfrs_post_last_normal bigint not null,
	ckd_egfr boolean not null, -- should we add NULL for when there is no egfr data ?
 	ckd_egfr_diagnosis_date timestamp(0) null
) ;

\echo 'create index on pat_egfr_ckd(ckd_last_normal_egfr_date)'
create index on pat_egfr_ckd(ckd_last_normal_egfr_date);
\echo 'create index on pat_egfr_ckd(ckd_egfr)'
create index on pat_egfr_ckd(ckd_egfr);



--------------egfr_analysis table--------------

-- 9,010,377 - ml_integration
-- 17,426,520 - ml_next


\echo 'insert into egfr_analysis'
insert into egfr_analysis(entity_id, visit_id, event_name, event_dttm, component_id, event_code, event_code_vocabulary,
                          event_unit,
                          clean_value, base_name, is_abnormal)

select distinct
    first_value(entity_id) over "win",
    first_value(visit_id) over "win",
    first_value(event_name) over "win",
    first_value(event_dttm) over "win",
    first_value(component_id) over "win",
    first_value(event_code) over "win",
    first_value(event_code_vocabulary) over "win",
    first_value(event_unit) over "win",
    computeCleanEgfr(first_value(event_value_numeric) over "win", first_value(event_value_string) over "win"),
    first_value(base_name) over "win",
    computeCleanEgfr(first_value(event_value_numeric) over "win", first_value(event_value_string) over "win") < 60
from
    labs
where
  base_name in ('EGFR','EGFRAA','EGFRNAA') and
  computeCleanEgfr(event_value_numeric, event_value_string) is not null
window win as (partition by entity_id, event_dttm
                 order by computeCleanEgfr(event_value_numeric, event_value_string)) ;



 -- misses 21081132 "EGFR NON-AFR. AMERICAN (QUEST)" which has a null bae_name

/*
'EGFR'
'EGFRAA'
'EGFRAAEX'
'EGFRELISAEX'
'EGFRMUTATION'
'EGFRNAA'
'EGFRNAAEX'
'EGFRNAAQD'
'EGFRNONAFAMN'
'QEGFRAFRAMER'
*/


-- current component list refers to these base_names:  "EGFRNAAQD" "EGFR" "EGFRNAA" "GFRALLOTHERS" "EGFRNAAEX"




--------------pat_egfr_ckd table--------------


\echo 'Initialize pat_egfr_ckd'
insert into pat_egfr_ckd(entity_id, ckd_egfr, number_of_egfrs_post_last_normal)
select entity_id, false, 0
from 
  cohort;

\echo 'Get last normal egfr'
-- can be group by, but this way we can do more stuff ... at we parallel the abnormal
with cte as (
  select
    distinct entity_id,
             -- with descending event_dttm, the first_value is the last normal egfr
             first_value(event_dttm) over win "date",
	     first_value(clean_value) over win "clean_value"
  from
    egfr_analysis 
  where
    not is_abnormal -- nulls ignored
    window win as (partition by entity_id
                   order by event_dttm desc)
)
update pat_egfr_ckd
set
  ckd_last_normal_egfr_date = cte.date
from
  cte
where
  pat_egfr_ckd.entity_id = cte.entity_id;

  
\echo 'Get last egfr'
-- can be group by, but this way we can do more stuff ... at we parallel the abnormal
with cte as (
  select
    distinct entity_id,
             -- with descending event_dttm, the first_value is the last normal egfr
             first_value(event_dttm) over win "date",
	     first_value(clean_value) over win "clean_value"
  from
    egfr_analysis 
  window win as (partition by entity_id
                   order by event_dttm desc)
)
update pat_egfr_ckd
set
  ckd_last_egfr_date = cte.date,
  ckd_last_egfr_value = cte.clean_value
from
  cte
where
  pat_egfr_ckd.entity_id = cte.entity_id;


\echo 'Get first/last abnormal egfr and count'
with cte as (
  select
    distinct entity_id,
          -- with ascending event_dttm, the first_value is the first abnormal egfr
         first_value(event_dttm) over win "first_date",
	 first_value(clean_value) over win "first_clean_value",
         last_value(event_dttm) over win "last_date",
	 last_value(clean_value) over win "last_clean_value",
	 count(entity_id) over win "count"
  from
    egfr_analysis 
  where
    event_dttm > (select coalesce(ckd_last_normal_egfr_date, timestamp '1900-01-01 00:00:00') from pat_egfr_ckd where pat_egfr_ckd.entity_id = egfr_analysis.entity_id) and
    is_abnormal
    window win as (partition by entity_id
                   order by event_dttm asc
		   -- needed so that the count is correct
		   rows between unbounded preceding and unbounded following
                  )
)
update pat_egfr_ckd
set
  ckd_first_abn_egfr_date = cte.first_date,
  ckd_first_abn_egfr_value = cte.first_clean_value,
  ckd_last_abn_egfr_date = cte.last_date,
  ckd_last_abn_egfr_value = cte.last_clean_value,
  number_of_egfrs_post_last_normal = cte.count,
  ckd_egfr = case
                when cte.count > 1 and DATE_PART('day', cte.last_date - cte.first_date) >= 90 then true
		else false
	     end	
from
  cte
where
  pat_egfr_ckd.entity_id = cte.entity_id;


\echo 'Get ckd diagnosis date'
with cte as (
  select distinct
    entity_id,
    first_value(event_dttm) over win "first_date"
  from
    egfr_analysis inner join pat_egfr_ckd using(entity_id)
  where
    ckd_egfr and 
    DATE_PART('day', event_dttm - ckd_first_abn_egfr_date) >= 90
  window win as (partition by entity_id 
                 order by event_dttm asc)
)
update pat_egfr_ckd
set
  ckd_egfr_diagnosis_date = first_date
from
  cte
where
  pat_egfr_ckd.entity_id = cte.entity_id;


\if {debug}
-- collect some interesting patients
create temp table egfr_interesting
as
(
  (select entity_id from pat_egfr_ckd where ckd_egfr and ckd_last_normal_egfr_date is null and ckd_egfr_diagnosis_date = ckd_last_abn_egfr_date  order by entity_id limit 1)
    union
  (select entity_id from pat_egfr_ckd where ckd_egfr and ckd_last_normal_egfr_date is null and ckd_egfr_diagnosis_date <> ckd_last_abn_egfr_date  order by entity_id limit 1) 
    union
  (select entity_id from pat_egfr_ckd where ckd_egfr and ckd_last_normal_egfr_date is not null and ckd_egfr_diagnosis_date = ckd_last_abn_egfr_date  order by entity_id limit 1) 
    union
  (select entity_id from pat_egfr_ckd where ckd_egfr and ckd_last_normal_egfr_date is not null and ckd_egfr_diagnosis_date <> ckd_last_abn_egfr_date  order by entity_id limit 1)
   union
   (select entity_id from pat_egfr_ckd where coalesce(ckd_egfr, 0) = 0 and ckd_last_normal_egfr_date is not null  order by entity_id limit 1)
 )   ;


select entity_id, event_dttm, event_value_numeric, event_value_string, is_abnormal
from egfr_analysis
where
 entity_id in (select * from egfr_interesting)
order by
  entity_id, event_dttm;
  
  select entity_id, ckd_last_normal_egfr_date, ckd_first_abn_egfr_date, ckd_egfr_diagnosis_date, ckd_last_abn_egfr_date 
from pat_egfr_ckd
where
 entity_id in (select * from egfr_interesting)
 order by
  entity_id;

\endif
