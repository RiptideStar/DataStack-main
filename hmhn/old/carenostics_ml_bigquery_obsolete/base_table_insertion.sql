drop schema if exists {dataset} cascade ;
create schema {dataset} ;
\include update_patient_mapping.sql
\include cohort.sql
\include all_races.sql
\include all_genders.sql
\include all_ethnicity.sql
\include all_marital_status.sql
\include demographics.sql
\include conditions.sql
\include encounters.sql
\include labs.sql
\include medications.sql
\include concepts.sql
\include vitals.sql
\include procedures.sql
\include table_sizes.sql

