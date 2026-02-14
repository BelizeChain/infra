# BelizeChain Infrastructure

Production-ready infrastructure for BelizeChain blockchain platform.

## Quick Start

### Local Development
```bash
# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### Kubernetes Deployment
```bash
# Helm (Recommended)
helm install belizechain ./helm/belizechain -f ./helm/belizechain/values-production.yaml

# Or Kustomize
kubectl apply -k k8s/base/

# Or ArgoCD (GitOps)
kubectl apply -f argocd/
```

## Repository Structure

```
├── argocd/              # GitOps application manifests
├── docker-compose.yml   # Local development stack (12 services)
├── grafana/             # Monitoring dashboards & datasources
├── helm/                # Helm charts for Kubernetes
│   └── belizechain/     # Main chart with 6 environment configs
├── k8s/                 # Raw Kubernetes manifests
│   ├── base/            # Base configurations
│   └── istio/           # Service mesh policies
├── shared/              # Shared configurations
│   └── service-discovery.env  # Service DNS templates
├── sql/                 # Database initialization scripts
├── .env.example         # Environment variable template (100+ vars)
└── validate-helm.sh     # Helm chart validation script
```

## Components

- **BelizeChain Node**: Substrate blockchain with 16 custom pallets
- **Pakit**: Sovereign DAG storage with ZK proofs
- **Nawal**: Federated learning with 6 security layers
- **Kinich**: Quantum computing integration (Azure + IBM)
- **PostgreSQL**: Relational database
- **Redis**: Caching layer
- **IPFS**: Distributed file storage
- **Grafana + Prometheus**: Monitoring stack

## Environment Configuration

All services configured via environment variables. See `.env.example` for:
- 16 blockchain pallet configurations
- Pakit DAG/ZK proof settings
- Nawal AI security parameters
- Kinich quantum optimization
- Database credentials
- Network settings

## Deployment Targets

| Environment | Values File | Purpose |
|-------------|-------------|---------|
| Development | `values-dev.yaml` | Local testing |
| Staging | `values-staging.yaml` | Pre-production |
| Production | `values-production.yaml` | Live deployment |
| Quantum | `values-quantum.yaml` | Quantum-optimized |
| GPU | `values-gpu.yaml` | GPU acceleration |
| Unified | `values-unified.yaml` | All-in-one |

## Prerequisites

- Docker 20.10+
- Kubernetes 1.28+ (for K8s deployment)
- Helm 3.14+ (for Helm deployment)
- kubectl configured with cluster access

## Security

**NEVER commit these files:**
- `.env` (production secrets)
- `chain-spec-production.json` (validator keys)
- Any files in `secrets/`

Use `.env.example` as template. Store production secrets in:
- Azure Key Vault
- HashiCorp Vault  
- Kubernetes External Secrets Operator

## Monitoring

Access Grafana dashboard:
```bash
# Local: http://localhost:3000
# Kubernetes: kubectl port-forward svc/grafana 3000:3000
```

Default credentials: admin/admin (change immediately)

## Production Checklist

See `PRODUCTION_READINESS_CHECKLIST.md` for complete deployment requirements.

## Validation

```bash
# Validate Helm charts
./validate-helm.sh

# Validate Kubernetes manifests
kubectl apply --dry-run=client -k k8s/base/

# Lint YAML
yamllint .
```

## Quick Reference

### Service Ports
- Blockchain RPC: 9933 (HTTP), 9944 (WS)
- Nawal API: 8080
- Kinich API: 8888
- Pakit API: 8001
- PostgreSQL: 5432
- Redis: 6379
- IPFS: 5001 (API), 8080 (Gateway)
- Grafana: 3000
- Prometheus: 9090

### Health Checks
```bash
# Blockchain
curl http://localhost:9933/health

# Pakit
curl http://localhost:8001/health

# Nawal
curl http://localhost:8080/health

# Kinich
curl http://localhost:8888/health
```

---

**BelizeChain** - Sovereign Blockchain Infrastructure for Belize
