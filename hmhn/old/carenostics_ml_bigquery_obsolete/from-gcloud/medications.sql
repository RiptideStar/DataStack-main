-- Medication
-- Carenotics/JoEllen Gabriel
-- revisions as of 3/8/23
truncate table `hmh-carenostics-dev.ckd_table.medications`;

insert into `hmh-carenostics-dev.ckd_table.medications`
(entity_id,visit_id,event_dttm,event_code,event_code_vocabulary,dose,administration_type,medication,route,pharm_subclass,enc_type,discon_time)

select 
  distinct en.entity_id as entity_id, 
  cm.pat_enc_csn_id as visit_id, 
  cm.contact_date as event_dttm, 
  UPPER(norm.rxnorm_code) as event_code, 
  'rxnorm' as event_code_vocabulary, 
  med.strength as dose, 
  med.form as administration_type, 
  med.name as medication, 
  route.name as route, 
  med.pharm_subclass_c as pharm_subclass, 
  case when enc.enc_type_c in('3', '106') then 'inpatient' else 'outpatient' end as enc_type, 
  discon_time 
 from  `hmh-carenostics-dev.ckd_table.cohort` cohort
  inner join `hmh-carenostics-dev.ckd_table.pat_id_to_entity_id` as en on  en.entity_id = cohort.entity_id
  inner join `hmh-datalake-prod-c5b4.CLARITY.PAT_ENC` enc on enc.pat_id = en.pat_id
  inner join `hmh-datalake-prod-c5b4.CLARITY.PAT_ENC_CURR_MEDS` cm on cm.pat_enc_csn_id = enc.pat_enc_csn_id
  inner join `hmh-datalake-prod-c5b4.CLARITY.ORDER_MED` ord on  ord.order_med_id = cm.current_med_id 
  inner join `hmh-datalake-prod-c5b4.CLARITY.CLARITY_MEDICATION` med on med.medication_id  = ord.medication_id 
  inner join `hmh-datalake-prod-c5b4.CLARITY.RXNORM_CODES` norm on norm.medication_id = ord.medication_id
  inner join `hmh-datalake-prod-c5b4.CLARITY.RX_MED_TWO` rx on rx.medication_id  = ord.medication_id
  inner join `hmh-datalake-prod-c5b4.CLARITY.ZC_ADMIN_ROUTE` route on route.med_route_c = rx.admin_route_c 
