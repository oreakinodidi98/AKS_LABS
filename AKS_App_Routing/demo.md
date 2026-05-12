# AKS App Routing Add-On — Migration Demo Guide

> **Scenario:** Migrate from a self-managed (BYO) Nginx Ingress Controller to the AKS-managed App Routing Add-On with zero downtime using parallel running.

---

## Why This Matters

The Kubernetes Steering Committee announced that the **standalone Nginx Ingress Controller will be retired in March 2026**. After that date, it receives no further updates — including security patches. Running it past end-of-life exposes your clusters to unpatched CVEs.

The **AKS App Routing Add-On** is a Microsoft-managed Nginx Ingress Controller that:
- Runs the **same Nginx binary** — your annotations and config carry over
- Uses a **different IngressClass** (`webapprouting.kubernetes.azure.com`) — enabling parallel running
- Is **supported by Microsoft until November 2026** — buying time to plan the next move
- Integrates natively with **Azure Key Vault** (TLS certs) and **Azure DNS** (automatic DNS records)

**This demo shows the complete migration path: install BYO → deploy app → enable add-on → parallel validate → cutover → decommission BYO.**

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        AKS Cluster                          │
│                                                             │
│  ┌──────────────────────┐    ┌───────────────────────────┐  │
│  │ ingress-nginx (BYO)  │    │ app-routing-system (Addon)│  │
│  │                      │    │                           │  │
│  │ IngressClass: nginx  │    │ IngressClass:             │  │
│  │ LB IP: 20.x.x.1     │    │ webapprouting.k8s.azure   │  │
│  │                      │    │ LB IP: 20.x.x.2          │  │
│  └──────────┬───────────┘    └─────────────┬─────────────┘  │
│             │                              │                │
│             └──────────┐  ┌────────────────┘                │
│                        ▼  ▼                                 │
│              ┌──────────────────┐                           │
│              │   myapp (ns)     │                           │
│              │                  │                           │
│              │  Deployment (x2) │                           │
│              │  Service (ClIP)  │                           │
│              └──────────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

Both controllers route to the **same backend service**. Each has its own LoadBalancer IP. You validate via the add-on IP, then cut DNS over — zero downtime.

---

## Prerequisites

| Component | Requirement |
|---|---|
| Azure CLI | `az` authenticated (`az login`) |
| kubectl | Connected to your AKS cluster |
| Helm | v3+ installed (`helm version`) |
| AKS Cluster | Running, with `--node-count 2` minimum |

---

## Files in This Demo

| File | Purpose |
|---|---|
| `app-deployment.yaml` | Sample app — Namespace + Deployment (2 replicas) + ClusterIP Service |
| `byo-nginx-values.yaml` | Helm values for installing BYO Nginx Ingress Controller |
| `ingress.yaml` | Ingress resource targeting BYO Nginx (`ingressClassName: nginx`) |
| `ingressaddon.yaml` | Ingress resource targeting App Routing (`ingressClassName: webapprouting.kubernetes.azure.com`) |
| `setup.ps1` | Full scripted walkthrough (run section-by-section for the demo) |
| `cleanup.ps1` | Tears down all demo resources |
| `notes.md` | Reference article on the migration approach |

---

## Demo Walkthrough — 12 Steps

### Step 0: Set Variables

```powershell
$RG_NAME  = "rg-approuting-demo"
$AKS_NAME = "aks-approuting-demo"
$LOCATION = "eastus2"
```

Update these to match your environment.

---

### Step 1: Connect to Your AKS Cluster

```powershell
az aks get-credentials --resource-group $RG_NAME --name $AKS_NAME --overwrite-existing
kubectl config current-context
```

**What to show:** Confirm the context is your AKS cluster.

---

### Step 2: Install BYO Nginx Ingress Controller

This simulates the "before" state — a self-managed Nginx Ingress Controller that is approaching end-of-life.

```powershell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx `
  --create-namespace `
  -f byo-nginx-values.yaml
```

Wait for it to be ready:

```powershell
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=120s

kubectl get svc -n ingress-nginx
```

**What to show:** The controller pod is running and has an external LoadBalancer IP.

---

### Step 3: Deploy the Sample Application

```powershell
kubectl apply -f app-deployment.yaml
```

This creates:
- `myapp` namespace
- Deployment with 2 replicas of the ASP.NET sample app (`mcr.microsoft.com/dotnet/samples:aspnetapp`)
- ClusterIP Service on port 80 → container port 8080

Wait for pods:

```powershell
kubectl wait --namespace myapp `
  --for=condition=ready pod `
  --selector=app=myapp `
  --timeout=120s

kubectl get pods -n myapp
kubectl get svc -n myapp
```

**What to show:** 2/2 pods running, service has endpoints.

---

### Step 4: Create BYO Nginx Ingress Resource

```powershell
kubectl apply -f ingress.yaml
```

This creates an Ingress with `ingressClassName: nginx`, routing `myapp.example.com` → `myapp` service.

Verify and test:

```powershell
kubectl get ingress -n myapp

# Get the BYO external IP
$BYO_IP = kubectl get svc ingress-nginx-controller -n ingress-nginx `
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Test the route
curl -s -o /dev/null -w "%{http_code}" -H "Host: myapp.example.com" http://$BYO_IP
```

**What to show:** HTTP 200 — traffic flows through BYO Nginx to the app. This is the baseline.

---

### Step 5: Show Current IngressClasses

```powershell
kubectl get ingressclass
```

**What to show:** Only `nginx` exists. There's one controller, one IngressClass.

> **Talking Point:** "This is what most clusters look like today — a single BYO Nginx controller. The Kubernetes project is retiring this in March 2026. Let's migrate to the AKS-managed alternative."

---

### Step 6: Enable the AKS App Routing Add-On ⭐

This is the key step. It installs the managed controller **alongside** the existing BYO controller.

```powershell
az aks approuting enable --resource-group $RG_NAME --name $AKS_NAME
```

Wait and verify:

```powershell
kubectl wait --namespace app-routing-system `
  --for=condition=ready pod `
  --selector=app=nginx `
  --timeout=120s

kubectl get pods -n app-routing-system
kubectl get svc -n app-routing-system
```

**What to show:**
- A new `app-routing-system` namespace appeared with controller pods
- A new `nginx` service with its own LoadBalancer IP
- The BYO controller in `ingress-nginx` is **completely untouched**

> **Talking Point:** "Notice: the existing controller didn't restart, didn't reconfigure, didn't lose its IP. The add-on deployed in its own namespace with its own IP. Both run independently."

---

### Step 7: Show IngressClasses — Parallel Running

```powershell
kubectl get ingressclass
```

**What to show:** Two IngressClasses now exist:

| IngressClass | Controller |
|---|---|
| `nginx` | BYO (ingress-nginx namespace) |
| `webapprouting.kubernetes.azure.com` | AKS Add-On (app-routing-system namespace) |

> **Talking Point:** "This is the magic of IngressClass-based routing. Each controller only watches Ingress resources that reference its class. They don't interfere with each other."

---

### Step 8: Create the App Routing Ingress (Parallel with BYO)

```powershell
kubectl apply -f ingressaddon.yaml
```

Now **both** Ingress resources exist in the `myapp` namespace, pointing to the same backend service:

```powershell
kubectl get ingress -n myapp
```

Expected output:
```
NAME                   CLASS                                HOSTS               ADDRESS       
myapp-ingress-byo      nginx                                myapp.example.com   20.x.x.1
myapp-ingress-addon    webapprouting.kubernetes.azure.com   myapp.example.com   20.x.x.2
```

Get both IPs:

```powershell
$BYO_IP = kubectl get svc ingress-nginx-controller -n ingress-nginx `
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$ADDON_IP = kubectl get svc nginx -n app-routing-system `
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

Write-Host "BYO Nginx IP:   $BYO_IP"
Write-Host "App Routing IP: $ADDON_IP"
```

> **Talking Point:** "Same app, same host, two controllers, two IPs. Production traffic still flows through BYO because DNS points to the BYO IP. We haven't touched anything."

---

### Step 9: Validate via the App Routing Add-On IP ✅

Test both routes to confirm they both serve the app:

```powershell
# Test via BYO
curl -s -o /dev/null -w "%{http_code}" -H "Host: myapp.example.com" http://$BYO_IP

# Test via App Routing add-on
curl -s -o /dev/null -w "%{http_code}" -H "Host: myapp.example.com" http://$ADDON_IP
```

**What to show:** Both return HTTP 200. The add-on routes traffic correctly.

> **Talking Point:** "Both return 200. In production, this is where you'd run your full test suite against the add-on IP — TLS, path routing, custom headers, rate limiting. If anything fails, production is unaffected because DNS still points to BYO."

---

### Step 10: Cutover — Remove the BYO Ingress

In production, you'd update DNS first (lower TTL to 60s ahead of time, then update the A record). For this demo, we just remove the BYO Ingress:

```powershell
kubectl delete ingress myapp-ingress-byo -n myapp
kubectl get ingress -n myapp
```

**What to show:** Only `myapp-ingress-addon` remains. All traffic now flows through the add-on.

---

### Step 11: Verify No Remaining BYO Ingress Resources

Before decommissioning the BYO controller, verify nothing else still references it:

```powershell
kubectl get ingress --all-namespaces `
  -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,CLASS:.spec.ingressClassName'
```

**What to show:** No Ingress resources with `ingressClassName: nginx` remain.

---

### Step 12: Decommission BYO Nginx Controller

```powershell
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx

# Verify only add-on IngressClass remains
kubectl get ingressclass
```

**What to show:** Only `webapprouting.kubernetes.azure.com` remains. The old LoadBalancer is released. Migration complete.

---

## Key Differences — BYO vs. App Routing Add-On

| Feature | BYO Nginx | App Routing Add-On |
|---|---|---|
| **Management** | Self-managed (you own upgrades, patches) | Microsoft-managed |
| **IngressClass** | `nginx` | `webapprouting.kubernetes.azure.com` |
| **Namespace** | `ingress-nginx` | `app-routing-system` |
| **TLS Certificates** | cert-manager / manual Secrets | cert-manager + **Azure Key Vault integration** |
| **DNS** | external-dns / manual | external-dns + **Azure DNS zone integration** |
| **Custom Nginx Config** | Full ConfigMap access | Restricted (managed by Azure) |
| **Annotations** | `nginx.ingress.kubernetes.io/*` | Same — compatible |
| **Support** | Community (retired March 2026) | Microsoft (until November 2026) |

---

## What Comes After November 2026?

The App Routing add-on buys time, but it's not the final destination. Plan for one of:

| Option | Technology | API | Status |
|---|---|---|---|
| **New App Routing Add-On** | Istio-based | Gateway API | Expected late 2026 |
| **App Gateway for Containers** | Envoy-based | Gateway API | GA now |
| **Third-party** | Traefik, Contour, etc. | Ingress or Gateway API | Varies |

**Migration tool:** Use [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway) to convert Ingress resources to Gateway API format.

**AGC Migration Utility:** Use [Application Gateway for Containers Migration Utility](https://github.com/Azure/Application-Gateway-for-Containers-Migration-Utility/releases) to migrate from AGIC/Nginx to AGC.

---

## Cleanup

```powershell
.\cleanup.ps1
```

Or manually:

```powershell
kubectl delete -f ingressaddon.yaml
kubectl delete -f app-deployment.yaml
az aks approuting disable --resource-group $RG_NAME --name $AKS_NAME
# (Optional) Delete the cluster
# az group delete --name $RG_NAME --yes --no-wait
```

---

## Talking Points for the Demo

1. **"Zero downtime"** — Both controllers run simultaneously. DNS cutover is the only traffic-affecting step, and TTL management makes it seamless.

2. **"Same Nginx, different management"** — The add-on runs the same Nginx binary. Your annotations carry over. This isn't a rewrite; it's a management plane change.

3. **"This buys time, not infinity"** — The add-on is supported until November 2026. Use that time to evaluate Gateway API + Istio or App Gateway for Containers.

4. **"The retirement is real"** — The Kubernetes Steering Committee announced the standalone Nginx Ingress Controller retirement for March 2026. No more security patches after that date.

5. **"IngressClass is the key"** — The parallel running pattern works because Kubernetes routes based on IngressClass. Each controller only processes its own resources.
