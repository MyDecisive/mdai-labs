#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/helpers.sh"

OUT="${SANDBOX}/out_doctor_linux.txt"
export MDAI_UNAME_S=Linux
export MDAI_UNAME_M=x86_64
RC=$(run_cli_rc "${OUT}" doctor)
assert_ok "${RC}"
assert_contains "${OUT}" "Operating system : Linux \\(linux\\)"
assert_contains "${OUT}" "OS support       : supported"
assert_contains "${OUT}" "CPU architecture : x86_64 \\(amd64\\)"
assert_contains "${OUT}" "Architecture     : common"

OUT2="${SANDBOX}/out_doctor_macos.txt"
export MDAI_UNAME_S=Darwin
export MDAI_UNAME_M=arm64
RC2=$(run_cli_rc "${OUT2}" doctor)
assert_ok "${RC2}"
assert_contains "${OUT2}" "Operating system : Darwin \\(macos\\)"
assert_contains "${OUT2}" "OS support       : supported"
assert_contains "${OUT2}" "CPU architecture : arm64 \\(arm64\\)"
assert_contains "${OUT2}" "Architecture     : common"

OUT3="${SANDBOX}/out_doctor_windows.txt"
export MDAI_UNAME_S=MINGW64_NT
export MDAI_UNAME_M=x86_64
RC3=$(run_cli_rc "${OUT3}" doctor)
assert_not_ok "${RC3}"
assert_contains "${OUT3}" "Operating system : MINGW64_NT \\(unsupported\\)"
assert_contains "${OUT3}" "OS support       : unsupported"
unset MDAI_UNAME_S MDAI_UNAME_M
