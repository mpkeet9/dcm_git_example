# Production Snowflake DCM Project (Snowsight-First, Manual Prod)

This repository is a working reference implementation for a production-style Snowflake DCM project where:

- `DEV`, `STAGE`, and `PROD` run in the **same Snowflake account**
- each environment is isolated by **separate database/schema tiers**
- collaboration is **Git-first** with a shared Snowsight Workspace
- production deployment is **manual-only** through GitHub Environment approval
- Modifications are tracked

Reference: [Get Started with Snowflake DCM Projects](https://www.snowflake.com/en/developers/guides/get-started-snowflake-dcm-projects/)

## Repository Layout

```text
.
├── manifest.yml
├── sources/
│   ├── definitions/
│   │   ├── 00_platform_foundation.sql
│   │   ├── 10_data_objects.sql
│   │   └── 20_grants.sql
│   └── macros/
│       └── naming.sql
├── docs/
│   └── runbooks/
│       ├── snowflake-rbac-bootstrap.sql
│       ├── snowsight-operations.md
│       └── dcm-deploy-rollback.md
└── .github/workflows/
    ├── dcm-pr-validate.yml
    ├── dcm-main-stage-deploy.yml
    └── dcm-prod-manual-deploy.yml
```

## Operating Model

- **Primary workspace:** Snowsight Workspace connected to this Git repository
- **Source of truth:** `manifest.yml` + `sources/**`
- **Promotion path:** feature branch -> PR -> merge to `main` -> auto deploy `STAGE` -> manual deploy `PROD`
- **Safety rule:** always run `PLAN` before `DEPLOY`
- **Production rule:** only manual workflow can deploy `PROD`

## 1) Configure `manifest.yml`

This repo already includes a production-oriented manifest:

- targets: `DEV`, `STAGE`, `PROD`
- same `account_identifier` for all targets
- unique `project_name` and `project_owner` per target
- `default_target: DEV` to minimize accidental production commands

Update placeholder values in `manifest.yml`:

- `account_identifier`
- control-plane project names if needed
- role names and object names under `templating.configurations`

## 2) Bootstrap Snowflake RBAC and DCM project objects

Run:

```sql
-- docs/runbooks/snowflake-rbac-bootstrap.sql
```

This script:

- creates control-plane databases/schemas for each target
- creates deploy/read/monitor roles per environment
- grants `CREATE DCM PROJECT ON SCHEMA` for deploy roles
- creates the three DCM project objects
- grants `READ`/`MONITOR` on DCM projects

Then replace service user placeholders (`SVC_GITHUB_STAGE`, `SVC_GITHUB_PROD`) with your real users.

## 3) Connect Snowsight Workspace (primary collaboration path)

1. Create Snowsight Workspace from this repository.
2. Work in feature branch for all definition changes.
3. Edit files under `sources/definitions/` and `sources/macros/`.
4. Run `PLAN` in `DEV` and review output.
5. Deploy `DEV` when plan is approved.
6. Commit and push; open PR to `main`.

Detailed operations: `docs/runbooks/snowsight-operations.md`.

## 4) GitHub Actions setup (ready to run)

### Workflows

- `dcm-pr-validate.yml`
  - Trigger: pull request to `main`
  - Runs `connection-test` + `plan` for `DEV` and `STAGE`
- `dcm-main-stage-deploy.yml`
  - Trigger: push to `main`
  - Runs `connection-test` + `plan` + `deploy` for `STAGE`
- `dcm-prod-manual-deploy.yml`
  - Trigger: manual `workflow_dispatch`
  - Runs `connection-test` + `plan` + `deploy` for `PROD`

### Required GitHub environments

Create environments matching target names exactly:

- `DEV`
- `STAGE`
- `PROD`

Configure `PROD` environment protections:

- required reviewers enabled
- prevent self-approval (recommended)

### Required repository or environment variables

Define:

- `SNOWFLAKE_USER_NONPROD`
- `SNOWFLAKE_USER_STAGE`
- `SNOWFLAKE_USER_PROD`

The workflows use OIDC through Snowflake CLI action internally (via Snowflake Labs DCM actions), so no password/private key secrets are required for the default path.

## 5) Snowflake OIDC service users

Create service users with environment-scoped OIDC subject claims:

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

Grant each user the deploy role defined by that target's `project_owner`:

```sql
GRANT ROLE DCM_STAGE_DEPLOYER TO USER SVC_GITHUB_STAGE;
GRANT ROLE DCM_PROD_DEPLOYER TO USER SVC_GITHUB_PROD;
```

## 6) Local CLI fallback commands

If needed outside Snowsight:

```bash
snow dcm plan --target DEV
snow dcm deploy --target DEV

snow dcm plan --target STAGE
snow dcm deploy --target STAGE

snow dcm plan --target PROD
snow dcm deploy --target PROD
```

Use explicit targets for all non-DEV operations.

## 7) Rollback strategy

Rollback is Git-based:

1. Revert bad commit/merge in Git.
2. Merge revert PR.
3. Re-run plan/deploy for affected environment.
4. For production, use manual `dcm-prod-manual-deploy.yml`.

Detailed steps: `docs/runbooks/dcm-deploy-rollback.md`.

## 8) Guardrails for this model

- Keep one DCM project object per environment target.
- Avoid ownership transfers to roles not inherited by project owner role.
- Disable secondary role leakage for SQL-run execution:
  - `USE SECONDARY ROLES NONE;`
- Keep `default_target` on `DEV`.
- Keep `allow-drops: "false"` unless a drop is intentional and approved.

## 9) Quick start checklist

- [ ] Updated `manifest.yml` placeholders
- [ ] Executed `docs/runbooks/snowflake-rbac-bootstrap.sql`
- [ ] Created GitHub environments `DEV`, `STAGE`, `PROD`
- [ ] Configured `PROD` required reviewers
- [ ] Added workflow variables for Snowflake users
- [ ] Configured OIDC service users and grants
- [ ] Validated PR plan workflow
- [ ] Validated auto `STAGE` deploy on merge
- [ ] Validated manual `PROD` deployment path
# Production DCM Project Setup (Git + Snowflake)

This repository demonstrates how to run a production-grade Snowflake DCM (Declarative Change Management) project with:

- collaborative Git-based development
- environment promotion (`DEV` -> `STAGE` -> `PROD`)
- execution in a shared Snowflake workspace and/or local CLI

Reference guide: [Snowflake - Get Started with DCM Projects](https://www.snowflake.com/en/developers/guides/get-started-snowflake-dcm-projects/)

## Project Goal

Use one version-controlled DCM codebase to define Snowflake objects once and deploy safely across multiple environments with a predictable, auditable plan/deploy workflow.

## Production Architecture

- **Source of truth:** Git repository containing `manifest.yml` and SQL definitions under `sources/definitions/`
- **Execution runtimes:** Snowflake Workspaces (Git-integrated) and Snowflake CLI (local or CI)
- **Environment mapping:** separate DCM target entries for `DEV`, `STAGE`, and `PROD`
- **Deployment model:** always run `PLAN` before `DEPLOY`
- **Promotion model:** PR merge to main triggers non-prod validation, then controlled stage/prod deployment

Snowflake recommends strong environment separation for production (often separate accounts per environment).

## Prerequisites

1. Snowflake account(s) for target environments (`DEV`, `STAGE`, `PROD`)
2. Snowflake roles with DCM privileges, including:
   - `CREATE DCM PROJECT ON SCHEMA`
   - ownership/execute permissions needed to run DCM project `PLAN` and `DEPLOY`
3. Snowflake CLI installed and authenticated
4. Git repository and branch protection configured
5. Shared Snowflake Workspace connected to the same Git repository (recommended for team visibility)

Example privilege bootstrap:

```sql
GRANT CREATE DCM PROJECT ON SCHEMA <schema_name> TO ROLE <role_name>;
```

## Step 1: Initialize the DCM Project

Initialize from Snowflake's DCM template:

```bash
snow init <project_name> --template DCM_PROJECT
cd <project_name>
```

Expected structure (minimum):

```text
<project_name>/
  manifest.yml
  sources/
    definitions/
      <objects>.sql
  out/
```

Notes:
- Keep deployable definitions under `sources/`
- Add `out/` to `.gitignore` to avoid committing generated artifacts

## Step 2: Define Targets in `manifest.yml`

Configure targets so each environment points to its own account/project/owner role. Keep this in Git so every deploy path is explicit and reviewable.

Minimum shape:

```yaml
manifest_version: 2
type: DCM_PROJECT
default_target: DEV

targets:
  DEV:
    account: <dev_account_identifier>
    project: <db>.<schema>.<dcm_project_name_dev>
    role: <dcm_owner_role_dev>
    templating_config: DEV
  STAGE:
    account: <stage_account_identifier>
    project: <db>.<schema>.<dcm_project_name_stage>
    role: <dcm_owner_role_stage>
    templating_config: STAGE
  PROD:
    account: <prod_account_identifier>
    project: <db>.<schema>.<dcm_project_name_prod>
    role: <dcm_owner_role_prod>
    templating_config: PROD

templating:
  configurations:
    DEV: {}
    STAGE: {}
    PROD: {}
```

## Step 3: Create DCM Project Objects in Snowflake

Create project objects per target before first deploy.

CLI examples:

```bash
snow dcm create <my_project> --if-not-exists
snow dcm create --target DEV
snow dcm create --target STAGE
snow dcm create --target PROD
```

SQL alternative:

```sql
CREATE DCM PROJECT IF NOT EXISTS <my_project>;
```

## Step 4: Team Git Collaboration Workflow

Use a PR-first workflow to keep environments stable and auditable.

1. Create a feature branch from `main`
2. Edit `manifest.yml` and SQL in `sources/definitions/`
3. Run `PLAN` locally or in Workspace for target environment(s)
4. Open PR with plan output attached
5. Require review + CI checks before merge
6. Merge to `main` and promote through environments

Recommended branch policies:

- Require PR approvals
- Require CI success
- Prevent direct pushes to `main`
- Tag releases used for production deploy windows

## Step 5: Plan/Deploy by Environment

### Developer validation (`DEV`)

```bash
snow dcm plan --target DEV
snow dcm deploy --target DEV
```

### Pre-production validation (`STAGE`)

```bash
snow dcm plan --target STAGE
snow dcm deploy --target STAGE
```

### Controlled production release (`PROD`)

```bash
snow dcm plan --target PROD
snow dcm deploy --target PROD
```

SQL execution pattern (for workspace/stage-based execution):

```sql
EXECUTE DCM PROJECT <dcm_project_name>
  PLAN
  USING CONFIGURATION DEV
FROM
  '<path_to_project_with_manifest>';
```

## Shared Workspace + Git Integration Pattern

For collaborative execution in Snowflake:

1. Create Snowflake Workspace from the Git repository
2. Select branch in Workspace (same branch as PR work)
3. Run DCM plan/deploy from the checked-out project path
4. Commit/push changes and open PR from the shared workflow

This gives teams one visible, git-integrated control plane while still supporting local CLI and CI/CD automation.

## CI/CD Recommendation (Production Baseline)

Implement a pipeline with three stages:

1. **PR checks**: run `PLAN` against non-prod targets and fail on errors
2. **Merge to main**: deploy to `STAGE` after approvals
3. **Release gate**: manual approval then deploy to `PROD`

Snowflake Labs provides reusable actions and workflow patterns for DCM projects:
[Snowflake Labs DCM repository](https://github.com/Snowflake-Labs/snowflake-dcm-projects)

## Security and Governance Recommendations

- Use dedicated DCM owner roles per environment
- Use dedicated service users for CI/CD execution
- Avoid relying on secondary roles during deploy
- Keep ownership and grant changes explicit in definitions
- Log and retain deployment history for audits
- Use least privilege for readers/monitors vs deployers

## Operational Checklist

- [ ] `manifest.yml` includes all target mappings
- [ ] `sources/definitions/` is the only deployable source path
- [ ] `PLAN` output reviewed for every environment before deploy
- [ ] PR approvals required before promotion
- [ ] Production deployments gated with explicit approval
- [ ] Rollback strategy documented (revert commit + re-plan/re-deploy)

## Open Questions to Finalize This for Your Org

To make this fully directionally correct for your implementation, please confirm:

1. Should `DEV`, `STAGE`, and `PROD` be separate Snowflake accounts, or separate databases/schemas in one account?
2. Do you want production deploys to be manual-only, or automated after approval?
3. Do you want this README to include concrete naming conventions for roles, warehouses, databases, and DCM project objects?
4. Should we include a ready-to-run GitHub Actions workflow in this repo next?
5. Are you standardizing on Snowsight Workspaces, local CLI, or both as primary developer experience?
