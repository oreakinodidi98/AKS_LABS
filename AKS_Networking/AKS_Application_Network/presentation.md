# Azure Kubernetes Application Network – Presentation Deck

> **Prerequisites:** 2 AKS clusters, 1 Azure Monitor Workspace
> **Hook:** *"A Network that Grows with You – Without the Growing Pains"*

---

## Slide 1: What is Application Network?

> **Slogan:** *"One network. Three superpowers. Zero growing pains."*

### Slide Content

- **L7, one-stop shop** for all your Kubernetes networking needs
- A network that grows with you — Security, Connectivity, Observability
- Massive amount of functionality available **out of the box** the moment your cluster joins Application Network

| Secure | Connect | Observe |
|--------|---------|---------|
| mTLS encryption by default | Gateway API routing (East-West) | Full L4 telemetry with Managed Prometheus |
| TLS-based Authorization Policy (L4 & L7) | Fine-tuned load balancing | HTTP metrics: latency, failure rates |
| Azure Key Vault-backed identities, auto-rotated every 24 hrs | gRPC, inference routing, weighted load balancing | Trace span collection & audit logs (L4 + L7) |

- **Secure:** Encryption and Authorization
  - mTLS for all traffic — no code changes, no labelling, no restarting workloads
  - TLS-based Authorization Policy for all traffic, with L4 and L7 attributes
  - Azure Key Vault-based identities automatically distributed and rotated for defence-in-depth
- **Connect:** Routing and Load Balancing
  - Fine-tuned load balancing — request-based, least-conn, round-robin and more
  - Gateway API routing for internal traffic, with hostname, path, headers, and more
  - Protocol support for gRPC, inference routing, and more coming soon!
  - Built on Gateway API + Istio Ambient Mode for familiar, consistent controls
- **Observe:** Metrics, Traces, and Logs
  - Full HTTP telemetry with Managed Prometheus, Kiali integration, and support for bring-your-own Prometheus
  - Automatic trace span collection to analyse traffic, isolate outliers, and drive debugging
  - Audit log collection for compliance and troubleshooting

### Speaker Notes

Alright so what is Application Network? Think of it as the L7, one-stop shop for all of your Kubernetes networking needs. The whole idea is that the network grows with you.

The features fall along three lines — Security, Connectivity, and Observability. And there's a huge amount of functionality available out of the box by default when your cluster is on Application Network.

**Security** — by default, all of your traffic in the cluster is encrypted using mTLS — mutual TLS. We're using cryptographic identities on both the server side and client side. Those identities are rotated once every 24 hours, with the root of the identity stored in Azure Key Vault on the customer's behalf. So no need for management or manual rotation — it's all managed automatically by Application Network. And when a customer is ready to leverage those TLS identities to write authorization policies, it's a simple API call.

**Connectivity** — most of the connectivity functionality requires configuration. It requires users to tell us what modifications they want. We also use Kubernetes Gateway API to let users define connectivity standards for their in-cluster traffic — essentially East-West traffic. Traffic that's staying in the cluster or in a multi-cluster environment, not from outside the Application Network environment. App routing is automatically included, so users can get traffic into the cluster. You can fine-tune load balancing, you've got gRPC support, route based on path and headers with weighted load balancing. And because it's Gateway API based, it makes things easier — it's all standard APIs, so users don't need to re-learn custom APIs. It uses standard Kubernetes APIs that should already be familiar to them for all their connectivity needs.

**Observability** — right out of the box you get full Layer 4 telemetry with Managed Prometheus. This gives you information like which apps are talking to other apps in the cluster, total throughput, TCP latency. With more configuration you can get HTTP metrics like request latency and request failure rates. There's also Layer 7 metrics like trace span collection and audit log collection for both L4 and L7.

**Important framing note** — under the hood, Application Network is a service mesh, but we are not positioning it that way to users. We're leading with use cases. We want to focus on what your application needs, without having to educate users about a whole variety of CNCF vocabulary. The reason for this is the history of service mesh — the complaints about complexity, high overhead in terms of compute, and total cost of ownership.

---

## Slide 2: Why Now? — Istio Utilization on Azure

> **Hook:** *"The numbers speak for themselves."*

### Slide Content

> **Visual idea:** Infographic/diagram with the three stats below as large callout numbers, each with an icon (shield for CVE, clock for unsupported, empty circle for no mesh)

- **85%** of open-source Istio users on Azure are vulnerable to **known CVEs** — already documented, exposed in the wild, and still unpatched
- **44%** of Istio users are on **unsupported versions** — running a version more than 7 months old
- **60%** of AKS clusters have **no service mesh installed** — meaning no controls for L7 authorization or L7 traffic routing

### Speaker Notes

These are based on Azure's own data, and honestly the picture could be better.

85% of open-source Istio users on Azure are vulnerable to known CVEs. These are already documented, already exposed in the wild — and yet still vulnerable. 44% of Istio users are on unsupported versions, running something more than 7 months old. And 60% of AKS clusters have no service mesh installed at all. So no controls for L7 authorization or L7 traffic routing.

These numbers are exactly why we're positioning Application Network the way we are. Customers need this, and they need it to be simple.

---

## Slide 3: Immediate Benefits — What You Get on Day One

> **Slogan:** *"Join the network. Get the benefits. That's it."*

### Slide Content

- Azure Key Vault Secured **Root of Trust** for all workloads
- **Zero-trust mTLS encryption** — no labels, no restarts
- **Observability** with Managed Prometheus and Kiali
- Upgrades handled **automatically** out of the box
- CVEs patched within **72 hours**
- Always able to **rollback**
- Microsoft's **24/7 product support**

### Speaker Notes

So the moment you join, you get all of these immediate benefits. Ranging from an Azure Key Vault secured root of trust for all workloads — you've got mTLS encryption applied with zero trust on all of your traffic immediately. No labelling, no restarting any pods.

You also get out-of-the-box observability data if your cluster is already onboarded to Managed Prometheus, and you can run Kiali to show your graph of service dependency and current health.

But most importantly — it's backed by Microsoft's 24/7 product support guarantee. Customers are not on their own.

---

## Slide 4: Onboarding — Demo

> **Hook:** *"One command to create the world's most powerful cloud-native network."*

### Slide Content

> **Visual idea:** Terminal recording / live demo showing the commands below running in sequence. Keep it minimal — just the CLI and the output.

**Onboarding in 2 steps:**

1. Create your Application Network
2. Add your member cluster

That's all. No helm charts. No labelling. Nothing else.

```powershell
# Create resource groups
az group create --name $AKS_RG --location $LOCATION
az group create --name $APPNET_RG --location $LOCATION

# Create AKS cluster
az aks create --name $CLUSTER_NAME --resource-group $AKS_RG \
  --enable-oidc-issuer --enable-aad

# Create Application Network
az appnet create --resource-group $APPNET_RG --name $APPNET_NAME \
  --location $LOCATION --identity-type SystemAssigned

# Verify Application Network
az appnet show --resource-group $APPNET_RG --name $APPNET_NAME

# Join member cluster
az appnet member join --resource-group $APPNET_RG \
  --appnet-name $APPNET_NAME \
  --member-name $APPNET_MEMBER_NAME \
  --member-resource-id /subscriptions/$SUBSCRIPTION/resourcegroups/$AKS_RG/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME \
  --upgrade-mode SelfManaged

# Verify member
az appnet member show --resource-group $APPNET_RG \
  --appnet-name $APPNET_NAME \
  --member-name $APPNET_MEMBER_NAME
```

### Speaker Notes

So here's the experience — we create our Application Network. One command. One command to add your member cluster. That's all. Very simple experience, no helm charts, no labelling, nothing along those lines.

*(If doing live demo, run through the commands above. Otherwise play the demo video.)*

---

## Slide 5: Architecture — Under the Hood

> **Slogan:** *"Two components. Full control. Zero sidecar pain."*

### Slide Content

> **Visual idea:** Architecture diagram showing a node with Ztunnel running per-node at L4, and Waypoint proxies as independent deployments at L7. Arrows showing traffic flow through Ztunnel for L4 and optionally through Waypoint for L7. Include labels for "per-node" and "per-service/namespace".

**Built on Istio Ambient Mode — two components:**

| Component | Layer | Deployment | Purpose |
|-----------|-------|------------|---------|
| **Ztunnel** | L4 | Per-node proxy | Security guarantees — mTLS, encryption. One instance per node, safe for all workloads |
| **Waypoint** | L7 | Independent deployment (not a sidecar) | Full L7 control — routing, telemetry, authorization. Scales independently, upgrades without touching apps |

**Upgrade & Maintenance:**

- When a new version of Istio is available, App Network upgrades automatically — guaranteeing no disruption to traffic
- Controls to opt in to different **release channels**
- **Self-managed mode** available — define maintenance windows, enter a slower release channel, or rollback on individual waypoints/ingress gateways (not the whole cluster)
- CVEs patched within **72 hours** — customers don't need to do anything, as long as maintenance configuration allows it

### Speaker Notes

Now let's focus on the architecture — how this all happens under the hood. As you know, it's based on Istio Ambient Mode. There are two components.

First — a per-node Layer 4 proxy called **Ztunnel**. It provides all the security guarantees you want right out the door, and nothing else. This makes it super simple, very focused on a limited use case. It's a proxy that's safe to run for all workloads on the node in just one instance. The same cannot be said for an Envoy proxy.

For Layer 7, we have an Envoy proxy called the **Waypoint**. The Waypoint looks just like a sidecar, but runs as its own deployment instead. Because it's not a sidecar, we avoid the complexity that sidecars introduce — like restarting pods for upgrades, annotations on pods for CPU. Since it's an independent deployment, it can scale up and down, upgrade without touching any application. You declare a Waypoint for a service or a namespace, and all the pods behind that group get full L7 functionality.

When a new version of Istio is available, App Network will upgrade — guaranteeing no disruption to traffic during the process. It also comes with controls to let users opt in to different release channels. There's a self-managed mode where users can define maintenance configuration, set their desired frequency, enter a slower release channel, or rollback if something breaks — on an individual waypoint or ingress gateway, rather than the whole App Network on the cluster level.

And for CVEs — customers don't need to do anything. It'll be patched within 72 hours, as long as the maintenance configuration allows it.

---

## Slide 6: Multi-Cluster — Demo

> **Hook:** *"Add a cluster. Done. Microsoft handles the rest."*

### Slide Content

> **Visual idea:** Terminal demo or video showing Cluster 2 being joined. Split screen — left side shows the CLI, right side shows a topology diagram updating in real time.

**Building on the previous demo:**

- Cluster 1 is already a member of Application Network
- Now we add Cluster 2 as a second member

```powershell
az appnet member join --resource-group $APPNET_RG \
  --appnet-name $APPNET_NAME \
  --member-name $APPNET_MEMBER_NAME2 \
  --member-resource-id /subscriptions/$SUBSCRIPTION/resourcegroups/$AKS_RG/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME \
  --upgrade-mode SelfManaged
```

### Speaker Notes

This demo builds on having Cluster 1 already added to Application Network as a current member. Now we add a second member — Cluster 2. One command, same experience.

*(Play demo video or run live.)*

---

## Slide 7: Multi-Cluster Capabilities

> **Slogan:** *"Any cluster. Any subscription. Any region. One network."*

### Slide Content

> **Visual idea:** Diagram showing two (or more) clusters connected through Application Network, with encrypted tunnels between them. Arrows showing round-robin traffic distribution across clusters. Labels for "different subscription", "different region".

- Route cross-cluster traffic with **end-to-end mTLS** encryption and authentication
- TLS identity-based authorization for both **L4 and L7** across up to **1,000 clusters**
- Multi-cluster ingress control with **App Routing + Fleet** using Traffic Manager
- Any service marked as **global** becomes accessible from any other cluster in the Application Network
- Clusters can be from different **subscriptions, regions** — no manual operations required
- Application Network **round-robins** between clusters by default — users can set custom standards
- **Fine-grain control** to detect advanced failure scenarios via Application Network APIs
- **Proactive failover** to remote clusters for partial failure scenarios

### Speaker Notes

Microsoft takes care of the trust bundles and connectivity between the two clusters under the hood. In multi-cluster mode, App Network takes any service marked as global and allows traffic from any other cluster in the Application Network. That cluster could be from a different subscription, a different region — doesn't matter. No manual operations.

If a service is available in multiple clusters, Application Network will round-robin between them by default. Users can set their own standards if they need to. There's also fine-grain control to detect advanced failure scenarios using Application Network APIs, and it can proactively failover to remote clusters for partial failure scenarios.

---

## Slide 8: Multi-Cluster Benefits

> **Slogan:** *"Resilient across zones, regions, and failures — with one pane of glass."*

### Slide Content

> **Visual idea:** Icon grid — each benefit gets an icon. Shield for resilience, bypass arrow for partial failures, globe for global ingress, eye for observability, lock for policy enforcement. Consider a map visual showing multiple Azure regions connected.

- **Resilient** to zonal + regional outages
- **Bypasses partial failures** — proactive failover to healthy clusters
- **Global ingress control** — integrating with AKS Fleet
- **Single pane of glass observability** — visibility across all clusters in the mesh
- **Global and local policy enforcement** — authorization rules apply to both cross-cluster and local traffic
- Integrates with open-source tools like **Flagger** and **Argo Rollouts**

### Speaker Notes

You get complete resilience to zonal and regional outages — as long as those regions have all the services they're trying to call. We're also integrating with AKS Fleet for global ingress control.

Authorization rules apply to both cross-cluster traffic and local cluster traffic, so everything follows your security rules. Observability has visibility to all clusters in the mesh — a single pane of glass.

And it integrates with open-source tools like Flagger and Argo Rollouts for progressive delivery scenarios.

---

## Slide 9: Application Network Basics — Demo

> **Hook:** *"Onboard. Deploy. Authorize. All in minutes."*

### Slide Content

> **Visual idea:** Three-panel walkthrough — Panel 1: Terminal showing cluster onboarding. Panel 2: Bookinfo app running in browser. Panel 3: Browser showing blocked details/reviews after authorization policy applied. Before/after screenshot side-by-side.

**Demo Flow:**

1. **Onboard** — Create Application Network and join cluster
2. **Deploy Sample Application** — Istio Bookinfo (multi-language microservices)
3. **Apply Authorization Policy** — Block traffic using mTLS identity (not IPs)

**Bookinfo Architecture (4 microservices, 3 languages, zero code changes):**

| Service | Language | Role |
|---------|----------|------|
| **productpage** | Python | Front-end — calls details + reviews |
| **details** | Ruby | Book information |
| **reviews** | Java | Book reviews — calls ratings |
| **ratings** | Node.js | Star ratings |

**Key onboarding flags:**

```powershell
az appnet member join --resource-group $APPNET_RG \
  --appnet-name $APPNET_NAME \
  --member-name $APPNET_MEMBER_NAME \
  --member-resource-id /subscriptions/$SUBSCRIPTION/resourcegroups/$AKS_RG/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME \
  --upgrade-mode FullyManaged \
  --east-west-gateway External
```

- `--upgrade-mode FullyManaged` — Microsoft manages all upgrades
- `--east-west-gateway External` — Public IPs for cross-cluster traffic (end-to-end mTLS encrypted)
- For private networking: use `--east-west-gateway Internal` (requires VNet peering / VPN / Azure WAN)
- Fully managed private transit network is on the roadmap

**Important:** Label the namespace for ambient mode:

```powershell
kubectl label ns default istio.io/dataplane-mode=ambient
```

**Deploy the sample app:**

```powershell
kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/bookinfo/platform/kube/bookinfo.yaml
```

**Expose with Gateway API:**

```powershell
kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
kubectl get gateway
kubectl get svc
# Access at http://<ExternalIP>/productpage
```

**Block traffic with Authorization Policy:**

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "details-viewer"
  namespace: default
spec:
  selector:
    matchLabels:
      app: details
  action: DENY
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
```

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "reviews-viewer"
  namespace: default
spec:
  selector:
    matchLabels:
      app: reviews
  action: DENY
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
```

**The critical difference vs Network Policy:**

| Network Policy | Application Network Authorization |
|----------------|-----------------------------------|
| Operates on **IP addresses** | Operates on **mTLS identity** |
| IP can change, be spoofed | Identity follows the workload everywhere |
| Single cluster scope | Works **cross-cluster** and outside the mesh |

### Speaker Notes

This demo walks through onboarding an App Network, adding a cluster, deploying a sample app, and then using authorization policy to block traffic — showing App Network's configuration capabilities in action.

During the process, you can create a cluster with any of our networking properties — Cilium CNI or any other supported CNI. You just need to enable AAD and OIDC to allow App Network to connect to it.

For the `az appnet create` command, behind the scenes we're creating all of the records needed to represent the App Network. No clusters are added yet — we then need to add the cluster we just created.

When joining the cluster, the two important flags are `--upgrade-mode FullyManaged` and `--east-west-gateway External`. This is specifically for public east-west gateways and fully managed upgrades. The east-west gateway allows connectivity between clusters, and we have two ways for users to run them — internal or external mode. In external mode, the east-west gateways get public IPs, so cross-cluster traffic goes over the public internet. But the cross-cluster traffic is end-to-end mTLS encrypted, so it's safe — and it means we don't need VNet peering. If you have internal policies preventing public IP addresses, you can use east-west internal, but that means you'd be responsible for getting those gateways connected using VNet peering, VPN, Azure WAN, etc. A fully managed private transit network is on the roadmap.

Under the hood, App Network gets installed to the cluster along with a fully managed out-of-cluster control plane. We create an `istio-system` namespace with resources for the control plane components that run on Azure managed infrastructure. However, the data plane components run in the cluster — including Ztunnel as a DaemonSet running one per node, applying mTLS encryption to all traffic. By default we don't start with any gateways, but any gateways we define will deploy Envoy for them.

Important — if there's a regional failure, it only affects that region. Don't forget to label the default namespace: `kubectl label ns default istio.io/dataplane-mode=ambient`.

The Bookinfo application is made up of several microservices using different programming languages — to show how the service mesh doesn't require any code changes or integrations. We've got a front-end product page showing book information pulled from a Ruby service, reviews stored in Java for text and Node.js for star ratings.

We spin up an ingress gateway in front of the product page to provide public access, then start modifying. We apply the authorization policy to block product page from contacting details and reviews. The policy says: for the details/reviews app, any inbound traffic should be denied if it's coming from the product page identity.

When we refresh the page, we shouldn't be able to get details or reviews — traffic is blocked. You might be thinking this can be done with any standard network policy. But here's the critical difference — with network policy you're operating on IP addresses to block traffic. With Application Network using mTLS, you've got a client identity and server identity across every connection, which are referenced in the authorization policy. So any identity called `bookinfo-productpage` from the default namespace that tries to connect to the details service gets blocked. It doesn't matter what IP address the call is coming from — it could be from multi-cluster or outside the mesh. As long as that identity is prevented, the traffic will be blocked.

Delete the policy and traffic flows again.

---

## Slide 10: Application Network Observability — Demo

> **Hook:** *"See everything. From every node. Across every cluster."*

### Slide Content

> **Visual idea:** Screenshot of Azure Monitor workspace with PromQL query results. Side-by-side of Ztunnel metrics and Waypoint request metrics. Optionally show a Kiali service graph with traffic flowing.

**What's available:**

- Comprehensive **data plane metrics** for workloads and App Network components (Ztunnel, Istio CNI, Waypoint)
- Control plane metrics are not currently supported
- Metrics cover both workload/application telemetry and the `appnet-system` namespace

**Setup steps:**

1. Ensure Prometheus metrics collection is enabled on the member cluster (already done via `--azure-monitor-workspace-resource-id` at cluster creation)
2. Apply the ConfigMap to enable scraping of Ztunnel, Istio CNI, Waypoint, and your workloads
3. Add annotations to the application pods you want to scrape
4. Query metrics in Azure Monitor workspace using PromQL

**Step 1 — Apply ConfigMap for metric scraping:**

```powershell
@"
kind: ConfigMap
apiVersion: v1
metadata:
  name: ama-metrics-settings-configmap
  namespace: kube-system
data:
  schema-version: v1
  config-version: ver1
  prometheus-collector-settings: |-
    cluster_alias = ""
    https_config = true
  default-scrape-settings-enabled: |-
    ztunnel = true
    istio-cni = true
  pod-annotation-based-scraping: |-
    podannotationnamespaceregex = ".*"
  default-targets-metrics-keep-list: |-
    ztunnel = ""
    istio-cni = ""
    minimalingestionprofile = true
  default-targets-scrape-interval-settings: |-
    ztunnel = "30s"
    istio-cni = "30s"
    podannotations = "30s"
  debug-mode: |-
    enabled = false
"@ | kubectl apply -f -
```

**Step 2 — Annotate application pods for scraping:**

```powershell
kubectl label pod <pod-name> prometheus.io/scrape=true
kubectl label pod <pod-name> prometheus.io/port=15020
kubectl label pod <pod-name> prometheus.io/path=/metrics
```

> These annotations tell Prometheus to scrape the pod at `<pod IP>:15020/metrics`

| Annotation | Required | Default | Purpose |
|-----------|----------|---------|---------|
| `prometheus.io/scrape` | **Yes** | — | Enables scraping |
| `prometheus.io/path` | No | `/metrics` | Metrics endpoint path |
| `prometheus.io/port` | Recommended | Container port | Port where metrics are hosted |

**Step 3 — Query in Azure Monitor:**

| Component | Example PromQL Query |
|-----------|---------------------|
| **Ztunnel** | `istio_xds_connection_terminations_total` |
| **Waypoint** | `istio_requests_total` |
| **Istio CNI** | `istio_cni_install_ready` |

Navigate to your Azure Monitor workspace in the Azure portal to query these metrics using PromQL.

### Speaker Notes

Our next demo focuses on Application Network observability. App Network provides comprehensive metrics for your workloads and the data plane components — Ztunnel, Istio CNI, and Waypoint — through Azure Monitor metrics.

Control plane metrics aren't currently supported, but data plane metrics are available and you can use them to monitor the health and performance of your workloads and App Network components. Data plane metrics include metrics from your workloads and applications, plus the `appnet-system` namespace.

We've already deployed our cluster, and to configure data plane metrics we use an existing Azure Monitor workspace. We've already enabled Prometheus metrics collection on the member cluster using the `az aks update` command with the `--azure-monitor-workspace-resource-id` parameter.

First, we need to apply a ConfigMap in the `kube-system` namespace to enable scraping of Ztunnel, Istio CNI, Waypoint, and our workloads. Then we add annotations to the pods we want to scrape. The `prometheus.io/scrape=true` annotation is required. The path defaults to `/metrics` and the port is optional but recommended to set explicitly for reliable scraping.

Once that's in place, navigate to your Azure Monitor workspace in the Azure portal to query the metrics using PromQL. For example: `istio_xds_connection_terminations_total` for Ztunnel, `istio_requests_total` for Waypoint, and `istio_cni_install_ready` for Istio CNI.

---

## Slide 11: Getting Started

> **Hook:** *"You're closer than you think."*

### Slide Content

> **Visual idea:** A simple numbered path graphic — 3 stepping stones with icons: cluster → network → member. Keep it clean. Optionally add a QR code to the docs link at the bottom.

**What you need:**

- An AKS cluster with **AAD** and **OIDC Issuer** enabled
- That's the only hard requirement — any supported CNI, any region

**Three commands to get started:**

```powershell
# 1. Create your Application Network
az appnet create --resource-group $APPNET_RG --name $APPNET_NAME \
  --location $LOCATION --identity-type SystemAssigned

# 2. Join your cluster
az appnet member join --resource-group $APPNET_RG \
  --appnet-name $APPNET_NAME \
  --member-name $APPNET_MEMBER_NAME \
  --member-resource-id <cluster-resource-id> \
  --upgrade-mode FullyManaged \
  --east-west-gateway External

# 3. Label your namespace
kubectl label ns default istio.io/dataplane-mode=ambient
```

**Resources:**

| Resource | Link |
|----------|------|
| Get Started Guide | [learn.microsoft.com/azure/application-network/get-started](https://learn.microsoft.com/en-us/azure/application-network/get-started) |
| Bookinfo Sample App | [istio.io/docs/examples/bookinfo](https://istio.io/latest/docs/examples/bookinfo/) |
| Gateway API Docs | [gateway-api.sigs.k8s.io](https://gateway-api.sigs.k8s.io/) |

### Speaker Notes

So if you're thinking about trying this out — you're closer than you think. The only hard requirement is an AKS cluster with AAD and OIDC Issuer enabled. Any supported CNI works, any region works. You don't need Cilium, you don't need a specific node pool configuration — just those two flags at cluster creation.

From there it's three commands. Create the Application Network, join your cluster, label your namespace. That's it. You've got mTLS encryption, observability data flowing, and a foundation for authorization policies and cross-cluster connectivity whenever you're ready to configure them.

The Get Started guide on Microsoft Learn walks you through the full experience step by step. The Bookinfo sample app is great for testing — it gives you a multi-service application to play with, so you can see authorization policies and traffic routing in action without needing to bring your own workload.

---

## Slide 12: Closeout — Why Application Network

> **Slogan:** *"Stop managing the mesh. Start managing your applications."*

### Slide Content

> **Visual idea:** Summary slide with three columns — Secure, Connect, Observe — each with 2–3 key takeaways. A bold closing statement at the bottom. Consider a before/after visual: "Before: helm charts, CVEs, manual upgrades, IP-based rules" → "After: one command, auto-patched, identity-based, cross-cluster."

**What we covered today:**

| Secure | Connect | Observe |
|--------|---------|---------|
| mTLS encryption — zero config | Gateway API routing — East-West & Ingress | Data plane metrics with Managed Prometheus |
| Identity-based authorization — not IPs | Multi-cluster — up to 1,000 clusters | PromQL queries for Ztunnel, Waypoint, Istio CNI |
| CVEs patched within 72 hours | Proactive failover & round-robin | Single pane of glass across all clusters |

**The bottom line:**

- No helm charts. No manual upgrades. No sidecar overhead
- Microsoft manages the control plane, upgrades, and CVE patching
- You focus on your workloads — Application Network handles the rest
- Production-ready L7 networking in **minutes, not months**

### Speaker Notes

So let's bring it all together. We started with what Application Network is — the L7 one-stop shop for Kubernetes networking. Security, connectivity, observability — all out of the box.

We showed you how simple onboarding is — one command to create, one command to join. No helm charts, no complex configuration. You get mTLS encryption, managed identities backed by Key Vault, and automatic upgrades from the moment your cluster joins.

We walked through the architecture — Ztunnel at L4 for per-node security, Waypoint at L7 for routing and authorization. No sidecars, no pod restarts. And we showed you multi-cluster — adding a second cluster with one command and getting cross-cluster traffic, global services, and proactive failover.

In the demos, we deployed a real application, applied authorization policies using mTLS identity instead of IP addresses, and set up observability with Managed Prometheus — all in minutes.

The takeaway is simple. This is production-ready L7 networking that doesn't require you to become a service mesh expert. Microsoft handles the hard parts — upgrades, CVE patching, control plane management. You focus on your applications.

If you've been hesitant about service mesh because of complexity or overhead — that's exactly why we built this. Application Network removes those barriers. Try it out, and if you have questions, reach out — we're here to help.

---

## Reference

- [Get Started with Azure Application Network](https://learn.microsoft.com/en-us/azure/application-network/get-started)
- [Bookinfo Sample Application](https://istio.io/latest/docs/examples/bookinfo/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
