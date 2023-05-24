\skip off
drop table if exists concepts;

drop 
  table if exists concepts;
create table concepts (
  concept_code string  not null, 
  concept_text string not null, 
  concept_system string not null, 
  concept_display string , 
  concept_start_date datetime not null, 
  concept_end_date datetime , 
  concept_resource string not null, 
  hmh_concept_code string not null
);

\time_as 'insert into concepts'

INSERT into concepts (
  concept_code, concept_text, concept_system, 
  concept_display, concept_start_date, 
  concept_end_date, concept_resource, 
  hmh_concept_code
) 
values 
  (
    '35094-2', 'Blood pressure panel', 
    'LOINC', 'blood pressure', '2023-01-01' , 
    null, 'vitals', '5'
  ), 
  (
    'LP35925-4', 'Body mass index (BMI)', 
    'LOINC', 'BMI', '2023-01-01' , 
    null, 'vitals', '301070'
  ), 
  (
    '29463-7', 'Body weight', 'LOINC', 
    'weight', '2023-01-01' , null, 
    'vitals', '14'
  ), 
  (
    'C0232117', 'Pulse rate', 'SNOMED CT', 
    'pulse', '2023-01-01' , null, 
    'vitals', '8'
  ), 
  (
    '8867-4', 'Heart rate', 'LOINC', 'heart rate', 
    '2023-01-01' , null, 'vitals', 
    '301240'
  );



\skip off
\intfmt ,
select cast(count(*) as int) as `concepts size` from concepts ;

select * from concepts
order by concept_code
limit 10;

