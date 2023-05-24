declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

drop table if exists all_ethnicity ;

create table all_ethnicity (
  ethnicity int not null, 
  ethnicity_description string not null
) ;



insert into all_ethnicity(ethnicity, ethnicity_description)
select 
  cast(ethnic_group_c as int),
  name
from 
  $HMHN.ZC_ETHNIC_GROUP;

select utils.formatInt(count(*))  `Number ethnicity` from all_ethnicity;

if DEBUG
then
  select * from all_ethnicity order by ethnicity limit 10;
end if ;

