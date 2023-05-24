create or replace table pat_egfr_ckd(
    entity_id int,
    
  ckd_last_normal_egfr_date datetime,
  ckd_last_normal_egfr_value float64,

   ckd_first_abn_egfr_date datetime,
  ckd_first_abn_egfr_value float64,

    ckd_last_abn_egfr_date datetime, 
    ckd_last_abn_egfr_value float64,

   ckd_last_egfr_date datetime,
    ckd_last_egfr_value float64,

    number_of_egfrs_post_last_normal int not null,
  ckd_egfr boolean not null, -- should we add NULL for when there is no egfr data ?
   ckd_egfr_diagnosis_date datetime
) ;


\time_as 'get the last normal egfr date and value for each patient to temp table'
create or replace table pat_last_normal_egfr_tmp as
select distinct 
  entity_id,
  first_value(event_dttm) over win `last_normal_date`,
  first_value(clean_value) over win `last_normal_value`
from
  egfr_analysis
where
  not is_abnormal
window win as (partition by entity_id
               order by event_dttm desc, visit_id desc) 
;


\time_as 'get the last egfr date and value for each patient to temp table'
create or replace table pat_last_egfr_tmp as
select distinct 
  entity_id,
  first_value(event_dttm) over win `last_egfr_date`,
  first_value(clean_value) over win `last_egfr_value`
from
    egfr_analysis
window win as (partition by entity_id
               order by event_dttm desc, visit_id desc
               ) ;




\time_as 'first and last abnormal egfr after the last normal egfr'
create or replace table pat_first_last_abnormal_egfr_tmp as
select distinct 
  entity_id,
  first_value(event_dttm) over win `first_abnormal_date`,
  first_value(clean_value) over win `first_abnormal_value`,
  last_value(event_dttm) over win `last_abnormal_date`,
  last_value(clean_value) over win `last_abnormal_value`,
  count(entity_id) over win `abnormal_count`,
from
  egfr_analysis
  left join pat_last_normal_egfr_tmp using(entity_id)
where
  is_abnormal  
  and event_dttm >  coalesce(last_normal_date, '1900-01-01 00:00:00')
window win as (partition by entity_id
               order by event_dttm asc, visit_id desc
               rows between unbounded preceding and unbounded following) ;


\time_as 'first egfr diagnosis date'
create or replace table pat_first_egfr_diagnosis_date_tmp as
select distinct 
  entity_id,
  first_value(event_dttm) over win `first_diagnosis_date`
from
  egfr_analysis
  inner join pat_first_last_abnormal_egfr_tmp using(entity_id)
where
  first_abnormal_date is not null and
  DATE_DIFF(event_dttm, first_abnormal_date, day) >= 90
window win as (partition by entity_id
               order by event_dttm asc, visit_id desc
               rows between unbounded preceding and unbounded following) ;



\time_as 'insert into pat_egfr_ckd'
insert into pat_egfr_ckd(entity_id, 
                         ckd_last_egfr_date, ckd_last_egfr_value, 
                         ckd_last_normal_egfr_date, ckd_last_normal_egfr_value,
                         ckd_first_abn_egfr_date, ckd_first_abn_egfr_value,
                         ckd_last_abn_egfr_date, ckd_last_abn_egfr_value,
                         number_of_egfrs_post_last_normal, ckd_egfr, ckd_egfr_diagnosis_date)
select 
  entity_id, 
  last_egfr_date, last_egfr_value, 
  last_normal_date, last_normal_value, 
  first_abnormal_date, first_abnormal_value,
  last_abnormal_date, last_abnormal_value,
  coalesce(abnormal_count, 0),
  case 
     when last_abnormal_date is not null and DATE_DIFF(last_abnormal_date, first_abnormal_date, day) >= 90 then true
     else false
  end,
  first_diagnosis_date
from 
  cohort 
  left join pat_last_egfr_tmp using(entity_id)
  left join pat_last_normal_egfr_tmp using(entity_id)
  left join pat_first_last_abnormal_egfr_tmp using(entity_id)
  left join pat_first_egfr_diagnosis_date_tmp using(entity_id)
;


select * from pat_egfr_ckd 
where ckd_egfr 
limit 10;


\intfmt ,
select count(entity_id) `Number with pat_egfr_ckd`
from pat_egfr_ckd
where ckd_egfr ;


-- can drop the temp tables once we know we don't need them for debugging


\skip on
select * from pat_egfr_ckd  where entity_id = 33210; 
select * from egfr_analysis where entity_id = 33210 order by event_dttm;
