\timing off

\skip off
drop table if exists all_races ;

create table all_races (
  race int not null, 
  race_description string not null
) ;


\time_as 'insert into all_races'
insert into all_races(race, race_description)
select 
  cast(patient_race_c as int),
  name
from 
  {hmhn}.ZC_PATIENT_RACE;


\skip off
select * from all_races order by race limit 10;
select count(*)  `Number Races` from all_races;
