# BelizeChain Monitoring Stack

**Status**: ✅ Prometheus + Grafana configured, ready to start

## Overview

This monitoring infrastructure provides real-time observability for BelizeChain's multi-component architecture:

- **Blockchain Node** (port 9615): 40+ substrate metrics (blocks, transactions, p2p, database)
- **Oracle API** (port 8000): Request metrics, latency, auth failures, rate limits
- **Nawal API** (port 8001): AI model metrics, training stats, domain performance

## Quick Start

### 1. Start Monitoring Stack

```bash
cd /home/wicked/BelizeChain/belizechain/infra/monitoring
docker compose up -d
```

- **Prometheus UI**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/belizechain2025)

### 2. Verify Metrics Collection

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check blockchain metrics
curl http://localhost:9615/metrics | head -20

# Check Oracle API metrics  
curl http://localhost:8000/metrics | head -20

# Check Nawal API metrics
curl http://localhost:8001/metrics | head -20
```

### 3. Stop Monitoring Stack

```bash
docker compose down
```

## Architecture

```
┌─────────────────────┐
│  BelizeChain Node   │  
│   (ws://9944)       │  ← Blockchain RPC
│   (http://9615)     │  ← Prometheus metrics
└─────────────────────┘
           │
           │ scrape every 15s
           ▼
┌─────────────────────┐
│    Prometheus       │  ← Metrics storage
│  (localhost:9090)   │     & queries
└─────────────────────┘
           │
           │ query
           ▼
┌─────────────────────┐
│     Grafana         │  ← Visualization
│  (localhost:3000)   │     & dashboards
└─────────────────────┘
```

## Metrics Collected

### Blockchain Node Metrics (Substrate)
- `substrate_block_height` - Current blockchain height
- `substrate_block_verification_and_import_time` - Block import latency
- `substrate_number_leaves` - Number of chain forks
- `substrate_ready_transactions_number` - Transaction pool size
- `substrate_peers_count` - Connected peer nodes
- `substrate_database_cache_bytes` - RocksDB cache usage
- `rpc_*` - RPC request metrics

### Oracle API Metrics (FastAPI + Prometheus)
- `http_requests_total` - Total HTTP requests
- `http_request_duration_seconds` - Request latency (p50/p95/p99)
- `http_requests_inprogress` - Concurrent requests
- `http_response_size_bytes` - Response sizes
- Custom counters for:
  - Device registrations
  - Data submissions
  - Authentication failures
  - Rate limit hits

### Nawal API Metrics (FastAPI + Prometheus)
- `http_requests_total` - Total HTTP requests
- `http_request_duration_seconds` - Request latency
- `http_requests_inprogress` - Concurrent requests
- Custom metrics for:
  - Training job starts/completions
  - Model accuracy updates
  - Domain-specific requests
  - Genome evolution cycles

## Configuration Files

### `docker-compose.yml`
- Prometheus: Metrics collection (port 9090)
- Grafana: Visualization (port 3000)
- Volumes: Persistent data storage
- Network: `belizechain-monitoring` bridge

### `prometheus.yml`
- **Scrape interval**: 15 seconds
- **Targets**:
  - `host.docker.internal:9615` - Blockchain node
  - `host.docker.internal:8000` - Oracle API
  - `host.docker.internal:8001` - Nawal API
- **Labels**: service, component, environment

### `grafana/datasources/prometheus.yml`
- Prometheus datasource configuration
- Default data source for all dashboards

### `grafana/dashboards/dashboard.yml`
- Dashboard provisioning configuration
- Auto-import JSON dashboards

## Creating Dashboards

### Option 1: Web UI (Recommended for Learning)
1. Open http://localhost:3000
2. Login: admin / belizechain2025
3. Click "+" → "Create Dashboard"
4. Add panels with PromQL queries

### Option 2: JSON Import (Production)
1. Create dashboard in UI
2. Click "Share" → "Export" → "Save to file"
3. Save JSON to `grafana/dashboards/`
4. Dashboard auto-imports on restart

## Example PromQL Queries

### Blockchain Health
```promql
# Current block height
substrate_block_height{job="belizechain-node"}

# Blocks per minute (TPS * 60 / avg_block_time)
rate(substrate_block_height[1m]) * 60

# Peer connections
substrate_peers_count

# Block import latency (p95)
histogram_quantile(0.95, substrate_block_verification_and_import_time_bucket)
```

### API Performance
```promql
# Requests per second
rate(http_requests_total{job="oracle-api"}[5m])

# 95th percentile latency
histogram_quantile(0.95, http_request_duration_seconds_bucket{job="oracle-api"})

# Error rate (4xx + 5xx)
sum(rate(http_requests_total{job="oracle-api", status_code=~"4..|5.."}[5m])) / 
sum(rate(http_requests_total{job="oracle-api"}[5m]))
```

### Security Metrics
```promql
# Authentication failures (rate)
rate(http_requests_total{path=~".*auth.*", status_code="401"}[5m])

# Rate limit hits
rate(http_requests_total{status_code="429"}[5m])
```

## Dashboard Ideas

### 1. Blockchain Health Dashboard
- **Row 1**: Block height (graph), Current TPS (gauge), Peer count (stat)
- **Row 2**: Block import latency (heatmap), Transaction pool size (graph)
- **Row 3**: Database cache usage (graph), RPC errors (table)

### 2. API Performance Dashboard
- **Row 1**: Requests/sec (graph), Avg latency (gauge), Error rate (graph)
- **Row 2**: Latency heatmap (p50/p95/p99), Status code distribution (pie)
- **Row 3**: Top endpoints by latency (table), Concurrent requests (graph)

### 3. Security Events Dashboard
- **Row 1**: Auth failures (graph), Rate limit hits (graph), Invalid tokens (stat)
- **Row 2**: Failed login attempts by operator (table)
- **Row 3**: Request patterns (heatmap), Suspicious activity alerts

## Troubleshooting

### Prometheus can't scrape targets
```bash
# Check if services are running
curl http://localhost:9615/metrics  # Should return metrics
curl http://localhost:8000/metrics  # Should return metrics
curl http://localhost:8001/metrics  # Should return metrics

# Check Prometheus config
docker exec belizechain-prometheus cat /etc/prometheus/prometheus.yml

# Check Prometheus logs
docker logs belizechain-prometheus
```

### Grafana can't connect to Prometheus
```bash
# Verify network connectivity
docker exec belizechain-grafana ping prometheus

# Check datasource configuration
docker exec belizechain-grafana cat /etc/grafana/provisioning/datasources/prometheus.yml
```

### Metrics not appearing in Grafana
1. Verify Prometheus is scraping: http://localhost:9090/targets
2. Test query in Prometheus UI: http://localhost:9090/graph
3. Check Grafana datasource: Settings → Data Sources → Prometheus → Save & Test
4. Refresh dashboard or adjust time range

## Production Considerations

### Security
- [ ] Change default Grafana password
- [ ] Enable authentication for Prometheus
- [ ] Use TLS for Prometheus/Grafana
- [ ] Restrict access to monitoring stack (firewall rules)

### Scaling
- [ ] Configure Prometheus retention (default: 15 days)
- [ ] Set up long-term storage (Thanos, Cortex, or VictoriaMetrics)
- [ ] Add alerting rules (AlertManager)
- [ ] Create SLO dashboards (error budget, burn rate)

### High Availability
- [ ] Run multiple Prometheus instances
- [ ] Use Grafana HA setup (3+ instances)
- [ ] External database for Grafana (PostgreSQL)
- [ ] Federated Prometheus setup

## Next Steps

1. **Start monitoring stack**: `docker compose up -d`
2. **Import pre-built dashboards** (if available in `grafana/dashboards/*.json`)
3. **Create custom dashboards** for BelizeChain-specific metrics
4. **Set up alerts** for critical events (node down, high latency, auth failures)
5. **Document SLIs/SLOs** (target latency, uptime, error rates)

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Substrate Metrics](https://docs.substrate.io/build/prometheus-metrics/)
- [FastAPI Prometheus Instrumentator](https://github.com/trallnag/prometheus-fastapi-instrumentator)
