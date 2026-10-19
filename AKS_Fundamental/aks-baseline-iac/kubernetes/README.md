# Kubernetes Manifests

This directory contains Kubernetes manifests for deploying applications to the AKS cluster.

## Directory Structure

- `namespaces/` - Namespace definitions
- `deployments/` - Application deployment configurations
- `services/` - Service definitions
- `ingress/` - Ingress configurations
- `secrets/` - Secret templates (DO NOT commit actual secrets)

## Deployment Order

1. Create namespaces:
   ```bash
   kubectl apply -f namespaces/
   ```

2. Create secrets (replace placeholders first):
   ```bash
   # Copy template and replace placeholders
   cp secrets/secrets.yaml.template secrets/secrets.yaml
   # Edit secrets.yaml with actual values
   kubectl apply -f secrets/secrets.yaml
   ```

3. Deploy applications:
   ```bash
   kubectl apply -f deployments/
   ```

4. Create services:
   ```bash
   kubectl apply -f services/
   ```

5. Configure ingress:
   ```bash
   kubectl apply -f ingress/
   ```

## Verifying Deployment

```bash
# Check pod status
kubectl get pods -n applications

# Check service endpoints
kubectl get svc -n applications

# Check ingress
kubectl get ingress -n applications

# View logs
kubectl logs -n applications -l app=webapi
```

## Environment Variables

The deployments expect the following to be configured:
- `${ACR_NAME}` - Azure Container Registry name
- Database connection strings in secrets
- API URLs for service-to-service communication

## Production Considerations

For production deployments:
- Use Azure Key Vault with CSI driver for secrets
- Configure pod security policies
- Enable network policies
- Set up horizontal pod autoscaling
- Configure resource quotas per namespace
- Implement pod disruption budgets
