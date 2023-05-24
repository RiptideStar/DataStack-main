truncate table `hmh-carenostics-dev.ckd_table.ckd_dx_codes`;

insert into  `hmh-carenostics-dev.ckd_table.ckd_dx_codes` (entity_id, visit_id, event_name, event_dttm, event_code, event_code_vocabulary, event_type, n18, stage, is_abnormal)
select
    entity_id,
    cast(visit_id as integer) as visit_id,
    event_name ,
    cast(event_dttm as timestamp) as event_dttm,
    event_code , 
    event_code_vocabulary , 
    event_type ,
    case when event_code like '%N18%,%' then 
    replace(substring(event_code,STRPOS(event_code, 'N18'),STRPOS(event_code,',') ),',','')
      when event_code like '%N18%' then 
       substring(event_code,STRPOS(event_code, 'N18'))
    end,
    case 
      when event_code like '%N18.1%' then 1
      when event_code like '%N18.2%' then 2
      when event_code like '%N18.3%' then 3 
      when event_code like '%N18.30%' then 3
      when event_code like '%N18.31%' then 3 
      when event_code like '%N18.32%' then 3.5  
      when event_code like '%N18.4%' then 4 
      when event_code like '%N18.5%' then 5
      when event_code like '%N18.6%' then 5
      when event_code like '%N18.9%' then 3 
      else null
    end stage,

    case 
      when event_code like '%N18.1%' then 0
      when event_code like '%N18.2%' then 0
      when event_code like '%N18.3%' then 1
      when event_code like '%N18.30%' then 1
      when event_code like '%N18.31%' then 1
      when event_code like '%N18.32%' then 1
      when event_code like '%N18.4%' then 1
      when event_code like '%N18.5%' then 1
      when event_code like '%N18.6%' then 1
      when event_code like '%N18.9%' then 1
      else null
    end is_abnormal
from `hmh-carenostics-dev.ckd_table.conditions`
where strpos(event_code, 'N18.') > 0;

