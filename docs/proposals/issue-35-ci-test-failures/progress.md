# Issue #35: CI Test Failures - Progress Tracking

**Issue**: https://github.com/info-tech-io/hugo-templates/issues/35
**Status**: 📋 **READY TO START**
**Branch**: `bugfix/ci-test-failures`
**Created**: 2025-10-25
**Updated**: 2025-10-25

---

## Overview

Fix 4 integration tests failing in GitHub Actions CI due to environment differences and incomplete graceful error handling adaptation from Issue #31.

**Goal**: Achieve 100% test pass rate in both local and CI environments (185/185 tests) ✅

---

## Current Status

### Test Results

| Environment | Status | Pass Rate | Tests | Issues |
|-------------|--------|-----------|-------|--------|
| Local | ✅ PASSING | 100% | 185/185 | None |
| CI - Unit Tests | ✅ PASSING | 100% | 78/78 | None |
| CI - Integration | ❌ FAILING | 92.3% | 48/52 | 4 failing |
| CI - Overall | ❌ FAILING | 97.8% | 181/185 | **4 failures** |

### Failing Tests (CI Only)

1. ❌ `build workflow handles unexpected Hugo errors` (enhanced-features-v2.bats)
2. ❌ `error scenario: empty module.json file` (error-scenarios.bats:56)
3. ❌ `error scenario: malformed components` (error-scenarios.bats)
4. ❌ `error scenario: multiple simultaneous errors` (error-scenarios.bats:195)

---

## Implementation Progress

### Stage 1: Analyze Each Failing Test ⏳
**Status**: PENDING
**Duration**: ~5 minutes

**Tasks**:
- [ ] 1.1: Read "empty module.json file" test
- [ ] 1.2: Read "multiple simultaneous errors" test
- [ ] 1.3: Read "malformed components" test
- [ ] 1.4: Find "unexpected Hugo errors" test
- [ ] 1.5: Document fix strategy for each

**Deliverable**: Test-by-test fix plan

---

### Stage 2: Fix "empty module.json file" Test ⏳
**Status**: PENDING
**Duration**: ~10 minutes
**File**: `tests/bash/integration/error-scenarios.bats:48-58`

**Tasks**:
- [ ] 2.1: Add explicit `--template nonexistent`
- [ ] 2.2: Replace hard exit code check
- [ ] 2.3: Add graceful handling pattern
- [ ] 2.4: Test locally
- [ ] 2.5: Commit fix

**Deliverable**: 1 test fixed

---

### Stage 3: Fix "multiple simultaneous errors" Test ⏳
**Status**: PENDING
**Duration**: ~10 minutes
**File**: `tests/bash/integration/error-scenarios.bats:182-197`

**Tasks**:
- [ ] 3.1: Review test logic
- [ ] 3.2: Apply graceful pattern
- [ ] 3.3: Ensure error logging
- [ ] 3.4: Test locally
- [ ] 3.5: Commit fix

**Deliverable**: 1 test fixed

---

### Stage 4: Fix "malformed components" Test ⏳
**Status**: PENDING
**Duration**: ~10 minutes
**File**: `tests/bash/integration/error-scenarios.bats`

**Tasks**:
- [ ] 4.1: Locate exact test
- [ ] 4.2: Understand expected behavior
- [ ] 4.3: Apply fix
- [ ] 4.4: Test locally
- [ ] 4.5: Commit fix

**Deliverable**: 1 test fixed

---

### Stage 5: Fix "unexpected Hugo errors" Test ⏳
**Status**: PENDING
**Duration**: ~10 minutes
**File**: `tests/bash/integration/enhanced-features-v2.bats`

**Tasks**:
- [ ] 5.1: Locate test
- [ ] 5.2: Analyze failure
- [ ] 5.3: Apply graceful handling
- [ ] 5.4: Test locally
- [ ] 5.5: Commit fix

**Deliverable**: 1 test fixed

---

### Stage 6: Verify All Tests Pass ⏳
**Status**: PENDING
**Duration**: ~10 minutes

**Tasks**:
- [ ] 6.1: Run full local test suite
- [ ] 6.2: Verify 185/185 pass locally
- [ ] 6.3: Push to remote
- [ ] 6.4: Trigger CI via workflow_dispatch
- [ ] 6.5: Monitor CI run
- [ ] 6.6: Verify all 4 tests pass in CI
- [ ] 6.7: Confirm 100% CI pass rate

**Success Criteria**:
- ✅ Local: 185/185
- ✅ CI: 185/185

**Deliverable**: Green CI pipeline

---

### Stage 7: Create PR and Merge ⏳
**Status**: PENDING
**Duration**: ~5 minutes

**Tasks**:
- [ ] 7.1: Update this progress.md to COMPLETE
- [ ] 7.2: Create PR → epic/federated-build-system
- [ ] 7.3: Add PR description
- [ ] 7.4: Merge PR
- [ ] 7.5: Verify epic CI passes
- [ ] 7.6: Close Issue #35

**Deliverable**: Issue closed, changes merged

---

## Notes

### Root Causes Identified

**Cause 1: Environment Differences**
- CI pre-creates templates that don't exist in local isolated environment
- Tests without explicit `--template` use default (corporate)
- Default exists in CI → success, doesn't exist locally → failure

**Cause 2: Incomplete Issue #31 Adaptation**
- Issue #31 documented graceful error handling adaptation
- Some tests were missed and still use hard `[ "$status" -eq 1 ]`
- Build.sh can complete with exit 0 while logging errors

### Fix Strategy

**Hybrid Approach**:
1. Add explicit `--template nonexistent` to error tests
2. Replace hard exit code assertions with graceful patterns
3. Use `assert_log_message()` from Issue #31 helpers

**Pattern**:
```bash
# Before
[ "$status" -eq 1 ]

# After
if [ "$status" -ne 0 ]; then
    assert_contains "$output" "error"
else
    assert_log_message "$output" "error" "ERROR"
fi
```

---

## Timeline

**Estimated Total**: ~60 minutes
**Started**: TBD
**Completed**: TBD

---

## Next Actions

1. ⏳ Create branch `bugfix/ci-test-failures`
2. ⏳ Start Stage 1: Analyze failing tests
3. ⏳ Fix tests one by one (Stages 2-5)
4. ⏳ Verify CI passes (Stage 6)
5. ⏳ Create and merge PR (Stage 7)

---

**Last Updated**: 2025-10-25
**Status**: ⏳ **READY TO START**
**Next Action**: Create branch and begin Stage 1
**Target PR**: `bugfix/ci-test-failures` → `epic/federated-build-system`

---

## Stage Completion Progress

```
[░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 0% (0/7 stages)

⏳ Stage 1: Analysis (Pending)
⏳ Stage 2: Fix empty module.json (Pending)
⏳ Stage 3: Fix multiple errors (Pending)
⏳ Stage 4: Fix malformed components (Pending)
⏳ Stage 5: Fix Hugo errors (Pending)
⏳ Stage 6: Verify CI (Pending)
⏳ Stage 7: PR & Merge (Pending)
```
