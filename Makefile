
REGISTRY ?= 127.0.0.1:5000

build:
	for i in base langchain; do \
		docker build . -f Dockerfile_$$i -t rayspark:$$i; \
	done

push:
	for i in base langchain; do \
		docker tag rayspark:$$i $(REGISTRY)/daocloud/rayspark:$$i; \
		docker push $$_ || docker push $$_ ;\
	done

.PHONY: kuberay
kuberay:
	helm upgrade --install kuberay-operator \
		./kuberay/kuberay-operator \
		-n ray --create-namespace
	helm upgrade --install kuberay-apiserver \
		./kuberay/kuberay-apiserver \
		-n ray --create-namespace

word_count:
	./run-sample.sh $@.py

xgboost_ray_nyctaxi:
	./run-sample.sh $@.py