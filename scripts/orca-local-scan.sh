#!/usr/bin/env bash
# Run every Orca Shift Left scan locally with orca-cli.
#
# ── Install orca-cli ─────────────────────────────────────────────────────────
#   macOS (Homebrew):
#     brew install orcasecurity/orca-cli/orca-cli
#   Linux (or macOS without Homebrew):
#     curl -sfL https://raw.githubusercontent.com/orcasecurity/orca-cli/main/install.sh \
#       | sh -s -- -b "$HOME/.local/bin"            # optional last arg: version, e.g. 1.135.1
#     export PATH="$HOME/.local/bin:$PATH"
#   Docker (no install):
#     docker run --rm -e ORCA_SECURITY_API_TOKEN -v "$PWD":/src -w /src ghcr.io/orcasecurity/orca-cli:1 ...
#
# ── Usage ────────────────────────────────────────────────────────────────────
#   export ORCA_SECURITY_API_TOKEN=...   # Shift Left User role – never commit it
#   export ORCA_PROJECT_KEY=...
#   make build                           # builds orca-appsec-demo:local for the image scan
#   ./scripts/orca-local-scan.sh
#
# Demo mode: --exit-code 0, so policy violations are reported but never fail.
set -uo pipefail

cd "$(dirname "$0")/.."

missing=0
if [[ -z "${ORCA_SECURITY_API_TOKEN:-}" ]]; then
  echo "ERROR: ORCA_SECURITY_API_TOKEN is not set." >&2; missing=1
fi
if [[ -z "${ORCA_PROJECT_KEY:-}" ]]; then
  echo "ERROR: ORCA_PROJECT_KEY is not set." >&2; missing=1
fi
if (( missing )); then
  echo "Refusing to run. Export both variables and retry." >&2
  exit 1
fi
if ! command -v orca-cli >/dev/null 2>&1; then
  echo "ERROR: orca-cli not found. See install steps at the top of this script." >&2
  exit 1
fi

IMAGE="${IMAGE:-orca-appsec-demo:local}"
# orca-cli picks the token up from ORCA_SECURITY_API_TOKEN; it is never echoed.
ORCA=(orca-cli -p "$ORCA_PROJECT_KEY" --exit-code 0 --labels local-scan)

run() {
  local title=$1; shift
  printf '\n\033[1m==== %s ====\033[0m\n$ %s\n' "$title" "$*"
  "$@" || echo "!! $title exited with $? (continuing)"
}

orca-cli --version

run "SAST"                 "${ORCA[@]}" sast scan --path .
run "SCA"                  "${ORCA[@]}" sca scan --path . --dependency-tree
run "Secrets (+history)"   "${ORCA[@]}" secrets scan --path .
run "IaC"                  "${ORCA[@]}" iac scan --path infra/

if docker image inspect "$IMAGE" >/dev/null 2>&1; then
  run "Container image"    "${ORCA[@]}" image scan "$IMAGE"
else
  echo; echo "Skipping image scan: $IMAGE not found locally. Run 'make build' first."
fi
