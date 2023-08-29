#!/bin/bash -x
# Watch processes of Ray pods

[ -d ./tmp ] || mkdir -v ./tmp
cd ./tmp || exit 1

for i in $( kubectl get po -o name -l ray.io/node-type=head | awk -F '/' '{print $2}'); do
    kubectl exec -it $i -c ray-head -- ps -eww -o cmd >> $i.txt
    echo >> $i.txt
done

for j in $( kubectl get po -o name -l ray.io/node-type=worker | awk -F '/' '{print $2}'); do
    kubectl exec -it $j -c ray-worker -- ps -eww -o cmd >> $j.txt
    echo >> $j.txt
done

