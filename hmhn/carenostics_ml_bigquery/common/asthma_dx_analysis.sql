declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

-- ICD-10CC Code Description
-- J45.2x mild intermittent
-- J45.3x mild persistent
-- J45.4x moderate persistent
-- J45.5x severe persistent
-- J45.90x unspecified
-- X=0 uncomplicated
-- X=1 with exacerbation
-- X=2 with status
-- J45.909 Unspecified asthma, uncomplicated
-- J45.990 Exercise induced bronchospasm
-- J45.991 Cough variant asthma
-- J45.998 Other asthma

create or replace 
function `$DATASET`.asthmaEventCode(event_code string) 
returns string
as
  -- can be more specific to only allow the 'known' codes if we want
  (regexp_extract(event_code, '\\b(J45[.][0-9]+)\\b'))
;

create or replace 
function `$DATASET`.computeAsthmaSeverity(idc10 string) 
returns int64
as
 (if(substr(idc10, 5, 1)='9',
     null,
    cast(regexp_extract(idc10, 'J45[.]([0-9])') as int64)))
 ;


create or replace 
function `$DATASET`.computeAsthmaComplication(idc10 string) 
returns int64
as 
 (if(idc10='J45.909',
   0, 
   cast(regexp_extract(idc10, 'J45[.](?:[2345]|90)([012])') as int64)))
 ;



create or replace table asthma_dx_codes(
    entity_id int not null,
    visit_id int,
    event_name string,
    event_dttm datetime, 
    event_code string, 
    event_code_vocabulary string, 
    event_type string,
    idc10_code string not null, -- the J45 code
    severity int, -- null for unknown idc
    complication int, -- null when there is no complication field
    is_abnormal boolean not null
) ;


insert into asthma_dx_codes(entity_id, visit_id, event_name, event_dttm, 
                            event_code, event_code_vocabulary, 
                            event_type, idc10_code, severity, complication, is_abnormal)
select
    entity_id,
    cast(visit_id as integer) as visit_id,
    event_name,
    event_dttm,
    event_code, 
    event_code_vocabulary, 
    event_type,
    $DATASET.asthmaEventCode(event_code),
    $DATASET.computeAsthmaSeverity($DATASET.asthmaEventCode(event_code)),    
    $DATASET.computeAsthmaComplication($DATASET.asthmaEventCode(event_code)),
    true
from conditions
where  
  `$DATASET`.asthmaEventCode(event_code) is not null
  ;



select utils.formatInt(count(entity_id)) `Number of asthma_dx_codes`
from asthma_dx_codes ;

select utils.formatInt(count(distinct entity_id)) `Number of patients with asthma_dx_codes`
from asthma_dx_codes ;


select utils.formatInt(count(entity_id)) `Number of abnormal ckd_dx_codes`
from asthma_dx_codes where is_abnormal;


select event_code, utils.formatInt(count(*))
from mlg_common.conditions
where event_code like 'J45.%'
group by event_code
order by event_code;




