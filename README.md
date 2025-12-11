# AKS_LABS

## Startup

- az aks start --resource-group myresourcegroup489086251 --name myakscluster489086251
- Set-Alias k kubectl
- kubectl create namespace pets
- kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/refs/heads/main/aks-store-quickstart.yaml -n pets
- kubectl get all -n pets