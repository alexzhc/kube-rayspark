
SHELL := /bin/bash

REGISTRY ?= 127.0.0.1:5000
PIP_MIRROR ?=  https://pypi.tuna.tsinghua.edu.cn/simple

NAMESPACE ?= ray

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

word_count xgboost_ray_nyctaxi titanic iris scale:
	./run-sample.sh $@.py

clean:
	kubectl delete rayjobs.ray.io --all

scale-cluster:
	kubectl exec $$(kubectl get pods -l ray.io/identifier=raycluster-autoscaler-head -o name) \
		-it -c ray-head \
		-- python -c \
		"import ray;ray.init();ray.autoscaler.sdk.request_resources(num_cpus=4)"