declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

create or replace 
function `$DATASET`.computeCleanEgfr(event_value_numeric float64, event_value_string string) returns float64
as 
  (
    case
     when 0 <= event_value_numeric and event_value_numeric < 10000 then event_value_numeric
     when event_value_string like '<%' then 59
     when event_value_string like '>%' then 9999
     else null -- not usable value
  end 
 ) ;

create or replace table egfr_analysis(
      entity_id int not null,
      visit_id int,
      event_dttm datetime, 
      event_code string, 
      event_code_vocabulary string, 
      event_unit string, 
      clean_value float64 not null,
      is_abnormal boolean not null,
      component_id int, -- this and the following should only be used for debugging
      base_name string, -- the clarity_component.base_name
      event_name string -- the clarity_component.common_name
) ;


insert into egfr_analysis(entity_id, visit_id, event_name, event_dttm, component_id, event_code, event_code_vocabulary,
                          event_unit,
                          clean_value, base_name, is_abnormal)

select distinct
    first_value(entity_id) over `win`,
    first_value(visit_id) over `win`,
    first_value(event_name) over `win`,
    first_value(event_dttm) over `win`,
    first_value(component_id) over `win`,
    first_value(event_code) over `win`,
    first_value(event_code_vocabulary) over `win`,
    first_value(event_unit) over `win`,
    `$DATASET`.computeCleanEgfr(first_value(event_value_numeric) over `win`, first_value(event_value_string) over `win`),
    first_value(base_name) over `win`,
    `$DATASET`.computeCleanEgfr(first_value(event_value_numeric) over `win`, first_value(event_value_string) over `win`) < 60
from
    labs
where
  base_name in ('EGFR','EGFRAA','EGFRNAA') and
  `$DATASET`.computeCleanEgfr(event_value_numeric, event_value_string) is not null
window win as (partition by entity_id, event_dttm
                 order by `$DATASET`.computeCleanEgfr(event_value_numeric, event_value_string)) ;


select utils.formatInt(count(entity_id)) `egfr_analysis size`
from egfr_analysis ;


if DEBUG
then
  select * from egfr_analysis
  order by entity_id 
  limit 100 ;
end if ;

