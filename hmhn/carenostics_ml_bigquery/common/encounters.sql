declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

drop table if exists encounters;

create table encounters (
  entity_id int not null, 
  visit_id int not null, 
  visit_admit_dttm datetime , 
  visit_discharge_dttm datetime , 
  pcp_provider_id string, 
  visit_provider_id string, 
  ordering_provider_id string, 
  encounter_type string, 
  department_id int,
  is_emergency_encounter boolean
);



insert into encounters(entity_id, visit_id, visit_admit_dttm, visit_discharge_dttm,
                       pcp_provider_id, visit_provider_id, ordering_provider_id,
                       encounter_type, department_id, is_emergency_encounter)
select 
  entity_id, 
  cast(pat_enc_csn_id as int), 
  case when enc_type_c in ('3', '106') then hosp_admsn_time else contact_date end visit_admit_dttm, 
  case when enc_type_c in ('3', '106') then hosp_dischrg_time else contact_date end visit_discharge_dttm, 
  pcp_prov_id as pcp_provider_id, 
  visit_prov_id as visit_provider_id, 
  ordering_prov_id as ordering_provider_id, 
  enc_type_c as encounter_type, 
  cast(department_id as int),
  ed_enc.pat_enc_csn_id is not null
from 
  ($HMHN.PAT_ENC enc
   left outer join $HMHN.F_ED_ENCOUNTERS as ed_enc using(pat_enc_csn_id))
  join constant.pat_id_to_entity_id as eid on(enc.pat_id = eid.pat_id)
where
  entity_id in (select entity_id from cohort);




select utils.formatInt(count(*)) as `encounters size` from encounters ;

if DEBUG
then
  select * from encounters
  order by entity_id
  limit 10;
end if ;



