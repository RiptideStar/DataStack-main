import importlib as imp
import carenostics.big_query as bq
import carenostics.ckd_cohort as ckd

imp.reload(bq)
imp.reload(ckd)

pat_id = 'Z3510711'
evaluation_date = '2021-01-01'
bigquery = bq.BigQuery()

cohort_evaluator = ckd.Cohort(bigquery, pat_id,evaluation_date)
cohort_evaluator.get_cohort()