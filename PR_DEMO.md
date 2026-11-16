# PR Demo – Talk Track

Two prepared branches:

| Branch | Purpose | Merge? |
|--------|---------|--------|
| `feature/add-search` | Introduce NEW findings: inline comments, review summary, status checks, `/orca fix` | **No.** Close it after the demo (it conflicts with the fix branch) |
| `fix/remediate-findings` | Remediate the findings on `main` and show alerts closing after merge | **Yes**, at the end |

Prerequisites: `main` has been pushed and scanned at least once (DEMO.md A6), and the
Orca GitHub App has PR scanning enabled in **Warn** mode.

---

## Part 1 – `feature/add-search` (≈ 8 min)

**Open the PR:** base `main` ← compare `feature/add-search`, titled "Add user search endpoint".

> "A developer adds a search endpoint, the way they would on any Tuesday. Let's see what
> Orca says before anyone reviews it."

### 1. Status checks (bottom of the PR)
- The Orca GitHub App checks (SAST / SCA / IaC / Secrets) report **neutral or pass with warnings**,
  because policies are in Warn mode.
- The `Orca AppSec` workflow jobs pass too (`exit_code: "0"`).
- > "Nothing is blocked yet. We start in Warn so devs see value before we enforce anything."

### 2. Review summary
- The Orca bot's summary comment counts new findings per scan type and covers **only what this PR introduced**.
- > "This isn't 400 legacy findings. It's the 4 things this PR adds."

### 3. Inline comments (Files changed tab)

| File | Line | Finding |
|------|------|---------|
| `app/routes.py` | 71 | SAST – SQL injection (f-string `LIKE`) |
| `app/requirements.txt` | 23 | SCA – `requests==2.25.1` (CVE-2023-32681, CVE-2024-35195, CVE-2024-47081, CVE-2026-25645) |
| `config/settings.py` | 50–51 | Secrets – AWS access key pair |
| `infra/storage.tf` | 17 | IaC – S3 encryption disabled on the reports bucket |

### 4. AI fix in the PR
1. On the **SQL injection** inline comment, reply:
   ```
   /orca fix
   ```
   Orca replies with a suggested patch (a parameterized query).
2. Review the patch, then reply:
   ```
   /orca apply
   ```
   Orca commits the fix to `feature/add-search`. Show the new commit and the re-run checks.
3. Optional: repeat on the **IaC** comment (`encryption_enabled = false`).
   > "`/orca fix` and `/orca apply` work for **SAST and IaC** findings."

   For SCA the fix is a version bump, and for secrets the fix is rotate + remove, so there's no AI patch for those.

### 5. Where PR findings live in Orca
- **AppSec → Management → Scan Logs**: filter by repository `appsec-workshop-demo` and branch
  `feature/add-search`. Open the scan log and show the same findings.
- **Key point**:
  > "Orca creates **alerts only from the default branch** for SAST, IaC and vulnerabilities.
  > PR findings are in the PR and in Scan Logs, so they never pollute the alert backlog.
  > **Secrets are different.** They alert from **any branch or from history**, because once
  > a secret is pushed anywhere it's exposed."
- Show that the new AWS key from this PR **already has an alert** under AppSec → Code Security
  (Scan Type = Secrets), while the new SQLi doesn't.

### 6. Close the PR (don't merge)

---

## Part 2 – `fix/remediate-findings` (≈ 4 min + wait)

**Open the PR:** base `main` ← compare `fix/remediate-findings`, titled "Remediate Orca findings".

| Change | Closes |
|--------|--------|
| Parameterized query, no `shell=True`, safe path join, MD5 → scrypt, debug off | SAST #1–#6 |
| `yaml.safe_load`; PyYAML 5.3.1 → 6.0.3; PyJWT 1.7.1 → 2.15.1 | SAST #4, SCA #7, #8 |
| Secrets read from env (`config/settings.py`, `.env.example`, Dockerfile `ENV` removed) | Secrets #10–#16, #19 (in HEAD) |
| Dockerfile: `python:3.11-slim`, `COPY`, `USER 10001`, `HEALTHCHECK` | IaC #18, #20, #21 |
| `module.storage` → `encryption_enabled = true` | IaC #23 |

1. Show the Orca checks: the PR **resolves** findings and adds none.
2. **Merge** to `main`.
3. After the default-branch rescan (allow ~1 h for alert status to update):
   - AppSec → Code Security: SAST / SCA / IaC alerts above move to **Closed / Resolved**.
   - Secrets alerts **do not auto-close**. The values are still in history (they become
     `only_in_history`).
     > "Rotate first, then close manually."
4. To show the container side: `make build push-image` from `main`. Once the cloud rescan runs,
   the container asset no longer has reachable PyYAML.

Still open by design: the SG rules, the ECR settings and the IAM `s3:*` policy. Keep these
for the Warn → Block step and for later demos.
