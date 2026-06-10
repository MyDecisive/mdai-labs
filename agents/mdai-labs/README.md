# mdai-labs Agent Guide

This directory contains reusable project guidance for AI coding assistants working in `mdai-labs`.

It is written to be usable by Codex, Claude, GitHub Copilot, Cursor, or any other LLM-based coding agent. Product-specific adapters should point here instead of duplicating these instructions.

## Start here

1. Read this README for the short project workflow and validation checklist.
2. Read `references/cli.md` before changing `cli/mdai.sh`, CLI tests, command docs, or README command examples.
3. Read `references/experiments.md` before adding or changing experiments, use cases, platform examples, or Kubernetes manifests.

## Main rules

- Prefer MDAI CLI workflows over Makefile workflows.
- Run the narrowest useful validation for the change.
- Use `./cli/mdai.sh test` for CLI behavior changes.
- Use `./cli/mdai.sh validate-docs` for README alias or command-reference changes.
- Use `bash -n cli/mdai.sh` after shell changes.
- Do not commit generated cluster state, credentials, kubeconfig files, or local secrets.
- New experiences belong under `experiments/` and should follow `experiments/example_experiment/`.

## Why this exists

The repository has conventions that are easy to miss:

- CLI commands require updates in implementation, help text, parser, dispatcher, docs, and tests.
- CLI tests run through a sandboxed helper instead of requiring a live cluster.
- The root README should introduce users through `mdai install`, use-case workflows, and cleanup; standalone component commands belong in development/debugging context.
- Experiments are unversioned and use the latest hub version.
- Versioned `use_cases` and `platform` directories are for maintaining existing versioned examples.
- Local workflows are expected to work on Linux and macOS, including Ubuntu 24.04.

Keeping those rules in one place helps AI assistants make consistent changes without rediscovering the project structure every time.
