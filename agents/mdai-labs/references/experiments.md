# Experiments and Examples

Versioned `use_cases` and `platform` directories may be modified when maintaining existing versioned examples.

New experiences belong under `experiments/` and should not be versioned. Experiments use the latest hub version.

Use `experiments/example_experiment/` as the reference layout.

## Experiment structure

```text
experiments/
|__ experiment_name/
    |__ README.md
    |__ architecture.mmd
    |__ otel.yaml
    |__ hub.yaml
    |__ mock_data.yaml
    |__ <other relevant files>
```

## CLI behavior

The experiment command resolves:

- `experiments/<name>/otel.yaml`
- `experiments/<name>/hub.yaml`
- optional `experiments/<name>/mock_data.yaml`

Examples:

```sh
mdai experiment example_experiment
mdai experiment example_experiment --delete
```

`--version` is intentionally rejected for experiments.

## Manifest guidance

- Keep manifests portable across typical Kubernetes environments.
- Make provider-specific settings explicit when required.
- Include supporting manifests such as RBAC or scrape configs beside the experiment.
- Document the run order in the experiment `README.md`.
- Include a Mermaid diagram or another useful architecture/help diagram.
- Use-case READMEs should include a full example that walks from `mdai doctor` and `mdai install` through basic, static, dynamic, validation, and cleanup.
