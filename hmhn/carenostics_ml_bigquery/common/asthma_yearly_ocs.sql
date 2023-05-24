declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

create or replace 
function `$DATASET`.asthmaEventCodeOcs(event_code string) 
returns string
as
  -- can be more specific to only allow the 'known' codes if we want
  (regexp_extract(event_code, '\\b(J45[.][0-9]+)\\b'))
;


create or replace table asthma_ocs_dx_codes(
    entity_id int not null,
    visit_id int,
    event_name string,
    event_dttm datetime, 
    -- event_code string, -- we have the idc10_code
    event_code_vocabulary string, 
    event_type string,
    idc10_code string not null
) ;


insert into asthma_ocs_dx_codes(entity_id, visit_id, event_name, event_dttm, 
                            -- event_code,
			    event_code_vocabulary, 
                            event_type, idc10_code)
select
    entity_id,
    cast(visit_id as integer) as visit_id,
    event_name,
    event_dttm,
    -- event_code, 
    event_code_vocabulary, 
    event_type,
    $DATASET.asthmaEventCodeOcs(event_code)
from conditions
where  
  `$DATASET`.asthmaEventCodeOcs(event_code) is not null
  and event_type in ('ed_dx', 'har_dx', 'pat_enc_dx')
  ;



create or replace table asthma_ocs_meds_spans(
  entity_id int not null, 
  start_time datetime not null, 
  end_time datetime not null,
  number_meds int not null,
  duration_days int not null
) ;


insert into asthma_ocs_meds_spans(entity_id, start_time, end_time, number_meds, duration_days)
WITH
cte1 AS (
    SELECT entity_id, start_time the_date, 1 weight
    FROM asthma_meds
    where drug_class = 'OCS'
    UNION ALL
    SELECT entity_id, timestamp_add(effective_end_time, interval 30 day), -1
    FROM asthma_meds
    where drug_class = 'OCS'
),
cte2 AS (
    SELECT entity_id, 
           the_date, 
           SUM(weight) OVER (PARTITION BY entity_id 
                             ORDER BY the_date, weight DESC) weight
    FROM cte1
),
cte3 AS (
    SELECT entity_id, 
           the_date,
           SUM(CASE WHEN weight = 0 
                    THEN 1
                    ELSE 0
                    END) OVER (PARTITION BY entity_id
                               ORDER BY the_date DESC) group_no
    FROM cte2
)
SELECT entity_id, 
       MIN(the_date),
       MAX(the_date),
       cast(count(*)/2 as int64),
       timestamp_diff(max(the_date), min(the_date), day)
FROM cte3
GROUP BY entity_id, group_no
having 
  timestamp_diff(max(the_date), min(the_date), day) > 182 ;




select utils.formatInt(count(entity_id)) `Number of asthma_ocs_dx_codes`
from asthma_ocs_dx_codes ;

select utils.formatInt(count(*)) `Number of asthma_ocs_dx_codes by event_type`
from asthma_ocs_dx_codes
group by event_type;


select utils.formatInt(count(*)) `Number of asthma_ocs_meds`
from asthma_meds
where drug_class = 'OCS' ;


select utils.formatInt(count(*)) `Number of asthma med spans` from asthma_ocs_meds_spans;

select utils.formatInt(count(distinct entity_id)) `Number of patients asthma med spans` from asthma_ocs_meds_spans;
