set @@dataset_id = '$DATASET' ;

create or replace table pat_meta_data (
  label string not null,
  value string not null
);


insert into pat_meta_data(label, value)
values ('pat_creation', cast(current_timestamp() as string)),
       ('pat_dataset', '$DATASET'),
       ('ml_dataset', '$ML'),
       ('UNTIL_DATE', '$UNTIL_DATE'),
       ('PAT_EGFR_MAX_YEARS', '$PAT_EGFR_MAX_YEARS'),
       ('PAT_DX_CKD_EXCLUDE_N_CODES', '$PAT_DX_CKD_EXCLUDE_N_CODES'),
       ('PAT_DX_CKD_ONLY_PROBLEM_OR_DX', '$PAT_DX_CKD_ONLY_PROBLEM_OR_DX'),
       ('PAT_ALL_FLT_NO_USE_UACR', '$PAT_ALL_FLT_NO_USE_UACR')
;

select * from pat_meta_data ;

