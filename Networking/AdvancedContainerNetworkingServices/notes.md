# Advanced Container Networking Services

Advanced Container Networking Services (ACNS) enhances AKS operational capabilities through two key pillars:

- **Security**: Cilium Network policies with FQDN filtering and L7 policy support(for Azure CNI Powered by Cilium clusters)
- **Observability**: Hubble's control plane for networking visibility and performance insights (supports both Cilium and non-Cilium Linux data planes)

## Configuring FQDN Filtering

- Using network policies, you can control traffic flow to and from your AKS cluster.
- This is traditionally been enforced based on IP addresses and ports.
- But what if you want to control traffic based on fully qualified domain names (FQDNs)? What if an application owner asks you to allow traffic to a specific domain like Microsoft Graph API?
- This is where FQDN filtering comes in
- Verify FQDN `kubectl exec -n pets -it $(kubectl get po -n pets -l app=order-service -ojsonpath='{.items[0].metadata.name}') -c order-service  -- sh -c 'wget --spider --timeout=1 --tries=1 https://graph.microsoft.com'`
- Test connection to bing: `kubectl exec -n pets -it $(kubectl get po -n pets -l app=order-service -ojsonpath='{.items[0].metadata.name}') -c order-service -- sh -c 'wget --spider --timeout=1 --tries=1 www.bing.com'`

## Monitoring Advanced Network Metrics and Flows

- ACNS provides comprehensive network visibility by logging all pod communications, enabling you to investigate connectivity issues over time. 
- Using Azure Managed Grafana, you can visualize real-time traffic patterns, performance metrics, and policy effectiveness.

### What Metrics Dashboards Show:

- Real-time aggregated traffic statistics
- Dropped packet trends and reasons
- DNS query success/failure rates
- Service-to-service communication patterns
- Network policy effectiveness

### When to Use Metrics Dashboards:

- **Detection**: Identify when problems start occurring
- **Monitoring**: Track cluster health in real-time
- **Alerting**: Set up alerts based on drop rates or latency
- **High-level insights**: Understand traffic patterns at a glance

## Container Network Flow Logs for Faster Troubleshooting

- Who is being blocked (which specific source IPs or clients)
- Why DNS queries fail for specific domains
- When exactly the problem started affecting individual flows
- What external endpoints are failing vs succeeding
- **Container Network Flow Logs** accelerate your troubleshooting. 
- Metrics as the "smoke alarm" and flow logs as the "security camera footage" - metrics alert you to the problem, while flow logs show you exactly what happened.
- To enable container network flow logs, you need to apply a `ContainerNetworkLog` custom resource that defines which network flows to capture.

### The Traditional Troubleshooting Approach (Without Flow Logs):

1. SSH into individual nodes to check iptables rules (risky in production)
2. Enable debug logging on pods (requires restarts, loses existing state)
3. Manually test connections one-by-one to isolate the issue
4. Correlate timestamps across multiple pod logs to understand traffic patterns
Estimated time: 2-4 hours for a complex network policy issue

### With Container Network Flow Logs (What You'll Do Next):

1. Run a single KQL query to see exact blocked connections with source IPs
2. Query DNS traffic to identify which domains are allowed vs blocked
3. Correlate DNS success with connection failures in one view
4. Visualize traffic patterns over time to pinpoint when the issue started
Estimated time: 10-15 minutes to fully diagnose the root cause

`kubectl describe containernetworklog testcnl`

- Without container network flow logs, you would need to SSH into nodes to check iptables rules, manually correlate pod events with network policies, and spend hours trying different combinations to find the root cause
- Since Container Network Flow Logs are enabled with Log Analytics workspace, we have access to historical logs that allow us to analyze network traffic patterns over time. 
- Can query these logs using the `ContainerNetworkLog` table to perform detailed forensic analysis and troubleshooting.