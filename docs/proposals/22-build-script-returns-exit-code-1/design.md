# Issue #22: Build Script Returns Exit Code 1 on Successful Builds

**Type**: Bug Fix
**Priority**: Critical
**Status**: Investigation
**Created**: October 5, 2025
**Related Issue**: [#22](https://github.com/info-tech-io/hugo-templates/issues/22)

## Problem Statement

The `scripts/build.sh` script returns exit code 1 even when builds complete successfully. This causes GitHub Actions workflows to fail despite the Hugo build succeeding, pages being generated, and cache being stored correctly.

### Observed Behavior

**Successful Build Operations** ✅:
- Hugo build completes successfully
- All pages generated correctly (39 pages, 349ms)
- Cache stored successfully
- Build artifacts created

**But Script Exits with Error** ❌:
- Exit code: 1 (indicates failure)
- GitHub Actions workflow fails
- Deployment blocked

### Impact Assessment

| Severity | Impact |
|----------|--------|
| **CI/CD Blocker** | ✅ Prevents GitHub Actions workflows from completing |
| **Silent Success** | ✅ Builds succeed but script reports failure |
| **Deployment Blocked** | ✅ Cannot deploy to GitHub Pages without workarounds |
| **Testing Blocked** | ✅ Cannot verify Issue #14 fix in production |

**Affected Workflows**:
- InfoTech.io corporate site deployment (info-tech-io.github.io)
- All GitHub Actions workflows using `build.sh`
- CI/CD pipelines for modules and documentation

## Evidence from Issue #22

From workflow run [#18256945098](https://github.com/info-tech-io/info-tech-io.github.io/actions/runs/18256945098):

```
✅ Hugo build completed
✅ Hugo build completed
ℹ️  Storing build in cache...
✅ Build cached successfully
##[error]Process completed with exit code 1.
```

**Build Statistics** (showing success):
- Pages: 39
- Build time: 349ms
- Cache: stored successfully
- Hugo: completed without errors

**But**:
- Script exit code: 1
- Workflow result: FAILED

## Root Cause Analysis from Issue

### Initial Investigation (from Issue #22)

**Location**: `scripts/build.sh` lines 1175-1180

**Current Code**:
```bash
# Cleanup error handling system
cleanup_error_handling

# Explicit exit code for successful build
exit 0
}
```

**Previous Failed Fix Attempt** (commit befb36f - REVERTED):
- Added `exit 0` at end of `main()` function
- Did NOT solve the problem
- Suggests issue is deeper than simple missing exit code

### Suggested Root Cause

From Issue #22:
> The `cleanup_error_handling` function is the last function called before implicit script exit. The function's return value becomes the script's exit code.

**Hypothesis**: The `cleanup_error_handling` function in `scripts/error-handling.sh` is returning a non-zero exit code, which becomes the script's exit code even though the build succeeded.

## Investigation Strategy

### Stage 1: Bug Reproduction ✅ Priority

**Objective**: Reproduce the bug by running the corporate site deployment workflow

**Success Criteria**:
- ✅ Workflow runs and performs successful build
- ✅ Hugo build completes, pages generated, cache stored
- ✅ Workflow fails with exit code 1
- ✅ Build logs captured showing the contradiction
- ✅ Observable, reproducible evidence documented

**Test Environment**:
- Repository: `info-tech-io/info-tech-io.github.io`
- Workflow: `deploy-corporate.yml`
- Build script: `hugo-templates/scripts/build.sh`

**Why Start with Reproduction**:
Following the proven approach from Issue #14: before fixing code, we must reliably reproduce the bug in a real environment. This ensures:
1. We understand the exact conditions causing the bug
2. We have a test case to verify the fix
3. We can observe the bug's actual behavior, not just theory

### Stage 2: Log Analysis and Error Localization

**Objective**: Analyze workflow logs to identify the exact point of failure

**Actions**:
1. Examine complete workflow logs
2. Identify last successful operation
3. Trace execution flow through `cleanup_error_handling`
4. Locate the code returning exit code 1

**Success Criteria**:
- ✅ Exact line(s) of code causing exit code 1 identified
- ✅ Root cause understood with evidence
- ✅ Fix approach validated

### Stage 3: Fix Implementation

**Objective**: Implement verified fix based on Stage 2 findings

**Potential Fix Approaches** (to be determined in Stage 2):

1. **Fix `cleanup_error_handling` return value**:
   ```bash
   cleanup_error_handling() {
       # ... cleanup code ...
       return 0  # Explicit success
   }
   ```

2. **Ensure `main()` exits explicitly**:
   ```bash
   main() {
       # ... build logic ...
       cleanup_error_handling
       return 0  # or exit 0
   }
   ```

3. **Check ERROR_COUNT before exit**:
   ```bash
   cleanup_error_handling() {
       # ... cleanup ...
       if [[ $ERROR_COUNT -eq 0 ]]; then
           return 0
       else
           return 1
       fi
   }
   ```

**Note**: The actual fix will be determined after Stage 2 analysis.

## Previous Related Work

### Issue #14: Caching Bug

This bug (Issue #22) **reappeared** during the fix for Issue #14. Timeline:
1. Issue #14 introduced cache key fix (added `$CONTENT` to hash)
2. During testing, exit code 1 bug manifested
3. Blocked Issue #14 verification in production
4. Quick fix attempt (commit befb36f) failed
5. Now requires proper investigation

This suggests the bug may have been dormant or was reintroduced by changes in Issue #14.

## Expected Outcome

**Successful Resolution**:
- Build script returns exit code 0 on successful builds
- GitHub Actions workflows complete successfully
- Deployment to GitHub Pages works without `--no-cache` workaround
- Issue #14 fix can be verified in production
- CI/CD pipelines restored

**Testing Requirements**:
- Test with corporate site deployment workflow
- Test with module build workflows
- Verify exit codes in various scenarios (cache hit, cache miss, errors)
- Ensure error handling still works (real errors return exit code 1)

## Implementation Phases

### Phase 1: Investigation (Current)
- ✅ Stage 1: Reproduce bug via workflow run
- ✅ Stage 2: Analyze logs, localize error
- ⏳ Stage 3+: Additional investigation if needed

### Phase 2: Fix Implementation
- Implement verified fix
- Add tests for exit code verification
- Update error handling documentation

### Phase 3: Validation
- Test with corporate site workflow
- Verify all build scenarios return correct exit codes
- Confirm deployment to GitHub Pages succeeds
- Close Issue #22

## Documentation Structure

```
docs/proposals/22-build-script-returns-exit-code-1/
├── design.md                  # This file - problem analysis
├── progress.md                # Visual progress tracking
├── 001-reproduction.md        # Stage 1: Reproduction plan via workflow
├── 001-progress.md           # Stage 1: Reproduction results
├── 002-log-analysis.md       # Stage 2: Log analysis and localization plan
├── 002-progress.md           # Stage 2: Analysis results
└── [003+]                    # Fix implementation stages
```

## References

- **Issue**: [#22 Build script returns exit code 1 on successful builds](https://github.com/info-tech-io/hugo-templates/issues/22)
- **Failed Workflow**: [Run #18256945098](https://github.com/info-tech-io/info-tech-io.github.io/actions/runs/18256945098)
- **Code**: `scripts/build.sh` (main build logic)
- **Code**: `scripts/error-handling.sh` (cleanup function)
- **Related**: Issue #14 (caching bug that triggered this issue)
- **Reverted Fix**: commit befb36f (failed quick fix attempt)

---

**Status**: 🔍 **INVESTIGATION STARTED** (Stage 1: Reproduction)
**Next**: Create detailed reproduction plan in `001-reproduction.md`
