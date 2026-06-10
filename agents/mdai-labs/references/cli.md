# CLI Workflow

CLI behavior lives in `cli/mdai.sh`.

When adding or changing a command, update:

- the command implementation function
- the `usage()` help text
- `parse_globals()` known command list
- the `main()` dispatcher
- `cli/docs/usage.md`
- README examples when user-facing commands change
- tests in `cli/tests/cases/`

## Testing

Run:

```sh
./cli/mdai.sh test
bash -n cli/mdai.sh
```

The test runner wraps `cli/tests/run.sh`. Tests use `cli/tests/helpers.sh`, which creates a temporary sandbox and stubs `kubectl`, `helm`, `docker`, and `kind`.

Prefer test coverage for:

- command parsing
- dry-run output
- file resolution
- failure messages
- aliases and compatibility shims

Avoid tests that require a live cluster unless the user explicitly asks for integration validation.

## Existing CLI conventions

- Prefer `mdai` alias examples in docs after the README alias is introduced.
- Keep `./cli/mdai.sh` usable as the direct fallback.
- In the root README, lead users through `mdai install`, `mdai use-case ...`, then `mdai clean` / `mdai delete`.
- Do not present standalone `mdai logs`, `mdai hub`, `mdai collector`, or `mdai fluentd` as the main user path; those are development/debugging commands unless a workflow explicitly needs them.
- `validate-docs` checks README alias setup and documented command availability.
- `test` runs the CLI test suite.
- `doctor` checks OS platform, required tools, and Docker daemon status.
- `experiment` and `experiments` are aliases for experiment workflows.
- `use-case` and `use_case` are aliases for versioned use-case workflows.
