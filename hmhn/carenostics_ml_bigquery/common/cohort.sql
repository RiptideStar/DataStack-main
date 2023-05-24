set @@dataset_id = '$DATASET' ;
drop table if exists cohort;

create table cohort (
  entity_id int not null
);


insert into cohort 
select 
  entity_id
from 
  constant.pat_id_to_entity_id
  join $HMHN.PATIENT using(pat_id) -- seems that some patients are no longer present
limit $NUMBER_PATIENTS;


select utils.formatInt(count(*)) as `Cohort Size` from cohort ;


