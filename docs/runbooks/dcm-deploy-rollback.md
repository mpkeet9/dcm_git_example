# DCM Deploy Rollback Runbook

Rollback in DCM is performed by reverting Git definitions to a known-good state, then re-running plan and deploy.

## Incident trigger

Use this runbook when a `STAGE` or `PROD` deployment introduces incorrect schema/object/grant state.

## Recovery workflow

1. Identify the last known-good commit SHA.
2. Revert the bad commit(s):
   - `git revert <bad_sha>`
   - or revert a PR merge commit.
3. Open PR and run validation plan checks.
4. Merge revert PR.
5. Re-deploy:
   - `STAGE` auto deploy triggers on merge.
   - `PROD` is re-deployed via manual workflow dispatch and environment approval.

## Production emergency procedure

1. Freeze additional production deploys (temporarily disable manual dispatch approvals if needed).
2. Trigger `dcm-prod-manual-deploy.yml` using the revert commit SHA as `git_ref`.
3. Confirm plan output contains only intended restoration changes.
4. Approve and execute deploy.
5. Validate critical objects and privileges in Snowsight.

## Post-incident checklist

- Capture `plan_result.json` and deployment logs from GitHub artifacts.
- Record impacted objects and root cause.
- Add regression checks to SQL definitions or workflow guardrails.
- Update runbooks if operating assumptions changed.
