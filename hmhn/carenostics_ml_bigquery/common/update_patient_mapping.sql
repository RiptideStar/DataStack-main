set @@dataset_id = '$DATASET' ;
-- drop table if exists constant.pat_id_to_entity_id ;
create table if not exists constant.pat_id_to_entity_id (
  pat_id string,
  entity_id int
) ;


select utils.formatInt(count(*)) as `Previous Patient Mappings` from constant.pat_id_to_entity_id ;


-- entity_id is the index if the patients in the new patients + the number previous rows in the pat_id_to_entity_id table
insert into constant.pat_id_to_entity_id(pat_id, entity_id)
select pat_id,
       (row_number () over (order by pat_id)) + (select count(*) from constant.pat_id_to_entity_id)
from $HMHN.PATIENT hmhn_patient
where 
  not exists (select 1
              from constant.pat_id_to_entity_id ml_patient
              where ml_patient.pat_id = hmhn_patient.pat_id) ;




select utils.formatInt(count(*)) as `Current Patient Mappings` from constant.pat_id_to_entity_id ;
