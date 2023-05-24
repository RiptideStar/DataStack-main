/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to perform copy the tables from the source to the destination
                    normalized table.
                    
Author:             Michael Greenberg, Vikram Anand
***************************************************************************************************/ 

\timing on
\echo 'create pat_id_to_entity_id mapping table'
create table if not exists pat_id_to_entity_id (
  pat_id text primary key not null,
  entity_id bigint unique not null 
) ;

\echo 'update pat_id_to_entity_id'
-- entity_id is the index if the patients in the new patients + the number previous rows in the pat_id_to_entity_id table
insert into pat_id_to_entity_id(pat_id, entity_id)
select pat_id,
       (row_number () over (order by pat_id)) + (select count(*) from pat_id_to_entity_id)
from {normalized}.patient
where 
  not exists (select
              from pat_id_to_entity_id
              where pat_id_to_entity_id.pat_id = {normalized}.patient.pat_id) ;

