# pip install google-cloud-bigquery pandas db-dtypes jinja2 tabulate

from pprint import pprint
import os.path
import sys 
import re
import argparse
import traceback
import time
import numpy as np
from tabulate import tabulate
from google.cloud import bigquery
from google.oauth2 import service_account

class UserException(Exception):
    pass

class BigQueryEvaluator:
  def __init__(self, keyFile, project, dataset, variables):
    credentials = service_account.Credentials.from_service_account_file(keyFile, scopes=["https://www.googleapis.com/auth/cloud-platform"])
    jobConfig = bigquery.QueryJobConfig()
    if dataset != None:
        jobConfig.default_dataset = bigquery.DatasetReference(project, dataset)
    self.client = bigquery.Client(credentials=credentials, project=project, default_query_job_config=jobConfig) 
    self.variables = variables
    # global state
    self.timerOn = False
    self.skipOn = False
    # for next query only
    self.headers = None
    self.floatfmt = None
    self.showSchema = False
    self.timeAs = None
    self.intfmt = ""
    self.showQueries = False

  def compute_int_fmt(self, col, fmt):
      if col.field_type == 'INTEGER':
          return fmt
      else:
        return ""
      # if we use the data frame column ... col.name == 'Int64':


  def compute_float_fmt(self, col, fmt):
    if col.field_type == 'FLOAT':
        # for data frame col.name == 'float64':
        return fmt
    elif col.field_type == 'NUMERIC':
        # for data frame this is 'object' ... but then it tries to print as a float with decimals
        return ".0f"
    else:
        return ""
    
  def run_query(self, query):
        st = time.perf_counter()

        if self.showQueries:
            print(query)
        query_job = self.client.query(query)  
        results = query_job.result()
        elapsed = time.perf_counter() - st
        df = results.to_dataframe()
        if self.showSchema:
            pprint(results.schema)
            pprint(df.dtypes)

        # need to make sure all id fields are rendered w/o decimals.  will have to be more clever later
        if self.headers == None:
            self.headers = df.columns
        if self.floatfmt == None:
            self.floatfmt = 'g'

        if isinstance(self.intfmt, str):
            self.intfmt = [  self.compute_int_fmt(x, self.intfmt) for x in results.schema ]
        if isinstance(self.floatfmt, str):
            self.floatfmt = [  self.compute_float_fmt(x, self.floatfmt) for x in results.schema ]
        print()

        if len(df) == 0:
            print('No results')
            # pass
        else:
            print(tabulate(df, showindex=False, headers=self.headers, floatfmt=self.floatfmt,  intfmt = self.intfmt, disable_numparse=False))
            # missingval="-"
        if self.timeAs != None:
            print(f'{self.timeAs} ran in {elapsed:,.1f} sec')
        elif self.timerOn:
            print(f'Executed in {elapsed:,.1f} sec')
        self.headers = None
        self.floatfmt = None
        self.timeAs = None
        self.intfmt = ""

  def insert_line_numbers(self, txt):
    return "\n".join([f"{n+1:2d} {line}" for n, line in enumerate(txt.split("\n"))])


  def execute(self, scriptText, includeFolder):
    # parse the queries
    scriptText = re.sub(r"--.*", "", scriptText)
    for k,v in  self.variables.items():
        scriptText = re.sub(f'{{{k}}}', v, scriptText)
    # split into command blocks.  will end up with array of the form
    # [  '\command aaa bbb ccc', 'sql to run', ';   ', '   ' ]
    queries = re.split(r"(;\s*$|^\\.*$)", scriptText, 0, re.MULTILINE)
    for query in queries:
        if not query or query.isspace():
            pass
        elif query.startswith(';'):
            pass
        elif match := re.match(r"^\\skip\s+(on|off)\s*$", query):
            self.skipOn = match.group(1) == 'on'
        elif self.skipOn:
            pass
        elif match := re.match(r"^\\timing\s+(on|off)\s*$", query):
            self.timerOn = match.group(1) == 'on'
        elif match := re.match(r"^\\schema\s+(on|off)\s*$", query):
            self.showSchema = match.group(1) == 'on'
        elif match := re.match(r"^\\show_queries\s+(on|off)\s*$", query):
            self.showQueries = match.group(1) == 'on'
        elif match := re.match(r"^\\include\s+['\"`]?(.*?)['\"`]?\s*$", query):
            f = os.path.join(includeFolder, match.group(1))
            file = open(f,mode='r')
            data = file.read()
            file.close()
            print(f'include {f}')
            self.execute(data, os.path.dirname(f))
            self.skipOn = False
        elif match := re.match(r"^\\echo\s+(.*?)\s*$", query):
            print(match.group(1))
        elif match := re.match(r"^\\time_as\s+['\"`]?(.*?)['\"`]?\s*$", query):
            self.timeAs = match.group(1)
        elif match := re.match(r"^\\exit\s*$", query):
            print('exiting')
            break
        elif match := re.match(r"^\\headers\s+(.*?)\s*$", query):
            self.headers = re.split(";", match.group(1))
            pass
        elif match := re.match(r"^\\floatfmt\s+(.*?)\s*$", query):
            self.floatfmt = re.split(";", match.group(1))
            if len(self.floatfmt) == 1:
                self.floatfmt = self.floatfmt[0]
        elif match := re.match(r"^\\intfmt\s+(.*?)\s*$", query):
            self.intfmt = re.split(";", match.group(1))
            if len(self.intfmt) == 1:
                self.intfmt = self.intfmt[0]
        elif query.startswith('\\'):
            raise UserException(f'Unknown directive: "{query}"')
        else:
		    # get rid of blank lines to improve error message
            q = re.sub(r'^\s*$\n', '', query, flags=re.MULTILINE)
            try:
                self.run_query(q)
            except Exception as e:
                mm = self.insert_line_numbers(q)
                raise UserException(f'{e} while executing\n{mm}')

