/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to perform the UACR analysis for patients and update the values 
                    to the uacr_analysis table.
                    
Author:             Michael Greenberg, Vikram Anand
***************************************************************************************************/  

\timing on
\echo 'drop uacr_analysis'
drop table if exists uacr_analysis;
create table uacr_analysis(
  	entity_id bigint not null,
  	visit_id bigint null,
  	event_name text null,
  	event_dttm timestamp(0) null, 
  	component_id bigint null, 
  	event_code text null, 
  	event_code_vocabulary text null, 
  	event_value_string text null, 
  	event_value_numeric bigint null, 
  	event_unit text null,
	is_abnormal boolean null,
  	clean_value real null -- value to use.  null if there is no usable value.  otherwise a usable value gleaned from the event_value_numeric or event_value_string
	    -- normal = clean_value <= 30
	    -- immediate diagnosis = clean_value > 300
);

\echo 'create index on uacr_analysis(entity_id)'
create index on uacr_analysis(entity_id);
\echo 'create index on uacr_analysis(event_dttm)'
create index on uacr_analysis(event_dttm);
\echo 'create index on uacr_analysis(component_id)'
create index on uacr_analysis(component_id);

\echo 'insert into uacr_analysis'
insert into uacr_analysis(entity_id,visit_id,event_name,event_dttm,component_id,event_code,
			      event_code_vocabulary,event_value_string,event_value_numeric,event_unit,
                              clean_value)

select 
  entity_id, 
  visit_id,  -- might have multiple from same visit
  event_name, 
  event_dttm, 
  component_id, -- is (entity_id, visit_id, component_id) a PK ? possibly not
  event_code, 
  event_code_vocabulary, 
  event_value_string, 
  event_value_numeric, 
  event_unit, 
  
  case 
    when event_value_numeric is null then null --- there is no example of event_value_numeric null and event_value_string as non-NULL.  perhaps we should not even use this
    when event_value_numeric <= 10000 then event_value_numeric
    -- can be  '<6' or '<6 mg/g'  (and some others)
    when event_value_string similar to '[<>][0-9.]+( %)?' then   regexp_replace(event_value_string, '[^0-9.]', '', 'g')::numeric
    else null
  end clean_value

from 
  labs 
where 
--  event_code list was given by hmh
--  component_id from labs - loinc
  event_code in (
    '13705-9', '14585-4', '14958-3', '14959-1', 
    '30000-4', '32294-1', '44292-1', 
    '59159-4', '76401-9', '77253-3', 
    '77254-1', '89998-9', '9318-7'
  ) OR 
  component_id in (
    21050432, 800210000001127,800210000001096,5598,
    1910,123000005300,800123000005300,1557742,9864,
    235,800123000011570,11500,800123000122050,800123000039580,
    3974,800123000132431
  );

\echo 'update clean value'
update uacr_analysis
set is_abnormal = clean_value > 30 ; -- null if there is no clean value

\echo 'drop table if exists pat_uacr_ckd'
drop table if exists pat_uacr_ckd;

\echo 'create table pat_uacr_ckd'
create table pat_uacr_ckd(
  	entity_id bigint primary key,
  	ckd_last_normal_uacr_date timestamp(0) null,

  	ckd_uacr boolean null,

  	ckd_last_uacr_test_date timestamp(0) null,
  	ckd_last_uacr_value text null,
  	ckd_last_uacr_num_value real null,

  	ckd_first_abn_uacr_date timestamp(0) null,
  	ckd_first_abn_uacr_value text null,
  	ckd_first_abn_uacr_num_value bigint null,

  	ckd_last_abn_uacr_date timestamp(0) null, 

  	number_of_uacrs_post_last_normal bigint null
);

\echo 'create index on pat_uacr_ckd(ckd_uacr)'
create index on pat_uacr_ckd(ckd_uacr);



\echo 'insert into pat_uacr_ckd'
insert into pat_uacr_ckd(entity_id)
select entity_id
from 
  cohort;


\echo 'compute last uacr information'
with cte as (
  select
    distinct entity_id,
          -- with desc event_dttm, the first_value is the first abnormal egfr
         first_value(event_dttm) over win "first_date",
	 -- should these use 'clean value' instead ?  
	 first_value(event_value_string) over win "first_string_value",
	 first_value(event_value_numeric) over win "first_numeric_value"
  from
    uacr_analysis
  window win as (partition by entity_id
  	     	  -- sometimes, there are multiple visits on a day.  the uacr_analysis event_dttm does not seem enough. must see if we can get a better time
                   order by event_dttm desc, visit_id desc
                  )
)
update pat_uacr_ckd
set
	ckd_last_uacr_test_date = first_date,
	ckd_last_uacr_value = first_string_value,
	ckd_last_uacr_num_value = first_numeric_value
from
  cte
where
  pat_uacr_ckd.entity_id = cte.entity_id;



\echo 'compute last normal uacr information'
with cte as (
  select
    distinct entity_id,
          -- with desc event_dttm, the first_value is the first abnormal egfr
         first_value(event_dttm) over win "first_date",
	 first_value(event_value_string) over win "first_string_value",
	 first_value(event_value_numeric) over win "first_numeric_value"
  from
    uacr_analysis 
  where
    not is_abnormal --  nulls are ignored
  window win as (partition by entity_id
                   order by
		       -- sometimes, there are multiple visits on a day.  the uacr_analysis event_dttm does not seem enough. must see if we can get a better time
		       event_dttm desc,
		       visit_id desc 
                  )
)
update pat_uacr_ckd
set
  ckd_last_normal_uacr_date = first_date
from
  cte
where
  pat_uacr_ckd.entity_id = cte.entity_id;


\echo 'patients with > 300'
with cte as (
  select
    distinct entity_id,
          -- with ascending event_dttm, the first_value is the first abnormal uacr > 300
      	  first_value(event_dttm) over win "first_date",
	  first_value(event_value_string) over win "first_string_value",
	  first_value(event_value_numeric) over win "first_numeric_value"
  from
    uacr_analysis
  where
    is_abnormal and -- nulls are ignored
    clean_value > 300 and
    event_dttm > (select coalesce(ckd_last_normal_uacr_date, timestamp '1900-01-01 00:00:00') from pat_uacr_ckd  where pat_uacr_ckd.entity_id = uacr_analysis.entity_id)
    window win as (partition by entity_id
                   order by
		      event_dttm asc,
                      -- sometimes, there are multiple visits on a day.  the uacr_analysis event_dttm does not seem enough. must see if we can get a better time
    	       	      visit_id desc 
		      -- needed so that the count/last is correct
		      rows between unbounded preceding and unbounded following
                   )
)
update pat_uacr_ckd
set
  ckd_first_abn_uacr_date = cte.first_date,
  ckd_first_abn_uacr_value = cte.first_string_value,
  ckd_first_abn_uacr_num_value = cte.first_numeric_value,
  ckd_uacr = true
from
  cte
where
  pat_uacr_ckd.entity_id = cte.entity_id;

\echo 'uacr when no values > 300'
with cte as (
  select
    distinct entity_id,
          -- with ascending event_dttm, the first_value is the first abnormal egfr
      	    first_value(event_dttm) over win "first_date",
	    first_value(event_value_string) over win "first_string_value",
	    first_value(event_value_numeric) over win "first_numeric_value",
            last_value(event_dttm) over win "last_date",
	    last_value(event_value_string) over win "last_string_value",
	    last_value(event_value_numeric) over win "last_numeric_value",
	    count(entity_id) over win "count",
	    max(clean_value) over win "max_clean"
  from
    uacr_analysis
  where
    is_abnormal and 
    clean_value > 30 and -- not really needed
    event_dttm > (select coalesce(ckd_last_normal_uacr_date, timestamp '1900-01-01 00:00:00') from pat_uacr_ckd  where pat_uacr_ckd.entity_id = uacr_analysis.entity_id)
    window win as (partition by entity_id
                   order by
		      event_dttm asc,
                      -- sometimes, there are multiple visits on a day.  the uacr_analysis event_dttm does not seem enough. must see if we can get a better time
    	       	      visit_id desc 
		      -- needed so that the count/last is correct
		      rows between unbounded preceding and unbounded following
                   )
)
update pat_uacr_ckd
set
  ckd_first_abn_uacr_date = cte.first_date,
  ckd_first_abn_uacr_value = cte.first_string_value,
  ckd_first_abn_uacr_num_value = cte.first_numeric_value,

  ckd_last_abn_uacr_date = cte.last_date,
  number_of_uacrs_post_last_normal = cte.count,
  ckd_uacr = 
    case
      when DATE_PART('day', cte.last_date - cte.first_date) >= 90 then true
      else false
    end
from
  cte
where
  not coalesce(ckd_uacr, false) and
  pat_uacr_ckd.entity_id = cte.entity_id;


\if {debug}
-- all past last normal: 8,222 (was 8329)
-- only 300: 5,295
select
  (select count(*) from pat_uacr_ckd) "uacr patients",
  (select count(*) from pat_uacr_ckd where ckd_uacr) "uacr diagnosis" ;

drop table if exists uacr_interesting;
create temp table uacr_interesting
as
select entity_id
from
  pat_uacr_ckd
where
  coalesce(ckd_uacr, false) = false and
  entity_id in (select distinct entity_id from uacr_analysis where clean_value > 300)
limit 2 ;

select uacr_interesting.entity_id, event_dttm, event_value_string, event_value_numeric, clean_value
from
  uacr_interesting join uacr_analysis using(entity_id)
order by
  entity_id,
  event_dttm;
\endif
