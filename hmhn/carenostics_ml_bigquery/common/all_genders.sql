declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

drop table if exists all_genders ;

create table all_genders (
  gender int not null, 
  gender_description string not null
) ;



insert into all_genders(gender, gender_description)
select 
  cast(rcpt_mem_sex_c as int),
  name
from 
  $HMHN.ZC_SEX;



if DEBUG
then
  select * from all_genders order by gender limit 10;
  select utils.formatInt(count(*))  `Number Genders` from all_genders;
end if ;
