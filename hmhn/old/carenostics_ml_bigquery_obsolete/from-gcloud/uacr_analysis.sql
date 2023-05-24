truncate table  `hmh-carenostics-dev.ckd_table.uacr_analysis`;

insert into `hmh-carenostics-dev.ckd_table.uacr_analysis`
(entity_id,visit_id,event_name,event_dttm,component_id,event_code,
event_code_vocabulary,event_value_string,event_value_numeric,event_unit,is_valid,usable,clean_value,is_abnormal)


select 
  entity_id, 
  cast(visit_id as integer) as visit_id,  
  event_name, 
  cast(event_dttm as timestamp) as event_dttm,
  cast(component_id as integer) as component_id,
  event_code, 
  event_code_vocabulary, 
  event_value_string, 
  cast(event_value_numeric as integer) as event_value_numeric,
  event_unit, 
  case  -- unused
    when event_value_numeric is null then 0
    when event_value_numeric > 9999.0 then 9
    else 1  end 
    as is_valid,
  
  case -- unused
    when event_value_numeric is null then 10
    when event_value_numeric < 10000 then 1
    when event_value_string like '>%' or event_value_string like '<%' then 1
    else 0 end 
    as usable,
  
  case -- unused
    when event_value_numeric is null then null
    when event_value_numeric <= 10000 then event_value_numeric
    -- can be  '<6' or '<6 mg/g'  (and some others)
    when  RegexP_CONTAINS(event_value_string,'[<>][0-9.]+( %)?')  = true 
   then cast(REGEXP_REPLACE(event_value_string,'[^0-9.]', '') as float64)

    else null end
    as clean_value,
    case 
    when event_value_numeric <= 30 then 0
    when event_value_numeric < 10000 then 1
    -- can be  '<6' or '<6 mg/g'  (and some others)
    -- valid is mg/g
    when  RegexP_CONTAINS(event_value_string,'[<>][0-9.]+( %)?') = true
    then 
       case
         when 
      cast(REGEXP_REPLACE(event_value_string,'[^0-9.]', '') as numeric) <= 30 then 0
         else 1
       end	 
    else null
  end is_abnormal
  from `hmh-carenostics-dev.ckd_table.labs` 
where 
 
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
