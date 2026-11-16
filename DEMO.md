# Orca AppSec End-to-End Demo – Runbook

> Everything in this repo is **intentionally vulnerable** and every finding is
> marked `ORCA-DEMO:`. All credentials are **fake** (random values in the
> provider's format). Deploy only to a **sandbox** AWS account.

Covers: orca-cli (local + CI) · GitHub App PR scanning with `/orca fix` and `/orca apply` ·
GitHub Actions · SCA static reachability · Cloud-to-Dev (container → Dockerfile, AWS → Terraform) ·
Secret Detection including git history.

Companion doc: [PR_DEMO.md](PR_DEMO.md) (PR talk track).

---

## A. Manual prerequisites (do these by hand)

### A1. GitHub

1. Repo: `mohammedquadri-orca/appsec-workshop-demo` (already exists, **public**, empty).
2. **Push protection.** GitHub push protection will block the first push, because
   the history contains AWS, Slack and GitHub-PAT-format strings. Either:
   - Settings → Code security → Push protection → disable it for this repo, **or**
   - open the "unblock secret" URL GitHub prints for each blocked secret, choose
     "It's used in tests", then push again.

   GitHub's secret-scanning partner program may also notify AWS and Slack about
   the fake keys. That's harmless, because the keys aren't real.
3. Add a repo **secret** `ORCA_SECURITY_API_TOKEN` and a repo **variable**
   `ORCA_PROJECT_KEY` (Settings → Secrets and variables → Actions).
4. (Optional, for step B10) Branch protection on `main` that requires the
   `Orca AppSec` checks.

### A2. Orca

1. **API token.** Settings → Users & Permissions → API → create a token with the
   **Shift Left User** role. *(verify the exact menu path in your tenant)*
2. **Project key.** Shift Left → Projects → create a project (e.g. `orca-appsec-demo`)
   and copy its key. *(verify the menu path)* Its policies start in **Warn** mode.
3. **GitHub App.** Settings → Connections → Source code management → GitHub → install
   the Orca GitHub App on `appsec-workshop-demo` and enable **PR scanning** in
   **Warn** mode for SAST, SCA, IaC and Secrets. *(verify the menu path)*
4. **AWS.** Connect the sandbox AWS account (Settings → Cloud accounts → Add AWS).
5. **Scan configuration for Cloud-to-Dev.** In the AWS account's scan configuration:
   - select **"Scan Public and Private"**
   - enable **"Scan private buckets for Cloud to Dev"**
   - the state bucket is tagged `orca-cloud-to-dev=true`. If Orca doesn't auto-detect
     it, add the bucket manually.

### A3. Local tools

`orca-cli` ≥ 1.135, `terraform` ≥ 1.10, `docker` (Rancher Desktop must be **running**),
`aws` CLI logged in to the **sandbox** account.

```bash
brew install orcasecurity/orca-cli/orca-cli      # macOS
# Linux: curl -sfL https://raw.githubusercontent.com/orcasecurity/orca-cli/main/install.sh | sh -s -- -b ~/.local/bin
```

### A4. Pre-commit hook (Secret Detection – Git Hooks)

orca-cli ships a native hook: `orca-cli secrets pre-commit scan` (and `install [--global]`).

> ⚠️ `orca-cli secrets pre-commit install` appears to generate a hook script that
> contains `export ORCA_SECURITY_API_TOKEN='<token>'` in plaintext *(verify)*. Prefer
> the wrapper in this repo, which reads the token from your environment.

This repo sets `git config core.hooksPath .git/hooks` locally, so a global
hooks path (`~/.git/hooks`) doesn't fire here. Enable the Orca hook with **one** of:

```bash
# Option 1 – plain git hook (works even when core.hooksPath is set)
make hook-install                 # symlinks scripts/pre-commit-orca-secrets.sh -> .git/hooks/pre-commit

# Option 2 – pre-commit framework (refuses to install if core.hooksPath is set anywhere)
pip install pre-commit && pre-commit install

# Both need:
export ORCA_SECURITY_API_TOKEN=...      # e.g. from Keychain: security find-generic-password -s orca-api-token -w
export ORCA_PROJECT_KEY=...
```

Demo it: add a fake key to any file, `git add`, `git commit`, and the commit is blocked.
Bypass a single commit with `git commit --no-verify`. Remove the hook with `make hook-uninstall`.

### A5. Deploy the sandbox (≈ $1/day; run `make destroy` afterwards)

```bash
export AWS_PROFILE=<sandbox-profile>
make bootstrap OWNER=<you>         # state bucket tagged orca-cloud-to-dev=true -> writes infra/backend.hcl
make apply     OWNER=<you>         # VPC (private only), ECR, EC2 (no public IP), buckets
make build                         # docker build --platform linux/amd64 -t orca-appsec-demo:local
make push-image                    # pushes to ECR as :v1; the instance pulls it within ~30s
```

The EC2 instance runs the container through a systemd unit that retries every 30 s,
so the order of `apply` and `push-image` doesn't matter.

**Start this at least 24 h before the demo.** Orca's cloud scan, the repo scan and
Cloud-to-Dev matching all need to complete (see D).

### A6. Seed the default branch

```bash
git push -u origin main            # after you approve; see "push protection" above
git push origin feature/add-search fix/remediate-findings
```

Then run **Actions → Orca AppSec → Run workflow** on `main` once, so the baseline
scan logs and SARIF exist.

---

## B. Demo flow (~30 min)

| # | Min | What | Where |
|---|-----|------|-------|
| 1 | 2 | IDE scan | VS Code |
| 2 | 3 | Local CLI | Terminal |
| 3 | 5 | PR scan | GitHub PR |
| 4 | 4 | AI fix | GitHub PR + Orca |
| 5 | 2 | GitHub Actions + SARIF | GitHub |
| 6 | 3 | Code Security inventory + Triage Agent | Orca |
| 7 | 4 | Reachability | Orca |
| 8 | 4 | Cloud-to-Dev | Orca |
| 9 | 2 | Secrets history | Orca |
| 10 | 1 | Warn → Block | Orca + GitHub |

### 1. IDE – VS Code Orca extension
- Open `app/routes.py` with the Orca extension signed in.
- Show inline findings: SQLi (line 20), command injection (30), path traversal (38),
  `yaml.load` (49), MD5 (58), and debug mode in `app/main.py:34`.
- Open `app/clean/safe_patterns.py` and show that it's clean ("what good looks like").

### 2. Local CLI
```bash
export ORCA_SECURITY_API_TOKEN=...  ORCA_PROJECT_KEY=...
make build && ./scripts/orca-local-scan.sh
```
- Talk track: the same engine as CI. The scans run with `--exit-code 0`, so they warn and never block.
- Point out that SCA flags PyYAML, PyJWT and the GPL Unidecode, and that Secrets flags the
  removed Slack token from history.
- Show the scan log in **Orca → AppSec → Management → Scan Logs** (label `local-scan`).

### 3. PR scan – `feature/add-search`
- Open the PR (see [PR_DEMO.md](PR_DEMO.md)) and walk through:
  - **Inline comments** on the new SQLi (`app/routes.py:71`), `requests==2.25.1`,
    the new AWS key (`config/settings.py:50`), and `encryption_enabled = false` (`infra/storage.tf:17`).
  - The **review summary** comment from the Orca bot.
  - **Status checks**: Orca's App checks plus the `Orca AppSec` workflow jobs.

### 4. AI fix
- In the PR, reply **`/orca fix`** on the SQLi comment. Orca proposes a patch.
- Reply **`/orca apply`**. Orca commits the fix to the PR branch.
- In Orca: **AppSec → Code Security** → open a SAST alert (from `main`) → **Remediation**
  → **Code Fix** → **Open Fix PR**.

### 5. GitHub Actions + SARIF
- **Actions → Orca AppSec**: five jobs, all green (warn-only), with annotations on the run.
- **Security → Code scanning** (category `orca-sast`): Orca SAST results via SARIF.
- Mention `orca-cli-manual.yml` as the path for Jenkins, CircleCI and GitLab customers.

### 6. Code Security inventory
- **AppSec → Code Security**: filter **Scan Type** = SAST / SCA / IaC / Secrets.
- **Group by** repository → file.
- On SAST findings, show the **AppSec Triage Agent** verdict column (true/false
  positive and its reasoning).

### 7. Reachability
- **Alerts → Orca Views → Vulnerabilities → "Alerts with Reachable Packages"**.
- Filter on asset `orca-appsec-demo` (the container on the EC2 instance).
- **Installed Packages** tab of the container asset:
  - `PyYAML 5.3.1`, **reachable**: CVE-2020-14343. The Reachability Evidence column
    points to `app/routes.py` → `yaml.load`.
  - `PyJWT 1.7.1`, **not reachable**: CVE-2022-29217 and others. It's installed, but
    nothing imports it.
- Talk track: same severity, but a very different priority. Static reachability runs
  on the container asset, starting from the entry point (`python -m app.main`).

### 8. Cloud-to-Dev
- **Container**: Inventory → the running container (or the ECR image `orca-appsec-demo:v1`)
  → **Code Origin**: Dockerfile in this repo, plus repo owners and committers.
  Matching uses the image history: the unique `RUN … orca-c2d-7f3a9c41` marker and the labels.
- **S3**: Inventory → bucket `orca-appsec-demo-data-*` → Code Origin → Terraform resource
  `module.storage.aws_s3_bucket.this` → **module chain** `infra/storage.tf` → `infra/modules/storage/main.tf`.
- Open an IaC alert on that bucket (no encryption, versioning or logging) and show
  that it links back to the exact Terraform line.

### 9. Secrets history
- **AppSec → Code Security**, Scan Type = Secrets. Find the Slack token in `scripts/notify.sh`.
  It's gone from `HEAD` (commit `1929340`) but still in commit `88b1b38`.
- It carries the label **`shiftleft:secret_detection:only_in_history`**.
- Talk track: **rotate first, then close manually.** Removing the secret from HEAD doesn't
  remove the risk. Auto-closure after a history rewrite (`git filter-repo`) is inconsistent
  today, so close it manually once it's rotated.

### 10. Shift left: Warn → Block
- In Orca: **Shift Left → Projects → orca-appsec-demo → Policies** (or the GitHub App
  PR-scan settings). Switch e.g. the Secrets policy from **Warn** to **Block**. *(verify the menu path)*
- Re-run the checks on the `feature/add-search` PR. The Orca check now **fails**.
- For the Actions jobs, also change `exit_code: "0"` → `"3"` (see the header of `orca-appsec.yml`).

---

## C. Expected findings

Line numbers are on `main` unless the Branch column says otherwise.

| # | File:line | Scan | Expected Orca finding | Where |
|---|-----------|------|-----------------------|-------|
| 1 | app/routes.py:20 | SAST | SQL injection (string-formatted SQL) | Alert, Scan Logs, SARIF |
| 2 | app/routes.py:30 | SAST | OS command injection (`subprocess` `shell=True`) | Alert, Scan Logs, SARIF |
| 3 | app/routes.py:38 | SAST | Path traversal (`open()` on user input) | Alert, Scan Logs, SARIF |
| 4 | app/routes.py:49 | SAST | Insecure deserialization (`yaml.load` without SafeLoader) | Alert, Scan Logs, SARIF |
| 5 | app/routes.py:58 | SAST | Weak hash (MD5) | Alert, Scan Logs, SARIF |
| 6 | app/main.py:34 | SAST | Flask `debug=True` | Alert, Scan Logs, SARIF |
| 7 | app/requirements.txt:12 | SCA | PyYAML 5.3.1 – CVE-2020-14343 (**reachable** in container) | Alert, Scan Logs |
| 8 | app/requirements.txt:16 | SCA | PyJWT 1.7.1 – CVE-2022-29217, CVE-2026-32597, CVE-2026-48522/48524/48526, CVE-2026-101917, CVE-2026-102267..102270, CVE-2025-45768 (disputed), GHSA-pxh4-856f-4h89 (**unreachable**) | Alert, Scan Logs |
| 9 | app/requirements.txt:19 | SCA license | Unidecode 1.4.0 – GPLv2+ (copyleft) | Scan Logs (license policy) |
| 10 | config/settings.py:11-12 | Secrets | AWS access key ID + secret key | Alert (any branch), Scan Logs |
| 11 | config/settings.py:16 | Secrets | GitHub PAT (`ghp_`) | Alert, Scan Logs |
| 12 | config/settings.py:20 | Secrets | RSA private key | Alert, Scan Logs |
| 13 | .env.example:9-10 | Secrets | AWS key pair | Alert, Scan Logs |
| 14 | .env.example:13 | Secrets | GitHub PAT | Alert, Scan Logs |
| 15 | .env.example:16 | Secrets | Slack bot token | Alert, Scan Logs |
| 16 | .env.example:19 | Secrets | Password in connection string | Alert, Scan Logs |
| 17 | scripts/notify.sh:8 @ `88b1b38` | Secrets | Slack bot token, label `only_in_history` | Alert (history scan) |
| 18 | Dockerfile:9 | IaC (Dockerfile) | Base image uses `latest` tag | Alert, Scan Logs |
| 19 | Dockerfile:26-27 | Secrets / Image | AWS keys in `ENV` (also in image layers) | Alert, image scan |
| 20 | Dockerfile:32, 40 | IaC (Dockerfile) | `ADD` instead of `COPY` | Alert, Scan Logs |
| 21 | Dockerfile (whole file) | IaC (Dockerfile) | No `USER` (runs as root), no `HEALTHCHECK` | Alert, Scan Logs |
| 22 | image `orca-appsec-demo` | Container image | OS + Python package CVEs in `python:latest` and PyYAML/PyJWT | Scan Logs (CI), Alert (ECR/runtime) |
| 23 | infra/storage.tf:9 → modules/storage/main.tf:20 | IaC | S3 bucket without SSE configuration | Alert, Scan Logs |
| 24 | infra/modules/storage/main.tf:6 | IaC | S3 bucket without versioning / access logging | Alert, Scan Logs |
| 25 | infra/network.tf:82 | IaC | SG ingress from wide CIDR 10.0.0.0/8 | Alert, Scan Logs |
| 26 | infra/network.tf:91 | IaC | SG unrestricted egress 0.0.0.0/0 | Alert, Scan Logs |
| 27 | infra/ecr.tf:5 | IaC | ECR tag mutability `MUTABLE` | Alert, Scan Logs |
| 28 | infra/ecr.tf:9 | IaC | ECR `scan_on_push = false` | Alert, Scan Logs |
| 29 | infra/iam.tf:31 | IaC | IAM policy with `s3:*` | Alert, Scan Logs |
| P1 | app/routes.py:71 (`feature/add-search`) | SAST | NEW SQL injection | PR comment, Scan Logs |
| P2 | app/requirements.txt:23 (`feature/add-search`) | SCA | requests 2.25.1 – CVE-2023-32681, CVE-2024-35195, CVE-2024-47081, CVE-2026-25645 | PR comment, Scan Logs |
| P3 | config/settings.py:50-51 (`feature/add-search`) | Secrets | NEW AWS key pair | PR comment, **Alert** (secrets alert from any branch) |
| P4 | infra/storage.tf:17 (`feature/add-search`) | IaC | Reports bucket encryption disabled | PR comment, Scan Logs |

**CVE verification.** Checked with `pip-audit` (OSV + PyPI sources) and api.osv.dev on 2026-11-16.
The rest of the web stack (Flask 3.1.3, Werkzeug 3.1.9, Jinja2 3.1.6, …) had no known vulnerabilities on that date.

The cloud side also has runtime posture alerts on the same resources (S3, SG, ECR, IAM).
Those are what Cloud-to-Dev links back to the Terraform lines above.

---

## D. Known caveats (say these out loud)

- **Alert lag.** Alert status can trail scans by about **1 hour**.
- **Git-history secret scan cadence.** The history scan runs on a **slower cadence**.
  Trigger a manual repo rescan from the Orca UI to refresh it before the demo.
- **Static reachability** applies to **container assets running in the cloud** (here, the
  container on EC2), **not** to repo-only scans.
- **Non-default-branch PRs.** PR checks on PRs that target a branch other than `main` aren't
  natively supported. The workaround is the CLI (`orca-cli-manual.yml` pattern) plus a required status check.
- **Cloud-to-Dev** needs **both** the cloud scan and the repo scan to complete. Allow up to 24 h
  after the first `make apply`.
- **Default-branch alerting.** SAST, IaC and vulnerability alerts are created **only from the default
  branch**. PR and feature-branch findings live in Scan Logs and PR comments. **Secrets alert from any
  branch and from history.**
- **S3 "unencrypted" is code-only.** AWS applies SSE-S3 to every new bucket by default, so the IaC
  finding (missing encryption config) fires but a cloud-side "bucket not encrypted" alert may not.
- **`python:latest`** currently resolves to Python 3.14 (the app targets 3.11+). That drift is exactly
  what finding #18 warns about. The fix branch pins `python:3.11-slim`.

---

## E. Teardown

```bash
make destroy OWNER=<you>            # main stack; the ECR repo is force_delete=true, so its images go with it
# If you pushed images outside Terraform, delete them first:
#   aws ecr batch-delete-image --repository-name orca-appsec-demo --image-ids "$(aws ecr list-images --repository-name orca-appsec-demo --query 'imageIds[*]' --output json)"
make destroy-bootstrap OWNER=<you>  # state bucket – LAST
```

Also: remove the Orca GitHub App from the repo if needed, delete the demo project key,
and revoke the API token you created for the demo.

---

## Verify list (things I couldn't confirm from code or `--help`)

| Item | Status |
|------|--------|
| Orca UI menu paths marked *(verify)* above | From the brief; I didn't check them against a live tenant |
| `orca-cli secrets pre-commit scan` scans only staged changes | Inferred from the name and help text. Orca's "Git Hooks" docs page needs a login |
| `orca-cli secrets pre-commit install` embeds the token in the hook | Seen in an existing generated hook; not re-run here |
| IaC action tag `v.1.5.12` | Real tag name (with the dot); it's what `v1` points to. The `v1.7.0` tag is a stale 2022 tag with fewer inputs |
| SCA action `v1.0.0` | The only release; `v1` points to it |
| Container image action reading the local Docker daemon | Per the README example (Docker container actions get the runner's docker socket). Fallback: `docker save` + `tar_archive: "true"` |
| `docker build` of both Dockerfiles | **Not run.** The Docker daemon was down while building this repo. PyYAML 5.3.1 was confirmed to build from source on Python 3.14 |
| Orca Triage Agent / "Alerts with Reachable Packages" view names | From the brief |
