# Data Filtration Use Case

This use case shows how noisy log streams can be filtered progressively. The dynamic workflow is the key outcome: observer metrics and Prometheus alerts automatically update MDAI Hub variables, and the collector uses those variables to filter noisy services without a YAML redeploy.

## Use Case Outcomes

- **Basic**: Get logs flowing through a minimal customer pipeline.
- **Static**: Filter a fixed, hard-coded set of services in the collector config.
- **Dynamic**: Detect top talkers/listeners from observed traffic and automatically update the filtered service list.

## File Roles

- `basic/hub.yaml` and `basic/otel.yaml`: the bare-bones starting point for validating ingestion and export.
- `static/hub.yaml` and `static/otel.yaml`: a fixed filter that shows what hard-coded suppression looks like.
- `dynamic/hub.yaml`: defines the `service_list` variable and alert-driven rules for top talkers/listeners.
- `dynamic/otel.yaml`: filters logs whose `mdai_service` matches the hub-managed `SERVICE_LIST_REGEX`.
- `dynamic/observer.yaml`: creates received/exported service-volume metrics used to identify noisy services.
- `dynamic/monitor.yaml`: provides the hub monitor collector used by observer resources.
- `architecture.mmd`: Mermaid diagram of the dynamic workflow.

## Run

Start with the basic workflow:

```sh
mdai use-case data_filtration --version 0.9.0 --workflow basic --data mock-data/data_filtration.yaml
```

Move to static filtering:

```sh
mdai use-case data_filtration --version 0.9.0 --workflow static --data mock-data/data_filtration.yaml
```

Apply the dynamic support resources:

```sh
kubectl apply -f 0.9.0/use_cases/data_filtration/dynamic/monitor.yaml
kubectl apply -f 0.9.0/use_cases/data_filtration/dynamic/observer.yaml
```

Then run dynamic filtering:

```sh
mdai use-case data_filtration --version 0.9.0 --workflow dynamic --data mock-data/data_filtration.yaml
```

To remove the dynamic workflow resources:

```sh
mdai use-case data_filtration --version 0.9.0 --workflow dynamic --data mock-data/data_filtration.yaml --delete
kubectl delete -f 0.9.0/use_cases/data_filtration/dynamic/observer.yaml
kubectl delete -f 0.9.0/use_cases/data_filtration/dynamic/monitor.yaml
```

## Full Example

Use this path when you want to see the full progression in one session.

```sh
# Confirm local prerequisites.
mdai doctor

# Install MDAI and its cluster dependencies.
mdai install

# 1. Prove the basic log path.
mdai use-case data_filtration --version 0.9.0 --workflow basic --data mock-data/data_filtration.yaml

# 2. Compare the hard-coded static filter.
mdai use-case data_filtration --version 0.9.0 --workflow static --data mock-data/data_filtration.yaml

# 3. Add the dynamic observer and monitor resources.
kubectl apply -f 0.9.0/use_cases/data_filtration/dynamic/monitor.yaml
kubectl apply -f 0.9.0/use_cases/data_filtration/dynamic/observer.yaml

# 4. Run dynamic filtering backed by observed service volume.
mdai use-case data_filtration --version 0.9.0 --workflow dynamic --data mock-data/data_filtration.yaml

# Inspect generated resources and collector status.
kubectl get pods -n mdai
mdai report

# Remove dynamic resources, then clean generated use-case resources.
mdai use-case data_filtration --version 0.9.0 --workflow dynamic --data mock-data/data_filtration.yaml --delete
kubectl delete -f 0.9.0/use_cases/data_filtration/dynamic/observer.yaml
kubectl delete -f 0.9.0/use_cases/data_filtration/dynamic/monitor.yaml
mdai clean
```

## Dynamic Flow

Logs enter the gateway collector through Fluent Forward. The collector tags received and exported records for the observer, sends observer telemetry to the observer service, and filters customer logs when `mdai_service` matches the hub-managed service list. Prometheus alerts update that list when services cross traffic thresholds.
