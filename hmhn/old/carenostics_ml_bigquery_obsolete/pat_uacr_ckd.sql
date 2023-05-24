create or replace table pat_uacr_ckd(
    entity_id int not null,
    
    ckd_last_normal_uacr_date datetime,
    ckd_last_normal_uacr_value float64,

    ckd_first_abn_uacr_date datetime,
    ckd_first_abn_uacr_value float64,
    
    ckd_last_abn_uacr_value float64,
    ckd_last_abn_uacr_date datetime, 

    ckd_last_uacr_date datetime,
    ckd_last_uacr_value float64,

    number_of_uacrs_post_last_normal int,

    ckd_uacr boolean
);

----------------------------------------------------------------------------------------
-- be very careful with window function to use 'first_value'.  if you don't
-- you will also have to use 'rows between unbounded preceding and unbounded following'
----------------------------------------------------------------------------------------

\time_as 'get the last normal uacr date and value for each patient to temp table'
create or replace table pat_last_normal_uacr_tmp as
select distinct 
  entity_id,
  first_value(event_dttm) over win `last_normal_date`,
  first_value(clean_value) over win `last_normal_value`
from
  uacr_analysis
where
  not is_abnormal
window win as (partition by entity_id
                   order by event_dttm desc, visit_id desc) 
;


\time_as 'get the last uacr date and value for each patient to temp table'
create or replace table pat_last_uacr_tmp as
select distinct 
  entity_id,
  first_value(event_dttm) over win `last_uacr_date`,
  first_value(clean_value) over win `last_uacr_value`
from
    uacr_analysis
window win as (partition by entity_id
              -- sometimes, there are multiple visits on a day.  the uacr_analysis event_dttm does not seem enough. 
              -- must see if we can get a better time
               order by event_dttm desc, visit_id desc
               ) ;



-- for diagnosis ... either ... over 300  or  two samples of over 30 a month apart

\time_as 'get first uacr over 300 after the last normal uacr'
create or replace table pat_dx_over_300_tmp as
select distinct 
  entity_id,
  first_value(event_dttm) over win `first_abnormal_300_date`,
  first_value(clean_value) over win `first_abnormal_300_value`
from
  uacr_analysis
  left join pat_last_normal_uacr_tmp using(entity_id)
where
  is_abnormal  -- not really needed
  and clean_value > 300
  and event_dttm >  coalesce(last_normal_date, '1900-01-01 00:00:00')
window win as (partition by entity_id
               order by event_dttm asc, visit_id desc) 
;


\time_as 'first and last abnormal uacr after the last normal uacr'
create or replace table pat_first_last_abnormal_uacr_tmp as
select distinct 
  entity_id,
  first_value(event_dttm) over win `first_abnormal_30_date`,
  first_value(clean_value) over win `first_abnormal_30_value`,
  last_value(event_dttm) over win `last_abnormal_30_date`,
  last_value(clean_value) over win `last_abnormal_30_value`,
  count(entity_id) over win `abnormal_30_count`,
from
  uacr_analysis
  left join pat_last_normal_uacr_tmp using(entity_id)
where
  is_abnormal  
  and event_dttm >  coalesce(last_normal_date, '1900-01-01 00:00:00')
window win as (partition by entity_id
               order by event_dttm asc, visit_id desc
               rows between unbounded preceding and unbounded following) ;

\time_as 'insert into pat_uacr_ckd'
insert into pat_uacr_ckd(entity_id, 
                         ckd_last_uacr_date, ckd_last_uacr_value, 
                         ckd_last_normal_uacr_date, ckd_last_normal_uacr_value,
                         ckd_first_abn_uacr_date, ckd_first_abn_uacr_value,
                         ckd_last_abn_uacr_date, ckd_last_abn_uacr_value,
                         number_of_uacrs_post_last_normal, ckd_uacr)
select 
  entity_id, 
  last_uacr_date, last_uacr_value, 
  last_normal_date, last_normal_value, 
  first_abnormal_30_date, first_abnormal_30_value,
  last_abnormal_30_date, last_abnormal_30_value,
  abnormal_30_count,
  case 
     when first_abnormal_300_date is not null then true
     when last_abnormal_30_date is not null and DATE_DIFF(last_abnormal_30_date, first_abnormal_30_date, day) >= 90 then true
     else false
  end
from 
  cohort 
  left join pat_last_uacr_tmp using(entity_id)
  left join pat_last_normal_uacr_tmp using(entity_id)
  left join pat_first_last_abnormal_uacr_tmp using(entity_id)
  left join pat_dx_over_300_tmp using(entity_id)
;

\intfmt ,
select count(entity_id) `Number with ckd_uacr`
from pat_uacr_ckd
where ckd_uacr ;

-- can drop the temp tables once we know we don't need them for debugging

