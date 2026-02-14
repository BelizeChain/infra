# Istio Service Mesh Configuration for BelizeChain

This directory contains the complete Istio service mesh configuration for BelizeChain's multi-component architecture.

## Prerequisites

1. **Kubernetes cluster** (1.24+)
2. **Istio installed** (1.20+)
3. **kubectl** configured
4. **istioctl** CLI tool

## Installation

### 1. Install Istio

```bash
# Download Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Install with production profile
istioctl install --set profile=production -y

# Verify installation
kubectl get pods -n istio-system
```

### 2. Enable Sidecar Injection

```bash
# Label namespace for automatic sidecar injection
kubectl label namespace belizechain istio-injection=enabled

# Verify label
kubectl get namespace belizechain --show-labels
```

### 3. Deploy Istio Configurations

```bash
# Apply in order
kubectl apply -f peer-authentication.yaml
kubectl apply -f gateway.yaml
kubectl apply -f destination-rules.yaml
kubectl apply -f virtual-services.yaml
kubectl apply -f authorization-policies.yaml
```

### 4. Verify Configuration

```bash
# Check Istio configuration status
istioctl analyze -n belizechain

# View gateway
kubectl get gateway -n belizechain

# View virtual services
kubectl get virtualservice -n belizechain

# View peer authentication
kubectl get peerauthentication -n belizechain
```

## Configuration Files

### 1. **gateway.yaml**
Defines ingress gateways for external traffic:
- **belizechain-gateway**: Main gateway (HTTP/HTTPS, WebSocket)
- **pakit-public-gateway**: Public storage API (no auth)

**Exposed Domains:**
- `rpc.belizechain.bz` - Blockchain RPC
- `ai.belizechain.bz` - Nawal AI
- `quantum.belizechain.bz` - Kinich Quantum
- `storage.belizechain.bz` - Pakit Public Storage
- `gov.belizechain.bz` - Blue Hole Portal
- `wallet.belizechain.bz` - Maya Wallet
- `explorer.belizechain.bz` - Kijka Explorer

### 2. **virtual-services.yaml**
Defines routing rules for each service:
- Timeout configurations
- Retry policies
- WebSocket upgrade handling
- Traffic splitting between subsets

**Key Features:**
- **Blockchain WebSocket**: No timeout for persistent connections
- **Nawal**: 5-minute timeout for FL tasks
- **Kinich**: 10-minute timeout for quantum jobs
- **Pakit**: Public/internal endpoint separation

### 3. **peer-authentication.yaml**
Configures mTLS for inter-service communication:
- **STRICT mode**: All internal services (default)
- **PERMISSIVE mode**: Pakit public endpoints
- **DISABLE mode**: Blockchain P2P port (30333)

**Security Levels:**
```
┌─────────────────────────────────────────┐
│ STRICT (Default)                        │
│ ├─ Nawal ↔ Blockchain (encrypted)      │
│ ├─ Kinich ↔ Blockchain (encrypted)     │
│ └─ PostgreSQL ↔ Services (encrypted)   │
├─────────────────────────────────────────┤
│ PERMISSIVE                              │
│ ├─ Pakit public API (allow plaintext)  │
│ └─ Blockchain RPC (public access)      │
├─────────────────────────────────────────┤
│ DISABLE                                 │
│ └─ Blockchain P2P (external nodes)     │
└─────────────────────────────────────────┘
```

### 4. **authorization-policies.yaml**
Defines access control policies:
- **pakit-public-access**: Anyone can upload/download
- **pakit-internal-access**: Only blockchain service accounts
- **nawal-blockchain-integration**: FL API public, rewards internal
- **deny-postgres/redis**: Block external access to databases

**Authorization Flow:**
```
Public User → Pakit Upload API ✅ (allowed)
Public User → Pakit Register Proof ❌ (denied)
Blockchain SA → Pakit Register Proof ✅ (allowed)
External NS → PostgreSQL ❌ (denied)
```

### 5. **destination-rules.yaml**
Configures traffic management:
- Load balancing strategies
- Connection pooling
- Circuit breaking
- Outlier detection
- Traffic subsets (public/internal)

**Load Balancing:**
- **Blockchain**: Round-robin (high throughput)
- **Nawal**: Consistent hash by participant ID (session affinity)
- **Kinich**: Least connections (expensive jobs)
- **Pakit**: Round-robin with subsets

## TLS Certificate Setup

### Create TLS Secret

```bash
# Using Let's Encrypt (certbot)
certbot certonly --dns-cloudflare \
  -d '*.belizechain.bz' \
  -d 'belizechain.bz'

# Create Kubernetes secret
kubectl create secret tls belizechain-tls-cert \
  --cert=/etc/letsencrypt/live/belizechain.bz/fullchain.pem \
  --key=/etc/letsencrypt/live/belizechain.bz/privkey.pem \
  -n istio-system
```

### Using cert-manager (Automated)

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: belizechain-tls
  namespace: istio-system
spec:
  secretName: belizechain-tls-cert
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - belizechain.bz
    - '*.belizechain.bz'
```

## Service Mesh Features

### Observability

```bash
# Install Kiali (service mesh dashboard)
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

# Access Kiali
istioctl dashboard kiali

# Install Jaeger (distributed tracing)
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml

# Access Jaeger
istioctl dashboard jaeger
```

### Traffic Management

```bash
# Canary deployment (10% traffic to new version)
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: nawal-canary
  namespace: belizechain
spec:
  hosts:
    - nawal.belizechain.svc.cluster.local
  http:
    - match:
        - headers:
            x-version:
              exact: v2
      route:
        - destination:
            host: nawal.belizechain.svc.cluster.local
            subset: v2
    - route:
        - destination:
            host: nawal.belizechain.svc.cluster.local
            subset: v1
          weight: 90
        - destination:
            host: nawal.belizechain.svc.cluster.local
            subset: v2
          weight: 10
EOF
```

### Circuit Breaking

Already configured in `destination-rules.yaml`:
- **Consecutive errors**: 3-10 depending on service
- **Ejection time**: 30s-300s
- **Max connections**: Tuned per service

### Fault Injection (Testing)

```bash
# Inject 10% failure rate for testing
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: pakit-fault-injection
  namespace: belizechain
spec:
  hosts:
    - pakit.belizechain.svc.cluster.local
  http:
    - fault:
        abort:
          percentage:
            value: 10
          httpStatus: 500
      route:
        - destination:
            host: pakit.belizechain.svc.cluster.local
EOF
```

## Monitoring & Troubleshooting

### Check mTLS Status

```bash
# Verify mTLS is enabled
istioctl authn tls-check nawal.belizechain

# Expected output:
# HOST:PORT                          STATUS     SERVER     CLIENT
# nawal.belizechain.svc.cluster...   OK         STRICT     ISTIO_MUTUAL
```

### View Service Graph

```bash
# Open Kiali dashboard
istioctl dashboard kiali

# Navigate to Graph view
# Select namespace: belizechain
# View traffic flow between components
```

### Trace Requests

```bash
# Open Jaeger dashboard
istioctl dashboard jaeger

# Search for traces:
# Service: nawal
# Operation: POST /api/v1/rounds/start
# View distributed trace across blockchain, nawal, postgres
```

### Debug Configuration

```bash
# Analyze Istio configuration for errors
istioctl analyze -n belizechain

# View Envoy proxy configuration for a pod
istioctl proxy-config cluster nawal-pod-xyz -n belizechain

# View route configuration
istioctl proxy-config route nawal-pod-xyz -n belizechain

# View listener configuration
istioctl proxy-config listener nawal-pod-xyz -n belizechain
```

### Common Issues

#### 1. **503 Service Unavailable**
```bash
# Check if service exists
kubectl get svc -n belizechain

# Check if pods are ready
kubectl get pods -n belizechain

# Check Envoy logs
kubectl logs nawal-pod-xyz -c istio-proxy -n belizechain
```

#### 2. **mTLS Connection Refused**
```bash
# Verify peer authentication
kubectl get peerauthentication -n belizechain -o yaml

# Check destination rule
kubectl get destinationrule pakit -n belizechain -o yaml
```

#### 3. **Authorization Policy Denied**
```bash
# View authorization policies
kubectl get authorizationpolicy -n belizechain

# Check specific policy
kubectl describe authorizationpolicy pakit-public-access -n belizechain

# View Envoy access logs
kubectl logs pakit-pod-xyz -c istio-proxy --tail=100 -n belizechain
```

## Security Best Practices

1. **Enable mTLS globally** (already configured)
2. **Restrict PostgreSQL/Redis** to namespace only (configured)
3. **Separate public/internal Pakit access** (configured)
4. **Use service accounts** for authorization (required)
5. **Rotate TLS certificates** every 90 days
6. **Monitor unauthorized access** via Kiali/Jaeger
7. **Enable request authentication** for sensitive APIs

## Performance Tuning

### High-Throughput Services (Blockchain RPC)
```yaml
connectionPool:
  tcp:
    maxConnections: 1000
  http:
    http2MaxRequests: 1000
```

### Long-Running Tasks (Nawal, Kinich)
```yaml
timeout: 600s  # 10 minutes
retries:
  attempts: 1  # No retries for expensive operations
```

### Session Affinity (Nawal FL)
```yaml
loadBalancer:
  consistentHash:
    httpHeaderName: "X-Participant-ID"
```

## Rollback

```bash
# Remove Istio configurations
kubectl delete -f authorization-policies.yaml
kubectl delete -f virtual-services.yaml
kubectl delete -f destination-rules.yaml
kubectl delete -f gateway.yaml
kubectl delete -f peer-authentication.yaml

# Uninstall Istio
istioctl uninstall --purge -y

# Remove label from namespace
kubectl label namespace belizechain istio-injection-
```

## References

- [Istio Documentation](https://istio.io/latest/docs/)
- [Istio Security Best Practices](https://istio.io/latest/docs/ops/best-practices/security/)
- [Observability with Kiali](https://kiali.io/docs/)
