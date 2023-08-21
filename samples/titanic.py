#!/usr/bin/env python
import os

from langchain.chat_models import ChatOpenAI, ChatAnthropic, AzureChatOpenAI
from langchain.agents import create_spark_dataframe_agent

import ray
import raydp

# Native spark
# from pyspark.sql import SparkSession
# spark = SparkSession.builder.getOrCreate()
# df = spark.read.csv(csv_file_path, header=True, inferSchema=True)

# connect to ray cluster
ray.init()

# create a Spark cluster with specified resource requirements
spark = raydp.init_spark(app_name='RaySpark Titanic',
                         num_executors=2,
                         executor_cores=2,
                         executor_memory='4GB')

# read csv into spark
csv_file_path = "samples/titanic.csv"
df = spark.read.csv(csv_file_path, header=True, inferSchema=True)
df.show()

# here: Azure OpenAI information is set up bash envs
llm = AzureChatOpenAI(
    openai_api_base=os.environ["OPENAI_API_BASE"],
    openai_api_version=os.environ["OPENAI_API_VERSION"],
    deployment_name=os.environ["OPENAI_AZURE_DEPLOYMENT_NAME"],
    openai_api_key=os.environ["OPENAI_API_KEY"],
    openai_api_type=os.environ["OPENAI_API_TYPE"],
)

agent = create_spark_dataframe_agent(llm, df=df, verbose=True)

# agent.run("how many rows are there?")

agent.run("Who bought the most expensive ticket?")