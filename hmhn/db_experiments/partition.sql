set search_path = mlg_test;

drop table if exists egfr;

create table egfr (
  entity_id bigint not null,
  event_dttm timestamp(0) null,
  event_value_string text null,
  event_value_numeric bigint null,
  is_abnormal int not null
)  ;

insert into egfr(entity_id, event_dttm, event_value_string, event_value_numeric, is_abnormal)
select entity_id, event_dttm, event_value_string, event_value_numeric, is_abnormal
from s20230115_carenostics_ml_10000.new_egfr_analysis
where entity_id in (220, 556, 792, 893);


select
    distinct entity_id,
             -- with descending event_dttm, the first_value is the latest data
             first_value(event_dttm) over win "date",
	     first_value(event_value_string) over win "string_value",
	     first_value(event_value_numeric) over win "numeric_value"
  from
    egfr
  where
    is_abnormal = 0    
   WINDOW win as (PARTITION by entity_id
                  order by event_dttm desc) ;
		  


select
  distinct
    entity_id,
          -- with descending event_dttm, the first_value is the latest data
         first_value(event_dttm) over win "date",
	     first_value(event_value_string) over win "string_value",
	     first_value(event_value_numeric) over win "numeric_value",
         last_value(event_dttm) over win "last date",
         count(entity_id) over win "count"
         
  from
    egfr
  where
    is_abnormal = 0     
   WINDOW win as (PARTITION by entity_id
                  order by event_dttm desc
                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) ;
		 








set search_path = s20230115_carenostics_ml_1000000;

select
    distinct entity_id,
             -- with descending event_dttm, the first_value is the latest data
             first_value(event_dttm) over win "date",
	     first_value(event_value_string) over win "string_value",
	     first_value(event_value_numeric) over win "numeric_value"
  from
    new_egfr_analysis 
  where
    is_abnormal = 0    
   WINDOW win as (PARTITION by entity_id
                  order by event_dttm desc) ;
