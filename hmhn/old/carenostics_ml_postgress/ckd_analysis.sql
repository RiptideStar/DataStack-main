/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to perform the CKD analysis and update the values to the
                    pat_dx_ckd table.
                    
Author:             Michael Greenberg, Vikram Anand
***************************************************************************************************/  


--------------ckd_dx_codes table--------------
drop 
	table if exists ckd_dx_codes;
create table ckd_dx_codes(
  	entity_id bigint not null,
  	visit_id bigint null,
  	event_name text null,
  	event_dttm timestamp(0) null, 
  	event_code text null, 
  	event_code_vocabulary text null, 
  	event_type text null,
  	n18 text null,
  	stage real null,
  	is_abnormal integer null,
  	ckd_dx integer null -- true, false, null,   0, 1, -1 (unknown)
);

create index on ckd_dx_codes(entity_id);
create index on ckd_dx_codes(visit_id);
create index on ckd_dx_codes(event_dttm);
create index on ckd_dx_codes(event_code);	
--------------ckd_dx_codes table--------------


--------------pat_dx_ckd table--------------
drop 
	table if exists pat_dx_ckd;
create table pat_dx_ckd(
  	entity_id bigint primary key,
  	ckd_dx integer null,  -- does the patient have a ckd diagnosis.  non-nullable boolean
  	ckd_first_dx_3_plus_date timestamp(0) null, -- max diagnosis from the from the first stage 3+ diagnosis encounter
  	ckd_first_dx_3_plus_code text null,
  	ckd_first_dx_3_plus_stage real null,
  	last_dx_date timestamp(0) null, -- last date there was a ckd diagnosis
  	last_dx_stage real null -- max stage.  should be renamed.  
);
--------------pat_dx_ckd table--------------
create index on pat_dx_ckd(ckd_dx) ;


--truncate ckd_dx_codes;

\echo 'insert into ckd_dx_codes'
insert into ckd_dx_codes (entity_id, visit_id, event_name, event_dttm, event_code, event_code_vocabulary, event_type, n18, stage, is_abnormal)
select
    entity_id,
    visit_id ,
    event_name ,
    event_dttm , 
    event_code , 
    event_code_vocabulary , 
    event_type ,
    (regexp_match(event_code, '\mN18.\d+\M'))[1]  n18,  -- \m = word start, \M = word end. The event_code are a comma separated list of codes

    case 
      -- this is a complete list of the codes we currently have
      when event_code ~ '\mN18.1\M' then 1
      when event_code ~ '\mN18.2\M' then 2
      when event_code ~ '\mN18.3\M' then 3 -- will not match 18.30.  3 (unspecified)
      when event_code ~ '\mN18.30\M' then 3 -- unspecified 3
      when event_code ~ '\mN18.31\M' then 3 -- 3a
      when event_code ~ '\mN18.32\M' then 3.5  -- stage 3b
      when event_code ~ '\mN18.4\M' then 4 -- do we want to match all N18.4 ?
      when event_code ~ '\mN18.5\M' then 5
      when event_code ~ '\mN18.6\M' then 5
      when event_code ~ '\mN18.9\M' then 3 -- unknown stage
      else null  -- should not happen
    end stage,

    case 
      when event_code ~ '\mN18.1\M' then 0
      when event_code ~ '\mN18.2\M' then 0
      when event_code ~ '\mN18.3\M' then 1
      when event_code ~ '\mN18.30\M' then 1
      when event_code ~ '\mN18.31\M' then 1
      when event_code ~ '\mN18.32\M' then 1
      when event_code ~ '\mN18.4\M' then 1
      when event_code ~ '\mN18.5\M' then 1
      when event_code ~ '\mN18.6\M' then 1
      when event_code ~ '\mN18.9\M' then 1
      else null -- should not happen
    end is_abnormal
from conditions  
where strpos(event_code, 'N18.') > 0;


-- patient summary analysis


-- probably give 'false' for ckd_dx
\echo 'init pat_dx_ckd'
insert into pat_dx_ckd(entity_id)
select entity_id
from 
  cohort;


\echo 'first pat_dx_ckd dx_3+'
with cte as (
  select
    distinct entity_id,
             first_value(event_dttm) over win "first_date",
	     first_value(stage) over win "first_stage",
	     first_value(n18) over win "first_event_code"
  from
    ckd_dx_codes 
  where
    is_abnormal = 1
  window win as (partition by entity_id
                   order by event_dttm asc, stage desc
		   rows between unbounded preceding and unbounded following
		 )
)
update
   pat_dx_ckd
set
  ckd_first_dx_3_plus_date = first_date,
  ckd_first_dx_3_plus_stage = first_stage,
  ckd_first_dx_3_plus_code = first_event_code,
  ckd_dx = 1
from cte
where
  pat_dx_ckd.entity_id = cte.entity_id;
 
\echo 'last visit with ckd diagnosis'
with cte as (
  select
    distinct entity_id,
             first_value(event_dttm) over win "first_date"
  from
    ckd_dx_codes 
  window win as (partition by entity_id
                 order by event_dttm desc
		 )
)
update
   pat_dx_ckd
set
  last_dx_date = first_date
from cte
where
  pat_dx_ckd.entity_id = cte.entity_id;
 
\echo 'max ckd stage' -- which might not be the last visit
with cte as (
  select
    distinct entity_id,
	     first_value(stage) over win "first_stage"
  from
    ckd_dx_codes 
  where
    is_abnormal = 1
  window win as (partition by entity_id
                 order by stage desc
		 )
)
update
   pat_dx_ckd
set
  last_dx_stage = first_stage
from cte
where
  pat_dx_ckd.entity_id = cte.entity_id; -- add date
 
\if {debug}
select entity_id, visit_id, event_dttm, event_code, event_type, n18, stage, is_abnormal, ckd_dx
from ckd_dx_codes 
where entity_id =  1930
order by entity_id, event_dttm,  visit_id;

\echo 'events for a patient'
select * from pat_dx_ckd where entity_id = /*100*/ 1930;

with xx
as
  (select distinct(  (regexp_match(event_code, '\mN18.\d+\M'))[1]  ) "event_code"
  from conditions where strpos(event_code, 'N18') > 0)
select * from xx order by  event_code



\endif
 
\if false
select * 
from
  mlg_window_100000.pat_dx_ckd aa left outer join
  mlg.pat_dx_ckd bb on (aa.entity_id = bb.entity_id)
where
  bb.entity_id is null or
  aa.ckd_dx <> bb.ckd_dx or
  aa.ckd_first_dx_3_plus_date <> bb.ckd_first_dx_3_plus_date or
  aa.ckd_first_dx_3_plus_code <> bb.ckd_first_dx_3_plus_code or 
  aa.ckd_first_dx_3_plus_stage <> bb.ckd_first_dx_3_plus_stage or 
  aa.last_dx_date <> bb.last_dx_date or 
  aa.last_dx_stage <> bb.last_dx_stage
limit 100 ;


\endif
