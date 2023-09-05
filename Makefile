
SHELL := /bin/bash

REGISTRY ?= registry.k8s.local:5000
PIP_MIRROR ?=  https://pypi.tuna.tsinghua.edu.cn/simple

NAMESPACE ?= ray

HADOOP_NN ?= hadoop-hadoop-hdfs-nn-0
HADOOP_API ?= hadoop-hadoop-hdfs-nn.$(NAMESPACE).svc.cluster.local

OPENAI_API_TYPE ?= ""
OPENAI_API_VERSION ?= ""
OPENAI_API_BASE ?= ""
OPENAI_API_KEY ?= ""
OPENAI_AZURE_DEPLOYMENT_NAME ?= ""

build:
	for i in base langchain ml; do \
		docker build . --build-arg PIP_MIRROR=$(PIP_MIRROR) \
			-f Dockerfile_$$i -t rayspark:$$i; \
	done

push:
	for i in base langchain ml; do \
		docker tag rayspark:$$i $(REGISTRY)/daocloud/rayspark:$$i; \
		docker push $$_ || docker push $$_ ;\
	done

openai:
	kubectl delete secret openai-conf || true
	kubectl create secret generic openai-conf \
		--from-literal=OPENAI_API_TYPE=$(OPENAI_API_TYPE) \
		--from-literal=OPENAI_API_VERSION=$(OPENAI_API_VERSION) \
		--from-literal=OPENAI_API_BASE=$(OPENAI_API_BASE) \
		--from-literal=OPENAI_API_KEY=$(OPENAI_API_KEY) \
		--from-literal=OPENAI_AZURE_DEPLOYMENT_NAME=$(OPENAI_AZURE_DEPLOYMENT_NAME)
		kubectl get secret openai-conf -o json | jq -r .data

.PHONY: hadoop
hadoop:
	helm upgrade --install hadoop \
	./hadoop \
	-n $(NAMESPACE) --create-namespace

.PHONY: kuberay
kuberay:
	helm upgrade --install kuberay-operator \
		./kuberay/kuberay-operator \
		-n $(NAMESPACE) --create-namespace
	helm upgrade --install kuberay-apiserver \
		./kuberay/kuberay-apiserver \
		-n $(NAMESPACE) --create-namespace

.PHONY: spark
spark-operator:
	helm install spark-operator \
	./spark/charts/spark-operator-chart \
	-n $(NAMESPACE) --create-namespace \
	--set sparkJobNamespace=$(NAMESPACE) \
	--set serviceAccounts.sparkoperator.name=spark-operator \
	--set serviceAccounts.spark.name=spark \
	--set image.repository=$(REGISTRY)/googlecloudplatform/spark-operator \
	--set image.tag=v1beta2-1.3.8-3.1.1

spark-pi:
	cat ./spark/examples/spark-py-pi.yaml | \
		yq '.metadata.namespace = "$(NAMESPACE)"' | \
		yq '.spec.image = "$(REGISTRY)/spark-operator/spark-py:v3.1.1"' | \
		yq '.spec.imagePullPolicy = "IfNotPresent"' | \
		kubectl apply -f -

upload:
	kubectl exec -it $(HADOOP_NN) -- rm -vfr /tmp/samples
	kubectl cp samples $(HADOOP_NN):/tmp/
	kubectl exec -it $(HADOOP_NN) -- ls /tmp/samples
	kubectl exec -it $(HADOOP_NN) -- hadoop fs -rm -r -f hdfs://$(HADOOP_API):9000/samples
	kubectl exec -it $(HADOOP_NN) -- hadoop fs -put /tmp/samples hdfs://$(HADOOP_API):9000/
	kubectl exec -it $(HADOOP_NN) -- hadoop fs -ls hdfs://$(HADOOP_API):9000/samples

word_count xgboost_ray_nyctaxi titanic iris scale time:
	./run-sample.sh $@.py

clean:
	kubectl delete rayjobs.ray.io --all
	kubectl delete sparkapplications.sparkoperator.k8s.io --all

scale-cluster:
	kubectl exec $$(kubectl get pods -l ray.io/identifier=raycluster-autoscaler-head -o name) \
		-it -c ray-head \
		-- python -c \
		"import ray;ray.init();ray.autoscaler.sdk.request_resources(num_cpus=4)"

watch-procs:
	while sleep 1; do \
		./get-procs.sh; \
		[[ $$(kubectl get rayjob -o json | jq -r .items[0].status.jobStatus) == "SUCCEEDED" ]] && break; \
	done

logger:
	kubectl apply -f logger.yaml -n $(NAMESPACE)

logs:
	kubectl get pods -n $(NAMESPACE) -l k8s-app=logger --no-headers -o custom-columns=":metadata.name" | \
		xargs -tI % rsync -az --no-specials --no-devices --info=progress2 \
		--blocking-io --rsh ./kubectl-rsh.sh %.logger@$(NAMESPACE):/tmp/ray/ /tmp/ray/ \
		--exclude '*.so' \
		--exclude '*/runtime_resources' \
		|| true
	ls -1 /tmp/ray/

