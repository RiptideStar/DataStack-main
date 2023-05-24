set @@dataset_id = '$DATASET' ;

insert into meta_data(label, value)
values ('ml_table_creation', cast(current_timestamp() as string)),
       ('ml_table_dataset', '$DATASET')
;

select * from meta_data ;

