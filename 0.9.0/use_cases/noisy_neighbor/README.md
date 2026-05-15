# Noisy-Neighbor Lab — closed-loop throttle + diagnostic tail sampling

A single noisy tenant is about to topple a shared Postgres. MDAI detects the condition from a *combination* of database-pressure metrics and application-level per-tenant metrics, then makes **two simultaneous changes**:

1. **Hard corrective** *(sub-second)* — the app middleware caps the noisy tenant at 5 RPS via a `callWebhook` push.
2. **Diagnostic tuning** *(~ConfigMap-refresh, ~60s)* — the OTel tail sampler reconfigures itself: it now keeps **100% of the noisy tenant's genuine DB errors**, **50% of its normal traffic**, drops healthy tenants to **2% sampling**, and — the payoff — **deliberately drops 99% of the 429s MDAI itself just caused** (keeping a 1% sanity sample). Telemetry about your own mitigation isn't worth paying to store.

When the pressure clears, **both changes reverse automatically**.

> The story is "we kept more of the bad-behavior traces precisely when we needed them, stopped paying to store the throttle-rejections we deliberately caused, and threw the brakes on the offender — all from one declarative rule. **Sampling tuned by intent, not just by volume.**"

## Architecture

```
                                  load-gen
                                     │  rps mix: noisy-1=50, others=5
                                     ▼
                              ┌──────────────────────────────┐
                  HTTP +      │  noisy-app  (FastAPI)        │
                  X-Tenant-ID │   ├ token-bucket middleware  │
                              │   ├ injects 10% 503 (sim'd   │
                              │   │  DB timeouts)            │
                              │   └ OTel SDK → adds tenant   │
                              │     attr to every span       │
                              └────┬──────────────┬──────────┘
                                   │ SQL          │ OTLP/gRPC
                                   ▼              ▼
                       ┌────────────────┐   ┌──────────────────┐
                       │  postgres +    │   │ trace-balancer   │
                       │  exporter      │   │ (load-balances   │
                       │  max_conns=100 │   │  spans by trace) │
                       └────────┬───────┘   └────────┬─────────┘
                                │ scrape             │ OTLP/gRPC
                                ▼                    ▼
                     ┌─────────────────────────────────────────┐
                     │             Prometheus                  │
                     └───────────────────┬─────────────────────┘
                                         │ alerts
                                         ▼
                               ┌─────────────────┐
                               │  MdaiHub CR     │
                               │  Event Handler  │
                               └────┬──────┬─────┘
                                    │      │
              ┌─────────────────────┘      └───────────────────────┐
              ▼                                                    ▼
   ┌─────────────────────────┐                       ┌──────────────────────────┐
   │ Valkey (variable store) │                       │ HTTP POST                │
   │  rate_limited_tenants   │                       │  /admin/rate-limits      │
   │  noisy_tenant_list      │                       │   tenant=noisy-1 rps=5   │
   │  healthy_tenant_list    │                       │                          │
   └───────────┬─────────────┘                       └──────────────┬───────────┘
               │ ConfigMap mount                                    │
               │ (~60s kubelet refresh)                             │ token-bucket
               ▼                                                    ▼
   ┌─────────────────────────┐                       (back to noisy-app middleware
   │  gateway-collector      │                         in the top of the diagram)
   │  envFrom variables CM   │
   │   ├ NOISY_TENANT_LIST   │
   │   └ HEALTHY_TENANT_LIST │
   │                         │
   │  tail_sampling          │
   │   pol 0: noisy+429 drop │  →   1%   (first match wins)
   │   pol 1: noisy+ERROR    │  → 100%
   │   pol 2: noisy+normal   │  →  50%
   │   pol 3: healthy        │  →   2%
   │   pol 4: default        │  →  10%
   └──────────┬──────────────┘
              │
              ▼
       (vendor / store)
```

## The control loop, end to end

1. **Postgres exporter** ships `pg_stat_database_*`, `pg_stat_activity_count`, `pg_settings_max_connections`.
2. **noisy-app** ships `db_connections_per_tenant{tenant=…}` from per-tenant asyncpg pools, plus traces with a `tenant` span attribute.
3. **`db_pressure` alert** fires when cache hit ratio drops below 0.7 OR connection saturation exceeds 20% (lab-tuned threshold — see *Tunables*). This workload is **connection-bound** — each `/work` request holds a pooled connection across `pg_sleep` calls — so in practice the connection-saturation leg is what fires; the cache-hit leg is a generic template that won't move here (the app does no buffer-read I/O). The "DB failure" story on the dashboard is carried by the injected 5xx errors, not the cache-hit metric.
4. **`noisy_neighbor_detected` alert** fires only when *both* `db_pressure` is firing AND one tenant holds >50% of *active* connections.
5. The matching rule does **four** things atomically:
   - `addToMap` into `rate_limited_tenants` (Valkey state).
   - `callWebhook` → POST to `noisy-app:8080/admin/rate-limits` → middleware caps the tenant at 5 RPS *immediately*.
   - `addToSet` into `noisy_tenant_list`.
   - `removeFromSet` from `healthy_tenant_list`.
6. The `mdai-operator` materializes the two sets into env vars (`NOISY_TENANT_LIST`, `HEALTHY_TENANT_LIST`) inside the `mdaihub-noisy-neighbor-variables` ConfigMap.
7. The **gateway collector** mounts that ConfigMap and re-reads it on the kubelet's normal refresh cadence (~60s). The `tail_sampling` processor evaluates **5 policies in order, first match wins**:
   - **policy 0 `noisy-tenant-throttled-drop`** — a noisy span carrying `throttled==true` (a 429 *we* just caused) is kept at only **1%**. Placed first so it wins over policy 2; the other 99% of redundant throttle-rejection traces are dropped.
   - **policy 1 `noisy-tenant-errors`** — a noisy span with a *genuine* DB error (`error.injected==true`, or `STATUS_CODE_ERROR` that is **not** a throttle) is kept at **100%**.
   - **policy 2 `noisy-tenant-normal`** — the noisy tenant's remaining successful traffic, kept at **50%** for context.
   - **policy 3 `healthy-tenant-sample`** — healthy tenants ride **2%**.
   - **policy 4 `default-sample`** — catch-all (spans with no tenant attr, e.g. infra) at **10%**.

   When the sets swap members, these `string_attribute` policies match different tenants → sampling ratios flip.
8. When pressure clears (`keep_firing_for: 90s` hysteresis), the resolved-rule fires the inverse: webhook lifts the throttle, sets swap members back.

## What the demo shows

Once `noisy_neighbor_firing` fires:

- **Loadgen output:** `noisy-1` goes from `ok=50/s 429=0 5xx≈5` (steady) to `ok=5/s 429≈45 5xx≈0.5`. Other tenants unaffected.
- **`/admin/rate-limits`:** `{}` → `{"noisy-1": 5.0}`.
- **Valkey sets:** `noisy_tenant_list` ← `["noisy-1"]`; `healthy_tenant_list` ← `["tenant-a","tenant-b","tenant-c"]`.
- **ConfigMap:** `mdaihub-noisy-neighbor-variables` gains `NOISY_TENANT_LIST=noisy-1`, `HEALTHY_TENANT_LIST=tenant-a|tenant-b|tenant-c`.
- **Tail sampler** (after ~60s), the headline shot — four lines move at once:
  - `noisy-tenant-errors` jumps up and stays high — we now keep **100% of the noisy tenant's genuine DB failures** (the injected 5xx). It does **not** include 429s — those are handled by policy 0.
  - `noisy-tenant-normal` rises briefly, then settles at 50% of the noisy tenant's successful traffic.
  - `healthy-tenant-sample` collapses toward the 2% floor — the rest of the world.
  - `noisy-tenant-throttled-drop` sits near the **1% floor** — a thin line hugging the bottom, visibly far below the errors policy. **MDAI knows it *caused* those 429s by rate-limiting, so it stops paying to capture its own mitigation.** The 429 *rate* is still fully on the Action-1 metrics panel (`app_throttled_total`) — we just don't keep the redundant per-request traces.

The headline panel in Grafana is `sum by (policy) (rate(otelcol_processor_tail_sampling_count_traces_sampled[1m]))`, log-scaled so every policy line is individually readable — you can literally watch the ratios flip when the rule fires. **Sampling tuned by intent, not just by volume.**

## Design choices and why

- **Option B + `callWebhook`** for the throttle (one Python file does the limiting). Production would more likely use Envoy + a controller pod, but the lab's point is to show *MDAI*, not Envoy. `callWebhook` is push (sub-second), no Redis client in the app.
- **Tail sampling for the diagnostic side.** Static sampling is the bluntest instrument in the observability stack. MDAI turns it into a closed-loop knob: "sample everything from the suspect, sample less of the boring." The sharpest expression of this is the **`noisy-tenant-throttled-drop` policy (evaluated first)**: once MDAI decides to rate-limit a tenant, the resulting 429s are *its own mitigation working as intended* — no diagnostic value. So it keeps a 1% sanity sample and drops the rest, while still keeping 100% of that tenant's *genuine* DB errors. The sampler is tuned by **intent**, not volume.
- **Two-collector pattern.** Tail sampling needs all spans of a trace to land on the same collector. The `loadbalancing` exporter routes by `traceID` to the gateway, then the gateway makes the sampling decision once per trace.
- **Hysteresis via `keep_firing_for: 90s`** on both alerts. Prevents flapping when throttling brings pressure right back under the threshold.

## Postgres-in-kind stand-in (caveat)

The lab uses Postgres-in-kind as a stand-in for what would in production be RDS / Cloud SQL / AlloyDB.

| Real prod metric | Lab proxy | Why |
|---|---|---|
| `FreeableMemory` (RDS) | `pg_stat_database` cache hit ratio | Postgres doesn't expose freeable memory; cache hit ratio drops when working set spills to disk. |
| DB CPU utilization | not used in this lab's expr | `node_cpu_seconds_total` reflects the kind node, not the DB. |
| `DatabaseConnections` (RDS) | `pg_stat_activity_count` | Direct equivalent. |
| `max_connections` | `pg_settings_max_connections` | Direct equivalent. |

Swap the alert expressions for managed-DB equivalents from CloudWatch / GCP managed-prometheus when porting.

## Tunables

| Knob | Default | Where |
|---|---|---|
| Cache hit ratio threshold | 0.7 | `hub.yaml` → `prometheusAlerts.db_pressure.expr` |
| Connection saturation threshold | 0.2 | same (tuned for in-kind PG + asyncpg idle-decay; prod-comparable ≈ 0.8) |
| Dominance threshold | 0.5 | `prometheusAlerts.noisy_neighbor_detected.expr` |
| Alert detection window | 30s | `for:` |
| Hysteresis | 90s | `keep_firing_for:` |
| RPS cap when throttled | 5 | `rules.noisy_neighbor_firing` → `addToMap.value` and `callWebhook.templateValues.rps` |
| Injected 5xx rate | 10% | `manifests/20-noisy-app.yaml` → `ERROR_INJECT_PROB` |
| `noisy-tenant-throttled-drop` sampling | 1% | `otel.yaml` → tail_sampling policy 0 (evaluated first) |
| `noisy-tenant-errors` sampling | 100% | policy 1 |
| `noisy-tenant-normal` sampling | 50% | policy 2 |
| `healthy-tenant-sample` sampling | 2% | policy 3 |
| `default-sample` sampling | 10% | policy 4 |
| Per-tenant DB pool max | 30 | `manifests/20-noisy-app.yaml` env |
| Load mix (rps per tenant) | 5/5/5/50 | `manifests/30-loadgen.yaml` ConfigMap |

## Run

Prereq: MDAI base install (`./cli/mdai.sh install -f values/overrides_0.9.0-partial.yaml`).

```sh
cd 0.9.0/use_cases/noisy_neighbor
make run          # build image, kind-load, apply everything, SADD healthy_tenant_list, scale loadgen
make teardown
```

## What to watch

```sh
# 1. Loadgen output (status mix per tenant — watch 5xx and 429 rise on noisy-1)
kubectl -n noisy-neighbor logs -f deploy/loadgen

# 2. Live rate-limit table
kubectl -n noisy-neighbor port-forward svc/noisy-app 8080:8080 &
watch -n 1 'curl -s localhost:8080/admin/rate-limits'

# 3. Valkey sets — the variable store, swapping members in real time
PASS=$(kubectl -n mdai get secret valkey-secret -o jsonpath='{.data.VALKEY_PASSWORD}' | base64 -d)
watch -n 2 "kubectl -n mdai exec mdai-valkey-primary-0 -- env P=$PASS sh -c \
  'valkey-cli -a \$P --no-auth-warning SMEMBERS variable/mdaihub-noisy-neighbor/noisy_tenant_list && \
   echo --- && \
   valkey-cli -a \$P --no-auth-warning SMEMBERS variable/mdaihub-noisy-neighbor/healthy_tenant_list'"

# 4. Tail-sampler decisions by policy — the headline panel
kubectl -n mdai port-forward svc/kube-prometheus-stack-prometheus 9090:9090 &
open 'http://localhost:9090/graph?g0.expr=sum%20by%20(policy)%20(rate(otelcol_processor_tail_sampling_count_traces_sampled%5B1m%5D))&g0.tab=0&g0.range_input=15m'

# 5. Prometheus alerts
open http://localhost:9090/alerts

# 6. Grafana (admin / mdai)
kubectl -n mdai port-forward svc/mdai-grafana 3000:80 &
open http://localhost:3000
```

Useful PromQL queries for the demo:

| Goal | Query |
|---|---|
| **Headline: sampling shift** | `sum by (policy) (rate(otelcol_processor_tail_sampling_count_traces_sampled{sampled="true"}[1m]))` |
| Sampling kept-vs-dropped per policy | `sum by (policy, sampled) (rate(otelcol_processor_tail_sampling_count_traces_sampled[1m]))` |
| Connection pressure | `sum(pg_stat_activity_count) / on() group_left() max(pg_settings_max_connections)` |
| Per-tenant active conns | `db_connections_per_tenant` |
| Throttled rate | `sum by (tenant) (rate(app_throttled_total[1m]))` |
| Error rate per tenant | `sum by (tenant) (rate(app_errors_total[1m]))` |
| Dominance ratio | `max by (tenant) (db_connections_per_tenant) / on() group_left() clamp_min(sum(db_connections_per_tenant), 1)` |

## Limitations

- **In-app limiter is per-pod.** Multi-replica needs a distributed limiter (shared Valkey-backed token bucket, or Envoy + RateLimit Service). Lab uses 1 replica.
- **No PgBouncer.** Production usually has a pooler in front of the DB.
- **ConfigMap refresh lag.** Kubelet refreshes mounted ConfigMaps every ~60-90s. Acceptable for the diagnostic side; we don't want it for the corrective side, which is why the throttle goes through `callWebhook` instead.
- **Tail sampling latency.** `decision_wait: 10s` — spans sit in memory for up to 10s before the sampler picks them up. That's the standard tail-sampling tradeoff and is independent of MDAI.

## File map

```
noisy_neighbor/
├── README.md                  (this file)
├── RECORDED_RUN.md            (evidence from a real run)
├── Makefile                   (build / load / apply / teardown)
├── hub.yaml                   (4 vars, 2 alerts, 4 rules — adds set actions for sampling)
├── otel.yaml                  (RBAC + trace-balancer + gateway; 5-policy tail_sampling, throttled-drop first)
├── app/
│   ├── Dockerfile
│   ├── main.py                (FastAPI + middleware + /admin + OTel SDK + 10% 503 inject)
│   └── requirements.txt
├── manifests/
│   ├── 00-namespace.yaml
│   ├── 10-postgres.yaml       (StatefulSet + exporter sidecar + PodMonitor)
│   ├── 20-noisy-app.yaml      (Deployment + Service + PodMonitor)
│   └── 30-loadgen.yaml        (Deployment scaled 0; ConfigMap with loadgen.py and rates)
├── scripts/
│   ├── run-scenario.sh
│   └── teardown.sh
└── grafana/
    └── dashboard.json
```
