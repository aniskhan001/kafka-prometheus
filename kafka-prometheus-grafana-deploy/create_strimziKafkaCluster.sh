#!/bin/bash

if [ $# -lt 3 ]
then
  echo "Usage: $0 <NameSpace> <Brokers(Integer)> <ZookeeperNodes(Integer)>"
  exit 3
fi

if [ -z $1 ]
then
  echo "Please give namespace as argument - regex : '[a-z0-9]([-a-z0-9]*[a-z0-9])?'"
  exit -1
else
  namespace=$1
fi

number='^[0-9]+$'
if ! [[ $number =~ $2 ]] & [ -z $2 ]
then
  echo "Number of Zookeeper Nodes must be a non zero integer"
  exit -1
else
  brokers=$2
fi

if ! [[ $number =~ $3 ]] & [ -z $3 ]
then
  echo "Number of Zookeeper Nodes must be a non zero integer"
  exit -1
else
  zknodes=$3
fi

echo "creating namespace $namespace"
kubectl create namespace $namespace

echo "applying strimzi installation files"
cat strimzi-cluster-operator.yaml \
  | sed "s/namespace: .*/namespace: $namespace/" \
  | kubectl -n $namespace apply -f -

echo "creating kafka and zookeeper clusters"
cat kafka-persistent.yaml \
  | sed "0,/replicas: 1/s//replicas: $brokers/1" \
  | sed "0,/replicas: 1/s//replicas: $zknodes/1" \
  | kubectl apply -n $namespace -f -

echo "creating Prometheus deployment"
cat prometheus-install.yaml \
  | sed "s/namespace: .*/namespace: $namespace/" \
  | kubectl -n $namespace apply -f -

echo "creating Grafana dashboard"
cat grafana/grafana-configmap.yaml \
  | sed "s/namespace: .*/namespace: $namespace/" \
  | kubectl -n $namespace apply -f -

cat grafana/grafana-dashboard-configmap.yaml \
  | sed "s/namespace: .*/namespace: $namespace/" \
  | kubectl -n $namespace apply -f -

cat grafana/grafana-deploy.yaml \
  | sed "s/namespace: .*/namespace: $namespace/" \
  | kubectl -n $namespace apply -f -

echo "list of pods in the namespace:"
kubectl get pods -n $namespace

