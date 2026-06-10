---
name: mdai-labs
description: Use when working in the mdai-labs repository, especially when changing the mdai CLI, tests, contribution docs, experiments, use cases, Kubernetes manifests, or README guidance. Provides repo-specific workflows, validation commands, and conventions for experiments and versioned examples.
---

# mdai-labs

Use this skill for changes in the mdai-labs repository.

This is the Codex-specific adapter. The source of truth is the tool-neutral agent guide at `AGENTS.md` and `agents/mdai-labs/README.md`.

## Workflow

1. Read `AGENTS.md`.
2. Read `agents/mdai-labs/README.md`.
3. For CLI changes, read `agents/mdai-labs/references/cli.md`.
4. For experiments, use cases, platform examples, or Kubernetes manifests, read `agents/mdai-labs/references/experiments.md`.

## Required checks

- Docs alias or command reference changes: `./cli/mdai.sh validate-docs`
- CLI behavior changes: `./cli/mdai.sh test`
- Shell syntax changes: `bash -n cli/mdai.sh`
- Local platform/tool readiness: `./cli/mdai.sh doctor`
