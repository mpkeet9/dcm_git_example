# Build Guide: Production DCM Project (Snowsight-First, Manual Prod)

This guide walks through implementing and operating this repository as a production-style Snowflake DCM project.

## Step 0: Prerequisites

Before setup, confirm:

- Snowflake account has DCM Projects enabled.
- You can run SQL as a role that can create roles, databases, schemas, and users.
- You have a GitHub repository with Actions enabled.
- Snowflake CLI is installed locally (optional but recommended for validation).

## Step 1: Clone and inspect the repository

```bash
git clone <your_repo_url>
cd dcm_git_example
```

Verify these key files exist:

- `manifest.yml`
- `sources/definitions/*.sql`
- `docs/runbooks/snowflake-rbac-bootstrap.sql`
- `.github/workflows/dcm-pr-validate.yml`
- `.github/workflows/dcm-main-stage-deploy.yml`
- `.github/workflows/dcm-prod-manual-deploy.yml`

## Step 2: Configure `manifest.yml`

Open `manifest.yml` and update placeholders:

- `targets.*.account_identifier` (same account across DEV/STAGE/PROD)
- `targets.*.project_name` (unique DCM project object per environment)
- `targets.*.project_owner` (unique deploy role per environment)
- values in `templating.configurations` (DB/schema/warehouse/role names)

Important:

- Keep `default_target: DEV`.
- Keep one DCM project object per target (`DEV`, `STAGE`, `PROD`).

## Step 3: Bootstrap Snowflake RBAC and DCM control plane

Run `docs/runbooks/snowflake-rbac-bootstrap.sql` in Snowflake.

This script:

- creates control-plane DB/schema for each environment
- creates deploy/reader/monitor roles
- grants `CREATE DCM PROJECT ON SCHEMA`
- creates DCM project objects per environment
- grants `READ`/`MONITOR` privileges

After running, replace sample service-user grants with your real usernames.

## Step 4: Configure OIDC service users in Snowflake

Create service users for GitHub Actions (at least STAGE and PROD) with workload identity:

```sql
CREATE USER SVC_GITHUB_STAGE
  TYPE = SERVICE
  WORKLOAD_IDENTITY = (
    TYPE = OIDC
    ISSUER = 'https://token.actions.githubusercontent.com'
    SUBJECT = 'repo:<owner>/<repo>:environment:STAGE'
  );

CREATE USER SVC_GITHUB_PROD
  TYPE = SERVICE
  WORKLOAD_IDENTITY = (
    TYPE = OIDC
    ISSUER = 'https://token.actions.githubusercontent.com'
    SUBJECT = 'repo:<owner>/<repo>:environment:PROD'
  );
```

Grant roles:

```sql
GRANT ROLE DCM_STAGE_DEPLOYER TO USER SVC_GITHUB_STAGE;
GRANT ROLE DCM_PROD_DEPLOYER TO USER SVC_GITHUB_PROD;
```

## Step 5: Configure GitHub Environments

In GitHub repo settings, create environments:

- `DEV`
- `STAGE`
- `PROD`

For `PROD`, enforce manual control:

- required reviewers enabled
- prevent self-review (recommended)

## Step 6: Configure GitHub Variables

Add repository (or environment-level) variables:

- `SNOWFLAKE_USER_NONPROD`
- `SNOWFLAKE_USER_STAGE`
- `SNOWFLAKE_USER_PROD`

These are referenced directly by the workflow files.

## Step 7: Confirm workflow permissions

In GitHub Actions settings:

- allow `id-token: write` and `contents: read`
- allow PR comments if you want plan output posted in PRs

The included workflows already set job-level permissions.

## Step 8: Run first local validation (optional, recommended)

```bash
snow dcm plan --target DEV
snow dcm plan --target STAGE
snow dcm plan --target PROD
```

If plan fails:

- re-check role grants from bootstrap SQL
- confirm target names match `manifest.yml`
- verify project path is repo root (`./`)

## Step 9: Snowsight-first developer workflow

1. Create a Snowsight Workspace from this Git repo.
2. Create a feature branch.
3. Edit `sources/definitions/` and/or `sources/macros/`.
4. Run `PLAN` in `DEV`.
5. Run `DEPLOY` in `DEV` when plan is clean.
6. Commit and push branch.
7. Open PR to `main`.

## Step 10: CI/CD promotion flow

### PR validation

- Workflow: `.github/workflows/dcm-pr-validate.yml`
- Trigger: PR to `main`
- Action: connection test + plan for `DEV` and `STAGE`

### Auto stage deployment

- Workflow: `.github/workflows/dcm-main-stage-deploy.yml`
- Trigger: merge/push to `main`
- Action: plan + deploy `STAGE`

### Manual production deployment

- Workflow: `.github/workflows/dcm-prod-manual-deploy.yml`
- Trigger: manual dispatch only
- Action: plan + deploy `PROD` after environment approval

## Step 11: Production release checklist

Before triggering PROD workflow:

- STAGE deploy succeeded on the same commit
- plan output reviewed for unexpected drops
- approvals complete for PROD environment
- release/ref selected explicitly in workflow dispatch

## Step 12: Rollback procedure

Use Git revert + redeploy:

1. Revert the bad commit/merge commit.
2. Open and merge revert PR.
3. STAGE redeploy happens on merge.
4. Trigger manual PROD deploy on the revert ref.

Detailed rollback runbook: `docs/runbooks/dcm-deploy-rollback.md`.

## Definition of done

Implementation is complete when:

- `manifest.yml` is configured with real account/object/role names
- bootstrap SQL has run successfully
- GitHub environments and variables are configured
- PR validation workflow passes
- main-to-STAGE deploy succeeds
- manual PROD deploy succeeds with reviewer approval
