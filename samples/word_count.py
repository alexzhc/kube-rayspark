import ray
import raydp

# connect to ray cluster
ray.init()

# create a Spark cluster with specified resource requirements
spark = raydp.init_spark(app_name='RayDP Example',
                         num_executors=2,
                         executor_cores=2,
                         executor_memory='4GB')

# normal data processesing with Spark
df = spark.createDataFrame([('look',), ('spark',), ('tutorial',), ('spark',), ('look', ), ('python', )], ['word'])
df.show()
word_count = df.groupBy('word').count()
word_count.show()

# stop the spark cluster
raydp.stop_spark()
