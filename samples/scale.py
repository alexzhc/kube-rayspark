import ray
import time

ray.init()

ray.autoscaler.sdk.request_resources(num_cpus=4)

time.sleep(3)