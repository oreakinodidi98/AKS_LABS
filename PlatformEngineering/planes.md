# Creating Scalable and Resilient Systems part 2

Platform divided in planes

## Planes

- Control Plane
- Security Plane
- Observability Plane
- Identity Plane
- FinOps Plane
- Enviroment Plane
- Service Plane


## Desighning a Platform (IDP- Internal Developer Platform)

### Do you need a Platform

Before starting your organisation needs to decide if you actually need a platform that scales. If the answer is not a clear yes then NO.
Building an IDP is a costly project that takes a while to setup and maintaine, if your buisness is not scalling yet then focus on scalling that first instead of your K8 cluster.
Platforms are also refered to as , Portals, Golden Paths, self-service provisioning

### Layers and planes

Thinking in layers : hardware, virtualization, containers, orchestration -> users
E.G. Storage/CPU/RAM -> BareMetal/Hypervisor -> Ubuntu/Flatcar -> runc/CRI-O/containerd -> Kubelet/Kube-proxy -> API/etcd/CNI ->
Layers are static. Planes interact, evolve, and overlap without breaking everything else, mostly

## 5 planes by Platform engineering ORG

Developer control Plane -> IDE, Developer portal, Version control (App/Platfrom source code), Cloud enviroment
Integration & Delivery Plane 
Monitoring and Logging plane
Security Plane
Resource plane
