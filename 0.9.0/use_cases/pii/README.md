# PII Use Case

This use case shows how PII handling can evolve from a simple telemetry path into configurable redaction, hashing, and field scrubbing. The dynamic workflow is the key outcome: regexes, templates, and field sets move into MDAI Hub variables so sensitive-data handling can change without collector YAML edits.

## Use Case Outcomes

- **Basic**: Get PII-bearing logs flowing through a minimal gateway collector.
- **Static**: Apply hard-coded PII handling rules in the collector config.
- **Dynamic**: Use MDAI Hub variables to control regexes, replacement templates, fields to redact, and fields to hash.

## File Roles

- `basic/hub.yaml` and `basic/otel.yaml`: the bare-bones starting point for validating PII log ingestion.
- `static/hub.yaml` and `static/otel.yaml`: fixed PII handling rules for deterministic comparison.
- `dynamic/singlevar/hub.yaml`: defines credit-card regex and replacement template variables.
- `dynamic/singlevar/otel.yaml`: applies credit-card replacement using hub-provided variables.
- `dynamic/multivar/hub.yaml`: defines field sets, regex variables, and replacement templates for multiple PII types.
- `dynamic/multivar/otel.yaml`: includes redaction, hashing, and scrub/replace processors.
- `architecture.mmd`: Mermaid diagram of the dynamic workflow.

## Run

Start with the basic workflow:

```sh
mdai use-case pii --version 0.9.0 --workflow basic --data mock-data/pii.yaml
```

Move to static PII handling:

```sh
mdai use-case pii --version 0.9.0 --workflow static --data mock-data/pii.yaml
```

Then run single-variable dynamic credit-card scrubbing:

```sh
mdai use-case pii --version 0.9.0 --workflow dynamic --option singlevar --data mock-data/pii.yaml
```

Or run multi-variable dynamic PII processing:

```sh
mdai use-case pii --version 0.9.0 --workflow dynamic --option multivar --data mock-data/pii.yaml
```

To remove a dynamic variant, run the same command with `--delete`.

## Full Example

Use this path when you want to see the full progression in one session.

```sh
# Confirm local prerequisites.
mdai doctor

# Install MDAI and its cluster dependencies.
mdai install

# 1. Prove the basic PII log path.
mdai use-case pii --version 0.9.0 --workflow basic --data mock-data/pii.yaml

# 2. Compare hard-coded static PII handling.
mdai use-case pii --version 0.9.0 --workflow static --data mock-data/pii.yaml

# 3. Run single-variable dynamic credit-card scrubbing.
mdai use-case pii --version 0.9.0 --workflow dynamic --option singlevar --data mock-data/pii.yaml

# 4. Run multi-variable dynamic redaction, hashing, and replacement.
mdai use-case pii --version 0.9.0 --workflow dynamic --option multivar --data mock-data/pii.yaml

# Inspect generated resources and collector status.
kubectl get pods -n mdai
mdai report

# Remove dynamic variants, then clean generated use-case resources.
mdai use-case pii --version 0.9.0 --workflow dynamic --option singlevar --data mock-data/pii.yaml --delete
mdai use-case pii --version 0.9.0 --workflow dynamic --option multivar --data mock-data/pii.yaml --delete
mdai clean
```

## Dynamic Flow

Fluentd forwards logs with PII fields to the gateway collector. The gateway reads MDAI Hub variables from the generated variables ConfigMap. Depending on the selected variant, the collector applies regex-based replacement, field deletion, or hashing before exporting sanitized log output.
