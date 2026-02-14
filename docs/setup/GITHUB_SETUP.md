# 🚀 GitHub Setup Guide for BelizeChain Infrastructure

**Repository**: `github.com/BelizeChain/infra`  
**Version**: v1.0.0  
**Extraction Date**: January 31, 2026

---

## 📋 Quick Start Checklist

### ✅ Step 1: Create GitHub Repository

1. Go to: https://github.com/new
2. Fill in repository details:
   ```
   Repository name: infra
   Description: BelizeChain Infrastructure - GitOps deployment configurations (Docker Compose, Kubernetes, Helm, ArgoCD)
   Visibility: Public
   
   ⚠️ DO NOT initialize with:
   ❌ README (we already have one)
   ❌ .gitignore (we already have one)
   ❌ License (will add separately)
   ```
3. Click **"Create repository"**

---

### ✅ Step 2: Push Code to GitHub

```bash
# Navigate to extraction directory
cd /tmp/infra-extract

# Add GitHub remote
git remote add origin https://github.com/BelizeChain/infra.git

# Rename branch to main (GitHub default)
git branch -M main

# Push code and tags
git push -u origin main
git push origin v1.0.0

# Verify push
git remote -v
git log --oneline --all
```

**Expected Output**:
```
Enumerating objects: 83, done.
Counting objects: 100% (83/83), done.
Delta compression using up to 8 threads
Compressing objects: 100% (80/80), done.
Writing objects: 100% (83/83), 267.4 KiB | 5.3 MiB/s, done.
Total 83 (delta 15), reused 0 (delta 0)
To github.com:BelizeChain/infra.git
 * [new branch]      main -> main
 * [new tag]         v1.0.0 -> v1.0.0
```

---

### ✅ Step 3: Configure Repository Settings

#### **3.1 General Settings**
```
Settings → General:
  ✅ Description: "BelizeChain Infrastructure - GitOps deployment configurations"
  ✅ Website: https://belizechain.org
  ✅ Topics: gitops, kubernetes, helm, docker-compose, argocd, istio, belize, blockchain, substrate
```

#### **3.2 Features**
```
Settings → Features:
  ✅ Issues
  ✅ Discussions (for deployment questions)
  ✅ Projects
  ❌ Wiki (use docs/ folder instead)
```

#### **3.3 Branches**
```
Settings → Branches:
  ✅ Default branch: main
  ✅ Branch protection rules for main:
     ✅ Require pull request reviews (1 reviewer)
     ✅ Require status checks (CI/CD workflows)
     ✅ Require conversation resolution
     ✅ Do not allow force pushes
     ✅ Require linear history
```

---

### ✅ Step 4: Add GitHub Secrets (for CI/CD)

Go to: **Settings → Secrets and variables → Actions**

#### **4.1 GitHub Container Registry** (for Docker image publishing)
```
Secret Name: GHCR_TOKEN
Value: <your-github-token>

# Create GitHub token with permissions:
# - write:packages (push Docker images)
# - read:packages (pull Docker images)
# - delete:packages (delete old images)

# Get token at: https://github.com/settings/tokens
# Select: Classic token → write:packages scope
```

**Note**: GitHub Actions automatically has access to `GITHUB_TOKEN` for GHCR, but adding `GHCR_TOKEN` provides more control.

---

### ✅ Step 5: Enable GitHub Actions

1. Go to: **Actions** tab
2. Click **"I understand my workflows, go ahead and enable them"**
3. Verify workflows appear:
   - ✅ Docker Build & Publish
   - ✅ Helm Chart Lint & Test
   - ✅ Security Audits

---

### ✅ Step 6: Verify CI/CD Pipelines

#### **6.1 Trigger First Workflow Run**
```bash
# Make a small change to trigger workflows
echo "# Infrastructure Status: Active" >> README.md

# Commit and push
git add README.md
git commit -m "docs: Update README with status"
git push origin main
```

#### **6.2 Check Workflow Status**
1. Go to: **Actions** tab
2. You should see 3 workflows running:
   - 🟡 Docker Build & Publish (in progress)
   - 🟡 Helm Chart Lint & Test (in progress)
   - 🟡 Security Audits (in progress)

3. Wait for completion (3-8 minutes):
   - ✅ Docker Build & Publish (passed) - 5 images built
   - ✅ Helm Chart Lint & Test (passed) - 7 value files validated
   - ✅ Security Audits (passed) - No critical vulnerabilities

---

### ✅ Step 7: Test Local Deployment

#### **7.1 Clone Repository**
```bash
# On a clean machine
git clone https://github.com/BelizeChain/infra.git
cd infra
```

#### **7.2 Test Docker Compose**
```bash
# Create .env file (optional - uses defaults)
cp .env.example .env 2>/dev/null || true

# Start all services
docker compose up -d

# Check status
docker compose ps

# Expected output: 11 services running
# - belizechain-node
# - nawal-fl-server
# - kinich-quantum
# - pakit-storage
# - postgres
# - redis
# - ipfs
# - prometheus
# - grafana
# - ui-maya-wallet
# - ui-blue-hole

# View logs
docker compose logs -f belizechain-node

# Stop services
docker compose down
```

#### **7.3 Test Helm Chart**
```bash
# Lint Helm chart
helm lint helm/belizechain
helm lint helm/belizechain -f helm/belizechain/values-dev.yaml
helm lint helm/belizechain -f helm/belizechain/values-production.yaml

# Dry-run installation
helm install --dry-run --debug test helm/belizechain

# Expected output: YAML manifests generated successfully
```

---

### ✅ Step 8: Setup ArgoCD (Production Deployment)

#### **8.1 Install ArgoCD**
```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port-forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access ArgoCD: https://localhost:8080
# Username: admin
# Password: <from above command>
```

#### **8.2 Deploy BelizeChain via ArgoCD**
```bash
# Create ArgoCD project
kubectl apply -f argocd/project.yaml

# Deploy production environment
kubectl apply -f argocd/application-production.yaml

# Check application status
kubectl get applications -n argocd

# Expected output:
# NAME                     SYNC STATUS   HEALTH STATUS
# belizechain-production   Synced        Healthy

# ArgoCD will automatically:
# 1. Clone github.com/BelizeChain/infra
# 2. Deploy Helm chart with production values
# 3. Monitor for Git changes
# 4. Auto-sync on commits to main branch
```

#### **8.3 Verify Deployment**
```bash
# Check pods
kubectl get pods -n belizechain

# Expected output: All pods Running (5-10 minutes)
# - belizechain-node-0          1/1     Running
# - nawal-fl-server-xxx         1/1     Running
# - kinich-quantum-xxx          1/1     Running
# - pakit-storage-xxx           1/1     Running
# - postgres-0                  1/1     Running
# - redis-xxx                   1/1     Running
# - ipfs-0                      1/1     Running

# Check services
kubectl get svc -n belizechain

# Check ingress (if configured)
kubectl get ingress -n belizechain
```

---

## 🔍 Verification Checklist

### **Repository Structure**
- ✅ README.md displays correctly on GitHub homepage
- ✅ All 80 files present in repository
- ✅ 5 Dockerfiles in root directory
- ✅ .github/workflows/ contains 3 YAML files
- ✅ helm/belizechain/ contains Chart.yaml and 7 value files
- ✅ k8s/base/ contains Kubernetes manifests
- ✅ k8s/istio/ contains Istio service mesh configs
- ✅ argocd/ contains 4 application manifests

### **GitHub Actions**
- ✅ All 3 workflows enabled
- ✅ Docker Build workflow passes (5 images)
- ✅ Helm Lint workflow passes (7 value files)
- ✅ Security Audit workflow passes (no critical issues)
- ✅ Docker images published to `ghcr.io/belizechain/*`

### **Branch Protection**
- ✅ main branch protected
- ✅ PR reviews required
- ✅ Status checks required
- ✅ Force push disabled

### **Repository Settings**
- ✅ Topics/tags added
- ✅ Description set
- ✅ Website URL set
- ✅ Discussions enabled

---

## 🐛 Troubleshooting

### **Issue: Docker Build Workflow Fails**
**Solution**:
1. Check Dockerfile syntax errors
2. Verify base image availability
3. Check GHCR authentication:
   ```bash
   # Test Docker login
   echo $GHCR_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```
4. Review workflow logs in Actions tab

---

### **Issue: Helm Lint Fails**
**Solution**:
1. Validate YAML syntax:
   ```bash
   helm lint helm/belizechain --debug
   ```
2. Check for missing required values
3. Verify template rendering:
   ```bash
   helm template test helm/belizechain -f helm/belizechain/values-production.yaml
   ```

---

### **Issue: ArgoCD Sync Fails**
**Solution**:
1. Check repository URL in ArgoCD application
2. Verify ArgoCD has access to GitHub repository
3. Check Helm chart path in application manifest
4. Review ArgoCD logs:
   ```bash
   kubectl logs -n argocd deployment/argocd-application-controller
   ```

---

### **Issue: Docker Compose Fails to Start**
**Solution**:
1. Check Docker daemon is running
2. Verify port availability (9933, 9944, 8001, 8002, 8003)
3. Check Docker Compose version (v2.0+)
4. Review service logs:
   ```bash
   docker compose logs <service-name>
   ```

---

### **Issue: Kubernetes Pods CrashLoopBackOff**
**Solution**:
1. Check pod logs:
   ```bash
   kubectl logs <pod-name> -n belizechain
   ```
2. Verify ConfigMap and Secret values
3. Check resource limits (CPU/memory)
4. Verify persistent volume claims (PVCs) are bound
5. Check init container logs:
   ```bash
   kubectl logs <pod-name> -c init-<container> -n belizechain
   ```

---

## 📊 Post-Setup Metrics

After successful setup, you should see:

| Metric | Expected Value |
|--------|----------------|
| **Total Commits** | 2+ (initial + post-extraction updates) |
| **Git Tags** | 1 (v1.0.0) |
| **Branches** | 1+ (main + feature branches) |
| **Workflows** | 3 (all passing) |
| **Docker Images** | 5 (published to GHCR) |
| **Contributors** | 1+ |
| **Open Issues** | 0 (initially) |
| **Pull Requests** | 0-1 (test PR optional) |
| **Stars** | 0+ (will grow) |

---

## 🔗 Useful Links

### **GitHub Repository**
- Repository: https://github.com/BelizeChain/infra
- Actions: https://github.com/BelizeChain/infra/actions
- Packages: https://github.com/BelizeChain?tab=packages
- Issues: https://github.com/BelizeChain/infra/issues

### **Docker Images (GitHub Container Registry)**
- `ghcr.io/belizechain/node:latest`
- `ghcr.io/belizechain/fl-server:latest`
- `ghcr.io/belizechain/quantum:latest`
- `ghcr.io/belizechain/pakit:latest`
- `ghcr.io/belizechain/ui:latest`

### **Documentation**
- Main README: [README.md](./README.md)
- Extraction Summary: [EXTRACTION_SUMMARY.md](./EXTRACTION_SUMMARY.md)
- Extraction Readiness: [EXTRACTION_READINESS.md](./EXTRACTION_READINESS.md)
- Blockchain Deployment: [blockchain/README.md](./blockchain/README.md)
- Nawal Deployment: [nawal/README.md](./nawal/README.md)
- Monitoring Setup: [monitoring/README.md](./monitoring/README.md)
- Istio Service Mesh: [k8s/istio/README.md](./k8s/istio/README.md)

---

## 🎉 Success!

Once all steps are complete, your BelizeChain Infrastructure repository is:

- ✅ **Live on GitHub** with full version history
- ✅ **CI/CD enabled** with automated Docker builds and security scans
- ✅ **Production-ready** with Kubernetes manifests and Helm charts
- ✅ **GitOps-ready** with ArgoCD integration
- ✅ **Multi-environment** with dev, staging, production configs
- ✅ **Hardware-optimized** with GPU and quantum-specific deployments

---

**Next Steps**: Deploy to production using ArgoCD and monitor via Grafana dashboards.

---

_Last Updated: January 31, 2026_
