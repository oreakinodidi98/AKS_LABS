# PDB

Pod Disruption Budgets (PDBs) in Azure Kubernetes Service (AKS) limit the number of replicated application pods that can be simultaneously down during voluntary disruptions like cluster upgrades or node drains

## Flow 

1. Deployment created with 3 replicas and label app=my-app
2. Admin applies Deployment and PDB YAML
3. API Server receives the spec and stores it in etcd
4. etcd stores Deployment and PDB objects
5. Controller Manager validates, stores, and creates ReplicaSet
6. ReplicaSet creates 3 Pods based on the spec
7. Scheduler assigns Pods to nodes
8. Kubelet (Node1) runs Pod-1 and Pod-2
9. Kubelet (Node2) runs Pod-3
10. PDB with minAvailable: 2 monitors Pod status with matching labels
11. Admin drains Node1 to simulate disruption
12. Eviction request for Pod-2 denied by PDB (would violate availability)
13. Eviction of Pod-1 approved, still meets minAvailable
14. API Server coordinates eviction decisions
Note: Only one Pod evicted — PDB still valid