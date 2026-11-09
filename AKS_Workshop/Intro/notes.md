# Kubernetes Architecture

## Highlevel architecture

objective: run/orchestrate containers
container types like docker, creo, containerd
how: by running insinde VM or physical servers
cluster = multiple vms or physical servers (nodes)
in each node we want to run a container
to run a container we need container runtime to run in the node
e.g. docker containers = containerd runtime
allows you o run a container on the node

pain point: dont want to access nodes directly in order to run contianer

control plane : runs and orchestrates deployment of containers ont he node
- brain of kubernetes
- controlls which container runs on different worker nodes
- inside control plane you have :
 - API server: Gets request
 - ETCD: key value pair that stores configuration for cluster
 - Scheduler: schedules pods on nodes
 - Controller manger: helps deploy continers on to different nodes
 - cloud manager: provisions managed resources from cloud provider

- Inside Worker nodes
 - Kubelet: gets request from control plane to start command inside node
 - container runtime: what you need to run container

Developer -> kubectl -> Control plane -> worker nodes
- kubectl = cli to induce request to control plane
- can include yaml file
- kubernetes uses desired state configuration (declaritive)

for users to access the app they have to go through load alancers, as multiple instancce of application in container inside node inside cluster

role of node balancer is tot distribute traffic/request to the different containers 
this resource can be provisioned by the cloud that hosts the cluster
E.G. Azure (AKS), GCP (GKE), Amazon (EKS)
kubernetes managed service

managed isk -> database or want to store files