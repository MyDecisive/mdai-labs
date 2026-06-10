# Dynamic Tail Sampling

This experiment demonstrates dynamic tail sampling with MDAI Hub variables, Prometheus alerts, and OpenTelemetry Collector tail-sampling policies.

## Files

- `otel.yaml`: trace load-balancer and gateway collector configuration
- `hub.yaml`: MDAI Hub variables, alerts, and rules
- `mock_data.yaml`: synthetic trace generators for low- and high-volume operations
- `k8s_rbac.yaml`: service account and RBAC for the load-balancing collector
- `scrape_trace_count_metrics.yaml`: Prometheus scrape config for trace count metrics
- `architecture.mmd`: Mermaid architecture diagram

## Run

Apply the supporting resources first:

```sh
kubectl apply -f experiments/example_experiment/k8s_rbac.yaml
kubectl apply -f experiments/example_experiment/scrape_trace_count_metrics.yaml
```

Then run the experiment:

```sh
mdai experiment example_experiment
```

To remove the experiment resources:

```sh
mdai experiment example_experiment --delete
kubectl delete -f experiments/example_experiment/scrape_trace_count_metrics.yaml
kubectl delete -f experiments/example_experiment/k8s_rbac.yaml
```

## Flow

Synthetic trace generators send traces to the trace-balancer collector. The trace-balancer routes traces by trace ID to the gateway collector and exports per-service trace count metrics. Prometheus alerts update MDAI Hub variables, and the gateway collector uses those variables to adjust tail-sampling behavior by service volume.
