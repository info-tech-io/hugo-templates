# Stage 1: Bug Reproduction via Corporate Site Workflow

**Date**: October 5, 2025
**Status**: Planned
**Objective**: Reproduce exit code 1 bug by running the corporate site deployment workflow

## Overview

This stage focuses on creating a reliable, observable reproduction of the exit code bug described in Issue #22. We will trigger the `deploy-corporate.yml` workflow in the `info-tech-io.github.io` repository, which uses `hugo-templates/scripts/build.sh` to build the InfoTech.io corporate site.

## Success Criteria

### Mandatory Requirements

- ✅ **Workflow runs** and executes build script
- ✅ **Hugo build succeeds** - pages generated, cache stored
- ✅ **Workflow fails** with exit code 1
- ✅ **Build logs captured** showing the contradiction (success + exit 1)
- ✅ **Reproducible** - bug manifests consistently

### Evidence Requirements

- Workflow run URL
- Complete build logs
- Exit code documentation
- Screenshots showing successful build operations but failed workflow
- Page count and build metrics from logs

## Test Environment

### Repository Setup

**Hub Repository**: `info-tech-io/info-tech-io.github.io`
- Workflow file: `.github/workflows/deploy-corporate.yml`
- Contains GitHub Pages deployment configuration

**Build Repository**: `info-tech-io/hugo-templates`
- Build script: `scripts/build.sh`
- Error handling: `scripts/error-handling.sh`
- Current commit: cc5e0be (after reverting failed fix)

**Content Repository**: `info-tech-io/info-tech`
- Corporate site content in `docs/content/`
- Configuration in `docs/module.json`

### Workflow Overview

The `deploy-corporate.yml` workflow:
1. Checks out hub repository
2. Sets up Hugo 0.148.0
3. Checks out `hugo-templates` repository
4. Clones `info-tech` repository for content
5. Runs `scripts/build.sh` with corporate site content
6. Uploads artifacts to GitHub Pages
7. Deploys (if build succeeds)

**Current Issue**: Step 5 fails with exit code 1, blocking deployment.

## Reproduction Plan

### Step 1: Verify Current Workflow State

**Objective**: Check current state of deploy-corporate.yml workflow

**Actions**:
```bash
cd /root/info-tech-io/info-tech-io.github.io

# Check workflow file exists
ls -la .github/workflows/deploy-corporate.yml

# Check if it's enabled
cat .github/workflows/deploy-corporate.yml | head -20

# Check recent workflow runs
gh run list --workflow=deploy-corporate.yml --limit 5
```

**Expected Outcomes**:
- Workflow file exists and is ready to use
- Recent runs may show failures with exit code 1
- Workflow can be triggered via `workflow_dispatch`

**Control Procedure**:
- ✅ Workflow file exists
- ✅ Workflow has manual trigger (workflow_dispatch)
- ✅ GitHub CLI (`gh`) is authenticated

### Step 2: Ensure hugo-templates is Up to Date

**Objective**: Verify hugo-templates repository is at correct commit

**Actions**:
```bash
cd /root/info-tech-io/hugo-templates

# Check current commit
git log --oneline -1

# Should be at cc5e0be (after reverting befb36f)
git status

# Check build.sh doesn't have the failed fix
tail -20 scripts/build.sh
```

**Expected Outcomes**:
- Current commit: cc5e0be
- No `exit 0` at end of main() function
- Clean working tree

**Control Procedure**:
- ✅ At commit cc5e0be
- ✅ build.sh:1175-1177 shows only `cleanup_error_handling` call
- ✅ No uncommitted changes

### Step 3: Push hugo-templates State (if needed)

**Objective**: Ensure GitHub has the current state for workflow to use

**Note**: The workflow checks out `hugo-templates` from GitHub, so local state must be pushed.

**Actions**:
```bash
cd /root/info-tech-io/hugo-templates

# Check if we need to push
git status

# If on cc5e0be and no changes, we're ready
# Workflow will clone this commit from GitHub
```

**Control Procedure**:
- ✅ Working tree is clean
- ✅ Current commit matches what's on GitHub main branch
- ✅ No unpushed changes

### Step 4: Trigger Corporate Site Workflow

**Objective**: Run the workflow manually to reproduce the bug

**Actions**:
```bash
cd /root/info-tech-io/info-tech-io.github.io

# Trigger workflow manually without debug mode
gh workflow run deploy-corporate.yml

# Wait a moment for it to start
sleep 5

# Get the run URL
gh run list --workflow=deploy-corporate.yml --limit 1
```

**Alternative (with debug mode)**:
```bash
# Trigger with debug mode for more detailed logs
gh workflow run deploy-corporate.yml -f debug=true
```

**Expected Outcomes**:
- Workflow starts successfully
- Run appears in GitHub Actions tab
- Can monitor progress via CLI or web interface

**Control Procedure**:
- ✅ Workflow triggered successfully
- ✅ Run ID obtained
- ✅ Can view run status

### Step 5: Monitor Workflow Execution

**Objective**: Watch workflow progress and capture the failure

**Actions**:
```bash
# Watch workflow run (replace RUN_ID)
gh run watch RUN_ID

# Or view logs in real-time
gh run view RUN_ID --log
```

**Expected Behavior**:
1. ✅ Checkout steps succeed
2. ✅ Hugo setup succeeds
3. ✅ hugo-templates checkout succeeds
4. ✅ Build preparation succeeds
5. ✅ **Build step runs** - this is where bug manifests:
   - Hugo build completes
   - Pages generated
   - Cache stored
   - **But exit code 1**
6. ❌ **Workflow fails** at build step
7. ❌ Subsequent steps (upload, deploy) don't run

**Control Procedure - BUG CONFIRMED if**:
- ✅ Build logs show "Hugo build completed"
- ✅ Build logs show "Build cached successfully" (or pages generated)
- ✅ Build logs show statistics (page count, size, time)
- ✅ Build step fails with exit code 1
- ✅ Workflow status: FAILED
- ✅ Error message: "Process completed with exit code 1"

### Step 6: Capture Evidence

**Objective**: Document the bug with complete evidence

**Data Collection**:
```bash
# Get run URL for documentation
gh run view RUN_ID --web

# Save complete logs
gh run view RUN_ID --log > /tmp/workflow-run-logs.txt

# Extract key sections
grep -A 5 -B 5 "Hugo build completed" /tmp/workflow-run-logs.txt
grep -A 5 -B 5 "exit code 1" /tmp/workflow-run-logs.txt
grep -A 5 -B 5 "Build cached" /tmp/workflow-run-logs.txt

# Capture run metadata
gh run view RUN_ID --json conclusion,status,displayTitle,createdAt,updatedAt
```

**Evidence to Capture**:
1. **Workflow Run URL**: Link to GitHub Actions run
2. **Build Success Indicators**:
   - "✅ Hugo build completed"
   - Page count (e.g., "39 pages")
   - Build time (e.g., "349ms")
   - "✅ Build cached successfully"
3. **Failure Indicator**:
   - "##[error]Process completed with exit code 1"
4. **Workflow Conclusion**: Failed
5. **Timestamps**: When each step ran

**Control Procedure**:
- ✅ Complete logs saved
- ✅ Run URL documented
- ✅ Success + failure contradiction visible in logs
- ✅ Evidence ready for 001-progress.md

### Step 7: Comparative Analysis

**Objective**: Confirm this matches Issue #22 description

**Comparison with Issue #22 Evidence**:

| Metric | Issue #22 Original | Our Reproduction | Match? |
|--------|-------------------|------------------|--------|
| Hugo build status | ✅ Completed | ✅ Completed | ✅ |
| Cache status | ✅ Stored | ✅ Stored | ✅ |
| Page count | 39 | TBD | ? |
| Build time | 349ms | TBD | ? |
| Exit code | 1 | 1 | ✅ |
| Workflow result | FAILED | FAILED | ✅ |

**Control Procedure**:
- ✅ Pattern matches Issue #22
- ✅ Bug is reproducible
- ✅ Same contradiction: success operations + exit 1
- ✅ Ready to proceed to Stage 2

## Troubleshooting Guide

### If Workflow Doesn't Trigger

**Symptom**: `gh workflow run` fails or nothing happens

**Solutions**:
```bash
# Check authentication
gh auth status

# Re-authenticate if needed
gh auth login

# Check workflow file is valid
gh workflow list

# Verify PAT_TOKEN secret exists (workflow needs it)
# Must be configured in repo settings
```

### If Workflow Succeeds (Bug Doesn't Reproduce)

**Symptom**: Workflow completes successfully, no exit code 1

**Possible Causes**:
1. Bug was already fixed (check commit)
2. Workflow using wrong hugo-templates commit
3. Build conditions different

**Verification**:
```bash
# Check which commit workflow used
# Look in "Checkout hugo-templates" step logs
# Should show: "HEAD is now at cc5e0be..."

# Check if build.sh has exit 0
# In workflow logs, look for build.sh content
```

### If Build Actually Fails

**Symptom**: Hugo build fails with real errors (not exit code bug)

**Solutions**:
- Check Hugo version (should be 0.148.0)
- Check content repository accessible
- Check submodules initialized
- Review actual error messages (different from exit code bug)

**Distinction**:
- Real failure: Errors BEFORE "Hugo build completed"
- Exit code bug: Success messages, THEN exit code 1

### If Cannot Access Workflow Logs

**Symptom**: Permission denied or logs not available

**Solutions**:
```bash
# Use web interface
gh run view RUN_ID --web

# Check repository permissions
# Need read access to info-tech-io.github.io

# Try re-authentication
gh auth refresh
```

## Expected Timeline

| Step | Duration | Status |
|------|----------|--------|
| Verify workflow state | 5 min | Pending |
| Check hugo-templates commit | 2 min | Pending |
| Trigger workflow | 2 min | Pending |
| Monitor execution | 5-10 min | Pending |
| Capture evidence | 5 min | Pending |
| Analysis & documentation | 10 min | Pending |
| **Total** | **30-35 min** | Pending |

## Deliverables

### Documentation
- [x] This file (`001-reproduction.md`) - reproduction plan
- [ ] `001-progress.md` - execution results and evidence
- [ ] Workflow logs saved in docs/proposals/22-*/evidence/ (optional)

### Evidence
- Workflow run URL
- Complete build logs
- Screenshots (optional but helpful)
- Comparison table with Issue #22

### Next Steps
After successful reproduction:
1. Document results in `001-progress.md`
2. Update `progress.md` diagram (Stage 1 → ✅ Complete)
3. Create `002-log-analysis.md` for Stage 2
4. Begin analyzing logs to localize error source

## Git Commit (after reproduction)

```bash
git add docs/proposals/22-build-script-returns-exit-code-1/001-progress.md
git add docs/proposals/22-build-script-returns-exit-code-1/progress.md

git commit -m "docs(issue-22): Stage 1 - bug reproduced via corporate workflow

- Triggered deploy-corporate.yml workflow in info-tech-io.github.io
- Verified Hugo build succeeded (pages generated, cache stored)
- Confirmed workflow failed with exit code 1
- Documented contradiction: successful operations + failure exit code
- Matches Issue #22 description exactly

Evidence: 001-progress.md with workflow run URL and logs
Ready for Stage 2: Log analysis

Related: #22, Run: [URL]"
```

---

**Status**: 📋 **PLAN READY** - Ready for execution
**Next**: Execute reproduction steps and document results in `001-progress.md`
