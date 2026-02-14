# Helm Template Files - YAML Linting Exception

**Important:** The YAML files in this directory contain Helm template syntax (`{{- }}`), which is **not valid YAML** until processed by Helm.

## Why YAML Linters Show Errors

YAML linters will report errors on these files because they contain:
- Go template directives: `{{- if .Values.enabled }}`
- Template functions: `{{ .Release.Namespace }}`
- Template includes: `{{- include "belizechain.labels" . | nindent 4 }}`

These are **expected and correct** for Helm templates.

## How to Validate

Instead of using YAML linters directly, use:

```bash
# Validate Helm templates
helm lint helm/belizechain

# Validate with specific values
helm lint helm/belizechain -f helm/belizechain/values-production.yaml

# Test template rendering
helm template test helm/belizechain --debug

# Dry-run installation
helm install --dry-run test helm/belizechain
```

## CI/CD Validation

The GitHub Actions workflow `.github/workflows/helm-lint.yml` properly validates these templates using Helm's built-in tools.

## For Security Audits

If your security audit tool flags these files:
1. Configure your YAML linter to exclude `helm/**/templates/**` (see `.yamllint`)
2. Use Helm-specific validation tools instead
3. Reference this file to document why Helm templates are excluded from YAML validation

## Template Files in This Directory

- `configmap.yaml` - Configuration values for all services
- `pvcs.yaml` - Persistent Volume Claims for storage
- `pakit-deployment.yaml` - Pakit storage service deployment
- Plus all other Kubernetes resource templates

All templates are validated through Helm's rendering engine, not standard YAML parsers.
