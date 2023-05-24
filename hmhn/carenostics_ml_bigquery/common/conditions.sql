declare ignore_problem_status_3 boolean default $CONDITIONS_IGNORE_PROBLEM_STATUS_3 ;
declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

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



INSERT INTO conditions (entity_id, visit_id, event_name, event_dttm,
                         event_code, event_code_vocabulary,
                         event_type)
SELECT 
  distinct
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
  JOIN $HMHN.PROBLEM_LIST as pl  USING (pat_id)
  JOIN $HMHN.CLARITY_EDG as ce using (dx_id) 
  JOIN $HMHN.EDG_CURRENT_ICD10 ecricd using(dx_id)
where
  (not ignore_problem_status_3 or PROBLEM_STATUS_C <> 3)
UNION all -- do not need the distinct because each select has a different event_type
SELECT 
  distinct
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
  JOIN $HMHN.MEDICAL_HX as pl  USING (pat_id)
  JOIN $HMHN.CLARITY_EDG as ce using (dx_id) 
  JOIN $HMHN.EDG_CURRENT_ICD10 ecricd using(dx_id) 
UNION all
SELECT 
  distinct
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
  JOIN $HMHN.PAT_ENC_DX as pl  USING (pat_id)
  JOIN $HMHN.CLARITY_EDG as ce using (dx_id) 
  JOIN $HMHN.EDG_CURRENT_ICD10 ecricd using(dx_id)
UNION all
SELECT 
  distinct
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
  JOIN $HMHN.HSP_ACCOUNT hsac USING(pat_id)
  JOIN $HMHN.HSP_ACCT_DX_LIST hadl USING(hsp_account_id)
  JOIN $HMHN.CLARITY_EDG cedge using (dx_id)
  JOIN $HMHN.EDG_CURRENT_ICD10 ecricd using(dx_id)
union all 
select
  distinct
  pat_ent.entity_id,
  cast(enc.pat_enc_csn_id as int), 
  ce.dx_name, 
  enc.ADT_ARRIVAL_DATE, 
  UPPER(ecricd.code), 
  'icd_10', 
  'ed_dx' 
from 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN $HMHN.F_ED_ENCOUNTERS enc using(pat_id)
  INNER JOIN $HMHN.CLARITY_EDG as ce ON enc.PRIMARY_DX_ID = ce.DX_ID
  INNER JOIN $HMHN.EDG_CURRENT_ICD10 ecricd using(dx_id)
WHERE
  PRIMARY_DX_ID IS NOT NULL
;



select utils.formatInt(count(*)) as `conditions Size` from conditions ;

if DEBUG
then
-- need the coalesce lest we get complaints from tabulate because the visit_id can be null
-- would be nice to not require this
  select entity_id,coalesce(visit_id,0) `visit_id`, event_name, 
         event_dttm, event_code, event_code_vocabulary, event_type 
  from conditions 
  order by entity_id, coalesce(visit_id, 999999999)
  limit 10;
  select * from medications
  order by entity_id
  limit 10;
end if ;


