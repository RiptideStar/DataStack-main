set @@dataset_id = '$DATASET' ;
create or replace 
function `$DATASET`.computeCleanUacr(event_value_numeric float64, event_value_string string) returns float64
as 
  (
  case
    when event_value_numeric is null then null ---there is no example of event_value_numeric null and event_value_string as non-NULL.  perhaps we should not even use this
    when event_value_numeric <= 10000 then event_value_numeric -- can be  '<6' or '<6 mg/g'  (and some others)
    when regexp_contains(event_value_string, '[<>][0-9.]+( %)?')
         then cast(regexp_replace(event_value_string,"[^0-9.]", "") as float64)
    else null
  end )
;

create or replace table uacr_analysis(
    entity_id int not null,
    visit_id int,
    event_name string,
    event_dttm datetime, 
    component_id int, 
    event_code string, 
    event_code_vocabulary string, 
    event_value_string string, 
    event_value_numeric float64, 
    event_unit string,
    is_abnormal boolean, -- null if no clean_value
    clean_value float64 -- value to use.  null if there is no usable value.  otherwise a usable value gleaned from the event_value_numeric or event_value_string
      -- normal = clean_value <= 30
      -- immediate diagnosis = clean_value > 300
);


insert into uacr_analysis(entity_id,visit_id,event_name,event_dttm,component_id,event_code,
                          event_code_vocabulary,event_value_string,event_value_numeric,event_unit,
                          clean_value, is_abnormal)

select 
  entity_id, 
  visit_id, 
  -- might have multiple from same visit
  event_name, 
  event_dttm, 
  component_id, 
  -- is (entity_id, visit_id, component_id) a PK ? possibly not
  event_code, 
  event_code_vocabulary, 
  event_value_string, 
  event_value_numeric, 
  event_unit, 
  `$DATASET`.computeCleanUacr(event_value_numeric, event_value_string),
  `$DATASET`.computeCleanUacr(event_value_numeric, event_value_string) > 30
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
    3974, 800123000132431
  );


select utils.formatInt(count(entity_id)) `uacr_analysis size`
from uacr_analysis ;

