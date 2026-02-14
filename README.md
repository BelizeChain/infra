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

### 🎯 **Platform Capabilities**

| Component | Features | Technology Stack |
|-----------|----------|------------------|
| **BelizeChain Blockchain** | 16 custom pallets: Economy (DALLA/bBZD), BelizeX DEX, Identity, Governance, Staking (PoUW), Quantum, Meshtastic Mesh, Land Registry, BNS, Smart Contracts | Substrate 4.0, Rust, 2000 TPS, 6s blocks |
| **Nawal AI** | Federated Learning, Differential Privacy (DP-SGD), Genetic Algorithms, Byzantine Detection, Gradient Verification, Data Poisoning Detection | Flower, PyTorch, TensorFlow, Python 3.11 |
| **Kinich Quantum** | Zero Noise Extrapolation, Readout Mitigation, Hybrid Quantum-Classical, Circuit Optimization L3, Azure/IBM Backends | Qiskit, Azure Quantum, IBM Quantum, Python 3.11 |
| **Pakit Storage** | Sovereign DAG, ZK Proofs (Groth16), Quantum Compression, Deduplication, Multi-tier Cache | Python 3.13, DAG, IPFS (optional), Arweave (optional) |
| **GEM Contracts** | BelizeX DEX (Factory/Pair/Router), PSP37 Multi-Token, Access Control, Security Audit Checklist | ink! 5.0, WebAssembly, Rust |
| **Infrastructure** | Istio Service Mesh, ArgoCD GitOps, Prometheus/Grafana, Multi-environment (dev/staging/prod) | Kubernetes, Helm, Docker Compose |

---

## 📚 Documentation

**Comprehensive documentation available in the [`docs/`](./docs/) directory:**

- **[Production Deployment Guide](./docs/guides/production/deployment-guide.md)** - Complete production deployment procedures
- **[Security Best Practices](./docs/guides/production/security-best-practices.md)** - Security hardening and compliance
- **[Secrets Management](./docs/guides/production/secrets-management.md)** - Comprehensive secrets management guide
- **[Security Audit Resolution](./SECURITY_AUDIT_RESOLUTION.md)** - YAML linting exceptions explained
- **[Component Documentation](./docs/components/)** - Individual component guides (Blockchain, Nawal, Kinich, Pakit)
- **[Update History](./docs/updates/)** - Platform update documentation
- **[Full Documentation Index](./docs/README.md)** - Complete documentation navigation

---

## ✅ Infrastructure Status

### Complete Features
✅ **Docker Compose** - Unified deployment (12 services)  
✅ **Component Isolation** - Standalone deployment packages (blockchain/, nawal/, kinich/, pakit/)  
✅ **Kubernetes Manifests** - Base configurations in k8s/base/  
✅ **Istio Service Mesh** - Complete mTLS + traffic management in k8s/istio/  
✅ **Helm Charts** - Hardware-specific values (GPU, quantum, unified)  
✅ **Service Discovery** - FQDN templates in shared/  
✅ **Strict Dependency Validation** - Init containers verify all services  
✅ **16 Custom Pallets** - Complete sovereign blockchain runtime  
✅ **Pakit DAG Storage** - Sovereign DAG backend with ZK proofs  
✅ **Nawal AI Security** - Byzantine detection, differential privacy, genetic algorithms  
✅ **Kinich Quantum** - Error mitigation (ZNE + Readout), hybrid quantum-classical  
✅ **GEM Smart Contracts** - ink! 5.0 with BelizeX DEX, PSP37 multi-token  
✅ **Meshtastic LoRa Mesh** - Decentralized mesh networking support  
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
| **Pakit Storage** | http://localhost:8001 | Sovereign DAG storage |
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

**16 Custom Pallets**:
- **Financial**: Economy (DALLA/bBZD), BelizeX (DEX), Payroll
- **Governance**: Governance, Community
- **Identity**: Identity (BelizeID), Compliance (KYC/AML), Oracle
- **Infrastructure**: Belize Staking (PoUW), Consensus, Interoperability, Quantum
- **Meshtastic**: Belize Mesh (LoRa networking) 🆕
- **Registries**: LandLedger, BNS (.bz domains), Contracts (ink! 5.0)

**Performance**:
- Target: 2,000 TPS
- Block time: 6 seconds
- Max block size: 5MB

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

**Core Features**:
- Flower federated learning orchestration
- Minimum 2 clients for training (configurable)
- 10 rounds by default
- Publishes models to IPFS
- Records contributions on-chain (PoUW rewards)

**Privacy & Security** 🆕:
- **Differential Privacy** (DP-SGD): Noise multiplier 1.1, gradient clipping
- **Genetic Algorithm**: Population-based model evolution
- **Byzantine Detection**: Cosine similarity verification (threshold 0.8)
- **Gradient Verification**: Norm checking with historical analysis
- **Data Poisoning Detection**: KL divergence, loss spike detection
- **Data Leakage Detection**: Membership inference, gradient inversion

**Security Scores**:
- Quality: 40%
- Timeliness: 30%
- Honesty: 30%

#### 4. Quantum Simulator
```yaml
Image: Custom (Python 3.11 + Qiskit)
Port: 8888
Volume: quantum-results
Backend: qasm_simulator (local)
```

**Backends Supported**:
- Qiskit (local simulator)
- IBM Quantum (requires API key)
- Azure Quantum (requires credentials)

**Circuit Optimization** 🆕:
- Optimization Level: 3 (maximum)
- Max Qubits: 127
- Max Shots: 100,000
- Basis Gates: cx, id, rz, sx, x

**Error Mitigation** 🆕:
- **Zero Noise Extrapolation (ZNE)**: Noise factors [1, 2, 3]
- **Readout Mitigation**: Calibration matrix correction
- Hybrid quantum-classical optimization (COBYLA)

**Use Cases**:
- Quantum circuit simulation
- Hybrid algorithms (VQE, QAOA)
- Error-mitigated quantum computation
- Cross-chain quantum workload distribution

#### 5. Pakit Storage Service
```yaml
Image: Custom (Python 3.13)
Port: 8001
Volumes: pakit-dag-storage, pakit-cache
```

**Features**:
- Sovereign DAG-based storage (primary)
- Zero-Knowledge proof generation and verification
- Quantum compression support
- Content deduplication and chunking
- Multi-tier caching (10GB default)
- Optional IPFS/Arweave backends

**Storage Backends**:
- DAG Backend (sovereign, 3x replication)
- IPFS (optional fallback)
- Arweave (optional permanent storage)

**ZK Proof Configuration**:
- System: Groth16
- On-upload verification: Optional
- Cached proofs for performance

**Public Access Mode**:
- View/list: Public
- Upload/download: Requires BelizeID
- Blockchain proof registration: Authenticated only

#### 6. PostgreSQL
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
- pakit_files (storage metadata with ZK proofs)

#### 7. Redis
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
- Pakit DAG node discovery

---

## � **GEM Smart Contract Platform**

### What is GEM?
**General Ecosystem Machinery** - BelizeChain's ink! 5.0 smart contract platform

### Key Components

#### **BelizeX DEX Contracts** (v1.3.0)
- **Factory**: Creates/manages trading pairs (350 lines, 8 tests)
- **Pair**: Constant product AMM x*y=k (832 lines, 4 tests)
- **Router**: Multi-hop routing, slippage protection (760 lines, 4 tests)

#### **Token Standards**
- **PSP37 Multi-Token**: Batch operations, mixed fungible/NFT (650 lines)
- **Access Control**: Ownable, RBAC, Pausable patterns (550 lines)

#### **SDKs Available**
- **BelizeXSDK**: 22 methods for DEX operations (790 lines)
- **MeshNetworkSDK**: LoRa mesh integration, node registration
- **PrivacySDK**: Commitment computation, vote privacy

#### **Integration Capabilities**
GEM contracts can interact with:
- DALLA/bBZD tokens (Economy pallet)
- Nawal AI predictions
- Kinich quantum computations
- Pakit storage (DAG + ZK proofs)
- BelizeID verification
- Governance proposals
- BNS .bz domain registry
- Meshtastic mesh network

---

## 🔧 Configuration

### Environment Variables

Create `.env` file in `infra/` directory:

```bash
# =====================
# BLOCKCHAIN
# =====================
CHAIN_SPEC=dev
BASE_PATH=/data
RUST_LOG=info

# Runtime Pallets (16 total)
ENABLE_PALLET_ECONOMY=true
ENABLE_PALLET_BELIZEX=true
ENABLE_PALLET_PAYROLL=true
ENABLE_PALLET_GOVERNANCE=true
ENABLE_PALLET_COMMUNITY=true
ENABLE_PALLET_IDENTITY=true
ENABLE_PALLET_COMPLIANCE=true
ENABLE_PALLET_ORACLE=true
ENABLE_PALLET_STAKING=true
ENABLE_PALLET_CONSENSUS=true
ENABLE_PALLET_INTEROPERABILITY=true
ENABLE_PALLET_QUANTUM=true
ENABLE_PALLET_MESH=true
ENABLE_PALLET_LANDLEDGER=true
ENABLE_PALLET_BNS=true
ENABLE_PALLET_CONTRACTS=true

# Meshtastic LoRa Mesh
MESH_NETWORK_ENABLED=false
MESH_CHANNEL=BelizeChain

# Performance
TARGET_TPS=2000
BLOCK_TIME=6

# =====================
# DATABASE & CACHE
# =====================
# Database
POSTGRES_PASSWORD=belize_chain_secure_2025

# Redis
REDIS_PASSWORD=belize_redis_2025

# Grafana
GRAFANA_PASSWORD=belize_grafana_2025

# =====================
# NAWAL FEDERATED LEARNING
# =====================
# Federated Learning
FL_MIN_CLIENTS=2
FL_ROUNDS=10
NAWAL_MIN_PARTICIPANTS=3
NAWAL_MAX_PARTICIPANTS=100
NAWAL_ROUNDS_PER_EPOCH=10
NAWAL_MIN_FIT_CLIENTS=2

# Differential Privacy (DP-SGD)
DIFFERENTIAL_PRIVACY_ENABLED=true
DP_NOISE_MULTIPLIER=1.1
DP_MAX_GRAD_NORM=1.0
DP_DELTA=1e-5

# Genetic Algorithm Model Evolution
GENETIC_ALGORITHM_ENABLED=true
GA_POPULATION_SIZE=10
GA_GENERATIONS=5
GA_MUTATION_RATE=0.1

# Byzantine Detection & Security
BYZANTINE_DETECTION_ENABLED=true
COSINE_SIMILARITY_THRESHOLD=0.8
GRADIENT_VERIFICATION_ENABLED=true
GRADIENT_NORM_THRESHOLD=10.0

# Data Poisoning Detection
DATA_POISONING_DETECTION=true
KL_DIVERGENCE_THRESHOLD=0.5
LOSS_SPIKE_THRESHOLD=2.0

# Data Leakage Detection
DATA_LEAKAGE_DETECTION=true
MEMBERSHIP_INFERENCE_ENABLED=true
GRADIENT_INVERSION_DETECTION=true

# =====================
# KINICH QUANTUM COMPUTING
# =====================
# Quantum
QUANTUM_BACKEND=qasm_simulator
QUANTUM_SHOTS=1024
KINICH_MAX_CONCURRENT_JOBS=10
KINICH_DEFAULT_BACKEND=qasm_simulator
KINICH_ENABLE_ERROR_MITIGATION=true

# Azure Quantum
AZURE_QUANTUM_ENABLED=true
AZURE_QUANTUM_SUBSCRIPTION_ID=your_subscription_id
AZURE_QUANTUM_RESOURCE_GROUP=your_resource_group
AZURE_QUANTUM_WORKSPACE=your_workspace
AZURE_QUANTUM_LOCATION=eastus

# IBM Quantum
IBM_QUANTUM_ENABLED=false
IBM_QUANTUM_TOKEN=your_token_here
IBM_QUANTUM_HUB=ibm-q
IBM_QUANTUM_GROUP=open
IBM_QUANTUM_PROJECT=main

# Circuit Optimization
CIRCUIT_OPTIMIZATION_LEVEL=3
MAX_QUBITS=127
MAX_SHOTS=100000

# Error Mitigation
ZNE_ENABLED=true
ZNE_NOISE_FACTORS=[1,2,3]
READOUT_MITIGATION_ENABLED=true

# Hybrid Mode
HYBRID_MODE_ENABLED=true
CLASSICAL_OPTIMIZER=COBYLA
TRANSPILE_OPTIMIZATION_LEVEL=3

# =====================
# PAKIT STORAGE
# =====================
# Pakit Storage
PAKIT_API_PORT=8001
DAG_BACKEND_ENABLED=true
DAG_REPLICATION_FACTOR=3
DAG_QUANTUM_COMPRESSION=true
ZK_PROOF_ENABLED=true
ZK_PROOF_SYSTEM=groth16
PAKIT_PUBLIC_MODE=view-only
MAX_FILE_SIZE=104857600
CACHE_MAX_SIZE=10737418240

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
