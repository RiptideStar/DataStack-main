declare exclude_n18_9 boolean default $PAT_DX_CKD_EXCLUDE_N_CODES;
declare only_problem_or_dx boolean default $PAT_DX_CKD_ONLY_PROBLEM_OR_DX;
declare until datetime default(if("$UNTIL_DATE"="", current_datetime, parse_datetime("%F", "$UNTIL_DATE"))) ;
set @@dataset_id = '$DATASET' ;

create 
or replace table pat_dx_ckd(
  entity_id int not null, 
  ckd_dx boolean not null, 
  -- does the patient have a ckd diagnosis.  non-nullable boolean
  ckd_first_dx_3_plus_date datetime, 
  -- max diagnosis from the from the first stage 3+ diagnosis encounter
  ckd_first_dx_3_plus_code string, 
  ckd_first_dx_3_plus_stage float64, 
  last_dx_date datetime, 
  -- last date there was a ckd diagnosis
  last_dx_code string, 
  last_dx_stage float64, 
  max_dx_stage_date datetime, 
  max_dx_stage_code string, 
  max_dx_stage float64 -- max stage.  should be renamed.  
  );


--create or replace table pat_dx_ckd_first_last_tmp as
create temp table pat_dx_ckd_first_last_tmp as 
select distinct
    first_value(entity_id) over win `entity_id`,

    first_value(event_dttm) over win `first_dx_date`,
    first_value(n18) over win `first_dx_n18`,
    first_value(stage) over win `first_dx_stage`,

    last_value(event_dttm) over win `last_dx_date`,
    last_value(n18) over win `last_dx_n18`,
    last_value(stage) over win `last_dx_stage`,
from
    $ML.ckd_dx_codes
where
  is_abnormal
  and (not exclude_n18_9 or n18 <> 'N18.9')
  and (not only_problem_or_dx or event_type in ('problem_list', 'medical_hx'))
  and event_dttm <= until
window win as (partition by entity_id
               order by entity_id, event_dttm
               rows between unbounded preceding and unbounded following) ;



--create or replace table pat_dx_ckd_max_tmp as 
create temp table pat_dx_ckd_max_tmp as 
select distinct
    first_value(entity_id) over win `entity_id`,

    first_value(event_dttm) over win `max_dx_date`,
    first_value(n18) over win `max_dx_n18`,
    first_value(stage) over win `max_dx_stage`,

from
    $ML.ckd_dx_codes
where
  is_abnormal
  and (not exclude_n18_9 or n18 <> 'N18.9')
  and (not only_problem_or_dx or event_type in ('problem_list', 'medical_hx'))
  and event_dttm <= until
window win as (partition by entity_id
               order by entity_id, stage desc
               ) ;



insert into pat_dx_ckd(entity_id,ckd_dx,
                        ckd_first_dx_3_plus_date,ckd_first_dx_3_plus_code,ckd_first_dx_3_plus_stage,
                        last_dx_date,last_dx_code,last_dx_stage,
                        max_dx_stage_date,max_dx_stage_code,max_dx_stage)
select 
  entity_id, 
  max_dx_stage is not null,
  first_dx_date,
  first_dx_n18,
  first_dx_stage,
  last_dx_date,
  last_dx_n18,
  last_dx_stage,
  max_dx_date,
  max_dx_n18,
  max_dx_stage
from 
  $ML.cohort 
  left join pat_dx_ckd_first_last_tmp using(entity_id)
  left join pat_dx_ckd_max_tmp using(entity_id)
;



select 
  (select utils.formatInt(count(*)) from pat_dx_ckd) `pat_dx_ckd table size`,
  (select utils.formatInt(count(*)) from pat_dx_ckd where  ckd_dx) `with ckd` ;

