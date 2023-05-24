declare until datetime default(if("$UNTIL_DATE"="", current_datetime, parse_datetime("%F", "$UNTIL_DATE"))) ;
set @@dataset_id = '$DATASET' ;

create 
or replace table pat_dx_severe_asthma(
  entity_id int not null,
  severe_asthma_dx bool not null,
  first_dx_date datetime,
  first_idc10_code string,
  first_drug_start datetime,
  first_drug_end datetime,  
  first_drug_class string,
  first_drug_dose string,
  last_drug_start datetime,
  last_drug_end datetime,
  last_drug_class string,
  last_drug_dose string
  ) ;


  
create temp table pat_dx_severe_asthma_first
as
select distinct
  first_value(entity_id) over win `entity_id`,
  first_value(event_dttm) over win `first_dx_date`,
  first_value(idc10_code) over win `first_dx_idc10`
from
  $ML.asthma_dx_codes
where
  event_dttm <= until
  and severity = 5
WINDOW win as (partition by entity_id
               order by entity_id, event_dttm) ;


create temp table pat_asthma_drugs_first_last
as
select distinct
  first_value(entity_id) over win `entity_id`,
  first_value(start_time) over win `first_start`,
  first_value(effective_end_time) over win `first_discon`,
  first_value(drug_class) over win `first_drug_class`,
  first_value(dose) over win `first_dose`,
  last_value(start_time) over win `last_start`,
  last_value(effective_end_time) over win `last_discon`,
  last_value(drug_class) over win `last_drug_class`,
  last_value(dose) over win `last_dose`
from
  $ML.asthma_meds
where
  start_time <= until
WINDOW win as (partition by entity_id
               order by entity_id, start_time
       	       rows between unbounded preceding and unbounded following
	       )
	       ;


insert into pat_dx_severe_asthma(entity_id, severe_asthma_dx, first_dx_date, first_idc10_code,
                                 first_drug_start, first_drug_end, first_drug_class, first_drug_dose, 
                                 last_drug_start, last_drug_end, last_drug_class, last_drug_dose)

select
  entity_id, first_dx_date is not null, first_dx_date, first_dx_idc10,
  first_start, first_discon, first_drug_class, first_dose, 
  last_start, last_discon, last_drug_class, last_dose
from
  $ML.cohort 
  left join pat_dx_severe_asthma_first using(entity_id)
  left join pat_asthma_drugs_first_last using(entity_id)
;
       

select (select utils.formatInt(count(*)) from pat_dx_severe_asthma) `patients`,
       (select utils.formatInt(count(*)) from pat_dx_severe_asthma where severe_asthma_dx) `severe asthma dx`,
       (select utils.formatInt(count(*)) from pat_dx_severe_asthma where first_drug_start is not null) `asthma drugs`,
       (select utils.formatInt(count(*)) from pat_dx_severe_asthma where severe_asthma_dx and first_drug_start is not null) `dx and drugs`
       ;
       
