#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl delete -f "$ROOT/otel.yaml" --ignore-not-found
kubectl delete -f "$ROOT/hub.yaml" --ignore-not-found
kubectl delete -f "$ROOT/manifests/30-loadgen.yaml" --ignore-not-found
kubectl delete -f "$ROOT/manifests/20-noisy-app.yaml" --ignore-not-found
kubectl delete -f "$ROOT/manifests/10-postgres.yaml" --ignore-not-found
kubectl delete -f "$ROOT/manifests/00-namespace.yaml" --ignore-not-found
