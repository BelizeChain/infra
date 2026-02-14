# BelizeChain Production Deployment Guide

**Last Updated:** February 14, 2026  
**Target Environment:** Production  
**Recommended By:** Infrastructure Team

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Infrastructure Requirements](#infrastructure-requirements)
3. [Security Hardening](#security-hardening)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Rollback Procedures](#rollback-procedures)
7. [Monitoring & Alerts](#monitoring--alerts)

---

## Pre-Deployment Checklist

### Environment Preparation

- [ ] Production Kubernetes cluster running (v1.28+)
- [ ] Helm 3.14+ installed on deployment machine
- [ ] kubectl configured with production cluster access
- [ ] ArgoCD installed and configured (GitOps)
- [ ] Istio service mesh deployed (v1.20+)
- [ ] Cert-manager configured for TLS certificates
- [ ] External secrets operator installed (for secret management)

### Configuration Files

- [ ] `.env` file created from `.env.example` with production values
- [ ] All "CHANGE_ME" and "YOUR_" placeholders replaced
- [ ] Strong passwords generated (32+ characters)
- [ ] API keys generated and stored securely
- [ ] Azure Quantum credentials configured
- [ ] Database credentials rotated
- [ ] Redis password set

### Security Review

- [ ] All secrets stored in Kubernetes secrets (NOT in Git)
- [ ] TLS certificates obtained for all public endpoints
- [ ] Network policies configured
- [ ] RBAC policies reviewed and applied
- [ ] External access restricted to necessary services only
- [ ] Firewall rules configured
- [ ] DDoS protection enabled
- [ ] Rate limiting configured

### Storage Preparation

- [ ] Persistent volumes provisioned:
  - Blockchain data: 2Ti (production)
  - Pakit storage: 1Ti (production)
  - Pakit cache: 100Gi
  - PostgreSQL: 500Gi
  - Prometheus: 500Gi
- [ ] Storage class supports CSI snapshots (for backups)
- [ ] Backup solution configured and tested

### DNS & Load Balancing

- [ ] DNS records configured:
  - rpc.belizechain.org → Blockchain RPC
  - ws.belizechain.org → Blockchain WebSocket
  - storage.belizechain.org → Pakit API
  - ai.belizechain.org → Nawal API
  - quantum.belizechain.org → Kinich API
  - api.belizechain.org → Main API Gateway
- [ ] Load balancer provisioned
- [ ] Health check endpoints configured
- [ ] SSL/TLS termination configured

---

## Infrastructure Requirements

### Minimum Cluster Resources

#### Kubernetes Nodes

**Control Plane:**
- 3 nodes minimum (high availability)
- 4 vCPU, 8Gi RAM per node
- 100Gi SSD storage per node

**Worker Nodes:**
- 5 nodes minimum
- 8 vCPU, 32Gi RAM per node
- 200Gi SSD storage per node

**GPU Nodes (for Nawal AI):**
- 2 nodes minimum
- 8 vCPU, 32Gi RAM per node
- 1x NVIDIA T4 or better GPU
- 100Gi SSD storage per node

#### Resource Allocation

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Replicas |
|-----------|-------------|-----------|----------------|--------------|----------|
| Blockchain Node | 4 cores | 8 cores | 16Gi | 32Gi | 3 |
| Pakit | 2 cores | 4 cores | 8Gi | 16Gi | 3 |
| Nawal | 4 cores | 8 cores | 16Gi | 32Gi | 2 |
| Kinich | 2 cores | 4 cores | 8Gi | 16Gi | 2 |
| PostgreSQL | 2 cores | 4 cores | 8Gi | 16Gi | 1 |
| Redis | 1 core | 2 cores | 4Gi | 8Gi | 1 |

**Total Cluster Minimum:** 40 vCPU, 128Gi RAM

### Network Requirements

- **Bandwidth:** 1 Gbps minimum, 10 Gbps recommended
- **Latency:** <50ms between nodes (intra-cluster)
- **Ingress:** 100 Mbps minimum for public traffic
- **Egress:** Unlimited (for IPFS, quantum backends)

---

## Security Hardening

### 1. Kubernetes Security

```bash
# Apply security policies
kubectl apply -f k8s/istio/peer-authentication.yaml
kubectl apply -f k8s/istio/authorization-policies.yaml

# Enable pod security standards
kubectl label namespace belizechain-production \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

### 2. Network Policies

All network policies are defined in `k8s/istio/`:
- Only allow inter-service communication on required ports
- Block all ingress by default except through Istio Gateway
- Restrict egress to known external services

### 3. Secrets Management

**DO NOT store secrets in Git. Use Kubernetes secrets or external secret management.**

```bash
# Create namespace
kubectl create namespace belizechain-production

# Create secrets from .env file
kubectl create secret generic belizechain-secrets \
  --from-env-file=.env \
  --namespace=belizechain-production

# Create database credentials
kubectl create secret generic postgres-credentials \
  --from-literal=username=belizechain \
  --from-literal=password="$(openssl rand -base64 32)" \
  --namespace=belizechain-production

# Create Redis password
kubectl create secret generic redis-credentials \
  --from-literal=password="$(openssl rand -base64 32)" \
  --namespace=belizechain-production
```

### 4. TLS Configuration

```bash
# Install cert-manager (if not already installed)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@belizechain.org
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: istio
EOF
```

### 5. RBAC Configuration

```bash
# Create service accounts with minimal permissions
kubectl create serviceaccount blockchain-node -n belizechain-production
kubectl create serviceaccount pakit-service -n belizechain-production
kubectl create serviceaccount nawal-service -n belizechain-production

# Apply RBAC policies (defined in your Helm charts)
```

---

## Deployment Steps

### Option 1: Helm Deployment (Recommended)

```bash
# 1. Add Helm repository (if using private registry)
helm repo add belizechain https://charts.belizechain.org
helm repo update

# 2. Install with production values
helm install belizechain helm/belizechain \
  --namespace belizechain-production \
  --create-namespace \
  --values helm/belizechain/values-production.yaml \
  --timeout 30m \
  --wait

# 3. Verify deployment
helm list -n belizechain-production
kubectl get pods -n belizechain-production
```

### Option 2: ArgoCD GitOps (Production Recommended)

```bash
# 1. Apply ArgoCD application manifest
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application-production.yaml

# 2. Sync application
argocd app sync belizechain-production

# 3. Monitor deployment
argocd app get belizechain-production
argocd app wait belizechain-production --health
```

### Option 3: Manual Kubernetes Deployment

```bash
# 1. Apply base manifests
kubectl apply -k k8s/base -n belizechain-production

# 2. Apply Istio configurations
kubectl apply -f k8s/istio/ -n belizechain-production

# 3. Verify all pods are running
kubectl get pods -n belizechain-production -w
```

### Database Initialization

```bash
# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres \
  -n belizechain-production --timeout=300s

# Initialize database schema
kubectl exec -it deployment/postgres -n belizechain-production -- \
  psql -U belizechain -d belizechain -f /docker-entrypoint-initdb.d/init.sql
```

---

## Post-Deployment Verification

### 1. Health Checks

```bash
# Check all pods are running
kubectl get pods -n belizechain-production

# Expected output: All pods in Running state with READY 1/1 or 2/2
NAME                              READY   STATUS    RESTARTS   AGE
blockchain-node-0                 1/1     Running   0          5m
blockchain-node-1                 1/1     Running   0          5m
blockchain-node-2                 1/1     Running   0          5m
pakit-xxxxxxxxxx-xxxxx            1/1     Running   0          5m
nawal-xxxxxxxxxx-xxxxx            1/1     Running   0          5m
kinich-xxxxxxxxxx-xxxxx           1/1     Running   0          5m
postgres-0                        1/1     Running   0          5m
redis-0                           1/1     Running   0          5m
```

### 2. Service Connectivity

```bash
# Test blockchain RPC
kubectl run test-curl --rm -it --image=curlimages/curl -- \
  curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' \
  http://blockchain-service.belizechain-production.svc.cluster.local:9933

# Test Pakit API
kubectl run test-curl --rm -it --image=curlimages/curl -- \
  curl http://pakit-service.belizechain-production.svc.cluster.local:8001/health

# Test Nawal API
kubectl run test-curl --rm -it --image=curlimages/curl -- \
  curl http://nawal-service.belizechain-production.svc.cluster.local:8080/health

# Test Kinich API
kubectl run test-curl --rm -it --image=curlimages/curl -- \
  curl http://kinich-service.belizechain-production.svc.cluster.local:8888/health
```

### 3. External Access Verification

```bash
# Test public endpoints (from outside cluster)
curl https://rpc.belizechain.org -X POST -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}'

curl https://storage.belizechain.org/health
curl https://ai.belizechain.org/health
curl https://quantum.belizechain.org/health
```

### 4. Database Connection

```bash
kubectl exec -it deployment/postgres -n belizechain-production -- \
  psql -U belizechain -c "SELECT version();"
```

### 5. Monitoring Stack

```bash
# Access Grafana (via port-forward for initial access)
kubectl port-forward svc/grafana 3000:3000 -n belizechain-production

# Visit http://localhost:3000
# Default credentials: admin / (password from .env GRAFANA_ADMIN_PASSWORD)

# Check Prometheus targets
kubectl port-forward svc/prometheus 9090:9090 -n belizechain-production
# Visit http://localhost:9090/targets
```

### 6. Blockchain Sync Verification

```bash
# Check blockchain sync status
kubectl logs -f statefulset/blockchain-node -n belizechain-production | grep -i "best:"

# Expected: Block numbers increasing, no errors
```

---

## Rollback Procedures

### Helm Rollback

```bash
# List revisions
helm history belizechain -n belizechain-production

# Rollback to previous revision
helm rollback belizechain -n belizechain-production

# Rollback to specific revision
helm rollback belizechain 2 -n belizechain-production
```

### ArgoCD Rollback

```bash
# Rollback to previous version
argocd app rollback belizechain-production

# Rollback to specific revision
argocd app rollback belizechain-production <REVISION_ID>
```

### Manual Rollback

```bash
# Scale down new deployment
kubectl scale deployment pakit --replicas=0 -n belizechain-production

# Apply previous manifests from Git history
git checkout <PREVIOUS_COMMIT>
kubectl apply -k k8s/base -n belizechain-production
```

---

## Monitoring & Alerts

### Key Metrics to Monitor

1. **Blockchain Node:**
   - Block height (should increase every 6 seconds)
   - Peer count (should be >3)
   - Transaction pool size
   - Memory usage (<75% of limit)

2. **Pakit Storage:**
   - API response time (<100ms p95)
   - Storage usage (<80% of capacity)
   - DAG replication factor (should be 5)
   - ZK proof verification rate

3. **Nawal AI:**
   - Active training sessions
   - Byzantine detection events
   - Data poisoning alerts
   - GPU utilization

4. **Kinich Quantum:**
   - Quantum job queue length
   - Error mitigation success rate
   - Backend availability (Azure/IBM)

5. **Infrastructure:**
   - Pod restart count (should be 0)
   - CPU usage per service
   - Memory usage per service
   - Disk I/O
   - Network throughput

### Grafana Dashboards

Pre-configured dashboards available at `/monitoring/grafana/dashboards/`:
- `blockchain-health.json` - Blockchain metrics
- Custom dashboards for each service

### Alerting Rules

Configure alerts in Prometheus for:
- Pod crashes (restart count > 5 in 1 hour)
- High memory usage (>90%)
- High CPU usage (>90%)
- Blockchain sync lag (>10 blocks behind)
- Storage capacity (>85% full)
- Service downtime (>5 minutes)

```yaml
# Example alert rule
groups:
- name: belizechain-alerts
  rules:
  - alert: HighPodRestarts
    expr: rate(kube_pod_container_status_restarts_total{namespace="belizechain-production"}[1h]) > 5
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Pod {{ $labels.pod }} is restarting frequently"
```

---

## Maintenance Windows

### Recommended Schedule

- **Daily:** Automated backups at 02:00 UTC
- **Weekly:** Security patching (Sundays 04:00-06:00 UTC)
- **Monthly:** Full system audit and capacity review

### During Maintenance

1. Set maintenance mode in UI applications
2. Scale up backup nodes
3. Perform updates with rolling deployment
4. Verify all services after updates
5. Monitor for 30 minutes post-update
6. Deactivate maintenance mode

---

## Support Contacts

- **Infrastructure Team:** infra@belizechain.org
- **Security Team:** security@belizechain.org
- **On-Call:** +XXX-XXX-XXXX (24/7)

---

## Additional Resources

- [Security Best Practices](./security-best-practices.md)
- [Secrets Management Guide](./secrets-management.md)
- [Disaster Recovery Plan](./disaster-recovery.md)
- [Performance Tuning Guide](./performance-tuning.md)
