# Tail Sampling Use Case

This use case shows how trace sampling can evolve from a simple trace path into alert-driven adaptive sampling. The dynamic workflow is the key outcome: observed trace volume updates MDAI Hub variables, and the gateway collector changes sampling behavior from those variables without a YAML redeploy.

## Use Case Outcomes

- **Basic**: Get traces flowing through a trace-balancer and gateway collector.
- **Static**: Apply hard-coded tail-sampling policy for known high-volume operations.
- **Dynamic**: Classify services as high, medium, or low volume from Prometheus alerts and adjust sampling percentages automatically.

## File Roles

- `basic/hub.yaml` and `basic/otel.yaml`: the bare-bones starting point for validating trace ingestion and routing.
- `static/hub.yaml` and `static/otel.yaml`: fixed tail-sampling rules for deterministic comparison.
- `dynamic/hub.yaml`: defines high, medium, and low volume service sets plus alert-driven update rules.
- `dynamic/otel.yaml`: deploys the trace-balancer collector and gateway collector with hub-driven tail-sampling policies.
- `k8s_rbac.yaml`: gives the load-balancing collector the Kubernetes discovery permissions it needs.
- `scrape_trace_count_metrics.yaml`: lets Prometheus scrape trace count metrics emitted by the trace-balancer.
- `architecture.mmd`: Mermaid diagram of the dynamic workflow.

## Run

Start with the basic workflow:

```sh
mdai use-case tail_sampling --version 0.9.0 --workflow basic --data mock-data/tail_sampling.yaml
```

Move to static tail sampling:

```sh
mdai use-case tail_sampling --version 0.9.0 --workflow static --data mock-data/tail_sampling.yaml
```

Apply the dynamic support resources:

```sh
kubectl apply -f 0.9.0/use_cases/tail_sampling/k8s_rbac.yaml
kubectl apply -f 0.9.0/use_cases/tail_sampling/scrape_trace_count_metrics.yaml
```

Then run dynamic tail sampling:

```sh
mdai use-case tail_sampling --version 0.9.0 --workflow dynamic --data mock-data/tail_sampling_dynamic.yaml
```

To remove the dynamic workflow resources:

```sh
mdai use-case tail_sampling --version 0.9.0 --workflow dynamic --data mock-data/tail_sampling_dynamic.yaml --delete
kubectl delete -f 0.9.0/use_cases/tail_sampling/scrape_trace_count_metrics.yaml
kubectl delete -f 0.9.0/use_cases/tail_sampling/k8s_rbac.yaml
```

## Full Example

Use this path when you want to see the full progression in one session.

```sh
# Confirm local prerequisites.
mdai doctor

# Install MDAI and its cluster dependencies.
mdai install

# 1. Prove the basic trace path.
mdai use-case tail_sampling --version 0.9.0 --workflow basic --data mock-data/tail_sampling.yaml

# 2. Compare hard-coded static tail sampling.
mdai use-case tail_sampling --version 0.9.0 --workflow static --data mock-data/tail_sampling.yaml

# 3. Add the dynamic RBAC and Prometheus scrape resources.
kubectl apply -f 0.9.0/use_cases/tail_sampling/k8s_rbac.yaml
kubectl apply -f 0.9.0/use_cases/tail_sampling/scrape_trace_count_metrics.yaml

# 4. Run dynamic tail sampling backed by observed trace volume.
mdai use-case tail_sampling --version 0.9.0 --workflow dynamic --data mock-data/tail_sampling_dynamic.yaml

# Inspect generated resources and collector status.
kubectl get pods -n mdai
mdai report

# Remove dynamic resources, then clean generated use-case resources.
mdai use-case tail_sampling --version 0.9.0 --workflow dynamic --data mock-data/tail_sampling_dynamic.yaml --delete
kubectl delete -f 0.9.0/use_cases/tail_sampling/scrape_trace_count_metrics.yaml
kubectl delete -f 0.9.0/use_cases/tail_sampling/k8s_rbac.yaml
mdai clean
```

## Dynamic Flow

Synthetic trace generators send OTLP traces to the trace-balancer collector. The trace-balancer routes spans by trace ID to the gateway collector and emits service trace-count metrics. Prometheus alerts update MDAI Hub service-volume sets, and the gateway collector uses those variables in tail-sampling policies.
