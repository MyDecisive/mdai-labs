# Compliance Use Case

This use case shows how log routing can evolve from a simple pass-through pipeline into an automated compliance workflow. The dynamic workflow is the key outcome: MDAI Hub variables decide which log levels and services are treated as compliance-critical without changing collector YAML.

## Use Case Outcomes

- **Basic**: Get compliance logs flowing through a minimal gateway collector.
- **Static**: Route compliance logs with hard-coded levels and service rules in the collector config.
- **Dynamic**: Move those routing rules into MDAI Hub variables so critical levels and services can change at runtime.

## File Roles

- `basic/hub.yaml` and `basic/otel.yaml`: the bare-bones starting point for proving ingestion and export.
- `static/hub.yaml` and `static/otel.yaml`: a fixed-policy version for comparing deterministic routing behavior.
- `dynamic/hub.yaml`: defines the editable `non_crit_levels`, `crit_levels`, and `crit_services` variable sets.
- `dynamic/otel.yaml`: reads hub-generated variables and routes records into non-critical or compliance pipelines.
- `mock_data/fluentd_config.yaml`: sample compliance-style log input for local validation.
- `architecture.mmd`: Mermaid diagram of the dynamic workflow.

## Run

Start with the basic workflow:

```sh
mdai use-case compliance --version 0.9.0 --workflow basic --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml
```

Move to static policy:

```sh
mdai use-case compliance --version 0.9.0 --workflow static --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml
```

Then run dynamic policy:

```sh
mdai use-case compliance --version 0.9.0 --workflow dynamic --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml
```

To remove the dynamic workflow resources:

```sh
mdai use-case compliance --version 0.9.0 --workflow dynamic --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml --delete
```

## Full Example

Use this path when you want to see the full progression in one session.

```sh
# Confirm local prerequisites.
mdai doctor

# Install MDAI and its cluster dependencies.
mdai install

# 1. Prove the basic log path.
mdai use-case compliance --version 0.9.0 --workflow basic --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml

# 2. Compare the hard-coded static policy.
mdai use-case compliance --version 0.9.0 --workflow static --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml

# 3. Run the dynamic policy backed by MDAI Hub variables.
mdai use-case compliance --version 0.9.0 --workflow dynamic --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml

# Inspect generated resources and collector status.
kubectl get pods -n mdai
mdai report

# Remove the dynamic workflow, then clean generated use-case resources.
mdai use-case compliance --version 0.9.0 --workflow dynamic --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml --delete
mdai clean
```

## Dynamic Flow

Fluentd forwards logs to the gateway collector. The collector reads MDAI Hub variables from the generated variables ConfigMap and routes log records by level or service. Non-critical records go through the standard debug path, while critical records go through the compliance debug exporter with detailed output.
