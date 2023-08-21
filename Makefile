
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
	for i in base langchain; do \
		docker build . --build-arg PIP_MIRROR=$(PIP_MIRROR) \
			-f Dockerfile_$$i -t rayspark:$$i; \
	done

push:
	for i in base langchain; do \
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

word_count:
	./run-sample.sh $@.py

xgboost_ray_nyctaxi:
	./run-sample.sh $@.py

titanic:
	./run-sample.sh $@.py