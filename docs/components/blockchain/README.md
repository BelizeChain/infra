# BelizeChain Blockchain Node - Standalone Deployment

This directory contains the standalone deployment configuration for the BelizeChain blockchain node.

## Quick Start

```bash
# Build and start blockchain node
docker compose up -d

# View logs
docker compose logs -f

# Check health
curl http://localhost:9933/health

# Connect via WebSocket
wscat -c ws://localhost:9944
```

## Requirements

- Docker 20.10+
- Docker Compose 2.0+
- 50GB disk space (chain data)
- 4GB RAM minimum

## Exposed Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 30333 | TCP | P2P networking (libp2p) |
| 9933 | HTTP | JSON-RPC API |
| 9944 | WebSocket | RPC subscriptions |
| 9615 | HTTP | Prometheus metrics |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RUST_LOG` | `info,runtime=debug` | Logging level |
| `BELIZECHAIN_CHAIN` | `dev` | Chain specification |
| `BELIZECHAIN_BASE_PATH` | `/data` | Data directory |
| `NODE_NAME` | `BelizeChain-Standalone` | Node identifier |

## Production Configuration

For production deployment, modify:

```yaml
command: >
  --chain chain_spec.json
  --base-path /data
  --validator
  --rpc-external
  --ws-external
  --prometheus-external
  --name "BelizeChain-Validator-01"
  --bootnodes /ip4/BOOTSTRAP_IP/tcp/30333/p2p/PEER_ID
```

## Integration with Other Components

Other BelizeChain components connect via:

```bash
# WebSocket RPC (Python components - Nawal, Kinich, Pakit)
BLOCKCHAIN_RPC=ws://belizechain-node-standalone:9944

# HTTP RPC (UI applications)
NEXT_PUBLIC_BLOCKCHAIN_RPC=http://localhost:9933
NEXT_PUBLIC_BLOCKCHAIN_WS=ws://localhost:9944
```

## Kubernetes Deployment

For Kubernetes, use the Helm chart instead:

```bash
helm install belizechain-node ../helm/belizechain \
  -f ../helm/belizechain/values-blockchain-only.yaml \
  --namespace belizechain
```
