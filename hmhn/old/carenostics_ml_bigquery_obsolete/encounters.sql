\skip off
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
  department_id int
);


\time_as 'insert into encounters'
insert into encounters(entity_id, visit_id, visit_admit_dttm, visit_discharge_dttm,
                       pcp_provider_id, visit_provider_id, ordering_provider_id,
                       encounter_type, department_id)
select 
  entity_id, 
  cast(pat_enc_csn_id as int), 
  case when enc_type_c in ('3', '106') then hosp_admsn_time else contact_date end visit_admit_dttm, 
  case when enc_type_c in ('3', '106') then hosp_dischrg_time else contact_date end visit_discharge_dttm, 
  pcp_prov_id as pcp_provider_id, 
  visit_prov_id as visit_provider_id, 
  ordering_prov_id as ordering_provider_id, 
  enc_type_c as encounter_type, 
  cast(department_id as int)
from 
  {hmhn}.PAT_ENC
join 
  constant.pat_id_to_entity_id as en using (pat_id)
  --to consider only patient in demographics table
where entity_id in (select entity_id from cohort);


\skip off
\intfmt ,
select cast(count(*) as int) as `encounters size` from encounters ;

select * from encounters
order by entity_id
limit 10;

