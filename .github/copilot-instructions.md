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
- **AKS**: `belizechain-aks` (Free tier, 1x Standard_D4s_v3, K8s v1.33.6)
- **ACR**: `belizechainacr.azurecr.io`
- **Resource Group**: `BelizeChain` in `centralus`
- **Subscription**: `77e6d0a2-78d2-4568-9f5a-34bd62357c40`
- **Tenant**: `belizechain.org`

## Deployment Status: Phase 3 — DEPLOYED (PoC)
### Single-node proof-of-concept — proves BelizeChain runs on one machine
All services deployed on a single Standard_D4s_v3 node (4 vCPU, 16GB RAM),
equivalent to a modern laptop. Resource requests tuned in `values-dev.yaml`.

## Services Managed (all on same AKS node)
| Service | Image | Ports | Resource Budget (requests/limits) |
|---------|-------|-------|-----------------------------------|
| ceiba-node | belizechainacr.azurecr.io/ceiba-node | 30333, 9944 | 250m-1500m CPU, 1-3Gi RAM |
| ui (belizechain-org) | belizechainacr.azurecr.io/belizechain-org | 80 | 100m-250m CPU, 128-512Mi RAM |
| kinich-quantum | belizechainacr.azurecr.io/kinich-quantum | 8888 | 100m-500m CPU, 256Mi-1Gi RAM |
| nawal-ai | belizechainacr.azurecr.io/nawal | 8080 | 100m-500m CPU, 256Mi-1Gi RAM |
| pakit-storage | belizechainacr.azurecr.io/pakit-storage | 8001 | 100m-500m CPU, 128-512Mi RAM |
| postgres | postgres:15-alpine | 5432 | 100m-500m CPU, 256Mi-1Gi RAM |
| redis | redis:7-alpine | 6379 | 50m-250m CPU, 128-512Mi RAM |
| prometheus | prom/prometheus | 9090 | 100m-500m CPU, 256Mi-1Gi RAM |
| grafana | grafana/grafana | 3000 | 50m-250m CPU, 128-512Mi RAM |

## Critical Constraints
- **AKS Free tier**: No SLA, no control plane cost, limited to 1 node
- **Single node**: Standard_D4s_v3 = 4 vCPU / 16GB RAM — ALL services must fit
- **Cost ceiling**: ~$140/mo total (node ~$135 + ACR Basic ~$5)
- **No GPU nodes** — quantum and ML services run CPU-only mode
- Helm values-dev.yaml tuned for minimal resource requests

## Dev Commands
```bash
az aks get-credentials --resource-group BelizeChain --name belizechain-aks
kubectl get pods -n belizechain
helm template ./helm -f helm/values-dev.yaml  # Dry-run
docker-compose up -d                           # Local dev stack
```
