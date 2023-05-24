-- new labs

select 
  count(*)
from 
  --On using is still pending here as I am getting error while doing so
  mlg_ml_100.cohort
  inner join mlg_normalized.pat_id_to_entity_id en on en.entity_id = mlg_ml_100.cohort.entity_id
  inner join mlg_normalized.pat_enc enc on enc.pat_id = en.pat_id
  inner JOIN mlg_normalized.order_proc AS opr ON opr.pat_enc_csn_id = enc.pat_enc_csn_id
  inner join mlg_normalized.order_results ores on  ores.order_proc_id = opr.order_proc_id 
  inner join mlg_normalized.clarity_component as cc ON cc.component_id = ores.component_id;




select 
  en.entity_id, 
  ores.pat_enc_csn_id as visit_id, 
  cc.common_name as event_name, 
  ores.result_date as event_dttm, 
  ores.component_id, 
  cc.loinc_code as event_code, 
  'loinc' as event_code_vocabulary, 
  ores.ord_value as event_value_string, 
  ores.ord_num_value as event_value_numeric, 
  cc.dflt_units as event_unit 
from 
  --On using is still pending here as I am getting error while doing so
  mlg_normalized.order_results as ores 
  JOIN mlg_normalized.order_proc AS opr ON ores.order_proc_id = opr.order_proc_id 
  JOIN mlg_normalized.clarity_component as cc ON cc.component_id = ores.component_id 
  JOIN mlg_normalized.pat_id_to_entity_id AS en ON opr.pat_id = en.pat_id 
  JOIN mlg_normalized.pat_enc AS enc ON enc.pat_enc_csn_id = ores.pat_enc_csn_id 
  JOIN mlg_normalized.patient AS pt ON opr.pat_id = pt.pat_id
  --to consider only patient in demographics table
  where en.entity_id in (select entity_id from mlg_ml_100.cohort);
limit 10


