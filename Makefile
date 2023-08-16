build:
	docker build . -t rayspark-ml

push:
	docker tag rayspark-ml $(REGISTRY)/daocloud/rayspark-ml
	docker push $(REGISTRY)/daocloud/rayspark-ml

word_count:
	./run-sample.sh $@.py

xgboost_ray_nyctaxi:
	./run-sample.sh $@.py