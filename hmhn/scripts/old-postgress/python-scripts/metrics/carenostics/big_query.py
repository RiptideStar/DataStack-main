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

import os
import logging
from google.cloud import bigquery, storage

logger = logging.getLogger('BigQuery')

class BigQuery:
  """Class Bigquery to connect and execute a query."""

  def __init__(self, source_project = 'hmh-carenostics-dev', source_dataset = 'ckd_table'):
    """Class Bigquery to connect and execute a query."""
    self.source_project = source_project
    self.source_dataset = source_dataset
    self.__initialize()

  def __initialize(self):
    self.client = bigquery.Client(project=self.source_project)

  def query(self, query):
    query_df = self.client.query(query).result().to_dataframe()
    return query_df
