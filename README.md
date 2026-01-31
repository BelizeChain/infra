# 🚀 BelizeChain Infrastructure Repository

**GitOps-managed deployment configurations for BelizeChain's sovereign blockchain infrastructure**

> ⚠️ **Important**: This `infra/` directory should be extracted to a **separate Git repository** for production GitOps workflows. ArgoCD will watch this repo for automated deployments.

## 📋 Overview

BelizeChain infrastructure supports **flexible deployment topologies**:

1. **Unified Deployment**: All components on single node (development)
2. **Distributed Deployment**: Components on specialized hardware (production)
   - GPU nodes for AI (Nawal)
   - Quantum-ready nodes for hybrid computing (Kinich)
   - High-IOPS nodes for storage (Pakit)
   - Standard nodes for blockchain

### Architecture

```
┌──────────────────────────────────────────────────────────────┐
│ Istio Service Mesh (mTLS, observability, traffic mgmt)      │
└──────────────────────────────────────────────────────────────┘
         │                  │                  │
    ┌────┴────┐        ┌────┴────┐       ┌────┴────┐
    │ GPU Pool│        │ Quantum │       │Standard │
    │ (Nawal) │        │ (Kinich)│       │ (Core)  │
    └─────────┘        └─────────┘       └─────────┘
         │                  │                  │
    NVIDIA T4          Azure Quantum    Blockchain Node
    PyTorch            IBM Quantum       PostgreSQL
    TensorFlow         Qiskit           Redis/IPFS
```

## ✅ Infrastructure Status

### Complete Features
✅ **Docker Compose** - Unified deployment (11 services)  
✅ **Component Isolation** - Standalone deployment packages (blockchain/, nawal/, kinich/, pakit/)  
✅ **Kubernetes Manifests** - Base configurations in k8s/base/  
✅ **Istio Service Mesh** - Complete mTLS + traffic management in k8s/istio/  
✅ **Helm Charts** - Hardware-specific values (GPU, quantum, unified)  
✅ **Service Discovery** - FQDN templates in shared/  
✅ **Strict Dependency Validation** - Init containers verify all services  
✅ **Pakit Public Access** - Two-tier authentication (public/BelizeID)  
✅ **ArgoCD GitOps** - Automated deployment configs  
✅ **Monitoring** - Prometheus + Grafana dashboards

---

## 🎯 Quick Start

### Prerequisites
```bash
# Required
- Docker 24+ (with Docker Compose V2)
- 16GB RAM minimum (32GB recommended)
- 100GB free disk space
- Git

# Optional (for production)
- Kubernetes 1.28+
- Helm 3.14+
```

### 1. Start Full Stack
```bash
cd /home/wicked/BelizeChain/belizechain

# Start all services
docker compose -f infra/docker-compose.yml up -d

# Check status
docker compose -f infra/docker-compose.yml ps

# View logs
docker compose -f infra/docker-compose.yml logs -f
```

### 2. Access Services

| Service | URL | Purpose |
|---------|-----|---------|
| **Blockchain RPC** | http://localhost:9933 | JSON-RPC API |
| **Blockchain WebSocket** | ws://localhost:9944 | Real-time subscriptions |
| **IPFS Gateway** | http://localhost:8080 | Decentralized storage |
| **IPFS API** | http://localhost:5001 | Upload files |
| **FL Aggregator** | http://localhost:8080 | Federated learning |
| **Quantum API** | http://localhost:8081 | Quantum computing |
| **Portal** | http://localhost:3000 | Government dashboard |
| **Maya Wallet** | http://localhost:3001 | Citizen wallet |
| **Kijka Explorer** | http://localhost:3002 | Block explorer |
| **Prometheus** | http://localhost:9090 | Metrics |
| **Grafana** | http://localhost:3003 | Dashboards (admin/belize_grafana_2025) |
| **PostgreSQL** | localhost:5432 | Database (belizechain/belize_chain_secure_2025) |
| **Redis** | localhost:6379 | Cache (password: belize_redis_2025) |

### 3. Verify Health

```bash
# Check blockchain node
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' \
  http://localhost:9933

# Expected: {"jsonrpc":"2.0","result":{"peers":0,"isSyncing":false,"shouldHavePeers":false},"id":1}

# Check IPFS
curl http://localhost:5001/api/v0/version

# Check database
docker exec belizechain-postgres psql -U belizechain -c '\dt'
```

---

## 📦 Service Architecture

### Core Services

#### 1. BelizeChain Node
```yaml
Image: Custom (Substrate-based)
Ports: 30333 (P2P), 9933 (RPC), 9944 (WebSocket)
Volume: blockchain-data (persistent chain state)
```

**Configuration**:
- Runs in development mode by default (`--alice` validator)
- Exposes unsafe RPC/WS for local development
- For production: remove unsafe flags, add production keys

#### 2. IPFS
```yaml
Image: ipfs/go-ipfs:latest
Ports: 4001 (swarm), 5001 (API), 8080 (gateway)
Volumes: ipfs-data, ipfs-staging
```

**Use Cases**:
- Federated learning model storage
- Document verification hashes
- NFT metadata storage

#### 3. Federated Learning Aggregator
```yaml
Image: Custom (Python 3.11 + Flower)
Port: 8080
Volume: fl-models (trained models)
```

**Features**:
- Minimum 2 clients for training
- 10 rounds by default
- Publishes models to IPFS
- Records contributions on-chain

#### 4. Quantum Simulator
```yaml
Image: Custom (Python 3.11 + Qiskit)
Port: 8081
Volume: quantum-results
Backend: qasm_simulator (local)
```

**Backends Supported**:
- Qiskit (local simulator)
- IBM Quantum (requires API key)
- Azure Quantum (requires credentials)

#### 5. PostgreSQL
```yaml
Image: postgres:15-alpine
Port: 5432
Volume: postgres-data
Database: belizechain
```

**Tables**:
- kyc_verifications (compliance data)
- transactions (on-chain activity)
- quantum_jobs (quantum computing logs)
- fl_contributions (federated learning stats)
- search_cache (explorer performance)

#### 6. Redis
```yaml
Image: redis:7-alpine
Port: 6379
Volume: redis-data
Password: belize_redis_2025
```

**Use Cases**:
- Session management
- Rate limiting
- WebSocket connection state
- API response caching

---

## 🔧 Configuration

### Environment Variables

Create `.env` file in `infra/` directory:

```bash
# Blockchain
CHAIN_SPEC=dev
BASE_PATH=/data
RUST_LOG=info

# Database
POSTGRES_PASSWORD=belize_chain_secure_2025

# Redis
REDIS_PASSWORD=belize_redis_2025

# Grafana
GRAFANA_PASSWORD=belize_grafana_2025

# Federated Learning
FL_MIN_CLIENTS=2
FL_ROUNDS=10

# Quantum
QUANTUM_BACKEND=qasm_simulator
QUANTUM_SHOTS=1024

# UI Apps
NEXT_PUBLIC_BLOCKCHAIN_RPC=http://localhost:9933
NEXT_PUBLIC_BLOCKCHAIN_WS=ws://localhost:9944
NEXT_PUBLIC_IPFS_GATEWAY=http://localhost:8080

# External APIs (Optional)
IBM_QUANTUM_TOKEN=your_token_here
AZURE_QUANTUM_WORKSPACE=your_workspace_here
```

### Production Overrides

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  belizechain-node:
    command: >
      --base-path /data
      --chain /app/chain-spec.json
      --port 30333
      --rpc-port 9933
      --ws-port 9944
      --rpc-cors all
      --validator
      --name "BelizeChain Validator"
      --telemetry-url "wss://telemetry.polkadot.io/submit/ 0"
    # Remove unsafe flags for production!
```

Run with:
```bash
docker compose -f infra/docker-compose.yml -f infra/docker-compose.prod.yml up -d
```

---

## 📊 Monitoring

### Prometheus Metrics

**Blockchain Metrics**:
- `substrate_block_height` - Current block number
- `substrate_finalized_height` - Finalized block
- `substrate_peers_count` - Connected peers
- `substrate_txpool_validations_scheduled` - Pending transactions

**Access**: http://localhost:9090

### Grafana Dashboards

**Default Login**:
- Username: `admin`
- Password: `belize_grafana_2025`

**Pre-configured**:
- Prometheus datasource
- PostgreSQL datasource

**Custom Dashboards** (to create):
1. Blockchain Performance (blocks/sec, finalization lag)
2. Quantum Job Statistics (jobs/day, backends used)
3. FL Training Progress (rounds, accuracy)
4. System Resources (CPU, RAM, disk)

---

## 🔐 Security Checklist

### Development (Current Setup)
- ✅ Isolated Docker network
- ✅ Password-protected databases
- ⚠️ Unsafe RPC/WS exposed (localhost only)
- ⚠️ Default passwords (change for production!)

### Production (Required Changes)
1. **Change ALL default passwords**
2. **Remove unsafe RPC/WS flags**
3. **Enable TLS/SSL** (Let's Encrypt)
4. **Add firewall rules** (only expose necessary ports)
5. **Set up proper validator keys** (no Alice/Bob!)
6. **Enable audit logging**
7. **Configure backup strategy**
8. **Add rate limiting** (nginx reverse proxy)
9. **Set resource limits** (CPU, memory)
10. **Enable log rotation**

---

## 🚨 Troubleshooting

### Port Conflicts
```bash
# Check if ports are already in use
sudo lsof -i :9933
sudo lsof -i :9944

# Stop conflicting services or change ports in docker-compose.yml
```

### Out of Memory
```bash
# Increase Docker memory limit
# Docker Desktop: Settings → Resources → Memory → 16GB+

# Check memory usage
docker stats
```

### IPFS Not Syncing
```bash
# Restart IPFS
docker restart belizechain-ipfs

# Check IPFS logs
docker logs belizechain-ipfs
```

### Database Connection Failed
```bash
# Verify PostgreSQL is running
docker exec belizechain-postgres pg_isready

# Check database logs
docker logs belizechain-postgres
```

### Blockchain Not Producing Blocks
```bash
# Check node logs
docker logs belizechain-node

# Verify validator is active
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys"}' \
  http://localhost:9933
```

---

## 🧹 Maintenance

### Stop All Services
```bash
docker compose -f infra/docker-compose.yml down
```

### Stop and Remove Volumes (CAUTION: Data Loss!)
```bash
docker compose -f infra/docker-compose.yml down -v
```

### Update Services
```bash
# Pull latest images
docker compose -f infra/docker-compose.yml pull

# Rebuild custom images
docker compose -f infra/docker-compose.yml build

# Restart with new images
docker compose -f infra/docker-compose.yml up -d
```

### Backup Data
```bash
# Backup blockchain data
docker run --rm -v belizechain_blockchain-data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/blockchain-$(date +%Y%m%d).tar.gz /data

# Backup database
docker exec belizechain-postgres pg_dump -U belizechain belizechain \
  > backups/database-$(date +%Y%m%d).sql

# Backup IPFS data
docker run --rm -v belizechain_ipfs-data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/ipfs-$(date +%Y%m%d).tar.gz /data
```

---

## 📈 Scaling

### Horizontal Scaling (Kubernetes)

When you're ready for production, migrate to Kubernetes:

```bash
# Coming soon: infra/k8s/
- deployment.yml (blockchain nodes)
- statefulset.yml (databases)
- service.yml (load balancers)
- ingress.yml (HTTPS routing)
- configmap.yml (configuration)
- secret.yml (credentials)
```

### Vertical Scaling (Resource Limits)

Edit `docker-compose.yml`:

```yaml
services:
  belizechain-node:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

---

## 🎯 Next Steps

1. **Generate Chain Spec** (for production)
2. **Set up CI/CD** (GitHub Actions)
3. **Create Kubernetes manifests** (for multi-node deployment)
4. **Configure monitoring alerts** (Alertmanager)
5. **Set up log aggregation** (ELK stack or Loki)
6. **Implement backup automation** (cronjobs)
7. **Add health checks** (liveness/readiness probes)
8. **Configure auto-scaling** (HPA in K8s)

---

## 📚 Additional Resources

- **Substrate Docs**: https://docs.substrate.io
- **Docker Compose**: https://docs.docker.com/compose/
- **IPFS Docs**: https://docs.ipfs.tech
- **Prometheus**: https://prometheus.io/docs/
- **Grafana**: https://grafana.com/docs/

---

**Status**: ✅ Infrastructure Ready for Local Development  
**Next Phase**: Testnet Deployment Planning
