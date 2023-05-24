select 
  entity_id, 
  pat_enc_csn_id as visit_id, 
  case when enc_type_c in ('3', '106') then hosp_admsn_time else contact_date end visit_admit_dttm, 
  case when enc_type_c in ('3', '106') then hosp_dischrg_time else contact_date end visit_discharge_dttm, 
  pcp_prov_id as pcp_provider_id, 
  visit_prov_id as visit_provider_id, 
  ordering_prov_id as ordering_provider_id, 
  enc_type_c as encounter_type, 
  department_id 
from 
  `hmh-datalake-prod-c5b4.CLARITY.PAT_ENC`
  join `hmh-carenostics-dev.ckd_table.pat_id_to_entity_id` as en using (pat_id)
  --to consider only patient in demographics table
  where entity_id in (select entity_id from `hmh-carenostics-dev.ckd_table.cohort`)
