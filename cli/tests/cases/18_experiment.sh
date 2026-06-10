#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/helpers.sh"

OUT="${SANDBOX}/out_experiment_apply.txt"
RC=$(run_cli_rc "${OUT}" --dry-run experiment demo)
assert_ok "${RC}"
assert_contains "${OUT}" "apply -f ./experiments/demo/otel.yaml"
assert_contains "${OUT}" "apply -f ./experiments/demo/hub.yaml"
assert_contains "${OUT}" "apply -f ./experiments/demo/mock_data.yaml"

OUT2="${SANDBOX}/out_experiment_delete.txt"
RC2=$(run_cli_rc "${OUT2}" --dry-run experiments demo --delete)
assert_ok "${RC2}"
assert_contains "${OUT2}" "delete -f ./experiments/demo/otel.yaml"
assert_contains "${OUT2}" "delete -f ./experiments/demo/hub.yaml"

OUT3="${SANDBOX}/out_experiment_version.txt"
RC3=$(run_cli_rc "${OUT3}" --dry-run experiment demo --version 0.8.6)
assert_not_ok "${RC3}"
assert_contains "${OUT3}" "experiment: --version is not supported"
