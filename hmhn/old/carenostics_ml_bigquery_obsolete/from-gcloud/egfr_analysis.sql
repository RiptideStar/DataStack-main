truncate table `hmh-carenostics-dev.ckd_table.egfr_analysis`;

insert into `hmh-carenostics-dev.ckd_table.egfr_analysis`
(entity_id, visit_id, event_name, event_dttm, component_id, event_code, event_code_vocabulary,
                          event_unit,clean_value, base_name, is_abnormal)  
select distinct
    first_value(entity_id) over win entity_id,
    first_value(cast(visit_id as Integer)) over win visit_id,
    first_value(event_name) over win event_name,
    first_value(cast(event_dttm as Timestamp)) over win event_dttm,
    first_value(cast(component_id as Integer)) over win component_id,
    first_value(event_code) over win event_code,
    first_value(event_code_vocabulary) over win event_code_vocabulary,
    first_value(event_unit) over win event_unit,
     `hmh-carenostics-dev.ckd_function.computeCleanEgfr`(first_value(cast(event_value_numeric as Integer)) over win,
                    first_value(event_value_string) over win) clean_value,
    first_value(base_name) over win  base_name,    
     `hmh-carenostics-dev.ckd_function.computeCleanEgfr`(first_value(cast(event_value_numeric as Integer)) over win,
                   first_value(event_value_string) over win)  < 60 is_abnormal
from
    `hmh-carenostics-dev.ckd_table.labs`
where
  base_name in ('EGFR','EGFRAA','EGFRNAA') and
  `hmh-carenostics-dev.ckd_function.computeCleanEgfr`(cast(event_value_numeric as Integer), event_value_string) is not null
window win as (partition by entity_id, event_dttm
                 order by `hmh-carenostics-dev.ckd_function.computeCleanEgfr`(cast(event_value_numeric as Integer), event_value_string)) ;
