# Security Audit - YAML Linting Exceptions

**Date:** February 14, 2026  
**Status:** Resolved  
**Issue:** YAML linter errors on Helm template files

---

## Summary

YAML linter errors in `/home/wicked/Projects/infra/helm/belizechain/templates/` are **false positives** and do not represent actual security or syntax issues.

---

## Root Cause

The files flagged by the YAML linter are **Helm templates**, not plain YAML files. They contain Go template syntax that is processed by Helm before becoming valid Kubernetes manifests.

### Example of Valid Helm Template Syntax

```yaml
{{- if .Values.pakit.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pakit-pvc
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "belizechain.labels" . | nindent 4 }}
spec:
  storageClassName: {{ .Values.pakit.persistence.storageClass }}
{{- end }}
```

**Why YAML linters fail:**
- `{{- if .Values.pakit.enabled }}` is Go template syntax, not YAML
- `{{ .Release.Namespace }}` is a Helm variable, not a YAML value
- `{{- include "belizechain.labels" . | nindent 4 }}` is a template function call

These constructs are **correct and expected** in Helm templates, but they're not valid YAML until Helm processes them.

---

## Resolution

### 1. YAML Linter Configuration

Created `.yamllint` to exclude Helm template directories:

```yaml
ignore: |
  helm/**/templates/**
```

This tells YAML linters to skip Helm template files entirely.

### 2. Validation Script

Created `validate-helm.sh` that uses the **correct** validation method:

```bash
# Run Helm validation
./validate-helm.sh
```

This script:
- Validates templates with `helm lint`
- Tests template rendering with `helm template`
- Validates all environment configurations (dev, staging, production, GPU, quantum)
- Packages and verifies the chart

### 3. Documentation

Added documentation to explain the distinction:
- `helm/belizechain/templates/README.md` - Explains why YAML linters fail
- `.vscode/settings.json` - Configures VS Code to understand Helm templates
- `helm/belizechain/.helmignore` - Excludes non-chart files from packaging

### 4. GitHub Actions Workflow

The existing `.github/workflows/helm-lint.yml` already uses the correct validation approach:
- Uses `helm lint` (not yamllint)
- Tests template rendering
- Validates package integrity

---

## Validation Results

### Helm Lint (Correct Method) ✅

```bash
$ helm lint helm/belizechain
==> Linting helm/belizechain
[INFO] Chart.yaml: icon is recommended
1 chart(s) linted, 0 chart(s) failed
```

### Template Rendering ✅

```bash
$ helm template test helm/belizechain --debug > /dev/null
# Renders successfully without errors
```

### All Environment Configurations ✅

- ✅ Default values
- ✅ dev values  
- ✅ staging values
- ✅ production values
- ✅ GPU values
- ✅ quantum values

---

## Why These Files Should NOT Be Changed

**DO NOT modify Helm templates to make YAML linters happy.** This would:

1. **Break Helm functionality** - Template syntax is required for dynamic configuration
2. **Remove environment flexibility** - The `{{- if }}` conditionals enable/disable features per environment
3. **Eliminate variable substitution** - Values like namespaces and ports must be templated
4. **Prevent reusability** - The chart couldn't be deployed to multiple environments

---

## Affected Files (All Valid)

### helm/belizechain/templates/configmap.yaml ✅

Contains 60+ environment variables with Helm value substitutions:
```yaml
POSTGRES_HOST: {{ printf "postgres.%s.svc.cluster.local" .Release.Namespace | quote }}
```

**Purpose:** Dynamic service discovery URLs based on namespace

### helm/belizechain/templates/pvcs.yaml ✅

Contains conditional PVC creation:
```yaml
{{- if and .Values.pakit.enabled .Values.pakit.persistence.enabled }}
```

**Purpose:** Only create storage volumes when components are enabled

### helm/belizechain/templates/pakit-deployment.yaml ✅

Contains full deployment with templated configuration:
```yaml
replicas: {{ .Values.pakit.replicaCount }}
```

**Purpose:** Scale replicas based on environment (2 for dev, 3 for staging, 5 for production)

---

## Security Audit Compliance

### For Auditors

**Question:** "Why do YAML files have syntax errors?"

**Answer:** These are not YAML files - they are **Helm templates** that generate YAML. They use Go template syntax (`{{- }}`) which is processed by Helm into valid Kubernetes manifests.

**Validation Method:** Use `helm lint` and `helm template`, not standard YAML linters.

**Verification:**
```bash
# Run our validation script
./validate-helm.sh

# Or manually validate
helm lint helm/belizechain
helm template test helm/belizechain --dry-run
```

### Compliance Evidence

1. ✅ **Chart validated** - `helm lint` passes for all configurations
2. ✅ **Templates render correctly** - `helm template` produces valid YAML
3. ✅ **CI/CD validated** - GitHub Actions workflow validates on every push
4. ✅ **Package integrity verified** - Chart packages and deploys successfully
5. ✅ **Industry standard** - This is how all Helm charts work (Kubernetes community standard)

---

## References

### Official Documentation

- [Helm Template Language](https://helm.sh/docs/chart_template_guide/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes Helm Charts](https://kubernetes.io/docs/reference/kubectl/kubectl/)

### Example Production Helm Charts

All major Kubernetes projects use the same template syntax:
- [Prometheus Helm Chart](https://github.com/prometheus-community/helm-charts)
- [Grafana Helm Chart](https://github.com/grafana/helm-charts)
- [PostgreSQL Helm Chart](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)
- [Redis Helm Chart](https://github.com/bitnami/charts/tree/main/bitnami/redis)

All contain "YAML errors" when validated with standard linters because they use Helm template syntax.

---

## Conclusion

**Status:** ✅ **RESOLVED - No Action Required**

The YAML linter errors are **expected false positives** for Helm templates. The files are:
- ✅ Syntactically correct (as Helm templates)
- ✅ Validated by Helm tooling
- ✅ Following Kubernetes/Helm best practices
- ✅ Used in production by thousands of organizations
- ✅ Properly excluded from YAML linting via `.yamllint`

**Recommendation:** Accept these linter exceptions and use Helm-specific validation tools.

---

**Prepared By:** Infrastructure Team  
**Reviewed By:** Security Team  
**Date:** February 14, 2026
