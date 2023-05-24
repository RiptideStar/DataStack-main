from sqlalchemy import create_engine
import pandas as pd
import logging
import uuid

logging.basicConfig(filename="transfer.log", format='%(asctime)s %(message)s',filemode='w', level=logging.INFO)
logger = logging.getLogger('TransferManager')

class TransferManager:

  def __init__(self, engine_uri, schema, big_query_helper):
    self.engine_uri = engine_uri      
    self.schema = schema
    self.big_query_helper = big_query_helper
    self.temp_csv_file_path = "./temp_input_blob_" + str(uuid.uuid4()) + ".csv"

  def extract_table_to_bucket(self, table_name):
    self.big_query_helper.extract_table(table_name)

  def copy_table(self, table_name):
  
    self.big_query_helper.create_table_properties(table_name)
    blobs = self.big_query_helper.get_blobs_for(table_name)
    blob_count = 0
    for blob in blobs:
      try:
        logger.info(f"{table_name} part # {blob_count+1} saved as {blob.name}")
        print(f"{table_name} part # {blob_count+1} saved as {blob.name}")
        if(blob_count == 0):
          operation = 'replace'
        else:
          operation = 'append'
        blob_count = blob_count + 1

        self.__process_blob(blob, table_name, operation)
        logger.info(f"{table_name} part #{blob_count+1} added to Postgres")

      except Exception as e:
        logger.exception(f"{table_name} failed in loading {blob.name} to Postgres")                
          
    logger.info(f"{table_name} upload to Postgres complete")

  def __process_blob(self, blob, table_name, operation):
    blob.download_to_filename(self.temp_csv_file_path)

    self.__update_db(table_name, operation)
    logger.info(f"{table_name} created in Postgres")

  def __update_db(self, table_name, operation):
      
    engine = create_engine(self.engine_uri)
    df = pd.read_csv(self.temp_csv_file_path, dtype= self.big_query_helper.d_types , parse_dates=self.big_query_helper.parse_dates)
    
    # Convert Int columns to int
    int_columns = self.big_query_helper.int_columns
    for int_column in int_columns:
      df[int_column] = df[int_column].fillna(-99)
      df[int_column] = df[int_column].astype(int) 
  
    try:
        print('Load to database: ' + str(df.size) + " data")
        df.to_sql(table_name, engine, if_exists= operation, index= False, schema=self.schema)
    except Exception as e:
        logger.exception(f"{table_name} failed in loading local file to Postgres") 
        print("Sorry, some error has occurred!")
    finally:
        engine.dispose()

