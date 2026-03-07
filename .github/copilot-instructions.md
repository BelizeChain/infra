# BelizeChain Infra — GitOps Infrastructure

## Project Identity
- **Repo**: `BelizeChain/infra`
- **Role**: GitOps-managed deployment configs — Helm, ArgoCD, Grafana, K8s manifests
- **Language**: YAML, SQL, Shell
- **Branch**: `main` (default)

## Contents
- `docker-compose.yml` — 12 services for local dev
- `helm/` — Helm charts for K8s deployment
- `k8s/` — Raw Kubernetes manifests
- `argocd/` — ArgoCD GitOps application definitions
- `grafana/` — Monitoring dashboards and datasources
- `sql/` — Database initialization scripts
- `shared/` — Shared config templates
- 6 values files: dev, staging, prod, quantum, gpu, unified

## Azure Deployment Target
- **AKS**: `belizechain-aks` (Free tier, 1x Standard_D2s_v3, K8s v1.33.6)
- **ACR**: `belizechainacr.azurecr.io`
- **Resource Group**: `BelizeChain` in `centralus`
- **Subscription**: `77e6d0a2-78d2-4568-9f5a-34bd62357c40`
- **Tenant**: `belizechain.org`

## Deployment Status: Phase 3 — TODO
### What needs to be done:
1. **Adapt Helm charts for AKS Free tier** — Single node (2 vCPU / 8GB RAM), all services must fit
2. **Deploy Helm charts** to `belizechain-aks`:
   ```bash
   az aks get-credentials --resource-group BelizeChain --name belizechain-aks
   helm install belizechain ./helm -f helm/values-dev.yaml -n belizechain --create-namespace
   ```
3. **Configure ArgoCD** (optional, if resources allow):
   - Point ArgoCD to this repo for GitOps sync
   - Target: `belizechain-aks` cluster
4. **Deploy Grafana dashboards** for monitoring:
   - Node metrics, pallet activity, consensus health
   - Prometheus endpoint: `belizechain-node:9615`
5. **Update K8s manifests** to reference ACR images:
   - `belizechainacr.azurecr.io/belizechain-node`
   - `belizechainacr.azurecr.io/ui`
   - `belizechainacr.azurecr.io/kinich`
   - `belizechainacr.azurecr.io/nawal`
   - `belizechainacr.azurecr.io/pakit`

## Services Managed (all on same AKS node)
| Service | Image | Ports | Resource Budget |
|---------|-------|-------|-----------------|
| belizechain-node | belizechainacr.azurecr.io/belizechain-node | 30333, 9944, 9615 | 500m-1500m CPU, 1-3Gi RAM |
| ui | belizechainacr.azurecr.io/ui | 80/3000 | 100m-250m CPU, 128-512Mi RAM |
| kinich-quantum | belizechainacr.azurecr.io/kinich | 8000 | 100m-500m CPU, 256Mi-1Gi RAM |
| nawal-ai | belizechainacr.azurecr.io/nawal | 8001 | 100m-500m CPU, 256Mi-1Gi RAM |
| pakit-storage | belizechainacr.azurecr.io/pakit | 8002 | 100m-250m CPU, 128-512Mi RAM |

## Critical Constraints
- **AKS Free tier**: No SLA, no control plane cost, but limited to 1 node
- **Single node**: Standard_D2s_v3 = 2 vCPU / 8GB RAM — ALL services must fit
- **Cost ceiling**: ~$75/mo total (node ~$70 + ACR Basic ~$5)
- **No GPU nodes** — quantum and ML services must run CPU-only mode
- Helm values must be tuned for minimal resource requests

## Dev Commands
```bash
az aks get-credentials --resource-group BelizeChain --name belizechain-aks
kubectl get pods -n belizechain
helm template ./helm -f helm/values-dev.yaml  # Dry-run
docker-compose up -d                           # Local dev stack
```
