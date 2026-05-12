# ArgoCD

## Deploy ArgoCD to Kubernetes

1. Create the namespace:

   ```bash
   kubectl create ns argocd
   ```

2. Deploy the ArgoCD manifests:

   ```bash
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

3. Verify the pods are running:

   ```bash
   kubectl get pods -n argocd
   ```

4. Access ArgoCD by port-forwarding the service:

   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0
   ```

5. Retrieve the auto-generated admin password:

   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
   ```

6. Decode the password (PowerShell):

   ```powershell
   [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("<base64-password>"))
   ```

7. Log in with **username:** `admin` and the decoded password.

## Login via CLI

1. Download and install the ArgoCD CLI:

   ```bash
   wget https://github.com/argoproj/argo-cd/releases/download/v3.1.8/argocd-linux-amd64 -O argocd
   chmod +x argocd
   ```

2. Log in:

   ```bash
   argocd login localhost:8080 --username admin --password <admin-password>
   ```

## Deploy an Application

1. Create an application in ArgoCD with the following settings:

   | Field               | Value                                  |
   | ------------------- | -------------------------------------- |
   | Application name    | your app name                          |
   | Project name        | default                                |
   | Auto-create namespace | enabled                              |
   | Repository URL      | your source repo URL                   |
   | Path                | directory containing your YAML manifests |
   | Cluster URL         | `https://kubernetes.default.svc/`      |
   | Namespace           | target namespace                       |

2. Click **Create**.

3. Port-forward the application service:

   ```bash
   kubectl port-forward svc/argocd-demo-app-service 9090:3000 --address 0.0.0.0
   ```

4. Access the application at `http://localhost:9090/`.
5. Update the deployment image tag (e.g., from `v1` to `v2`) to see ArgoCD automatically sync the change. Use the **History** and **Rollback** options as needed.

6. To delete an application, choose one of the following propagation options:

   - **Foreground propagation** — ArgoCD terminates all child resources before the parent.
   - **Background propagation** — ArgoCD deletes the parent first and lets Kubernetes remove the child objects asynchronously (same as `kubectl delete` default behavior).
   - **Do not touch the resources** — Keeps the Kubernetes resources running but removes them from ArgoCD's management.

## Authentication and authorization

