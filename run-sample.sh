#!/bin/bash -x
cd ./samples || exit 1

job_file=$1
[ -z ${job_file} ] && exit 1
[ -f ${job_file} ] || exit 1

cp -vf ${job_file} sample_code.py
kubectl delete cm ray-job-code-sample
kubectl create cm ray-job-code-sample --from-file=./
rm -vf sample_code.py
cd ../

kubectl delete -f ray-job.yaml
kubectl apply -f ray-job.yaml

until kubectl get job/rayjob-sample; do
    sleep 1
done
kubectl wait job/rayjob-sample --for=jsonpath='{.status.ready}'=1 --timeout=90s
kubectl logs -f job/rayjob-sample