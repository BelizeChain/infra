# BelizeChain Security Best Practices

**Last Updated:** February 14, 2026  
**Classification:** Internal  
**Owner:** Security Team

## Table of Contents

1. [Security Principles](#security-principles)
2. [Secrets Management](#secrets-management)
3. [Network Security](#network-security)
4. [Access Control](#access-control)
5. [Data Protection](#data-protection)
6. [Monitoring & Incident Response](#monitoring--incident-response)
7. [Compliance](#compliance)

---

## Security Principles

### Defense in Depth

BelizeChain implements multiple layers of security:

1. **Perimeter Security:** Firewalls, DDoS protection, WAF
2. **Network Security:** Service mesh (Istio), network policies, mTLS
3. **Application Security:** Input validation, rate limiting, authentication
4. **Data Security:** Encryption at rest and in transit, ZK proofs
5. **Identity Security:** BelizeID verification, RBAC, OAuth 2.0

### Zero Trust Architecture

- Never trust, always verify
- Assume breach mentality
- Least privilege access
- Microsegmentation
- Continuous verification

---

## Secrets Management

### CRITICAL RULES

**⚠️ NEVER commit secrets to Git repositories**

- No `.env` files in version control
- No hardcoded passwords, API keys, or tokens
- Use `.gitignore` to exclude sensitive files
- Scan commits for secrets before pushing

### Kubernetes Secrets

```bash
# Create secrets from literal values
kubectl create secret generic database-credentials \
  --from-literal=username=belizechain \
  --from-literal=password="$(openssl rand -base64 32)" \
  --namespace=belizechain-production

# Create secrets from files
kubectl create secret generic api-keys \
  --from-file=azure-quantum-key=./secrets/azure-key.txt \
  --from-file=ibm-quantum-key=./secrets/ibm-key.txt \
  --namespace=belizechain-production

# Create TLS secrets
kubectl create secret tls belizechain-tls \
  --cert=./certs/tls.crt \
  --key=./certs/tls.key \
  --namespace=belizechain-production
```

### External Secrets Operator (Recommended)

Use External Secrets Operator to sync secrets from external vaults:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: azure-keyvault
  namespace: belizechain-production
spec:
  provider:
    azurekv:
      authType: ManagedIdentity
      vaultUrl: "https://belizechain-vault.vault.azure.net"

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: belizechain-production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: azure-keyvault
    kind: SecretStore
  target:
    name: postgres-credentials
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: postgres-password
```

### Secret Rotation

- **Database Passwords:** Rotate every 90 days
- **API Keys:** Rotate every 180 days
- **TLS Certificates:** Auto-renew 30 days before expiration
- **Service Account Tokens:** Rotate annually

### Password Requirements

- **Minimum Length:** 32 characters for production
- **Complexity:** Mix of uppercase, lowercase, numbers, symbols
- **Generation:** Use cryptographically secure random generators

```bash
# Generate strong password
openssl rand -base64 32

# Generate API key
uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-'
```

---

## Network Security

### Service Mesh (Istio)

All service-to-service communication encrypted with mTLS:

```yaml
# Enforce strict mTLS
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: belizechain-production
spec:
  mtls:
    mode: STRICT
```

### Network Policies

Deny all traffic by default, allow only required connections:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: belizechain-production
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---
# Allow blockchain node to access database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: blockchain-to-postgres
  namespace: belizechain-production
spec:
  podSelector:
    matchLabels:
      app: blockchain-node
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
```

### Firewall Rules

**Ingress (Public-Facing):**
- 443/tcp (HTTPS) - Istio Gateway only
- 80/tcp (HTTP) - Redirect to HTTPS
- 30333/tcp (Blockchain P2P) - Whitelisted nodes only

**Egress:**
- 443/tcp (HTTPS) - Azure Quantum, IBM Quantum, IPFS gateways
- 53/udp (DNS) - Internal DNS servers
- Block all other egress by default

### DDoS Protection

- Use cloud provider DDoS protection (Azure DDoS Protection Standard)
- Rate limiting at Istio Gateway level
- Connection limits per IP

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: ratelimit
  namespace: istio-system
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: GATEWAY
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.filters.http.local_ratelimit
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
          stat_prefix: http_local_rate_limiter
          token_bucket:
            max_tokens: 1000
            tokens_per_fill: 100
            fill_interval: 1s
```

---

## Access Control

### Role-Based Access Control (RBAC)

Implement least privilege access:

```yaml
# Read-only developer access
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-readonly
  namespace: belizechain-production
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "jobs", "logs"]
  verbs: ["get", "list", "watch"]

---
# Database admin access
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: database-admin
  namespace: belizechain-production
rules:
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["postgres-0"]
```

### Service Accounts

Each service runs with its own service account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: blockchain-node
  namespace: belizechain-production
automountServiceAccountToken: false

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pakit-service
  namespace: belizechain-production
automountServiceAccountToken: false
```

### Authentication & Authorization

**External Access:**
- OAuth 2.0 / OIDC for user authentication
- JWT tokens for API access
- BelizeID verification for blockchain transactions

**Internal Services:**
- Service mesh mTLS for authentication
- Istio authorization policies for authorization

```yaml
# Require BelizeID for Pakit uploads
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: pakit-upload-requires-belizeid
  namespace: belizechain-production
spec:
  selector:
    matchLabels:
      app: pakit
  action: ALLOW
  rules:
  - when:
    - key: request.headers[x-belizeid-verified]
      values: ["true"]
    to:
    - operation:
        methods: ["POST", "PUT"]
        paths: ["/upload", "/api/files"]
```

### Multi-Factor Authentication (MFA)

- **All administrative access:** Require MFA
- **Production deployments:** Require MFA
- **Database access:** Require MFA + IP whitelisting

---

## Data Protection

### Encryption at Rest

**Database (PostgreSQL):**
```yaml
# Enable transparent data encryption
volumeClaimTemplates:
- metadata:
    name: postgres-data
  spec:
    storageClassName: encrypted-ssd
    accessModes: ["ReadWriteOnce"]
    resources:
      requests:
        storage: 500Gi
```

**Blockchain Storage:**
- Enable filesystem encryption (LUKS)
- Encrypt backups before uploading to cloud storage

**Pakit Storage:**
- ZK proof encryption of sensitive files
- Quantum-resistant compression algorithms

### Encryption in Transit

- **All external traffic:** TLS 1.3
- **All internal traffic:** mTLS (Istio)
- **Database connections:** Require SSL

```yaml
# PostgreSQL SSL configuration
env:
- name: POSTGRES_SSL_MODE
  value: "require"
- name: POSTGRES_SSL_CERT
  valueFrom:
    secretKeyRef:
      name: postgres-tls
      key: tls.crt
- name: POSTGRES_SSL_KEY
  valueFrom:
    secretKeyRef:
      name: postgres-tls
      key: tls.key
```

### Data Classification

| Classification | Description | Examples | Encryption | Access |
|----------------|-------------|----------|------------|--------|
| Public | Publicly accessible | Documentation, APIs | Optional | All |
| Internal | Internal use only | Metrics, logs | Required | Employees |
| Confidential | Sensitive business data | User data, transactions | Required | Limited |
| Secret | Critical security data | Private keys, credentials | Required | Minimal |

### Data Retention

- **Blockchain Data:** Permanent (immutable ledger)
- **Application Logs:** 90 days
- **Audit Logs:** 7 years (compliance requirement)
- **Backups:** 30 days rolling, 1 year annual snapshots
- **Temporary Files:** Delete after 24 hours

### Backup Security

```bash
# Encrypt backups before upload
tar czf - /data/blockchain | \
  gpg --encrypt --recipient backup@belizechain.org | \
  aws s3 cp - s3://belizechain-backups/blockchain-$(date +%Y%m%d).tar.gz.gpg

# Verify backup integrity
aws s3 cp s3://belizechain-backups/blockchain-$(date +%Y%m%d).tar.gz.gpg - | \
  gpg --decrypt | \
  tar tz > /dev/null && echo "Backup OK"
```

---

## Monitoring & Incident Response

### Security Monitoring

**Monitor for:**
- Unauthorized access attempts
- Privilege escalation
- Unusual network traffic patterns
- Byzantine behavior in federated learning
- Data poisoning attempts
- Gradient inversion attacks
- Failed authentication attempts (>5/minute)
- Secret access from unauthorized pods

### Audit Logging

Enable audit logging for all critical operations:

```yaml
# Kubernetes audit policy
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
  namespaces: ["belizechain-production"]
  
- level: Metadata
  resources:
  - group: "apps"
    resources: ["deployments", "statefulsets"]
  namespaces: ["belizechain-production"]
```

### Alerting

Configure immediate alerts for:
- Secrets accessed by unauthorized service accounts
- NetworkPolicy violations
- Pod crashes (potential exploitation attempts)
- Unusual API request patterns
- Byzantine detection triggers in Nawal
- ZK proof verification failures in Pakit

### Incident Response Plan

1. **Detection:** Alert triggered
2. **Assessment:** Determine severity (Critical/High/Medium/Low)
3. **Containment:** Isolate affected components
4. **Eradication:** Remove threat
5. **Recovery:** Restore normal operations
6. **Lessons Learned:** Post-mortem analysis

**Critical Incident Escalation:**
1. On-call engineer notified (5 minutes)
2. Security team notified (15 minutes)
3. CTO notified (30 minutes)
4. External authorities notified if required (24 hours)

---

## Compliance

### Regulatory Requirements

BelizeChain complies with:
- **Data Protection:** GDPR, CCPA
- **Financial Regulations:** AML/KYC requirements
- **Government Standards:** Local Belizean regulations
- **Industry Standards:** ISO 27001, SOC 2

### Privacy by Design

**Nawal Federated Learning:**
- Differential Privacy (DP-SGD) enabled in production
- No raw user data leaves local devices
- Model updates encrypted and aggregated
- Data leakage detection enabled

**BelizeID Identity Pallet:**
- PII encrypted with user-controlled keys
- Selective disclosure with ZK proofs
- Right to be forgotten implemented
- Consent management

### Audit Trail

Maintain immutable audit logs for:
- All blockchain transactions
- Administrative actions
- Secret access
- Deployment changes
- Configuration modifications

Store in tamper-proof ledger (Confidential Ledger or blockchain):

```bash
# Append audit log to Confidential Ledger
curl -X POST https://confidential-ledger.azure.com/app/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "event": "SECRET_ACCESSED",
    "service_account": "pakit-service",
    "secret_name": "azure-quantum-key",
    "timestamp": "2026-02-14T10:30:00Z",
    "justification": "Quantum job submission"
  }'
```

---

## Security Checklist

### Pre-Production

- [ ] All secrets stored in external vault (not Git)
- [ ] TLS certificates configured for all public endpoints
- [ ] mTLS enabled for all service-to-service communication
- [ ] Network policies applied (default deny)
- [ ] RBAC configured with least privilege
- [ ] Audit logging enabled
- [ ] Security monitoring alerts configured
- [ ] Vulnerability scanning enabled
- [ ] Penetration testing completed
- [ ] Security review approved

### Ongoing

- [ ] Weekly secret rotation
- [ ] Monthly security updates
- [ ] Quarterly penetration testing
- [ ] Annual compliance audit
- [ ] Continuous vulnerability scanning
- [ ] Daily backup verification
- [ ] Log review (weekly at minimum)

---

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Istio Security Best Practices](https://istio.io/latest/docs/ops/best-practices/security/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

## Contact

**Security Team:** security@belizechain.org  
**Bug Bounty Program:** bugbounty@belizechain.org  
**Emergency Hotline:** +XXX-XXX-XXXX (24/7)
