declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;
drop table if exists all_races ;

create table all_races (
  race int not null, 
  race_description string not null
) ;



insert into all_races(race, race_description)
select 
  cast(patient_race_c as int),
  name
from 
  $HMHN.ZC_PATIENT_RACE;


select utils.formatInt(count(*))  `Number Races` from all_races;

if DEBUG
then
  select * from all_races order by race limit 10;
end if ;
