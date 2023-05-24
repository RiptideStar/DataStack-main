-- Conditions
-- Carenostics/JoEllen Gabriel
-- revisions as of 3/8/2023
truncate table `hmh-carenostics-dev.ckd_table.conditions`;

INSERT INTO `hmh-carenostics-dev.ckd_table.conditions` (entity_id, visit_id, event_name, event_dttm,
       	                event_code, event_code_vocabulary,
 		                    event_type)
SELECT 
  pat_ent.entity_id, 
  pl.problem_ept_csn, 
  ce.dx_name, 
  pl.noted_date, 
  UPPER(ecricd.code), 
  'icd_10', 
  'problem_list'  
from 
   `hmh-carenostics-dev.ckd_table.cohort` 
  join `hmh-carenostics-dev.ckd_table.pat_id_to_entity_id` pat_ent using (entity_id)
  join `hmh-datalake-prod-c5b4.CLARITY.PROBLEM_LIST`  pl using (pat_id)
  join `hmh-datalake-prod-c5b4.CLARITY.CLARITY_EDG`  ce  using (dx_id) 
  join `hmh-datalake-prod-c5b4.CLARITY.EDG_CURRENT_ICD10` ecricd using(dx_id) 

UNION DISTINCT

SELECT 
  pat_ent.entity_id, 
  pl.pat_enc_csn_id, 
  ce.dx_name, 
  pl.contact_date, 
  UPPER(ecricd.code), 
  'icd_10', 
  'MEDICAL_HX' 
FROM 
 `hmh-carenostics-dev.ckd_table.cohort` 
  JOIN `hmh-carenostics-dev.ckd_table.pat_id_to_entity_id` pat_ent USING(entity_id)
  JOIN `hmh-datalake-prod-c5b4.CLARITY.MEDICAL_HX` as pl  USING (pat_id)
  JOIN `hmh-datalake-prod-c5b4.CLARITY.CLARITY_EDG` as ce using (dx_id) 
  JOIN `hmh-datalake-prod-c5b4.CLARITY.EDG_CURRENT_ICD10` ecricd using(dx_id)

UNION DISTINCT


SELECT 
  pat_ent.entity_id, 
  pl.pat_enc_csn_id, 
  ce.dx_name, 
  pl.contact_date, 
  UPPER(ecricd.code), 
  'icd_10', 
  'pat_enc_dx' 
FROM 
 `hmh-carenostics-dev.ckd_table.cohort` 
  JOIN `hmh-carenostics-dev.ckd_table.pat_id_to_entity_id`pat_ent USING(entity_id)
  JOIN `hmh-datalake-prod-c5b4.CLARITY.PAT_ENC_DX` as pl  USING (pat_id)
  JOIN `hmh-datalake-prod-c5b4.CLARITY.CLARITY_EDG` as ce using (dx_id) 
  JOIN `hmh-datalake-prod-c5b4.CLARITY.EDG_CURRENT_ICD10` ecricd using(dx_id)

UNION DISTINCT


SELECT 
  pat_ent.entity_id,
  hsac.prim_enc_csn_id,
  cedge.dx_name,
  hsac.adm_date_time,
  UPPER(ecricd.code),
  'icd_10',
  'har_dx'
FROM
 `hmh-carenostics-dev.ckd_table.cohort` 
  JOIN `hmh-carenostics-dev.ckd_table.pat_id_to_entity_id` pat_ent USING(entity_id)
  JOIN `hmh-datalake-prod-c5b4.CLARITY.HSP_ACCOUNT` hsac USING(pat_id)
  JOIN `hmh-datalake-prod-c5b4.CLARITY.HSP_ACCT_DX_LIST` hadl USING(hsp_account_id)
  JOIN `hmh-datalake-prod-c5b4.CLARITY.CLARITY_EDG` cedge using (dx_id)
  JOIN `hmh-datalake-prod-c5b4.CLARITY.EDG_CURRENT_ICD10` ecricd using(dx_id);
