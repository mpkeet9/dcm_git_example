# Snowsight Operations Runbook

This runbook is the primary day-to-day operating model for DCM in this repository.

## 1) Workspace setup

1. In Snowsight, create a Workspace from this Git repository.
2. Select the branch for your change (feature branch for development, `main` for controlled promotion).
3. Confirm the workspace folder root contains `manifest.yml`.

## 2) Development workflow (`DEV`)

1. Make SQL/template changes in `sources/definitions/` and `sources/macros/`.
2. Run **Plan** with target `DEV`.
3. Review change summary and confirm there are no unintended drops.
4. Run **Deploy** to `DEV`.
5. Commit and push through Git from the workspace.

## 3) Promotion workflow (`STAGE`)

1. Open PR to `main` and wait for CI plan validation.
2. After merge, GitHub Actions deploys to `STAGE` automatically.
3. In Snowsight, inspect deployment history on `DCM_CONTROL_STAGE.ADMIN.DCM_GIT_EXAMPLE_STAGE`.

## 4) Production workflow (`PROD`, manual-only)

1. Confirm `STAGE` validations are complete.
2. Trigger the manual GitHub workflow: `dcm-prod-manual-deploy.yml`.
3. Approve deployment in GitHub environment `PROD`.
4. Validate deployment in Snowsight history for `DCM_CONTROL_PROD.ADMIN.DCM_GIT_EXAMPLE_PROD`.

## 5) Deterministic command equivalents (worksheet)

Always disable secondary roles before DCM execution:

```sql
USE SECONDARY ROLES NONE;
```

Example `STAGE` plan/deploy:

```sql
USE ROLE DCM_STAGE_DEPLOYER;
USE SECONDARY ROLES NONE;

EXECUTE DCM PROJECT DCM_CONTROL_STAGE.ADMIN.DCM_GIT_EXAMPLE_STAGE
  PLAN
  USING CONFIGURATION STAGE
FROM
  'snow://workspace/<workspace_path>';

EXECUTE DCM PROJECT DCM_CONTROL_STAGE.ADMIN.DCM_GIT_EXAMPLE_STAGE
  DEPLOY AS 'release-<yyyy-mm-dd>'
  USING CONFIGURATION STAGE
FROM
  'snow://workspace/<workspace_path>';
```

## 6) CLI fallback commands

```bash
snow dcm plan --target DEV
snow dcm deploy --target DEV

snow dcm plan --target STAGE
snow dcm deploy --target STAGE

snow dcm plan --target PROD
snow dcm deploy --target PROD
```

Use explicit targets for every production command.
