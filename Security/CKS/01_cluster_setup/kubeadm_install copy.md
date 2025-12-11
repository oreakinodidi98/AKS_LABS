# Control Plane Node Configuration

## Step 1: Setup Container Runtime as well as CRI (containerd)

[refrence](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

1. turn off swap -> `sudo swapoff -a`
2. set

```sh
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sysctl net.ipv4.ip_forward
```

3. Install a container runtime
   1. [Doc](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
   2. Step 1: Download and etract containerd  [ContainerD](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)
      1. Install using wget [Install](https://github.com/containerd/containerd/releases/download/)
      2. tar Cxzvf /usr/local containerd-2.1.4-linux-amd64.tar.gz
   3. download the containerd.service unit file from [Link](https://raw.githubusercontent.com/containerd/containerd/main/containerd.service)
      1. `wget -O /usr/local/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service` or `sudo wget -O /etc/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service`
      2. systemctl daemon-reload
      3. systemctl enable --now containerd
   4. Installing runc
      1. `wget https://github.com/opencontainers/runc/releases/download/v1.3.1/runc.amd64`
      2. `install -m 755 runc.amd64 /usr/local/sbin/runc`
   5. Installing CNI plugins
      1. `wget https://github.com/containernetworking/plugins/releases/download/v1.8.0/cni-plugins-linux-amd64-v1.8.0.tgz`
      2. mkdir -p /opt/cni/bin
      3. tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.8.0.tgz
   6. Generate a /etc/containerd/config.toml
      1. mkdir -p /etc/containerd/
      2. `containerd config default > /etc/containerd/config.toml`
   7. Configuring the systemd cgroup driver in /etc/containerd/config.toml
      1. sudo systemctl restart containerd

```sh
      [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc]
  ...
  [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
    SystemdCgroup = true
```

hint: `https://github.com/{owner}/{repo}/releases/download/{tag}/{filename}`

## Step 2: Kernel Parameter Configuration

```sh
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
```

```sh
sudo sysctl --system
```

## Step 3: Configuring Repo and Installation (From documentation)

1. `sudo apt-get update`
2. `apt-get install -y apt-transport-https ca-certificates curl gpg`
3. `curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg`
4. `echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list`
5. `sudo apt-get update`
6. `sudo apt-get install -y kubelet kubeadm kubectl`
7. `sudo apt-mark hold kubelet kubeadm kubectl`
8. `systemctl enable --now kubelet`

## Step 4 - Initialize Cluster with kubeadm

- [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- For multiple control planes
  - use `ip addr`
  - pass it into `--control-plane-endpoint`

- To install pod network addon use [NetworkAddon](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)
  - choose addon from [List](https://kubernetes.io/docs/concepts/cluster-administration/addons/)
    - Example i used [Calico](https://www.tigera.io/project-calico/)
  - Init Kubeadm with this `sudo kubeadm init --pod-network-cidr=192.168.0.0/16`
  - `mkdir -p $HOME/.kube`
  - `sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`
  - `sudo chown $(id -u):$(id -g) $HOME/.kube/config`

## Step 5 - Install Calico and Remove the Taint

- `kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/tigera-operator.yaml`
- `kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/custom-resources.yaml`
- `kubectl taint nodes --all node-role.kubernetes.io/control-plane-`

## Step 6- Verification

- `kubectl get nodes`
- `kubectl run nginx --image=nginx`
- `kubectl get pods`

### Worker Node Configuration

1. Run Step 1 to Step 3 from Master Node configuration in worker node as well
2. Use the `kubeadm join` command that was generated in your Control Plane Node server. The below command is just for reference.

```sh
kubeadm join 209.38.120.248:6443 --token 9vxoc8.cji5a4o82sd6lkqa \
        --discovery-token-ca-cert-hash sha256:1818dc0a5bad05b378dd3dcec2c048fd798e8f6ff69b396db4f5352b63414baf
```
Run the following command in Mater node to ensure that worker node is in Ready status.

```sh
kubectl get nodes
```

### (refrence)[https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/]
