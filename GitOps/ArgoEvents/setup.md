# Setting Up and Using Argo Events

## Prerequisites: Install Argo Workflows

1. Create the `argo` namespace and install Argo Workflows:

   ```bash
   kubectl create ns argo
   kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.7.3/install.yaml
   ```

2. Change the authentication mode of the Argo Server to `server` so the UI can properly authenticate requests:

   ```bash
   kubectl patch deployment argo-server --namespace argo --type='json' \
     -p='[{"op":"replace","path":"/spec/template/spec/containers/0/args","value":["server","--auth-mode=server"]}]'
   ```

3. Port-forward the Argo Server to access the UI at `https://localhost:2746`:

   ```bash
   kubectl -n argo port-forward deployment/argo-server 2746:2746
   ```

## Install Argo Events

1. Create the `argo-events` namespace and install Argo Events:

   ```bash
   kubectl create ns argo-events
   kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml
   ```

2. Apply the validating webhook to ensure incoming requests to the Kubernetes API server are valid:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install-validating-webhook.yaml
   ```

3. Set up the EventBus — this handles event transportation in Argo Events:

   ```bash
   kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml
   ```

4. Set up the EventSource to listen to webhook events:

   ```bash
   kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/event-sources/webhook.yaml
   ```

5. Apply RBAC for the sensor (service account, roles, rolebinding):

   ```bash
   kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/master/examples/rbac/sensor-rbac.yaml
   ```

6. Apply RBAC for workflows (roles, rolebinding):

   ```bash
   kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/master/examples/rbac/workflow-rbac.yaml
   ```

7. Deploy the webhook sensor — this triggers workflows based on webhook events.

8. Expose the EventSource pod via port-forward to consume requests over HTTP:

   ```bash
   kubectl -n argo-events port-forward $(kubectl -n argo-events get pod -l eventsource-name=webhook -o name) 12000:12000 &
   ```

9. Simulate an external event that triggers a workflow:

   ```bash
   curl -d '{"message":"this is my first webhook"}' -H "Content-Type: application/json" -X POST http://localhost:12000/example
   ```

## Using Pulsar to Trigger Argo Events Workflows

Pulsar is a distributed messaging system and serves as an alternative event source.

1. Deploy Apache Pulsar:

   ```bash
   kubectl apply -n argo-events -f https://raw.githubusercontent.com/lftraining/LFS256-code/main/argoevents/pulsar.yaml
   ```

2. Verify the pods are running:

   ```bash
   kubectl get pods -n argo-events
   ```

3. Port-forward the Pulsar pod for direct communication between your local machine and the Pulsar service:

   ```bash
   kubectl port-forward -n argo-events pulsar-758c47fc7-m4nfw 6650:6650 &
   ```

4. Set the EventSource for Argo Events to listen to Pulsar messages:

   ```bash
   kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/event-sources/pulsar.yaml
   ```

5. Deploy the sensor for reacting to Pulsar events:

   ```bash
   kubectl apply -n argo-events -f C:\AKS_LABS\GitOps\ArgoEvents\sensor.yaml
   ```

6. Exec into the Pulsar pod and produce a test message:

   ```bash
   kubectl exec -it -n argo-events pulsar-758c47fc7-m4nfw -- /bin/bash
   cd bin
   ./pulsar-client produce test --messages "Test"
   ```

7. Go to the Argo Workflows UI to see the triggered workflow and message.

8. Verify from the cluster by checking the pod logs:

   ```bash
   kubectl get pod -n argo-events | Select-String pulsar
   kubectl logs -n argo-events pulsar-758c47fc7-m4nfw
   ```
