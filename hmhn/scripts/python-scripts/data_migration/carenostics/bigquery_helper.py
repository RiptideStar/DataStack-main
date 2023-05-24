from google.cloud import bigquery, storage
from google.oauth2 import service_account
import logging

logger = logging.getLogger('BigQueryHelper')

class BigQueryHelper:

  def __init__(self, source_project = 'hmh-carenostics-dev', source_dataset = 'ckd_table', key_path = "./resources/sa_key.json"):
    self.source_project = source_project
    self.source_dataset = source_dataset
    self.key_path = key_path
    self.bucket_name = "hmh-us-mxcv-res-carenostics-default-us-dev"

    self.__initialize()

  def __initialize(self):
    self.credentials = service_account.Credentials.from_service_account_file(
        self.key_path, scopes=["https://www.googleapis.com/auth/cloud-platform"],
    )
    self.client = bigquery.Client(credentials=self.credentials, project=self.source_project)
    self.storage_client = storage.Client(credentials=self.credentials, project=self.source_project) 

  def get_big_query_table_schema(self, table_name):
    query = f"""SELECT column_name, data_type FROM {self.source_project}.{self.source_dataset}.INFORMATION_SCHEMA.COLUMNS WHERE table_name = '{table_name}'"""
    query_job = self.client.query(query)
    return(query_job.to_dataframe())

  def extract_table(self, table_name):
    destination_uri = "gs://{}/{}/{}".format(self.bucket_name, table_name, f"{table_name}-*.csv")
    dataset_ref = bigquery.DatasetReference(self.source_project, self.source_dataset)
    table_ref = dataset_ref.table(table_name)
    extract_job = self.client.extract_table(
            table_ref,
            destination_uri,
            # Location must match that of the source table.
            location="US",
    )  # API request
    extract_job.result()  # Waits for job to complete.
    logger.info(f"{table_name} added to GCS")

  def get_blobs_for(self,table_name):
    return self.storage_client.list_blobs(self.bucket_name, prefix=f"{table_name}/", delimiter='/')

  def create_table_properties(self, table_name):
    df = self.get_big_query_table_schema(table_name)
    data_type_mapping = {"FLOAT64":"float64","NUMERIC":"float64","STRING":"str","DATETIME":"str","BIGNUMERIC":"float64","TIMESTAMP":"str","INT64":"float64", "BOOL":"bool"}
    string_list=[]
    d_types = {}
    parse_dates = []
    int_columns = []
    for index, row in df.iterrows():
        bq_type = row['data_type']
        data_type = data_type_mapping[bq_type]
        column_name = row['column_name']
        if(column_name == 'entity_id'):
          d_types[column_name] = 'int64'
        else:
          d_types[column_name] = data_type
        
        if(bq_type == 'DATETIME') or (bq_type == 'TIMESTAMP') or (bq_type == 'DATE'):
          parse_dates.append(column_name)

        if(bq_type == 'INT64'):
          int_columns.append(column_name)

        string_list.append(row['column_name']+ " " + data_type)
    
    self.d_types = d_types
    self.parse_dates = parse_dates
    self.int_columns = int_columns
