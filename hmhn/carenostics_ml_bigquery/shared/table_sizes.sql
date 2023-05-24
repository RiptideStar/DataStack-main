set @@dataset_id = '$DATASET' ;
select table_id as `Tables in $DATASET`, format("%'14d",row_count) as `Count`
from __TABLES__ 
order by 
  row_count desc;

