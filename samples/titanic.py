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
                         num_executors=1,
                         executor_cores=1,
                         executor_memory='1GB',
                         configs = {
                            'spark.ray.raydp_spark_master.actor.resource.CPU': 0,
                            'spark.ray.raydp_spark_master.actor.resource.spark_master': 1,  # Force Spark driver related actor run on headnode
                         })

# read csv into spark
csv_file_path = "hdfs://hadoop-hadoop-hdfs-nn.ray.svc.cluster.local:9000/samples/titanic.csv"
df = spark.read.csv(csv_file_path, header=True, inferSchema=True)
df.show()

ds = ray.data.from_spark(df)
ds.show()

# # here: Azure OpenAI information is set up bash envs
# llm = AzureChatOpenAI(
#     openai_api_base=os.environ["OPENAI_API_BASE"],
#     openai_api_version=os.environ["OPENAI_API_VERSION"],
#     deployment_name=os.environ["OPENAI_AZURE_DEPLOYMENT_NAME"],
#     openai_api_key=os.environ["OPENAI_API_KEY"],
#     openai_api_type=os.environ["OPENAI_API_TYPE"],
# )

# agent = create_spark_dataframe_agent(llm, df=df, verbose=True)

# # agent.run("how many rows are there?")

# agent.run("Who bought the most expensive ticket?")

# # def train_loop_per_worker():
# #     dataset_shard = session.get_dataset_shard("train")

