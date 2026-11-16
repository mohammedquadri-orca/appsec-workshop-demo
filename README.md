# Orca AppSec end-to-end demo

> ⚠️ **Intentionally vulnerable.** Every vulnerability is marked `ORCA-DEMO:`.
> All credentials are **fake** (random, non-functional values in the provider's format).
> Deploy only to a sandbox AWS account.

A small Flask app, its Dockerfile, and its AWS Terraform, built to demo Orca Security AppSec end to end:

- **orca-cli**: locally (`scripts/orca-local-scan.sh`) and as raw CI commands (`.github/workflows/orca-cli-manual.yml`)
- **GitHub App PR scanning**: inline comments, `/orca fix`, `/orca apply`
- **GitHub Actions**: `orca-appsec.yml` (SAST with SARIF, SCA, IaC, Secrets, Image)
- **SCA static reachability**: PyYAML (reachable) vs PyJWT (unreachable)
- **Cloud-to-Dev**: container → Dockerfile, S3 bucket → Terraform module chain
- **Secret Detection**: including a secret that exists only in git history

| Doc | What |
|-----|------|
| [DEMO.md](DEMO.md) | Runbook: prerequisites, 30-min flow, expected findings, caveats, teardown |
| [PR_DEMO.md](PR_DEMO.md) | PR talk track |

```text
app/                  Flask app (vulnerable routes) + app/clean (secure patterns)
config/, .env.example Fake hardcoded secrets
scripts/              notify.sh (secret in history), orca-local-scan.sh, pre-commit hook
Dockerfile            Best-practice violations + Cloud-to-Dev markers
infra/                Terraform: private EC2 + ECR, storage module, misconfigs
infra/bootstrap/      State bucket tagged orca-cloud-to-dev=true
.github/workflows/    Orca actions (warn-only) + raw orca-cli
```

Quick start: `make help`
