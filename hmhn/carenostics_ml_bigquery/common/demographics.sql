declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;
drop  table if exists demographics;

create table demographics (
  entity_id int not null, 
  birth_date datetime, 
  death_date datetime, 
  gender string , 
  race int , 
  ethnicity int , 
  city string , 
  state string ,
  zip string , 
  marital_status int,
  living_status int 
);



insert into demographics(entity_id, birth_date, death_date, gender, race, ethnicity, city, 
                         state, zip, marital_status, living_status)
select 
  entity_id,
  birth_date, 
  death_date, 
  sex_c , 
  cast(pr.patient_race_c as int), 
  cast(ethnic_group_c as int), 
  city, 
  state_c, 
  zip, 
  cast(marital_status_c as int),
  cast(pat_living_stat_c as int)
from 
  cohort
  inner join constant.pat_id_to_entity_id as pte using(entity_id)
  inner join $HMHN.PATIENT as pt using(pat_id)
  -- just take the first patient race (which abrogates the need for a 'distinct on entity_id')
  left join $HMHN.PATIENT_RACE as pr on(pt.pat_id = pr.pat_id and (pr.line = 1 or pr.line is null))
  left join $HMHN.PATIENT_4 as p4 on(pt.pat_id = p4.pat_id)
  left join all_races as rc on pr.patient_race_c = rc.race 
  left join all_genders as gn on cast(pt.sex_c as int) = gn.gender 
  left join all_ethnicity as et on pt.ethnic_group_c = et.ethnicity 
  left join all_marital_status as ma on pt.marital_status_c = ma.marital_status
;



select utils.formatInt(count(*)) as `Demographics Size` from demographics;

if DEBUG
then
  select * from demographics limit 5;
-- select * from demographics where death_date is not null limit 5;
end if ;


