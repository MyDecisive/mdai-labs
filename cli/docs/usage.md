# mdai.sh — Usage

_Generated on 2026-02-14T17:36:29Z_

## Synopsis (from `--help`)

```text
mdai.sh - Modular MDAI quickstart

USAGE:
  ./mdai.sh [global flags] <command> [command flags]

GLOBAL FLAGS:
  --cluster-name NAME        Kind cluster name (default: $KIND_CLUSTER_NAME)
  --kind-config FILE         Kind cluster config file (optional)
  COMMANDS-f, --values FILE          Add a Helm values file (repeatable)

  --namespace NS             App namespace for kubectl applies (default: $NAMESPACE)
  --chart-namespace NS       Helm namespace (defaults to --namespace if omitted)
  --kube-context NAME        kubecontext for kubectl/helm
  --release-name NAME        Helm release name (default: mdai)
  --chart-ref REF            Full chart ref (e.g., oci://ghcr.io/mydecisive/mdai-hub)
  --chart-repo URL           Helm repo URL (default: $HELM_REPO_URL)
  --chart-name NAME          Helm chart name (default: $HELM_CHART_NAME)
  --chart-version VER        Helm chart version (default: $HELM_CHART_VERSION)
  --values FILE              Add a Helm values file (repeatable)
  --set key=val              Add a Helm --set (repeatable)
  --helm-extra "ARGS"        Extra Helm args (repeatable)
  --cert-manager-url URL     Override cert-manager manifest URL
  --no-cert-manager          Skip installing cert-manager
  --wait-timeout 120s        kubectl wait timeout (default: $KUBECTL_WAIT_TIMEOUT)
  --dry-run                  Print commands without executing
  --verbose                  Print commands and stream output
  -h, --help                 Show help

COMMANDS:
  use_case NAME [--version VER] [--hub FILE] [--otel FILE] [--workflow basic|static|dynamic] [--debug-resolve]

INSTALL / UPGRADE
  install                        Create Kind deps then install MDAI (alias: install_deps + install_mdai)
  install_deps                   Prepare Kind cluster + dependencies
  install_mdai                   Helm install/upgrade + wait
                                 [--version VER] [--values FILE] [--set k=v] [--resources [PREFIX]] [--no-cert-manager]
                                 [--version VER] [-f|--values FILE] [--set k=v] [--resources [PREFIX]] [--no-cert-manager]

  upgrade                        Helm upgrade/install only

COMPONENTS
  hub [--file FILE]              Apply Hub manifest (default: ./mdai/hub/hub_ref.yaml)
  collector [--file FILE]        Apply OTel Collector (default: ./otel/otel_ref.yaml)
  fluentd [--values FILE]        Install Fluentd with values
  mdai_monitor [--file FILE]     Apply Monitor manifest
  aws_secret [--script FILE]     Create Kubernetes secret from env script

DATA GENERATION
  datagen [--apply FILE ...]     Apply custom generator YAMLs (falls back to built-in synthetics)
  logs                           Alias for 'datagen'

USE-CASES
  use-case <pii|compliance|tail-sampling>
            [--version VER]
            [--workflow basic|static|dynamic]
            [--option OPT]
            [--hub PATH] [--otel PATH]
            [--apply FILE ...]

                    Apply a named bundle. If --hub/--otel not given, resolves:
                    use-cases/<case>[/<version>]/{hub.yaml,otel.yaml}

                    Extras can be added with repeatable --apply.

                    Examples:
                      use-case compliance --version 0.8.6
                      use-case pii --hub ./use-cases/pii/0.8.6/hub.yaml --otel ./use-cases/pii/0.8.6/otel.yaml
                      use-case compliance --workflow basic

KUBECTL HELPERS
  apply FILE                     kubectl apply -f FILE -n $NAMESPACE
  delete_file FILE               kubectl delete -f FILE -n $NAMESPACE

MAINTENANCE
  clean                          Remove common resources (keeps namespace)
  delete                         Delete the Kind cluster

REPORTING / DOCS
  report [--format table|json|yaml] [--out FILE]
                                 Show what’s installed
  gen-usage [--out FILE] [--examples FILE] [--section "..."]
                                 Generate usage.md

DEPRECATED (prefer `use-case`)
  compliance [--version VER] [--delete] [--otel FILE --hub FILE]
  df         [--version VER] [--delete] [--otel FILE --hub FILE]
  pii        [--version VER] [--delete] [--otel FILE --hub FILE]

For a full, nicely formatted guide, run:
  ./mdai.sh gen-usage --out ./docs/usage.md --examples ./cli/examples.md

HISTORY
  use-case-history [--json|--table]
                    Show tracked apply/delete operations from ./.mdai/state/use-cases.
                    Flags: --case NAME  --action apply|delete  --since TS  --until TS
```

## Global Flags

```text
  --cluster-name NAME        Kind cluster name (default: $KIND_CLUSTER_NAME)
  --kind-config FILE         Kind cluster config file (optional)
  COMMANDS-f, --values FILE          Add a Helm values file (repeatable)

  --namespace NS             App namespace for kubectl applies (default: $NAMESPACE)
  --chart-namespace NS       Helm namespace (defaults to --namespace if omitted)
  --kube-context NAME        kubecontext for kubectl/helm
  --release-name NAME        Helm release name (default: mdai)
  --chart-ref REF            Full chart ref (e.g., oci://ghcr.io/mydecisive/mdai-hub)
  --chart-repo URL           Helm repo URL (default: $HELM_REPO_URL)
  --chart-name NAME          Helm chart name (default: $HELM_CHART_NAME)
  --chart-version VER        Helm chart version (default: $HELM_CHART_VERSION)
  --values FILE              Add a Helm values file (repeatable)
  --set key=val              Add a Helm --set (repeatable)
  --helm-extra "ARGS"        Extra Helm args (repeatable)
  --cert-manager-url URL     Override cert-manager manifest URL
  --no-cert-manager          Skip installing cert-manager
  --wait-timeout 120s        kubectl wait timeout (default: $KUBECTL_WAIT_TIMEOUT)
  --dry-run                  Print commands without executing
  --verbose                  Print commands and stream output
  -h, --help                 Show help
```

## Commands

```text
  use_case NAME [--version VER] [--hub FILE] [--otel FILE] [--workflow basic|static|dynamic] [--debug-resolve]

INSTALL / UPGRADE
  install                        Create Kind deps then install MDAI (alias: install_deps + install_mdai)
  install_deps                   Prepare Kind cluster + dependencies
  install_mdai                   Helm install/upgrade + wait
                                 [--version VER] [--values FILE] [--set k=v] [--resources [PREFIX]] [--no-cert-manager]
                                 [--version VER] [-f|--values FILE] [--set k=v] [--resources [PREFIX]] [--no-cert-manager]

  upgrade                        Helm upgrade/install only

COMPONENTS
  hub [--file FILE]              Apply Hub manifest (default: ./mdai/hub/hub_ref.yaml)
  collector [--file FILE]        Apply OTel Collector (default: ./otel/otel_ref.yaml)
  fluentd [--values FILE]        Install Fluentd with values
  mdai_monitor [--file FILE]     Apply Monitor manifest
  aws_secret [--script FILE]     Create Kubernetes secret from env script

DATA GENERATION
  datagen [--apply FILE ...]     Apply custom generator YAMLs (falls back to built-in synthetics)
  logs                           Alias for 'datagen'

USE-CASES
  use-case <pii|compliance|tail-sampling>
            [--version VER]
            [--workflow basic|static|dynamic]
            [--option OPT]
            [--hub PATH] [--otel PATH]
            [--apply FILE ...]

                    Apply a named bundle. If --hub/--otel not given, resolves:
                    use-cases/<case>[/<version>]/{hub.yaml,otel.yaml}

                    Extras can be added with repeatable --apply.

                    Examples:
                      use-case compliance --version 0.8.6
                      use-case pii --hub ./use-cases/pii/0.8.6/hub.yaml --otel ./use-cases/pii/0.8.6/otel.yaml
                      use-case compliance --workflow basic

KUBECTL HELPERS
  apply FILE                     kubectl apply -f FILE -n $NAMESPACE
  delete_file FILE               kubectl delete -f FILE -n $NAMESPACE

MAINTENANCE
  clean                          Remove common resources (keeps namespace)
  delete                         Delete the Kind cluster

REPORTING / DOCS
  report [--format table|json|yaml] [--out FILE]
                                 Show what’s installed
  gen-usage [--out FILE] [--examples FILE] [--section "..."]
                                 Generate usage.md

DEPRECATED (prefer `use-case`)
  compliance [--version VER] [--delete] [--otel FILE --hub FILE]
  df         [--version VER] [--delete] [--otel FILE --hub FILE]
  pii        [--version VER] [--delete] [--otel FILE --hub FILE]

For a full, nicely formatted guide, run:
  ./mdai.sh gen-usage --out ./docs/usage.md --examples ./cli/examples.md

HISTORY
  use-case-history [--json|--table]
                    Show tracked apply/delete operations from ./.mdai/state/use-cases.
                    Flags: --case NAME  --action apply|delete  --since TS  --until TS
```

## Defaults (auto-detected)

| Variable | Default | Note |
|---|---|---|
| WORKFLOW | static |  |
| KIND_CLUSTER_NAME | mdai-labs |  |
| KIND_CONFIG |  |  |
| NAMESPACE | mdai | app namespace for kubectl applies |
| CHART_NAMESPACE |  | helm namespace (defaults to NAMESPACE if empty) |
| HELM_REPO_URL | https://charts.mydecisive.ai |  |
| HELM_CHART_NAME | mdai-hub |  |
| HELM_CHART_VERSION |  |  |
| HELM_CHART_REF | oci://ghcr.io/mydecisive/mdai-hub |  |
| HELM_RELEASE_NAME | mdai | helm release name |
| CERT_MANAGER_URL | https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml |  |
| KUBECTL_WAIT_TIMEOUT | 180s |  |
| KUBE_CONTEXT |  | --kube-context |
| SYN_PATH | ./synthetics |  |
| OTEL_PATH | ./otel |  |
| MDAI_PATH | ./mdai |  |
| USE_CASES_ROOT | . | root that contains versioned /use_cases trees |
| MDAI_STATE_DIR | ./.mdai/state |  |
| MDAI_UC_STATE_DIR | ${MDAI_STATE_DIR |  |
| MDAI_UC_RUNS_NDJSON | ${MDAI_UC_STATE_DIR |  |
| MDAI_UC_RUNS_LOG | ${MDAI_UC_STATE_DIR |  |
| HELP_EXAMPLES_FILE | ./cli/examples.md |  |
| HELP_EXAMPLES_LINES | 40 |  |
| DRY_RUN | false |  |
| VERBOSE | false |  |
| INSTALL_CERT_MANAGER | true |  |

