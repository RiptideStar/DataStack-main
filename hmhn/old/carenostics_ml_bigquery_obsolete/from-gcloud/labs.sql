-- Labs
-- Carenostics/JoEllen Gabriel
-- Revisions as of 3/8/23

truncate table `hmh-carenostics-dev.ckd_table.labs`;

insert into  `hmh-carenostics-dev.ckd_table.labs`
(entity_id, 
visit_id, 
event_name, 
event_dttm,
component_id, 
event_code, 
event_code_vocabulary,
event_value_string, 
event_value_numeric, 
event_unit,
proc_name, 
base_name)

select 
  en.entity_id, 
  ores.pat_enc_csn_id as visit_id, 
  cc.common_name as event_name, 
  ores.result_date as event_dttm, 
  ores.component_id, 
  UPPER(cc.loinc_code) as event_code, 
  'loinc' as event_code_vocabulary, 
  ores.ord_value as event_value_string, 
  ores.ord_num_value as event_value_numeric, 
  cc.dflt_units as event_unit,
  eap.proc_name,
  cc.BASE_NAME 
from  `hmh-carenostics-dev.ckd_table.cohort`co
  inner join `hmh-carenostics-dev.ckd_table.pat_id_to_entity_id` en 
  on en.entity_id = cO.entity_id
  inner join `hmh-datalake-prod-c5b4.CLARITY.PAT_ENC` enc 
  on enc.pat_id = en.pat_id
  inner JOIN `hmh-datalake-prod-c5b4.CLARITY.ORDER_PROC` AS opr 
  ON opr.pat_enc_csn_id = enc.pat_enc_csn_id
  inner join `hmh-datalake-prod-c5b4.CLARITY.ORDER_RESULTS` ores 
  on  ores.order_proc_id = opr.order_proc_id 
  inner join `hmh-datalake-prod-c5b4.CLARITY.CLARITY_COMPONENT` as cc 
  ON cc.component_id = ores.component_id 
  inner join `hmh-datalake-prod-c5b4.CLARITY.CLARITY_EAP` as eap
  ON opr.PROC_ID = eap.PROC_ID
 where ores.LAB_STATUS_C in (3,5)  -- this is not in the updated carenostic code but Vikram confirmed it needed for Final results
