#!/bin/bash
# Helm Template Validation Script
# This script properly validates Helm templates for security audits

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELM_CHART_DIR="$SCRIPT_DIR/helm/belizechain"

echo "========================================="
echo "BelizeChain Helm Template Validation"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "ℹ $1"
}

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install Helm 3.14+ first."
    echo "  Visit: https://helm.sh/docs/intro/install/"
    exit 1
fi

HELM_VERSION=$(helm version --short | cut -d'+' -f1)
print_success "Helm found: $HELM_VERSION"
echo ""

# Validate with default values
echo "1. Validating with default values..."
if helm lint "$HELM_CHART_DIR"; then
    print_success "Default values validation passed"
else
    print_error "Default values validation failed"
    exit 1
fi
echo ""

# Validate with dev values
echo "2. Validating with dev values..."
if helm lint "$HELM_CHART_DIR" -f "$HELM_CHART_DIR/values-dev.yaml"; then
    print_success "Dev values validation passed"
else
    print_error "Dev values validation failed"
    exit 1
fi
echo ""

# Validate with staging values
echo "3. Validating with staging values..."
if helm lint "$HELM_CHART_DIR" -f "$HELM_CHART_DIR/values-staging.yaml"; then
    print_success "Staging values validation passed"
else
    print_error "Staging values validation failed"
    exit 1
fi
echo ""

# Validate with production values
echo "4. Validating with production values..."
if helm lint "$HELM_CHART_DIR" -f "$HELM_CHART_DIR/values-production.yaml"; then
    print_success "Production values validation passed"
else
    print_error "Production values validation failed"
    exit 1
fi
echo ""

# Validate with GPU values
echo "5. Validating with GPU values..."
if helm lint "$HELM_CHART_DIR" -f "$HELM_CHART_DIR/values-gpu.yaml"; then
    print_success "GPU values validation passed"
else
    print_error "GPU values validation failed"
    exit 1
fi
echo ""

# Validate with quantum values
echo "6. Validating with quantum values..."
if helm lint "$HELM_CHART_DIR" -f "$HELM_CHART_DIR/values-quantum.yaml"; then
    print_success "Quantum values validation passed"
else
    print_error "Quantum values validation failed"
    exit 1
fi
echo ""

# Template rendering test (default)
echo "7. Testing template rendering (default)..."
if helm template test "$HELM_CHART_DIR" --debug > /dev/null; then
    print_success "Default template rendering succeeded"
else
    print_error "Default template rendering failed"
    exit 1
fi
echo ""

# Template rendering test (production)
echo "8. Testing template rendering (production)..."
if helm template test "$HELM_CHART_DIR" -f "$HELM_CHART_DIR/values-production.yaml" --debug > /dev/null; then
    print_success "Production template rendering succeeded"
else
    print_error "Production template rendering failed"
    exit 1
fi
echo ""

# Package the chart
echo "9. Packaging chart..."
if helm package "$HELM_CHART_DIR" -d /tmp; then
    print_success "Chart packaging succeeded"
    PACKAGE_FILE=$(ls -t /tmp/belizechain-*.tgz 2>/dev/null | head -1)
    print_info "Package: $PACKAGE_FILE"
else
    print_error "Chart packaging failed"
    exit 1
fi
echo ""

# Verify packaged chart
echo "10. Verifying packaged chart..."
if helm lint "$PACKAGE_FILE"; then
    print_success "Packaged chart verification passed"
else
    print_error "Packaged chart verification failed"
    exit 1
fi
echo ""

# Cleanup
rm -f /tmp/belizechain-*.tgz

echo "========================================="
print_success "All validations passed!"
echo "========================================="
echo ""
print_info "Note: YAML linter errors on Helm templates are expected."
print_info "Helm templates contain Go template syntax ({{- }}) that"
print_info "is not valid YAML until processed by Helm."
print_info ""
print_info "This script validates templates using Helm's engine,"
print_info "which is the correct validation method."
echo ""

exit 0
