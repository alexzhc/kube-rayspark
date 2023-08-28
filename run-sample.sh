#!/bin/bash -x
cd ./samples || exit 1

export job_file=$1
[ -z ${job_file} ] && exit 1
[ -f ${job_file} ] || exit 1
yq -v || exit 1
export job_name="rayjob"-"$( echo ${job_file} | sed 's/\..*$//;s/_/-/g')"

kubectl delete cm ${job_name}
kubectl create cm ${job_name} --from-file=./
cd ../ || exit 1

kubectl delete rayjob ${job_name}
cat ray-job.yaml \
    | yq '.metadata.name = env(job_name)' \
    | yq '.spec.entrypoint = "python /home/ray/samples/" + env(job_file)' \
    | yq '.spec.rayClusterSpec.headGroupSpec.template.spec.volumes[0].configMap.name = env(job_name) ' \
    | yq '.spec.rayClusterSpec.workerGroupSpecs[0].template.spec.volumes[0].configMap.name = env(job_name) ' \
    | kubectl apply -f -

until kubectl get job/${job_name}; do
    sleep 1
done
kubectl wait job/${job_name} --for=jsonpath='{.status.ready}'=1 --timeout=90s
kubectl logs -f job/${job_name}