# Service Discovery Configuration Guide

This directory contains service discovery templates for BelizeChain's multi-component architecture.

## FQDN vs Short Names vs Localhost

### 1. Kubernetes FQDN (Production/Staging)
**Format:** `<service>.<namespace>.svc.cluster.local:<port>`

**Use when:**
- Deploying to Kubernetes (GKE, AKS, EKS)
- Services in different namespaces
- Istio service mesh enabled
- Cross-cluster communication

**Example:**
```bash
export BLOCKCHAIN_RPC=ws://belizechain-node.belizechain.svc.cluster.local:9944
export NAWAL_API=http://nawal.belizechain.svc.cluster.local:8080
```

### 2. Docker Compose Short Names (Development)
**Format:** `<service-name>:<port>`

**Use when:**
- Running `docker compose up` locally
- All services in same compose file
- Single-host development

**Example:**
```bash
export BLOCKCHAIN_RPC=ws://belizechain-node:9944
export POSTGRES_HOST=postgres
```

### 3. Localhost (Local Development)
**Format:** `localhost:<port>` or `127.0.0.1:<port>`

**Use when:**
- Running services directly (no containers)
- Debugging individual components
- IDE integration

**Example:**
```bash
export BLOCKCHAIN_RPC=ws://localhost:9944
export NAWAL_API=http://localhost:8080
```

## Usage in Components

### Python Components (Nawal, Kinich, Pakit)

Create environment-aware connector:

```python
import os

class ServiceDiscovery:
    @staticmethod
    def get_blockchain_url():
        # Priority: K8s FQDN > Docker > Localhost
        return os.getenv('BLOCKCHAIN_RPC') or \
               os.getenv('DOCKER_BLOCKCHAIN_RPC_WS') or \
               os.getenv('LOCAL_BLOCKCHAIN_RPC_WS') or \
               'ws://localhost:9944'
    
    @staticmethod
    def get_postgres_host():
        return os.getenv('POSTGRES_HOST') or \
               os.getenv('DOCKER_POSTGRES_HOST') or \
               'localhost'
```

### TypeScript UI Applications

```typescript
// next.config.js or .env.local
const getBlockchainUrl = () => {
  if (process.env.NODE_ENV === 'production') {
    return process.env.PROD_BLOCKCHAIN_RPC_WS || 'wss://rpc.belizechain.bz';
  }
  if (process.env.KUBERNETES_SERVICE_HOST) {
    return 'ws://belizechain-node.belizechain.svc.cluster.local:9944';
  }
  return process.env.LOCAL_BLOCKCHAIN_RPC_WS || 'ws://localhost:9944';
};
```

### Rust Blockchain Node

Service discovery not needed (listens on configured ports), but other services discover it via:

```yaml
# Kubernetes Service definition
apiVersion: v1
kind: Service
metadata:
  name: belizechain-node
  namespace: belizechain
spec:
  selector:
    app: belizechain-node
  ports:
    - name: rpc-http
      port: 9933
      targetPort: 9933
    - name: rpc-ws
      port: 9944
      targetPort: 9944
```

## Cross-Namespace Communication

### Scenario: Dev Nawal connecting to Prod Blockchain

```bash
# In belizechain-dev namespace
kubectl set env deployment/nawal \
  BLOCKCHAIN_RPC=ws://belizechain-node.belizechain-prod.svc.cluster.local:9944
```

### Scenario: Multi-Region (East US -> West US)

```bash
# Nawal in East US connecting to West US blockchain
export BLOCKCHAIN_RPC=wss://westus-blockchain.belizechain.bz:9944
```

## Environment Variable Hierarchy

Components should check in this order:

1. **Explicit environment variable** (highest priority)
2. **Kubernetes service discovery** (FQDN)
3. **Docker Compose service name**
4. **Localhost fallback** (lowest priority)

Example implementation:

```python
# nawal/config/settings.py
import os

class Settings:
    # Try explicit FQDN first
    BLOCKCHAIN_RPC = os.getenv('BLOCKCHAIN_RPC')
    
    # Fall back to auto-detected K8s service
    if not BLOCKCHAIN_RPC and os.getenv('KUBERNETES_SERVICE_HOST'):
        BLOCKCHAIN_RPC = 'ws://belizechain-node.belizechain.svc.cluster.local:9944'
    
    # Fall back to Docker Compose
    if not BLOCKCHAIN_RPC and os.path.exists('/.dockerenv'):
        BLOCKCHAIN_RPC = 'ws://belizechain-node:9944'
    
    # Final fallback to localhost
    BLOCKCHAIN_RPC = BLOCKCHAIN_RPC or 'ws://localhost:9944'
```

## Istio Service Mesh Integration

With Istio enabled, services communicate through Envoy sidecars:

```
nawal-pod -> envoy-sidecar -> istio-proxy -> envoy-sidecar -> blockchain-pod
```

Benefits:
- Automatic mTLS encryption
- Circuit breaking
- Retry logic
- Traffic shifting
- Observability (distributed tracing)

No code changes required - just use FQDN service names.

## Troubleshooting

### DNS Resolution Issues

Test from inside pod:
```bash
kubectl exec -it nawal-pod -- nslookup belizechain-node.belizechain.svc.cluster.local
```

### Connection Refused

Check service exists:
```bash
kubectl get svc -n belizechain
```

Verify endpoints:
```bash
kubectl get endpoints belizechain-node -n belizechain
```

### Cross-Namespace Access Denied

Ensure NetworkPolicy allows traffic:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-belizechain-dev
spec:
  podSelector:
    matchLabels:
      app: belizechain-node
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: belizechain-dev
```
