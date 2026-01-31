# Nawal Federated Learning - Standalone Deployment

This directory contains the standalone deployment for Nawal, BelizeChain's privacy-preserving federated learning system.

## Quick Start

```bash
# Set required passwords
export POSTGRES_PASSWORD=your_secure_password
export REDIS_PASSWORD=your_secure_password

# Start all services
docker compose up -d

# View logs
docker compose logs -f nawal-server

# Check health
curl http://localhost:8080/health

# Access API documentation
open http://localhost:8080/docs
```

## Requirements

- Docker 20.10+
- Docker Compose 2.0+
- 100GB disk space (models + checkpoints)
- **8GB RAM minimum** (16GB recommended)
- **GPU recommended** for training (NVIDIA with Docker runtime)
- BelizeChain node accessible at `ws://belizechain-node:9944` (can be remote)

## Architecture

```
┌─────────────────────────────────────────────┐
│ Nawal FL Server (Port 8080)                 │
│ ├─ FastAPI REST endpoints                   │
│ ├─ Flower federated learning orchestrator   │
│ ├─ Genetic algorithm for model evolution    │
│ └─ Differential privacy (DP-SGD)            │
└─────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ PostgreSQL   │ │ Redis Cache  │ │ IPFS Storage │
│ (Metadata)   │ │ (Sessions)   │ │ (Models)     │
└──────────────┘ └──────────────┘ └──────────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ BelizeChain Node (External/Remote)           │
│ └─ Staking pallet (PoUW rewards)             │
└──────────────────────────────────────────────┘
```

## Service Dependencies

### Required Services (Must be running)
- ✅ **PostgreSQL** - Stores participant metadata, training history, compliance records
- ✅ **Redis** - Caches session data, participant states, temporary model weights
- ✅ **IPFS** - Stores trained models and checkpoints (decentralized)

### Optional Services (Can run degraded)
- 🔌 **BelizeChain** - For PoUW reward submission (set `BLOCKCHAIN_ENABLED=false` to disable)

## Environment Variables

### Critical Configuration
```bash
# Database
POSTGRES_PASSWORD=<required>          # PostgreSQL admin password
POSTGRES_HOST=postgres.belizechain.svc.cluster.local  # FQDN for K8s
POSTGRES_DB=belizechain
POSTGRES_USER=belizechain

# Cache
REDIS_PASSWORD=<required>             # Redis auth password
REDIS_HOST=redis.belizechain.svc.cluster.local

# Blockchain Integration
BLOCKCHAIN_RPC=ws://belizechain-node.belizechain.svc.cluster.local:9944
BLOCKCHAIN_ENABLED=true               # Set false for standalone mode

# IPFS
IPFS_API=http://ipfs.belizechain.svc.cluster.local:5001
```

### Federated Learning Settings
```bash
NAWAL_MIN_PARTICIPANTS=2              # Minimum clients for FL round
NAWAL_MAX_PARTICIPANTS=100            # Maximum clients per round
NAWAL_ROUNDS_PER_EPOCH=10             # Training rounds
NAWAL_MIN_FIT_CLIENTS=2               # Minimum for aggregation
```

### Privacy Settings
```bash
DIFFERENTIAL_PRIVACY_ENABLED=true     # Enable DP-SGD
DP_NOISE_MULTIPLIER=1.1               # Privacy budget (higher = more private)
DP_MAX_GRAD_NORM=1.0                  # Gradient clipping threshold
DP_DELTA=1e-5                         # Privacy parameter
```

## GPU Support

Uncomment in `docker-compose.yml`:

```yaml
nawal-server:
  runtime: nvidia
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
    - CUDA_VISIBLE_DEVICES=0
```

Verify GPU access:
```bash
docker compose exec nawal-server nvidia-smi
```

## Blockchain Integration

### PoUW Reward Submission

Nawal submits training results to `pallet-belize-staking`:

```python
# After FL round completion
await staking_connector.submit_training_result(
    participant_id="5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY",
    genome_id="genome_001",
    quality_score=85.5,      # 40% weight
    timeliness_score=92.0,   # 30% weight
    honesty_score=98.5,      # 30% weight
    model_hash="QmHash..."
)
```

Rewards are paid in **DALLA tokens** based on composite score.

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check (includes dependency status) |
| `/api/v1/rounds/start` | POST | Start new FL round |
| `/api/v1/participants/enroll` | POST | Register new participant |
| `/api/v1/models/latest` | GET | Get latest global model |
| `/api/v1/genomes/{id}` | GET | Get genome architecture |
| `/docs` | GET | OpenAPI documentation |

## Production Deployment

### Kubernetes with GPU Node Pool

```bash
# Deploy to GPU-enabled node pool
helm install nawal ../helm/belizechain \
  -f ../helm/belizechain/values-gpu.yaml \
  --set nawal.enabled=true \
  --set nawal.gpu.enabled=true \
  --set nawal.gpu.count=1 \
  --namespace belizechain
```

### Resource Requirements

**Development:**
- CPU: 2 cores
- RAM: 4GB
- Storage: 50GB

**Production (with GPU):**
- CPU: 4 cores
- RAM: 16GB
- GPU: 1x NVIDIA T4 or better
- Storage: 500GB NVMe

## Monitoring

Prometheus metrics exposed at `http://localhost:8080/metrics`:

- `nawal_participants_total` - Active FL participants
- `nawal_rounds_completed` - Completed training rounds
- `nawal_model_accuracy` - Current global model accuracy
- `nawal_privacy_budget_spent` - Cumulative privacy expenditure

## Troubleshooting

### Service won't start
```bash
# Check dependency health
docker compose ps

# View detailed logs
docker compose logs nawal-server --tail=100

# Verify database connection
docker compose exec nawal-server psql -h postgres -U belizechain -d belizechain
```

### Blockchain connection fails
```bash
# Test RPC endpoint
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' \
  http://belizechain-node:9933

# Disable blockchain integration for testing
export BLOCKCHAIN_ENABLED=false
docker compose up -d
```

### Out of memory during training
```bash
# Reduce batch size and participants
export NAWAL_MAX_PARTICIPANTS=10
export MODEL_BATCH_SIZE=16
docker compose up -d
```
