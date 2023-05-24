/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to build tables required for ML analysis. This 
                    includes reference tables, and resources tables (demographics, conditions
                    encounters, labs, medications, vitals, procedures)
                     
                    a flat table with all values required for analytics.
Author:             Michael Greenberg
***************************************************************************************************/  


--add in chhort for everythings

--------------reference tables--------------
drop table if exists all_races cascade;
create table all_races (
  race bigint primary key, 
  race_description text not null
);

drop  table if exists all_genders cascade;
create table all_genders (
  gender text primary key, 
  gender_description text not null
);

drop  table if exists all_ethnicity cascade;
create table all_ethnicity (
  ethnicity bigint primary key, 
  ethnicity_description text not null
);

drop table if exists all_marital_status cascade;
create table all_marital_status (
  marital_status bigint primary key, 
  marital_status_description text not null
);
--------------reference tables--------------


--------------cohort table--------------
drop  table if exists cohort;
create table cohort (
  entity_id bigint primary key
);
--------------cohort table--------------


--------------demographic table--------------
drop  table if exists demographics;
create table demographics (
  entity_id bigint primary key, 
  birth_date timestamp(0) null, 
  death_date timestamp(0) null, 
  gender text references all_genders(gender) null, 
  race bigint references all_races(race) check (race>=1 and race<=21) null, 
  ethnicity bigint references all_ethnicity(ethnicity) null, 
  city text null, 
  state text null, -- references all_states(state), 
  zip text null, 
  marital_status bigint references all_marital_status(marital_status) null,
  living_status int null
);

--indexes
create index on demographics(entity_id);
--------------demographic table--------------


--------------conditions table---------------
drop table if exists conditions;
create table conditions (
  entity_id bigint not null, 
  visit_id bigint null, 
  event_name text not null, 
  event_dttm timestamp(0) null, 
  event_code text null, 
  event_code_vocabulary text not null, 
  event_type text not null
);

--indexes
create index on conditions(entity_id);
create index on conditions(event_dttm);
create index on conditions(visit_id);
create index on conditions(event_code);

--------------conditions table--------------


--------------encounters table--------------

drop table if exists encounters;
create table encounters (
  entity_id bigint not null, 
  visit_id bigint not null, 
  visit_admit_dttm timestamp(0) null, 
  visit_discharge_dttm timestamp(0) null, 
  pcp_provider_id text null, 
  visit_provider_id text null, 
  ordering_provider_id text null, 
  encounter_type text null, 
  department_id bigint null
);

--indexes
create index on encounters(entity_id);
create index on encounters(visit_id);
create index on encounters(visit_admit_dttm);
create index on encounters(visit_discharge_dttm);

--------------encounters table--------------


-- labs moved to labs.sql, included by base_table_insertion


--------------medications table--------------
drop table if exists medications;
create table medications (
  entity_id bigint not null, 
  visit_id bigint not null, 
  event_dttm timestamp(0) not null, 
  event_code text not null, 
  event_code_vocabulary text not null, 
  dose text null, 
  administration_type text null, 
  medication text null, 
  route text null, 
  pharm_subclass bigint null,  
  enc_type text null, 
  discon_time timestamp(0) null
);
/*
--indexes
create index on medications(entity_id);
create index on medications(visit_id);
create index on medications(event_dttm);
create index on medications(pharm_subclass);
create index on medications(event_code);
*/
--------------medications table-------------- 



-------------------vitals table-----------------------
drop table if exists vitals;
create table vitals (
  entity_id bigint not null, 
  visit_id bigint not null, 
  event_name text null,
  event_dttm timestamp(0) not null, 
  event_code text not null, 
  event_code_vocabulary text not null, 
  event_value_string text null, 
  event_concept_code text not null,
  event_concept_system text not null,
  event_concept_text text null,
  fsd_id text null, 
  record_date timestamp(0) null
);
--indexes
create index on vitals(entity_id);
create index on vitals(visit_id);
create index on vitals(event_dttm);
create index on vitals(event_code);
create index on vitals(event_concept_code);

-------------------vitals table-----------------------

------------------------procedures table--------------------------------
drop 
  table if exists procedures;
create table procedures(
  entity_id bigint not null,
  visit_id bigint not null, 
  event_code text not null,
  event_dttm timestamp(0) not null, 
  event_type text not null,
  event_desc text null,
  enc_type text not null, 
  proc_count bigint not null
);
--indexes
create index on procedures(entity_id);
create index on procedures(visit_id);
create index on procedures(event_dttm);
create index on procedures(event_code);
------------------------procedures table--------------------------------

-------------------concepts table-----------------------
drop 
  table if exists concepts;
create table concepts (
  concept_code text primary key, 
  concept_text text not null, 
  concept_system text not null, 
  concept_display text null, 
  concept_start_date timestamp(0) not null, 
  concept_end_date timestamp(0) null, 
  concept_resource text not null, 
  hmh_concept_code text not null
);
--indexes
create index on concepts(hmh_concept_code);

-------------------concepts table-----------------------
