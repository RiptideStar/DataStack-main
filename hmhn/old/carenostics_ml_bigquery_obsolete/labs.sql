\skip off
drop table if exists labs;

create table labs (
  entity_id int not null, 
  visit_id int not null, 
  event_name string not null, 
  event_dttm datetime, 
  component_id int not null, 
  event_code string, 
  event_code_vocabulary string not null, 
  event_value_string string, 
  event_value_numeric float64, 
  event_unit string,
  proc_name string,
  base_name string
  
);

\time_as 'insert into labs'
insert into labs(entity_id, visit_id, event_name, event_dttm,
                  component_id, event_code, event_code_vocabulary,
                  event_value_string, event_value_numeric, event_unit,
                 proc_name, base_name)
select 
  en.entity_id, 
  cast(ores.pat_enc_csn_id as int), 
  cc.common_name, 
  ores.result_date, 
  cast(ores.component_id as int), 
  UPPER(cc.loinc_code), 
  'loinc', 
  ores.ord_value, 
  ores.ord_num_value, 
  cc.dflt_units,
  eap.proc_name,
  cc.base_name
from 
  cohort
  inner join constant.pat_id_to_entity_id en using(entity_id)
  inner join {hmhn}.PAT_ENC enc using(pat_id)
  inner join {hmhn}.ORDER_PROC opr using(pat_enc_csn_id)
  inner join {hmhn}.ORDER_RESULTS ores using(order_proc_id)
  inner join {hmhn}.CLARITY_COMPONENT cc using(component_id)
  inner join {hmhn}.CLARITY_EAP eap using(proc_id)
where
  -- "final" or "edited final" (ok to ignore the few nulls).  about 2.5% of the entries
  ores.lab_status_c in (3, 5) 
  ;

\skip off
\intfmt ,
select cast(count(*) as int) as `labs size` from labs ;

select * from labs
order by entity_id
limit 10;

