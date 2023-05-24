declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

drop table if exists all_marital_status ;

create table all_marital_status (
  marital_status int not null, 
  marital_status_description string not null
) ;



insert into all_marital_status(marital_status, marital_status_description)
select 
  cast(marital_status_c as int),
  name
from 
  $HMHN.ZC_MARITAL_STATUS;



if DEBUG
then
  select * from all_marital_status order by marital_status limit 10;
end if ;

select utils.formatInt(count(*))  `Number marital status` from all_marital_status;
