#!/usr/bin/env bash
# Orca Secret Detection pre-commit hook.
#
# Runs `orca-cli secrets pre-commit scan`, which scans the changes being
# committed and blocks the commit if a secret is found.
#
# The API token is NEVER stored in this file or in the repo. It is read from
# the environment (ORCA_SECURITY_API_TOKEN), e.g. exported from your shell
# profile or a secrets manager:
#   export ORCA_SECURITY_API_TOKEN="$(security find-generic-password -s orca-api-token -w)"   # macOS Keychain
#   export ORCA_SECURITY_PROJECT_KEY="<project-key>"
#
# Enable: see DEMO.md "Pre-commit hook" (make hook-install / pre-commit install).
# Bypass for a single commit (e.g. intentional demo secrets): git commit --no-verify
set -euo pipefail

if ! command -v orca-cli >/dev/null 2>&1; then
  echo "[orca pre-commit] orca-cli not found on PATH – skipping secret scan." >&2
  echo "[orca pre-commit] Install: brew install orcasecurity/orca-cli/orca-cli (see scripts/orca-local-scan.sh)" >&2
  exit 0
fi

# orca-cli reads both values from these env vars natively.
: "${ORCA_SECURITY_API_TOKEN:?[orca pre-commit] ORCA_SECURITY_API_TOKEN is not set}"
# Accept ORCA_PROJECT_KEY (used by the rest of this repo) as an alias.
export ORCA_SECURITY_PROJECT_KEY="${ORCA_SECURITY_PROJECT_KEY:-${ORCA_PROJECT_KEY:-}}"
: "${ORCA_SECURITY_PROJECT_KEY:?[orca pre-commit] ORCA_SECURITY_PROJECT_KEY (or ORCA_PROJECT_KEY) is not set}"

exec orca-cli secrets pre-commit scan --silent
