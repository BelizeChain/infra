# Secrets Management Guide

**Last Updated:** February 14, 2026  
**Classification:** Internal  
**Owner:** Security & Infrastructure Teams

## Table of Contents

1. [Overview](#overview)
2. [Secret Types](#secret-types)
3. [Storage Solutions](#storage-solutions)
4. [Kubernetes Secrets](#kubernetes-secrets)
5. [External Secrets Operator](#external-secrets-operator)
6. [Rotation Procedures](#rotation-procedures)
7. [Access Controls](#access-controls)
8. [Emergency Procedures](#emergency-procedures)

---

## Overview

This guide provides comprehensive instructions for managing secrets in the BelizeChain infrastructure.

### Principles

1. **Never commit secrets to version control**
2. **Use external secret management systems**
3. **Rotate secrets regularly**
4. **Implement least privilege access**
5. **Audit all secret access**

---

## Secret Types

### Database Credentials

- PostgreSQL username/password
- Redis password
- Connection strings

**Rotation Frequency:** Every 90 days

### API Keys

- Azure Quantum credentials
- IBM Quantum token
- External service API keys
- Pakit API keys

**Rotation Frequency:** Every 180 days

### TLS Certificates

- Ingress controller certificates
- Service mesh certificates
- Database SSL certificates

**Rotation Frequency:** Auto-renew 30 days before expiration

### Signing Keys

- Blockchain validator keys
- JWT signing keys
- ZK proof keys

**Rotation Frequency:** Annually (or immediately if compromised)

### Service Accounts

- Kubernetes service account tokens
- Cloud provider service principals
- Application service accounts

**Rotation Frequency:** Annually

---

## Storage Solutions

### Option 1: Kubernetes Native Secrets

**Pros:**
- Built into Kubernetes
- Simple to use
- No external dependencies

**Cons:**
- Base64 encoded (not encrypted by default)
- No automatic rotation
- Limited access auditing

**When to Use:**
- Development environments
- Non-sensitive configuration
- Temporary secrets

### Option 2: Azure Key Vault

**Pros:**
- Hardware Security Module (HSM) backed
- Comprehensive audit logging
- Integration with Azure services
- Automatic rotation support

**Cons:**
- Azure-specific
- Additional cost
- Requires Azure subscription

**When to Use:**
- Production environments
- Azure-hosted infrastructure
- Multi-tenant deployments

### Option 3: HashiCorp Vault

**Pros:**
- Cloud-agnostic
- Dynamic secret generation
- Advanced access policies
- Comprehensive audit trail

**Cons:**
- Requires separate infrastructure
- More complex setup
- Operational overhead

**When to Use:**
- Multi-cloud deployments
- Complex secret rotation requirements
- Large-scale deployments

---

## Kubernetes Secrets

### Creating Secrets

#### From Literal Values

```bash
kubectl create secret generic database-credentials \
  --from-literal=username=belizechain \
  --from-literal=password="$(openssl rand -base64 32)" \
  --namespace=belizechain-production
```

#### From Files

```bash
# Create secret from .env file
kubectl create secret generic app-config \
  --from-env-file=.env.production \
  --namespace=belizechain-production

# Create secret from individual files
kubectl create secret generic tls-certs \
  --from-file=tls.crt=./certs/server.crt \
  --from-file=tls.key=./certs/server.key \
  --namespace=belizechain-production
```

#### From Manifest (Encrypted)

**⚠️ ONLY if using encrypted Git storage (e.g., Sealed Secrets)**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: belizechain-production
type: Opaque
stringData:
  username: belizechain
  password: "ENCRYPTED_VALUE_HERE"
```

### Using Secrets in Pods

#### Environment Variables

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blockchain-node
spec:
  template:
    spec:
      containers:
      - name: blockchain
        image: belizechain/blockchain:latest
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: password
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: password
```

#### Volume Mounts

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pakit
spec:
  template:
    spec:
      containers:
      - name: pakit
        image: belizechain/pakit:latest
        volumeMounts:
        - name: azure-quantum-key
          mountPath: "/secrets/azure"
          readOnly: true
      volumes:
      - name: azure-quantum-key
        secret:
          secretName: azure-quantum-credentials
          items:
          - key: subscription-id
            path: subscription-id
          - key: resource-group
            path: resource-group
```

---

## External Secrets Operator

### Installation

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets \
  external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace
```

### Azure Key Vault Integration

#### 1. Create Azure Service Principal

```bash
# Create service principal
az ad sp create-for-rbac -n belizechain-external-secrets

# Output:
# {
#   "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#   "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
#   "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# }

# Grant access to Key Vault
az keyvault set-policy \
  --name belizechain-vault \
  --spn <appId> \
  --secret-permissions get list
```

#### 2. Create Kubernetes Secret with Azure Credentials

```bash
kubectl create secret generic azure-secret-sp \
  --from-literal=clientid=<appId> \
  --from-literal=clientsecret=<password> \
  --namespace=belizechain-production
```

#### 3. Create SecretStore

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: azure-keyvault
  namespace: belizechain-production
spec:
  provider:
    azurekv:
      authType: ServicePrincipal
      vaultUrl: "https://belizechain-vault.vault.azure.net"
      tenantId: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      authSecretRef:
        clientId:
          name: azure-secret-sp
          key: clientid
        clientSecret:
          name: azure-secret-sp
          key: clientsecret
```

#### 4. Create ExternalSecret

```yaml
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
  - secretKey: username
    remoteRef:
      key: postgres-username
  - secretKey: password
    remoteRef:
      key: postgres-password
```

### HashiCorp Vault Integration

#### 1. Install Vault

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
  --namespace vault-system \
  --create-namespace
```

#### 2. Initialize and Unseal Vault

```bash
# Initialize
kubectl exec -it vault-0 -n vault-system -- vault operator init

# Unseal (repeat with 3 different keys)
kubectl exec -it vault-0 -n vault-system -- vault operator unseal <KEY>

# Enable Kubernetes auth
kubectl exec -it vault-0 -n vault-system -- vault auth enable kubernetes
```

#### 3. Configure Vault for BelizeChain

```bash
# Store secrets in Vault
kubectl exec -it vault-0 -n vault-system -- \
  vault kv put secret/belizechain/database \
  username=belizechain \
  password="$(openssl rand -base64 32)"

# Create policy
kubectl exec -it vault-0 -n vault-system -- \
  vault policy write belizechain-policy - <<EOF
path "secret/data/belizechain/*" {
  capabilities = ["read"]
}
EOF

# Create role
kubectl exec -it vault-0 -n vault-system -- \
  vault write auth/kubernetes/role/belizechain \
  bound_service_account_names=blockchain-node \
  bound_service_account_namespaces=belizechain-production \
  policies=belizechain-policy \
  ttl=24h
```

#### 4. Create SecretStore for Vault

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: belizechain-production
spec:
  provider:
    vault:
      server: "http://vault.vault-system.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "belizechain"
          serviceAccountRef:
            name: "blockchain-node"
```

---

## Rotation Procedures

### Automated Rotation

External Secrets Operator automatically syncs secrets based on `refreshInterval`.

```yaml
spec:
  refreshInterval: 1h  # Check for updates every hour
```

### Manual Rotation

#### Database Password Rotation

```bash
# 1. Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)

# 2. Update password in Key Vault
az keyvault secret set \
  --vault-name belizechain-vault \
  --name postgres-password \
  --value "$NEW_PASSWORD"

# 3. Wait for External Secrets to sync (or force refresh)
kubectl annotate externalsecret database-credentials \
  force-sync=$(date +%s) \
  --namespace=belizechain-production

# 4. Restart pods to pick up new secret
kubectl rollout restart deployment/blockchain-node \
  --namespace=belizechain-production

# 5. Update database with new password
kubectl exec -it deployment/postgres -n belizechain-production -- \
  psql -U postgres -c "ALTER USER belizechain PASSWORD '$NEW_PASSWORD';"
```

#### API Key Rotation

```bash
# 1. Generate new API key
NEW_API_KEY=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')

# 2. Store in Key Vault
az keyvault secret set \
  --vault-name belizechain-vault \
  --name pakit-api-key \
  --value "$NEW_API_KEY"

# 3. Update application configuration to accept both old and new keys (grace period)

# 4. Wait 24 hours for all clients to update

# 5. Remove old key from accepted keys list
```

#### TLS Certificate Rotation

```bash
# Using cert-manager (automatic)
# Certificates auto-renew 30 days before expiration

# Manual rotation if needed:
# 1. Generate new certificate
openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout tls.key -out tls.crt -days 365 \
  -subj "/CN=belizechain.org"

# 2. Update Kubernetes secret
kubectl create secret tls belizechain-tls \
  --cert=tls.crt --key=tls.key \
  --namespace=belizechain-production \
  --dry-run=client -o yaml | kubectl apply -f -

# 3. Reload services
kubectl rollout restart deployment/istio-ingressgateway \
  --namespace=istio-system
```

---

## Access Controls

### Who Can Access Secrets?

| Role | Kubernetes Secrets | Key Vault | Vault | Justification Required |
|------|-------------------|-----------|-------|------------------------|
| Developer | Read (dev namespace) | No | No | No |
| DevOps Engineer | Read/Write (dev) | Read | Read | Yes |
| SRE | Read (production) | Read | Read | Yes |
| Security Team | Full | Full | Full | Yes |
| Automated Systems | Read (own secrets) | Read | Read | No (audit logged) |

### Implementing Access Controls

#### Kubernetes RBAC

```yaml
# Allow pakit service account to read only its secrets
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pakit-secret-reader
  namespace: belizechain-production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["pakit-credentials", "azure-quantum-credentials"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pakit-secret-reader-binding
  namespace: belizechain-production
subjects:
- kind: ServiceAccount
  name: pakit-service
  namespace: belizechain-production
roleRef:
  kind: Role
  name: pakit-secret-reader
  apiGroup: rbac.authorization.k8s.io
```

#### Azure Key Vault Access Policies

```bash
# Grant read-only access to specific secrets
az keyvault set-policy \
  --name belizechain-vault \
  --object-id <USER_OBJECT_ID> \
  --secret-permissions get list
```

### Break-Glass Procedures

In case of emergency access needed:

1. **Request approval** from security team
2. **Document justification** (incident ticket)
3. **Time-limited access** (24 hours maximum)
4. **Audit trail** automatically logged
5. **Review access** after incident resolution

```bash
# Grant emergency access
az keyvault set-policy \
  --name belizechain-vault \
  --upn john.doe@belizechain.org \
  --secret-permissions get list \
  --expires $(date -u -d '+24 hours' +%Y-%m-%dT%H:%M:%SZ)
```

---

## Emergency Procedures

### Compromised Secret

1. **Immediate Actions:**
   ```bash
   # Revoke compromised secret
   az keyvault secret set-attributes \
     --vault-name belizechain-vault \
     --name compromised-secret \
     --enabled false
   
   # Alert security team
   # Notify incident response team
   ```

2. **Generate New Secret:**
   ```bash
   NEW_SECRET=$(openssl rand -base64 32)
   az keyvault secret set \
     --vault-name belizechain-vault \
     --name new-secret \
     --value "$NEW_SECRET"
   ```

3. **Update All Services:**
   ```bash
   kubectl annotate externalsecret all-secrets \
     force-sync=$(date +%s) \
     --all --namespace=belizechain-production
   
   kubectl rollout restart deployment --all \
     --namespace=belizechain-production
   ```

4. **Audit:**
   - Review access logs
   - Identify unauthorized access
   - Document in incident report

### Lost Access to Key Vault

1. Use recovery keys (stored in secure offline location)
2. Contact cloud provider support
3. Restore from escrow backup
4. Execute business continuity plan

---

## Best Practices

1. **Never log secrets** - Redact secrets in application logs
2. **Use short-lived secrets** when possible
3. **Implement secret scanning** in CI/CD pipelines
4. **Regular audits** of secret access
5. **Principle of least privilege**
6. **Separate secrets per environment** (dev/staging/prod)
7. **Document all secrets** in secret inventory
8. **Test rotation procedures** regularly

---

## Monitoring & Auditing

### What to Monitor

- Secret access events
- Failed authentication attempts
- Secret rotation schedules
- Certificate expiration dates
- Unauthorized secret creation/deletion

### Azure Key Vault Audit Logs

```bash
# View recent secret access
az monitor activity-log list \
  --resource-group belizechain-production \
  --offset 24h \
  --query "[?contains(authorization.action, 'Microsoft.KeyVault/vaults/secrets')]"
```

### Kubernetes Audit Logs

```bash
# View secret access in Kubernetes
kubectl logs -n kube-system -l component=kube-apiserver | \
  grep "secrets" | \
  jq 'select(.objectRef.resource=="secrets")'
```

### Alerting Rules

```yaml
# Prometheus alert for unauthorized secret access
groups:
- name: secret-access-alerts
  rules:
  - alert: UnauthorizedSecretAccess
    expr: |
      rate(kubernetes_audit_event_count{
        objectRef_resource="secrets",
        responseStatus_code!~"2.."
      }[5m]) > 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Unauthorized secret access detected"
```

---

## Additional Resources

- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [External Secrets Operator](https://external-secrets.io/)
- [Azure Key Vault Best Practices](https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)

---

## Contact

**Security Team:** security@belizechain.org  
**Emergency Hotline:** +XXX-XXX-XXXX (24/7)
