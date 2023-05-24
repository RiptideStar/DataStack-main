drop table if exists cohort;

create table cohort (
  entity_id int not null
);

\time_as "Create cohort"
insert into cohort 
select 
  entity_id
from 
  constant.pat_id_to_entity_id
limit {numberpatients};

\intfmt ,
select count(*) as `Cohort Size` from cohort ;


