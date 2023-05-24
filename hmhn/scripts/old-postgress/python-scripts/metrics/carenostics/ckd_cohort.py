#!/usr/bin/env python
"""
  Copyright 2023 Carenostics Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
"""

__author__ = "Vikram Anand"
__email__ =  "vikram.anand@carenostics.com"
__license__ = "Apache 2.0"
__maintainer__ = "developer"
__status__ = "Production"
__version__ = "0.0.1"

import pandas as pd
from datetime import datetime
from dateutil.relativedelta import relativedelta

class Cohort:
  """Class Cohort to extract the cohort for a patient on a date."""

  def __init__(self, bigquery, patient_id, evaluation_date):
    self.bigquery = bigquery
    self.patient_id = patient_id
    self.evaluation_date = datetime.strptime(evaluation_date, '%Y-%m-%d').date()
    self.entity_id = self.get_entity_id()
    

  def get_cohort(self):
    """
      Return a string to get the cohort for the input:
      A1, A2, A3 or NONE
      This for the patient before the evaluation date.
    """
    cohort = 'NONE'
    egfr_df = self.get_egfr_values()
    abnormal_egfr_count = self.get_abnormal_egfr_count(egfr_df)

    if(abnormal_egfr_count == 0):
      return cohort

    has_ckd = self.get_ckd_dx()
    within_age_limit = self.check_age(18,85)
    has_kidney_failure = self.check_kidney_failure()
    has_dialysis = self.check_dialysis()
    has_ckd_meds = self.check_meds()
    
    meets_inclusion_criteria = within_age_limit and (not has_kidney_failure) and (not has_dialysis) 
    if(abnormal_egfr_count > 0 and meets_inclusion_criteria and (not has_ckd)):
      cohort = 'A1'

    if (abnormal_egfr_count > 1 and meets_inclusion_criteria and (not has_ckd)):
      cohort = 'A2'

    if(has_ckd and (not has_ckd_meds)):
      cohort = 'A3'
    
    return cohort

  def get_abnormal_egfr_count(self, egfr_df):
    """
      Get the abnormal counts for the eGFR the within a 2 year frame before the evaluation date.
    """
    eval_df = egfr_df.copy(deep=True)
    abnormal_count = 0

    if(len(eval_df) == 0 ):
      return abnormal_count

    ev_date_2_years_ago = self.evaluation_date  - relativedelta(years=2)
    eval_df = eval_df[eval_df['event_dttm'].dt.date >=  ev_date_2_years_ago]

    if(len(eval_df) == 0 ):
      return abnormal_count

    if(eval_df['clean_value'][0] >= 60):
      return abnormal_count 
    
    abnormal_count = abnormal_count + 1
    next_df =  egfr_df.copy(deep=True)
    ev_date_3_years_ago = self.evaluation_date  - relativedelta(years=4)
    next_df = next_df[next_df['event_dttm'].dt.date >=  ev_date_3_years_ago]

    comp_df = next_df.copy()
    comp_df['is_abnormal'] = comp_df['is_abnormal'].astype(int) 
    comp_df['value_grp'] = (comp_df.is_abnormal.diff(1) != 0).astype('int').cumsum()
    
    proc_df = pd.DataFrame({'begin_date' : comp_df.groupby('value_grp').event_dttm.first(), 
              'end_date' : comp_df.groupby('value_grp').event_dttm.last(),
              'cons_count' : comp_df.groupby('value_grp').size(), 
              'value' : comp_df.groupby('value_grp').is_abnormal.first()}).reset_index(drop=True)

    begin_date = proc_df['begin_date'][0]
    end_date = proc_df['end_date'][0]
    cons_count = proc_df['cons_count'][0]
    delta = begin_date - end_date

    if(cons_count > 1 and delta.days >90):
        abnormal_count = cons_count

    return abnormal_count

  def check_age(self, start_age, stop_age):
    """
      Check if the patient with the age before the evaluation date.
    """
    sql = """
      SELECT entity_id FROM `ckd_table.demographics` 
      WHERE 
        entity_id = {0}
        AND DATE_DIFF(DATE('{1}'),DATE(birth_date),YEAR) BETWEEN {2} AND {3}
    """.format(self.entity_id,self.evaluation_date, start_age, stop_age)

    df = self.bigquery.query(sql)  
    return not df.empty


  def check_kidney_failure(self):
    """
      Check if the patient has kidney failure before the evaluation date.
    """ 
    sql = """
      SELECT DISTINCT entity_id
      FROM ckd_table.conditions 
      WHERE 
        entity_id ={0} 
        AND event_code IN ('T86.10','T86.11','T86.12','T86.13','T86.19','Z48.22','Z94.0')
        AND TIMESTAMP(event_dttm) < TIMESTAMP('{1}')
    """.format(self.entity_id,self.evaluation_date)
    df = self.bigquery.query(sql)  
    return not df.empty

  def check_dialysis(self):
    """
      Check if the patient is on dialysis before the evaluation date.
    """
    sql = """
      SELECT DISTINCT(cond.entity_id) 
      FROM ckd_table.conditions AS cond
      WHERE 
        entity_id = {0} 
        AND cond.event_code IN ('I95.3','R88.0','T85.611A','T85.621A','T85.631A','T85.691A','T85.71XA','Y84.1','Z49.0','Z49.31','Z49.32','Z91.15','Z99.2')
        AND TIMESTAMP(cond.event_dttm) < TIMESTAMP('{1}')
    """.format(self.entity_id,self.evaluation_date)

    df = self.bigquery.query(sql)  
    return not df.empty

  def get_ckd_dx(self):
    """
      Check if the patient has CKD diagnosis before the evaluation date.
    """
    sql = """
      SELECT entity_id 
      FROM `ckd_table.conditions` 
      WHERE 
        entity_id = {0}
        AND event_code IN ('N18.3','N18.30','N18.31','N18.32','N18.4','N18.5')
        AND TIMESTAMP(event_dttm) < TIMESTAMP('{1}')
        AND event_type IN ('problem_list','MEDICAL_HX')
      """.format(self.entity_id,self.evaluation_date)

    df = self.bigquery.query(sql)  
    return not df.empty


  def check_meds(self):
    """
      Check if the patient is on renal protective meds before the evaluation date.
    """

    sql = """
      SELECT 1
      FROM ckd_table.medications 
      WHERE
        entity_id = {0} 
        AND pharm_subclass IN (2770,3750,3610,3615) 
        AND TIMESTAMP(event_dttm) < TIMESTAMP('{1}') 
        AND (discon_time IS NULL OR TIMESTAMP(discon_time) > TIMESTAMP('{1}'))
    """.format(self.entity_id,self.evaluation_date)

    df = self.bigquery.query(sql)  
    return not df.empty
  
  def get_egfr_values(self):
    """
      Extract the eGFR values for the patient before the evaluation date.
    """    
    egfr_query = """
      SELECT clean_value, event_dttm, is_abnormal
      FROM ckd_table.egfr_analysis 
      WHERE 
        entity_id ={0} 
        AND event_dttm < TIMESTAMP('{1}') 
      ORDER BY event_dttm DESC
    """.format(self.entity_id,self.evaluation_date)
    egfr_df = self.bigquery.query(egfr_query)
    
    return egfr_df

  def get_entity_id(self):
    """
      Extract the entity_id for the patient.
    """ 
    entity_id_query = """ SELECT entity_id 
      FROM constant.pat_id_to_entity_id  
      WHERE  pat_id = '{0}'""".format(self.patient_id)

    query_df = self.bigquery.query(entity_id_query)
    return query_df['entity_id'][0]

