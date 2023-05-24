\skip off
drop table if exists conditions;

create table conditions (
  entity_id int not null, 
  visit_id int, 
  event_name string not null, 
  event_dttm datetime, 
  event_code string, 
  event_code_vocabulary string not null, 
  event_type string not null
);

\skip off
\time_as "Create conditions"
INSERT INTO conditions (entity_id, visit_id, event_name, event_dttm,
                         event_code, event_code_vocabulary,
                         event_type)
SELECT 
  pat_ent.entity_id, 
  cast(pl.problem_ept_csn as int), 
  ce.dx_name,
  coalesce(pl.noted_date, pl.date_of_entry),
  UPPER(ecricd.code), 
  'icd_10', 
  'problem_list'  
FROM 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN {hmhn}.PROBLEM_LIST as pl  USING (pat_id)
  JOIN {hmhn}.CLARITY_EDG as ce using (dx_id) 
  JOIN {hmhn}.EDG_CURRENT_ICD10 ecricd using(dx_id)  
UNION DISTINCT
SELECT 
  pat_ent.entity_id, 
  cast(pl.pat_enc_csn_id as int), 
  ce.dx_name, 
  pl.contact_date, 
  UPPER(ecricd.code), 
  'icd_10', 
  'medical_hx' 
FROM 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN {hmhn}.MEDICAL_HX as pl  USING (pat_id)
  JOIN {hmhn}.CLARITY_EDG as ce using (dx_id) 
  JOIN {hmhn}.EDG_CURRENT_ICD10 ecricd using(dx_id) 
UNION DISTINCT
SELECT 
  pat_ent.entity_id, 
  cast(pl.pat_enc_csn_id as int), 
  ce.dx_name, 
  pl.contact_date, 
  UPPER(ecricd.code), 
  'icd_10', 
  'pat_enc_dx' 
FROM 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN {hmhn}.PAT_ENC_DX as pl  USING (pat_id)
  JOIN {hmhn}.CLARITY_EDG as ce using (dx_id) 
  JOIN {hmhn}.EDG_CURRENT_ICD10 ecricd using(dx_id)
UNION distinct
SELECT 
  pat_ent.entity_id,
  cast(hsac.prim_enc_csn_id as int),
  cedge.dx_name,
  hsac.adm_date_time,
  UPPER(ecricd.code),
  'icd_10',
  'har_dx'
FROM
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN {hmhn}.HSP_ACCOUNT hsac USING(pat_id)
  JOIN {hmhn}.HSP_ACCT_DX_LIST hadl USING(hsp_account_id)
  JOIN {hmhn}.CLARITY_EDG cedge using (dx_id)
  JOIN {hmhn}.EDG_CURRENT_ICD10 ecricd using(dx_id);

\skip off
\intfmt ,
select cast(count(*) as int) as `conditions Size` from conditions ;

-- need the coalesce lest we get complaints from tabulate because the visit_id can be null
-- would be nice to not require this
select entity_id,coalesce(visit_id,0) `visit_id`, event_name, 
       event_dttm, event_code, event_code_vocabulary, event_type 
from conditions 
order by entity_id, coalesce(visit_id, 999999999)
limit 10;


