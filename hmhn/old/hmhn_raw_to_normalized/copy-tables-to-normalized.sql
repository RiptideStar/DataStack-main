/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to perform copy the tables from the source to the destination
                    normalized table.
                    
Author:             Michael Greenberg, Vikram Anand
***************************************************************************************************/ 

-- copy the tables from the source to the destination

-- requires that the schema is totally empty

\timing on

-- order the tables from smaller to larger ... this way, if there is an
-- error, we might get it sooner

\echo 'copy table zc_admin_route'
create table zc_admin_route as select * from "{sourceSchema}"."ZC_ADMIN_ROUTE"  ;
\echo 'create indexpk zc_admin_route '
alter table zc_admin_route add primary key(med_route_c) ;


\echo 'copy table zc_disp_enc_type'
create table zc_disp_enc_type as select * from "{sourceSchema}"."ZC_DISP_ENC_TYPE"  ;
\echo 'create PK zc_disp_enc_type'
alter table zc_disp_enc_type add primary key(disp_enc_type_c) ;

\echo 'copy table zc_ethnic_group'
create table zc_ethnic_group as select * from "{sourceSchema}"."ZC_ETHNIC_GROUP"  ;
\echo 'create PK zc_ethnic_group'
alter table zc_ethnic_group add primary key(ethnic_group_c) ;

\echo 'copy table zc_net_affil_level'
create table zc_net_affil_level as select * from "{sourceSchema}"."ZC_NET_AFFIL_LEVEL"  ;
\echo 'create PK zc_net_affil_level'
alter table zc_net_affil_level add primary key(net_affil_level_c) ;

\echo 'copy table zc_patient_race'
create table zc_patient_race as select * from "{sourceSchema}"."ZC_PATIENT_RACE"  ;
\echo 'create PK zc_patient_race'
alter table zc_patient_race add primary key(patient_race_c) ;

\echo 'copy table zc_pat_class'
create table zc_pat_class as select * from "{sourceSchema}"."ZC_PAT_CLASS"  ;
\echo 'create PK zc_pat_class'
alter table zc_pat_class add primary key(adt_pat_class_c) ;

\echo 'copy table zc_sex'
create table zc_sex as select * from "{sourceSchema}"."ZC_SEX"  ;
\echo 'create PK zc_sex'
alter table zc_sex add primary key(rcpt_mem_sex_c) ;

\echo 'copy table zc_marital_status'
create table zc_marital_status as select * from "{sourceSchema}"."ZC_MARITAL_STATUS"  ;
\echo 'create PK zc_marital_status'
alter table zc_marital_status add primary key(marital_status_c) ;


\echo 'copy table rxnorm_codes'
create table rxnorm_codes as select * from "{sourceSchema}"."RXNORM_CODES"  ;
\echo 'create rxnorm_codes PK'
alter table rxnorm_codes add primary key(medication_id, line) ;

\echo 'copy table rx_med_two'
create table rx_med_two as select * from "{sourceSchema}"."RX_MED_TWO"  ;
\echo 'create index '
alter table rx_med_two add primary key(medication_id) ;
\echo 'create idx_med_two_admin_route_c'
create index on rx_med_two(admin_route_c);



\echo 'copy table clarity_component'
create table clarity_component as select * from "{sourceSchema}"."CLARITY_COMPONENT"  ;
\echo 'create index '
-- create clarity_component(component_id) PK ;
alter table clarity_component add primary key(component_id) ;

\echo 'copy table clarity_edg'
create table clarity_edg as select * from "{sourceSchema}"."CLARITY_EDG"  ;
\echo 'create PK clarity_edg(dx_id)'
alter table clarity_edg add primary key(dx_id) ;



\echo 'copy table clarity_medication'
create table clarity_medication as select * from "{sourceSchema}"."CLARITY_MEDICATION"  ;
\echo 'create index '
alter table clarity_medication add primary key(medication_id) ;

\echo 'copy table clarity_eap'
create table clarity_eap as select * from "{sourceSchema}"."CLARITY_EAP"  ;
\echo 'create PK clarity_eap '
alter table clarity_eap add primary key(proc_id) ;


\echo 'copy table clarity_ser_2'
create table clarity_ser_2 as select * from "{sourceSchema}"."CLARITY_SER_2"  ;
\echo 'create PK clarity_ser_2'
alter table clarity_ser_2 add primary key(prov_id) ;

\echo 'copy table clarity_ser_netaff'
create table clarity_ser_netaff as select * from "{sourceSchema}"."CLARITY_SER_NETAFF"  ;
\echo 'create PK clarity_ser_netaff'
alter table clarity_ser_netaff add primary key(prov_id, line) ;


------ patient

-- copy_table PATIENT  
\echo 'copy table patient'
create table patient as select * from "{sourceSchema}"."PATIENT"  ;
\echo 'create pk for patient'
alter table patient  add primary key(pat_id);


\echo 'copy table patient_4'
create table patient_4 as select * from "{sourceSchema}"."PATIENT_4"  ;
\echo 'create pk for patient'
alter table patient_4  add primary key(pat_id);

\echo 'copy table pat_enc_dx'
create table pat_enc_dx as select * from "{sourceSchema}"."PAT_ENC_DX"  ;
\echo 'create pk pat_enc_dx'
alter table pat_enc_dx add primary key(pat_enc_csn_id, line) ;
\echo 'create idx_pat_enc_dx_pat_id'
create index on pat_enc_dx(pat_id) ;

\echo 'copy table pat_enc_hsp'
create table pat_enc_hsp as select * from "{sourceSchema}"."PAT_ENC_HSP"  ;
\echo 'create pat_enc_hsp pk'
alter table pat_enc_hsp add primary key(pat_enc_csn_id) ;
\echo 'create idx_pat_enc_hsp_pat_id'
create index on pat_enc_hsp(pat_id) ;


\echo 'copy table pat_pcp'
create table pat_pcp as select * from "{sourceSchema}"."PAT_PCP"  ;
\echo 'create idx_pat_pcp_pat_id'
alter table pat_pcp add primary key(pat_id, line) ;

\echo 'copy table patient_race'
create table patient_race as select * from "{sourceSchema}"."PATIENT_RACE"  ;
\echo 'create idx_patient_race_pat_id'
-- all patients to not have an entry
-- each patient can have multiple lines (sequential starting at 1)
alter table patient_race add primary key(pat_id, line) ;

\echo 'copy table pat_enc'
create table pat_enc as select * from "{sourceSchema}"."PAT_ENC"  ;
\echo 'pat_enc primary key'
alter table pat_enc add primary key(pat_enc_csn_id) ;
\echo 'create idx_pat_enc_pat_id'
create index on pat_enc(pat_id) ;

\echo 'copy table pat_enc_curr_meds'
create table pat_enc_curr_meds as select * from "{sourceSchema}"."PAT_ENC_CURR_MEDS"  ;
\echo 'create primary key pat_enc_curr_meds'
alter table pat_enc_curr_meds add primary key(pat_enc_csn_id, line) ;
\echo 'create index on pat_enc_curr_meds(current_med_id)'
create index on pat_enc_curr_meds(current_med_id) ;
\echo 'create idx_pat_enc_curr_meds_pat_id'
create index on pat_enc_curr_meds(pat_id) ;

---------------

\echo 'copy table medical_hx'
create table medical_hx as select * from "{sourceSchema}"."MEDICAL_HX"  ;
\echo 'create idx_idx_medical_hx_pat_enc_cns_id'
alter table medical_hx add primary key(pat_enc_csn_id, line) ;
\echo 'create idx_medical_hx_pat_id'
create index on medical_hx(pat_id) ;

\echo 'copy table order_med'
create table order_med as select * from "{sourceSchema}"."ORDER_MED"  ;
\echo 'create order_med pk(order_med_id)'
alter table order_med add primary key(order_med_id) ;
\echo 'create idx_order_med_pat_id'
create index on order_med(pat_id) ;
\echo 'create idx_order_med_enc_csn_id'
create index on order_med(pat_enc_csn_id);
\echo 'create idx_order_med_medication_id'
create index on order_med(medication_id) ;


\echo 'copy table order_proc'
create table order_proc as select * from "{sourceSchema}"."ORDER_PROC"  ;
\echo 'create pk order_proc'
alter table order_proc add primary key(order_proc_id) ;
\echo 'create idx_order_proc_pat_id'
create index on order_proc(pat_id) ;
\echo 'create idx_proc_results_pat_enc_csn_id'
create index on order_proc(pat_enc_csn_id) ;


\echo 'copy table order_results'
create table order_results as select * from "{sourceSchema}"."ORDER_RESULTS"  ;
\echo 'create order_results primary key'
alter table order_results add primary key(order_proc_id, ord_date_real, line) ;
\echo 'create idx_order_results_pat_id'
create index on order_results(pat_id) ;
\echo 'create idx_order_results_pat_enc_csn_id'
create index on order_results(pat_enc_csn_id) ;
\echo 'create idx_order_results_component_id'
create index on order_results(component_id) ;


\echo 'copy table problem_list'
create table problem_list  as select * from "{sourceSchema}"."PROBLEM_LIST"  ;
\echo 'create problem_list PK'
alter table problem_list add primary key(problem_list_id) ;
\echo 'create idx_problem_list_pat_id'
create index on problem_list(pat_id) ;

\echo 'copy table edg_current_icd10'
create table edg_current_icd10 as select * from "{sourceSchema}"."EDG_CURRENT_ICD10"  ;
\echo 'create PK edg_current_icd10'
alter table edg_current_icd10  add primary key(dx_id, line) ;


\echo 'copy table daily_byte_sized_report'
create table daily_byte_sized_report as select * from "{sourceSchema}"."DAILY_BYTE_SIZED_REPORT"  ;
\echo 'create PK daily_byte_sized_report'
alter table daily_byte_sized_report add primary key(echo_id) ;

\echo 'copy table hsp_account'
create table hsp_account as select * from "{sourceSchema}"."HSP_ACCOUNT"  ;
\echo 'create primary key hsp_account(hsp_account_id)'
alter table hsp_account add primary key(hsp_account_id) ;
\echo 'create index hsp_account(pat_id)'
create index on hsp_account(pat_id) ;

\echo 'copy table hsp_acct_dx_list'
create table hsp_acct_dx_list as select * from "{sourceSchema}"."HSP_ACCT_DX_LIST"  ;
\echo 'create index hsp_acct_dx_list(hsp_account_id)'
alter table hsp_acct_dx_list add primary key(hsp_account_id, line) ;

\include_relative 'transactions.sql'
\include_relative 'measures.sql'
