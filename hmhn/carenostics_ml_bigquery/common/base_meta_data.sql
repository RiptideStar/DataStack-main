set @@dataset_id = '$DATASET' ;

create or replace table meta_data (
  label string not null,
  value string not null
);


insert into meta_data(label, value)
values ('base_table_creation', cast(current_timestamp() as string)),
       ('base_table_dataset', '$DATASET'),
       ('HMHN', '$HMHN'),
       ('NUMBER_PATIENTS', '$NUMBER_PATIENTS'),
       ('NUMBER_PATIENT_ENC', (select cast(count(*) as string) from $HMHN.PAT_ENC)),
       ('LAST_PATIENT_ENC', (select cast(max(contact_date) as string) from $HMHN.PAT_ENC where contact_date <= date_add(CURRENT_date(), interval 1 day)))
;

select * from meta_data ;

