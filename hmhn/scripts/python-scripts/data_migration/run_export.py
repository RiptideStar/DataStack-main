import importlib as imp
import carenostics.transfer_manager as tm
import carenostics.bigquery_helper as bh
import time
start = time.time()

imp.reload(tm)
imp.reload(bh)

# Set up Bigquery Helper
source_project = 'hmh-carenostics-dev' 
source_dataset = 'mlg' 
key_path = "./resources/sa_key.json"
bqh = bh.BigQueryHelper(source_project, source_dataset,key_path)

# Set up Transfer Manager
engine_uri = '<URI>'
#table_name = 'pat_egfr_ckd'
postgres_schema = 'mlg'
tmng = tm.TransferManager(engine_uri, postgres_schema, bqh)

table_names = [ 'all_races.sql', 'all_genders', 'all_ethnicity', 'all_marital_status',
                'ckd_dx_codes','cohort','conditions','demographics','egfr_analysis',
                'encounters','labs','medications','pat_all_flt_ckd','pat_dx_ckd',
                'pat_egfr_ckd','pat_uacr_ckd','procedures',
                'uacr_analysis','vitals']

for table_name in table_names:
  
  # start timer
  print("--------------------" + str(table_name)+ "--------------------")
  start_table = time.time()

  # copy bigquery table to csv files in GCP bucket
  bqh.extract_table(table_name)

  # copy csv file to Postgres table in specified schema
  tmng.copy_table(table_name)

  # Compute Time elapsed for table
  end_table = time.time()
  hours, rem = divmod(end_table - start_table, 3600)
  minutes, seconds = divmod(rem, 60)
  print("{:0>2}h:{:0>2}m:{:05.2f}s".format(int(hours),int(minutes),seconds))
  print("--------------------" + str(table_name)+ "--------------------")

# Compute Time elapsed
end = time.time()
hours, rem = divmod(end-start, 3600)
minutes, seconds = divmod(rem, 60)
print("{:0>2}h:{:0>2}m:{:05.2f}s".format(int(hours),int(minutes),seconds))


