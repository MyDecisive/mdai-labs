# mdai-labs

A repository full of reference solutions for getting started with MDAI.

## Contributing

We welcome fixes, examples, and documentation improvements. Before opening a pull request, please read [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, testing guidance, and review expectations.

<a href="https://github.com/mydecisive/mdai-labs/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=mydecisive/mdai-labs&cache=bust2" />
</a>

## Automated Install/Uninstall (Cluster + MyDecisive Dependencies)

Optional: In your .bashrc (or equivalent), add this to EOF. If you choose to do this, you can use `mdai` instead of `./cli/mdai.sh` to utilize the CLI-like shell script.
```
# Set this to the path of your local clone of mdai-labs
export MDAI_LABS_DIR="$HOME/path/to/mdai-labs"
  
# Set mdai alias
  
alias mdai='"${MDAI_LABS_DIR%/}/cli/mdai.sh"'
```

Run the following to make our install/uninstall script executable.
```
chmod +x ./cli/mdai.sh
```

Use the CLI to install a local SmartHub, then run complete use cases. Individual component commands such as `hub`, `collector`, `logs`, and `fluentd` are mainly useful when developing or debugging a specific manifest; most users should start with `use-case`.

```sh
mdai install
```

### Run a use case

Each `0.9.0` use case is organized as a progression:

- `basic`: bare-bones telemetry flow
- `static`: hard-coded settings or policies
- `dynamic`: alert-driven automated config changes through MDAI Hub variables

Start with basic, compare static, then run dynamic:

```sh
mdai use-case compliance --version 0.9.0 --workflow basic --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml
mdai use-case compliance --version 0.9.0 --workflow static --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml
mdai use-case compliance --version 0.9.0 --workflow dynamic --data 0.9.0/use_cases/compliance/mock_data/fluentd_config.yaml
```

Other available `0.9.0` use cases:

```sh
mdai use-case data_filtration --version 0.9.0 --workflow dynamic --data mock-data/data_filtration.yaml
mdai use-case pii --version 0.9.0 --workflow dynamic --option multivar --data mock-data/pii.yaml
mdai use-case tail_sampling --version 0.9.0 --workflow dynamic --data mock-data/tail_sampling_dynamic.yaml
```

Some dynamic use cases require supporting resources before running. See the use-case README for details:

- [Compliance](0.9.0/use_cases/compliance/README.md)
- [Data Filtration](0.9.0/use_cases/data_filtration/README.md)
- [PII](0.9.0/use_cases/pii/README.md)
- [Tail Sampling](0.9.0/use_cases/tail_sampling/README.md)

### Clean up

```sh
mdai clean
mdai delete
```

### Available commands

#### Basic Commands

| Action                          | Command                      | Description                                   |
|---------------------------------|------------------------------|-----------------------------------------------|
| Install local SmartHub          | `mdai install`               | Creates local dependencies and installs MDAI  |
| Clean config deployments        | `mdai clean`                 | Deletes common resources in the `mdai` namespace |
| Delete cluster                  | `mdai delete`                | Deletes the local Kind cluster                |
| Check local setup               | `mdai doctor`                | Checks OS platform, required tools, and Docker |

#### Use Case Commands

| Action                          | Command                      | Description                                   |
|---------------------------------|------------------------------|-----------------------------------------------|
| Run use case                    | `mdai use-case <name>`       | Applies a use-case bundle                     |
| Select version                  | `--version 0.9.0`            | Uses versioned use-case manifests             |
| Select workflow                 | `--workflow basic|static|dynamic` | Chooses the use-case outcome             |
| Select variant                  | `--option <name>`            | Chooses a dynamic variant when available      |
| Remove use case                 | `mdai use-case <name> ... --delete` | Deletes the selected use-case bundle    |

#### Development Commands

| Action                          | Command                         | Description                                                   |
|---------------------------------|---------------------------------|---------------------------------------------------------------|
| Validate README command docs    | `mdai validate-docs`            | Checks README alias and documented command availability       |
| Run CLI tests                   | `mdai test`                     | Runs the sandboxed CLI test suite                             |
| Run experiment                  | `mdai experiment <name>`        | Applies an unversioned experiment from `experiments/`         |
