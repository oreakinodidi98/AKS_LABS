# Azure Kubernetes Application Network for AKS

## Demo

Run script . Need 2 clusters and 1 Azure Monitor Workspace

## Azure Kubernetes Application Network

### Notes 1

- What: L7 , one stop shop for all of your needs in kubernetes networking
- Idea is network grows with you
- A Network that Grows with you – Without the Growing Pains
- Features fall along 3 lines, Security, Connectivity, Obserbility
- Huge amount of functunality that is available out of the box by defult when you have a cluster on Application network
**security**: by default all of your taffic in the cluster is encrypted using mTLS (mutual TLS) . Using crytographic identities on the server side and client side. The identities are rotated once ever 24 hours. With the root of the identity stored in azure key vault on the customers behalf. so no need for managment or manual rotation as its all managed automatically by Application Network
- Also when customer is ready to leverave TLS identities to write authorization policies its a simple API call.
**Connectivity**: most of the functunality requires configuration. Requires users to tell what modifications to connectivity they want. Also uses Kubernetes Gateway API to allow users to define connectivity standards for their in cluster traffic. Essentially East - West traffic. Traffic thats staying in the cluster or multi cluster enviroment, so not from outside the Application Network enviroment 
- App routing is automatically included allowing users to get traffic into cluster
- You can Fine tune load balancing
- Have gRPC support
- route based of path and headers with weighted load balancing
- Because it is gateway API based, this makes it easier for users. Its all standard APIs, so users dont need to re-learn custom APIs as it uses standrd Kubernetes APIs that should be familiar to them for all their connectivity needs 
**observability**: In terms of observability, right out of the box you get full layer 4 telemetry with managed promethoeus
- This provides information like which Apps are talking to other apps in the cluster
- Totall throughput or TCP latency
- With more configuration yo can get HTTP metrics like request latency, request failure rates
- Also has Layer 7 metrics like trace span collection and audit log collection for both layer 4 and layer 7
**important** to know under the hood application network is a service mesh but we are not positioning it like this to uers. We are leading with Use cases as seen on the slide. We want to focus on what your application needs, withouht having to educate users about a whole variety of CNCF vocabullary
Reason: history of service mesh and complaints about complexity, high overhead in terms of compute and total cost of ownership

### Slide 1

- Secure: Encryption and Authorization
  - mTLS for all traffic no code changes, no labelling, no restarting workloads
  - TLS-based Authorization Policy for all traffic, with L4 and L7 attributes 
  - Azure Key Vault based Identities automatically distributed and rotated for defence-in-depth
- Connect: Routing and Load Balancing
  - Fine-Tuned Load Balancing request-based, leastconn, round-robin and more
  - Gateway API routing for internal traffic, with hostname, path, headers, and more
  - Protocol Support for gRPC, inference routing, and more coming soon!
  - Built on Gateway API + Istio Ambient Mode for familiar, consistent controls
- Observe: Metrics, Traces, and Logs
  - Full HTTP Telemetry with Managed Prometheus with Kiali integration and support for bring-your own Prometheus 
  - Automatic Trace Span Collection to analyse traffic, isolate outliers, and drive debugging
  - Audit Log Collection for compliance and troubleshooting

### Notes 2

- Based of Azure results Picture could be better
- 85% of Open source istio users on azure are vulnerable to lnown CVE. These are already documented, and exposed in the wild but yet still vulnerable.
- 44% of istio users are on unsupported versions. using a version more than 7 months old
- 60% of AKS clusters have no service mesh installed. So no controlls for L7 authorization or L7 traffic routing
- These numbers contribute to why we are posioning App net

### Slide 2: Istio utilization on Azure

- includes diagram with facts

### notes 4

- We create our Application network -> One command to create the world’s most powerful cloud native network
- One command to add your member cluster (AKS cluster)
- That’s all. 
- Very simple experience, no helm charts or labelling or naything along those lines

if you want to do live run 
az group create --name $AKS_RG --location $LOCATION
az aks create --name $CLUSTER_NAME --resource-group $AKS_RG --enable-oidc-issuer --enable-aad
az group create --name $APPNET_RG --location $LOCATION
az appnet create --resource-group $APPNET_RG --name $APPNET_NAME --location $LOCATION  --identity-type SystemAssigned
az appnet show --resource-group $APPNET_RG --name $APPNET_NAME
az appnet member join --resource-group $APPNET_RG --appnet-name $APPNET_NAME --member-name $APPNET_MEMBER_NAME --member-resource-id /subscriptions/$SUBSCRIPTION/resourcegroups/$AKS_RG/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME --upgrade-mode SelfManaged
az appnet member show --resource-group $APPNET_RG --appnet-name $APPNET_NAME --member-name $APPNET_MEMBER_NAME

### slide 4 : Demo - onboarding App NEt

- include demo video

### notes 3

- You get all these immediate benefits 
- ranging from an azure key vault Secured Root of Trust for all Workloads
- you have mTLS Encryption applied with zero trust on all of your traffic immediatley. With no labelling or restarting of any pods
- Out of the box Observability data if cluster is already on boarderd to managed prometheous and can run Kiali to show your graph of service dependency and current health
- But must importantly backed by microsoft 24/7 product support guarantee. Customeres are not on their own.

### slides 3: immediate benefits

- AKV Secured Root of Trust for all Workloads
- Zero-Trust mTLS Encryption – no labels, no restarts
- Observability with Managed Prometheus and Kiali
- Upgrades automatically out of the box
- CVEs Patched within 72 hours
- Always Able to Rollback
- Microsoft’s 24/7 Product Support

### notes 5

- Focusing on architecture of how this all happens under the hood
- as you know its based of Istio ambient
- 2 components
- A per node layer 4 proxy called Ztunnel
- provides all the security guarantess you want out the door and nothing else
- Making it super simple and very focused on a limited use case
- Making it a proxy that is safe to run for all workloads on the node in just one instance
- Same cannot be said for an envoy proxy
- In terms of layer 7 we have an Envoy proxy called the Waypoint
- Waypoint looks just like a side car, but runs as its own deployment instead of like a sidecar
- Because its not a side car we avoid complexity introduces by sidecar such as restarting pods for upgrades, annotations on pods for CPU. And as it is an independent deployment can scale up and down, upgrade withouth touching any application.
- Allowing you to declare a Waypoint for a service or the service namespace if you want layer 7 controll/tellemetry/security. Affecing all the pods behind that group will get full layer 7 functionality
- When new version of Istio is availble , App net will upgrade guranteeing no distruption to traffic during process.
- Also comes with controlls to allow users to opt in to different release channels
- Their is also a self managed mode for users to manage upgrades -> where they can define maintence configuration to desired frequency and enter a slower release channel or rollback if broken on an individual waypoint or ingress gateway rather than appnet as a whole on the cluster level
- customers dont need to do anything to patch a CVE. This will be pathced withing 72 hours as long as  maintence configuration allows that

### slides 5: Architecture

will be picture of architeture

### notes 6

- Demo builds up on having Cluster 1 added to Application Network and current member
- Then we add a second member -> Member cluster-2


### slides 6: Demo App network Multi-cluster

- Play video of demo
- Essentially following command:
- az appnet member join --resource-group $APPNET_RG --appnet-name $APPNET_NAME --member-name $APPNET_MEMBER_NAME2 --member-resource-id /subscriptions/$SUBSCRIPTION/resourcegroups/$AKS_RG/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME --upgrade-mode SelfManaged

### notes 7

- Microsoft takes care of under the hood trust bundles and connectivity between the 2 clusters
- In a multi cluster mode AppNet takes any service marked as global and allows traffic from any other cluster in Application network
- Cluster could be from a different subscribtion,region etc..
- No manual operations
- If service is available in multiple clusters Application Network will round robin between those clusters . User can set standards if needed
- fine grain controll to detect advanced failure scenarios using Application Network APIs
- proactively failover to remote clusters for partial failure scenarios

### slides 7 : Multi cluster 

- Diagram of Multi cluster
- Route cross-cluster traffic with end-to-end mTLS encryption and authentication. 
- TLS identity-based authorization for both L4 and L7 across up to 1000 clusters.
- Multi-Cluster Ingress control w/ App Routing + Fleet using Traffic Manager

### notes 7.5

- Completelet resilence to zonal and regional outages
- As long as those regions have all the services they are trying to call
- Also integrating with AKS fleet for global ingress controll
- Authorization rules apply to cross cluster traffic and local closter traffic to make sure everything follows your security rules
- Observability has visibility to all clusters in the mesh
- integrates with open source tools like flagger and argo rollouts

### slides 7.5 Benefits

- Resilient to Zonal + Regional Outages
- Bypasses Partial Failures
- Global Ingress Control
- Single Pane of Glass Observability
- Global and Local Policy Enforcement

### notes 8

- Demo to show how to onboard an AppNet and adding a cluster
- Then install Istio Bookinfo sample application to run out tests again and make sure its accessible publicy
- Then use Authorization policy to block traffic and observe from the front end, showing Appnet configiuration capabilities
- Will discuss how it will differ from traditional fron end
- During the process can create a cluster with any of our networking properties from cillium cni or any other supported cni
- just need to enable AAD and OIDC to allow appnet to connect to it 
- for the az appnet create --resource-group $APPNET_RG --name $APPNET_NAME --location $LOCATION  --identity-type SystemAssigned command . behind the scenes we are creating all of the records needed to represent the App net. No clusters added to this yet. we would then need to add the cluster we just created
- when joinging the cluster the two importnt flags are "--upgrade-mode FullyManaged -- east-west-gateway External" 
- This is specifically for pulic east-west gateways and fully managed
- The east west gateway allows connectivity between clusters, and we have 2 ways for users to run them internal or external mode
- In external mode the east to west gateways will get public IPs. So cross cluster traffic will go over public internet
- the cross cluster traffic is end to end mTLS encrypted so makes it safer, and allows us to not have vNet airing
- if you have internal policies preventing public IP addresses you can use east-west Internal
- But that would mean you would be responsible for getting thoe east-west gateways connected using vnet pairing or VPN with Azure WAN etc depending on use case
- A fully managed private transite network is on the roadmap for later
- For that command under the hood appnet is been installed to the cluster as well as a fully managed out of cluster controll plane
- We create a istio system namespace with resources on the controll plane componets, that run on azure managed infrastructure
- However, the data plane componets will run in the cluster
- including Ztunnel as daemon set running one per node and applying mTLS encryption to all traffic
- By default we dont start with any gateways but as any gateways we define will deploy Envoy for
- The command should succede in addindg our applink memeber and spun up a dedicated managed control plane in the same region as our cluster
- important if their is a regional failure it only affects tha region
- Dont foget to add label to default ns important :   kubectl label ns default istio.io/dataplane-mode=ambient
- The application is made of several microservices using different programming languages to show how the istio service mesh doesnt require any code changes, integrations
- The Bookinfo application is broken into four separate microservices:

- productpage. The productpage microservice calls the details and reviews microservices to populate the page.
- details. The details microservice contains book information.
- reviews. The reviews microservice contains book reviews. It also calls the ratings microservice.
- ratings. The ratings microservice contains book ranking information that accompanies a book review.
- we have a front end product page that shows information about books pulled from a ruby sservice
- will show reviews for those books that are stored in java for text and nodejs for the star reviews
- the demo will show an ingress gateway spun up infront of the product page to provide public acess and then we will start modifying
- We with use authorization policy to block traffic . So block product page from contacting details/reviews
- first lets look at application: kubectl get svc
- As we dont have an external IP we need to apply a ingress gateway for this application to view it . Link to file is https://raw.githubusercontent.com/istio/istio/release-1.29/samples/bookinfo/networking/bookinfo-gateway.yaml
- kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
- or kubectl port-forward svc/productpage 9080:9080
- then kubectl get gateway
- kubectl get svc
- should see external ip
- http://<ExternalIP>/productpage for me http://20.223.99.1/productpage
- This should all be working
- now have our app routing ingress -> routing traffic to our backend which is fully mTLS encryted 
- Now we want to block it using the authorization policy we wrote
- kubectl apply -f
- This policy says for the details/review app any inbound traffic should be denied if its coming from the products page
- So when we refresh page we should not be able to get details
- so were able to block traffic
- you might be thinking this demo can be done with any standard network policy
- but critical diffrence is with network policy you are operating on ip adresses to block traffic
- with Application network using mTLS, having a client identity and serier identity accross every connection. Which are refrenced in authorization policy
- so any identify called bookinfo-productpage from the default namespace that tries to connect to the details service should be blocked
- so doesnt matter what ip adresses the call is coming from , could be from multicluster or outside of the Mesh . As long as that identiy is prevented the traffic will be blocked
- Delete and we shall see traffic flowing


### slides 8 : Application network basics demo

- Onboard
- sample Application
- Authorization
- if you want to do live run 
az group create --name $AKS_RG --location $LOCATION
az aks create --name $CLUSTER_NAME --resource-group $AKS_RG --enable-oidc-issuer --enable-aad
az group create --name $APPNET_RG --location $LOCATION
az appnet create --resource-group $APPNET_RG --name $APPNET_NAME --location $LOCATION  --identity-type SystemAssigned
az appnet show --resource-group $APPNET_RG --name $APPNET_NAME

az appnet member join --resource-group $APPNET_RG --appnet-name $APPNET_NAME --member-name $APPNET_MEMBER_NAME --member-resource-id /subscriptions/$SUBSCRIPTION/resourcegroups/$AKS_RG/providers/Microsoft.ContainerService/managedClusters/$CLUSTER_NAME --upgrade-mode FullyManaged -- east-west-gateway External

az appnet member show --resource-group $APPNET_RG --appnet-name $APPNET_NAME --member-name $APPNET_MEMBER_NAME

make sure to connect to cluster: az aks get-credentials --resource-group $env:AKS_RG_NAME --name $env:AKS_CLUSTER_NAME
or 
az aks get-credentials --resource-group $env:AKS_RG_NAME --name $env:AKS_CLUSTER_NAME --admin --overwrite-existing

run the following to install sample book info application: kubectl apply -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/bookinfo/platform/kube/bookinfo.yaml

to view bookinfo application: https://istio.io/latest/docs/examples/bookinfo/



Autorization policy code to block details traffic is:

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

Autorization policy code to block details traffic is:

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


### notes 9

- Our next demo focuses on application network observability 
- Azure Kubernetes Application Network provides comprehensive metrics for your workloads and the Azure Kubernetes Application Network data plane components (ZTunnel, Istio CNI, and Waypoint) through Azure Monitor metrics
- Control plane metrics aren't currently supported. 
- However, data plane metrics are available, and you can use them to monitor the health and performance of your workloads and Azure Kubernetes Application Network components
- Data plane metrics include metrics from your workloads/applications and the appnet-system namespace.
- weve already deployed our cluster and to Configure data plane metrics we will use an Use an existing Azure Monitor workspace.
- We have already enabled Prometheus metrics collection on your Azure Kubernetes Application Network member cluster using the az aks update command with the --azure-monitor-workspace-resource-id parameter set to your existing workspace ID.
- First we need to run the collowing configmap  in the kube-system namespace to enable scraping of Ztunnel, Istio CNI, waypoint, and application/workloads.
- then we will Add annotations to the applications pods you want to scrape 
- like kubectl label pod productpage-v1-574c45789d-frnm8 prometheus.io/scrape=true
- kubectl label pod productpage-v1-574c45789d-frnm8 prometheus.io/port=15020
- kubectl label pod productpage-v1-574c45789d-frnm8 prometheus.io/path=/metrics
- these commands defines annotations for a pod that is hosting metrics at <pod IP>:15020/metrics
- then Navigate to your Azure Monitor workspace in the Azure portal to query the metrics using PromQL.
- ztunnel: istio_xds_connection_terminations_total
- waypoint: istio_requests_total
- istio-cni: istio_cni_install_ready
- an run the following query to view the total number of requests handled by waypoint

### slides 9: Application network observability

- Managed Prometheus
- Dashboards
- Trace Spans

run the collowing configmap  in the kube-system namespace to enable scraping of Ztunnel, Istio CNI, waypoint, and your application/workloads.

prometheus.io/scrape: "true" is required to indicate that the pod should be scraped.
prometheus.io/path is optionally used to indicate the path where metrics are hosted. If omitted, it defaults to /metrics.
prometheus.io/port is optionally used to indicate the port where metrics are hosted. If omitted, Prometheus will use the container's declared ports from the pod spec. For containers with no declared ports, Prometheus creates a port-free target (IP only), which requires proper relabeling configuration to work with port annotations. It is recommended to explicitly specify the port to ensure reliable scraping.

```
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


## Refrence:

https://learn.microsoft.com/en-us/azure/application-network/get-started


