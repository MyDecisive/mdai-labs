#!/usr/bin/env bash
# End-to-end scenario driver for the noisy-neighbor lab.
#
# What this script does, in order:
#   1. Apply namespace, Postgres+exporter, noisy-app, loadgen (scaled to 0).
#   2. Apply the MdaiHub CR (variables/alerts/rules) and the OTel collectors
#      (trace-balancer + gateway with tail_sampling).
#   3. Wait for everything healthy.
#   4. Pre-populate healthy_tenant_list in Valkey with our four tenants.
#      (Idempotent: re-running keeps the same set; SADD ignores duplicates.)
#   5. Scale loadgen to 1 — noisy-neighbor scenario begins.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NS=noisy-neighbor
MDAI_NS=mdai

step() { printf "\n▶ %s\n" "$*"; }

step "Apply manifests"
kubectl apply -f "$ROOT/manifests/00-namespace.yaml"
kubectl apply -f "$ROOT/manifests/10-postgres.yaml"
kubectl apply -f "$ROOT/manifests/20-noisy-app.yaml"
kubectl apply -f "$ROOT/manifests/30-loadgen.yaml"

step "Apply MdaiHub CR (variables, alerts, rules)"
kubectl apply -f "$ROOT/hub.yaml"

step "Apply OTel collectors (trace-balancer + gateway with tail_sampling)"
kubectl apply -f "$ROOT/otel.yaml"

step "Wait for Postgres + noisy-app readiness"
kubectl -n "$NS" rollout status sts/postgres --timeout=180s
kubectl -n "$NS" rollout status deploy/noisy-app --timeout=180s

step "Wait for collectors"
kubectl -n "$MDAI_NS" wait --for=condition=Ready pod -l app.kubernetes.io/component=opentelemetry-collector --timeout=120s || true

step "Pre-populate healthy_tenant_list in Valkey"
# The MdaiHub variable is materialized into a Valkey set under
#   variable/<hub-name>/<varname>
# Pre-populating here ensures the tail sampler has a healthy set to match
# against from the first ConfigMap refresh — no chicken-and-egg.
# (Idempotent: SADD ignores existing members.)
VALKEY_KEY="variable/mdaihub-noisy-neighbor/healthy_tenant_list"
VALKEY_PASS="$(kubectl -n "$MDAI_NS" get secret valkey-secret \
  -o jsonpath='{.data.VALKEY_PASSWORD}' | base64 -d)"
kubectl -n "$MDAI_NS" exec mdai-valkey-primary-0 -- env PASS="$VALKEY_PASS" \
  sh -c 'valkey-cli -a "$PASS" --no-auth-warning SADD '"$VALKEY_KEY"' tenant-a tenant-b tenant-c noisy-1'

step "Force MdaiHub reconcile so the populated set is rendered into the variables ConfigMap"
kubectl -n "$MDAI_NS" annotate mdaihub mdaihub-noisy-neighbor \
  reconcile.mydecisive.ai/timestamp="$(date -u +%s)" --overwrite >/dev/null

step "Scale up loadgen — scenario begins"
kubectl -n "$NS" scale deploy/loadgen --replicas=1

cat <<EOF

Scenario started. Watch the loop in separate terminals:

  # 1. Per-tenant request mix from the load generator
  kubectl -n $NS logs -f deploy/loadgen

  # 2. Live rate-limit table inside the app
  kubectl -n $NS port-forward svc/noisy-app 8080:8080 &
  watch -n 1 'curl -s localhost:8080/admin/rate-limits'

  # 3. Tail-sampler decisions (the diagnostic side of the story)
  kubectl -n $MDAI_NS port-forward svc/kube-prometheus-stack-prometheus 9090:9090 &
  open 'http://localhost:9090/graph?g0.expr=sum%20by%20(policy)%20(rate(otelcol_processor_tail_sampling_count_traces_sampled%5B1m%5D))'

  # 4. Prometheus alerts and Grafana
  open http://localhost:9090/alerts
  kubectl -n $MDAI_NS port-forward svc/mdai-grafana 3000:80 &
  # Grafana: admin / mdai

  # 5. Current contents of the two Valkey sets
  PASS=\$(kubectl -n $MDAI_NS get secret valkey-secret -o jsonpath='{.data.VALKEY_PASSWORD}' | base64 -d)
  kubectl -n $MDAI_NS exec mdai-valkey-primary-0 -- env P=\$PASS sh -c \\
    'valkey-cli -a "\$P" --no-auth-warning SMEMBERS variable/mdaihub-noisy-neighbor/noisy_tenant_list'
  kubectl -n $MDAI_NS exec mdai-valkey-primary-0 -- env P=\$PASS sh -c \\
    'valkey-cli -a "\$P" --no-auth-warning SMEMBERS variable/mdaihub-noisy-neighbor/healthy_tenant_list'
EOF
