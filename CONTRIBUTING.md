# Contributing to mdai-labs

Welcome to the pod and thank you for helping improve `mdai-labs`. This repository contains reference solutions, example configurations, and helper scripts for getting started with the MyDecisive SmartHub, so contributions should be easy to reproduce and safe for others to run locally.

## Before you start

- Search existing issues and pull requests to avoid duplicate work.
- Open an issue first for larger changes, new use cases, or behavior that changes an existing workflow.
- Keep pull requests focused on one fix, example, or workflow improvement at a time.
- If you are using an AI coding assistant, read `AGENTS.md` and `agents/mdai-labs/README.md` for project-specific guidance.

## Local prerequisites

Most examples in this repository use Kubernetes-focused tooling. Install the tools needed for the path you are changing:

- `kind`
- `kubectl`
- `helm`
- Compatible shell (bash, zsh, etc)

Local workflows are supported on Linux and macOS, including Ubuntu 24.04. Run `mdai doctor` to check your OS platform and required tools.

Use the MDAI CLI for local workflows whenever possible. Make it executable before testing:

```sh
chmod +x ./cli/mdai.sh
```

If you configured the README alias, use `mdai` in place of `./cli/mdai.sh`.

## Making changes

- Follow the structure and naming patterns already used in the directory you are changing.
- Prefer small, readable YAML and shell changes over broad rewrites.
- Update documentation when commands, paths, manifests, or expected behavior change.
- Do not commit generated cluster state, local credentials, kubeconfig files, or environment-specific secrets, however, feel free to reference them with placeholders
- Keep example manifests usable across typical Kubernetes environments. If an example requires provider-specific settings, make that dependency clear.
- Use container images that run on common Linux and macOS local development setups.
- You may modify versioned `use_cases` or `platform` directories when maintaining existing versioned examples.
- Put new labs under `experiments/`. Experiments use the latest hub version and should not be versioned.

Use this structure for new experiments:

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

Use `experiments/example_experiment/` as the reference layout for a complete experiment, including the README and architecture diagram.

## CLI and tests

CLI behavior lives in `cli/mdai.sh`. When you add or change a command:

- Update the command implementation, help text, parser, and dispatcher in `cli/mdai.sh`.
- Update `cli/docs/usage.md` and any README examples affected by the change.
- Add or update a test case in `cli/tests/cases/`.

CLI tests use `cli/tests/helpers.sh`, which creates a temporary sandbox and stubs tools such as `kubectl`, `helm`, `docker`, and `kind`. Prefer testing command parsing, generated command output, file resolution, and dry-run behavior there instead of requiring a live cluster.

## Testing

Run the narrowest useful validation for your change and include the commands in your pull request.

For README alias and documented command changes:

```sh
mdai validate-docs
```

For CLI changes:

```sh
mdai test
```

For full local stack validation, prefer the MDAI CLI:

```sh
mdai install
mdai logs
mdai hub
mdai collector
mdai fluentd
```

For a narrower change, run only the relevant CLI command.

Use `make` only when you are changing Makefile behavior or validating a legacy path that is not covered by the CLI.

Clean up local resources when you are done:

```sh
mdai clean
mdai delete
```

If you cannot run a validation step locally, note why in the pull request and describe the manual review you performed.

## Pull requests

In your pull request:

- Summarize what changed and why.
- Link the related issue when one exists.
- List the commands you ran to test the change.
- Include screenshots, logs, or resource output when they help reviewers verify Kubernetes behavior.
- Call out any breaking changes or migration steps.

Before requesting review, make sure the pull request template checklist is accurate for your change.

## Reporting bugs and requesting features

Use the GitHub issue templates for bugs and feature requests. Include enough detail for maintainers to reproduce the behavior, including the project version, operating system, commands run, and relevant logs.
