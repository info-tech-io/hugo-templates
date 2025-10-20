# Issue #31: Fix Integration Tests - Progress Tracking

**Issue**: https://github.com/info-tech-io/hugo-templates/issues/31
**Status**: ⏳ NOT STARTED
**Branch**: `bugfix/integration-tests-fix`
**Created**: 2025-10-20
**Updated**: 2025-10-20

---

## Overview

Fix 17 failing integration tests that were not updated to match the new structured logging format introduced in Child #20 (Testing Infrastructure - Epic #15).

**Goal**: Achieve 100% test pass rate (265/265 tests)

---

## Current Status

### Test Results

| Test Suite | Status | Pass Rate | Tests |
|------------|--------|-----------|-------|
| Layer 1 Unit Tests | ✅ PASSING | 100% | 78/78 |
| Layer 2 Federation Tests | ✅ PASSING | 100% | 135/135 |
| Layer 1 Integration Tests | ❌ FAILING | 67% | 35/52 |
| **TOTAL** | ⚠️ **PARTIAL** | **93.6%** | **248/265** |

### Failed Tests Breakdown

| Category | Failed | Total | Tests to Fix |
|----------|--------|-------|--------------|
| Enhanced Features | 5 | 5 | Tests 1-5 |
| Error Scenarios | 9 | 9 | Tests 6-14 |
| Build Workflows | 3 | 3 | Tests 15-17 |
| **TOTAL** | **17** | **17** | **All** |

---

## Implementation Stages

### Stage 1: Create Test Helper Functions ⏳
**Status**: NOT STARTED
**Estimated Duration**: 30 minutes
**Priority**: HIGHEST
**File**: `tests/bash/helpers/test-helpers.bash`

**Tasks**:
- [ ] 1.1: Add `assert_log_message()` function (+30 lines)
- [ ] 1.2: Add `assert_log_message_with_category()` function (+30 lines)
- [ ] 1.3: Add JSDoc-style documentation for both helpers
- [ ] 1.4: Test helpers with sample inputs
- [ ] 1.5: Commit: `test: add structured logging test helpers`

**Deliverable**: 2 new helper functions with documentation

---

### Stage 2: Update Enhanced Features Tests ⏳
**Status**: NOT STARTED
**Estimated Duration**: 20 minutes
**Priority**: HIGH
**Dependencies**: Stage 1 ✅
**File**: `tests/bash/integration/enhanced-features-v2.bats`

**Tasks**:
- [ ] 2.1: Update test: `enhanced error messages provide user-friendly feedback`
- [ ] 2.2: Update test: `build progress indicators show step completion`
- [ ] 2.3: Update test: `error diagnostics file generation`
- [ ] 2.4: Update test: `comprehensive error context preservation`
- [ ] 2.5: Update test: `multi-step build process visualization`
- [ ] 2.6: Run test file to verify all 5 tests pass
- [ ] 2.7: Commit: `test: update enhanced features tests for structured logging`

**Deliverable**: 5 tests updated and passing

---

### Stage 3: Update Error Scenario Tests ⏳
**Status**: NOT STARTED
**Estimated Duration**: 30 minutes
**Priority**: MEDIUM
**Dependencies**: Stage 2 ✅
**File**: `tests/bash/integration/enhanced-features-v2.bats`

**Tasks**:
- [ ] 3.1: Update test: `error scenario: unreadable module.json file`
- [ ] 3.2: Update test: `error scenario: missing Hugo binary`
- [ ] 3.3: Update test: `error scenario: missing Node.js for module.json processing`
- [ ] 3.4: Update test: `error scenario: GitHub Actions environment error reporting`
- [ ] 3.5: Update test: `error scenario: error state persistence`
- [ ] 3.6: Update test: `error scenario: verbose error reporting`
- [ ] 3.7: Update test: `error scenario: quiet mode error handling`
- [ ] 3.8: Update test: `error scenario: debug mode error diagnostics`
- [ ] 3.9: Update test: `error scenario: validation-only mode with errors`
- [ ] 3.10: Run test file to verify all 9 tests pass
- [ ] 3.11: Commit: `test: update error scenario tests for structured logging`

**Deliverable**: 9 tests updated and passing

---

### Stage 4: Update Build Workflow Tests ⏳
**Status**: NOT STARTED
**Estimated Duration**: 20 minutes
**Priority**: MEDIUM
**Dependencies**: Stage 3 ✅
**File**: `tests/bash/integration/build-workflows.bats`

**Tasks**:
- [ ] 4.1: Update test: `build workflow provides comprehensive error information`
- [ ] 4.2: Update test: `build workflow handles permission errors gracefully`
- [ ] 4.3: Update test: `build workflow performance is within acceptable limits`
- [ ] 4.4: Run test file to verify all 3 tests pass
- [ ] 4.5: Run full test suite to verify 265/265 tests pass
- [ ] 4.6: Commit: `test: update build workflow tests for structured logging`

**Deliverable**: 3 tests updated, all 265 tests passing

---

## Progress Metrics

### Overall Completion: 0% (0/4 stages complete)

| Stage | Status | Progress | Duration | Tests Fixed |
|-------|--------|----------|----------|-------------|
| Stage 1: Helper Functions | ⏳ Pending | 0% | - | - |
| Stage 2: Enhanced Features | ⏳ Pending | 0% | - | 0/5 |
| Stage 3: Error Scenarios | ⏳ Pending | 0% | - | 0/9 |
| Stage 4: Build Workflows | ⏳ Pending | 0% | - | 0/3 |

**Total Tests Fixed**: 0/17 (0%)

---

## Timeline

### Estimated Timeline
- **Total Estimated**: 1.5-2 hours
- **Stage 1**: 30 minutes
- **Stage 2**: 20 minutes
- **Stage 3**: 30 minutes
- **Stage 4**: 20 minutes

### Actual Timeline
- **Started**: Not started
- **Completed**: Not completed
- **Total Duration**: -

---

## Test Pass Rate Progress

### Current State
```
Total Tests: 265
Passing: 248 (93.6%)
Failing: 17 (6.4%)
```

### Target State
```
Total Tests: 265
Passing: 265 (100%) ✅
Failing: 0 (0%) ✅
```

### Progress Graph
```
Stage 1: 248/265 (93.6%) ⏳
Stage 2: 253/265 (95.5%) → Target
Stage 3: 262/265 (98.9%) → Target
Stage 4: 265/265 (100%) ✅ → Target
```

---

## Files Modified

### Test Helpers
- [ ] `tests/bash/helpers/test-helpers.bash` (+60 lines)

### Integration Tests
- [ ] `tests/bash/integration/enhanced-features-v2.bats` (~14 tests updated)
- [ ] `tests/bash/integration/build-workflows.bats` (~3 tests updated)

**Total Changes**: ~100 lines modified, 60 lines added

---

## Commits

### Planned Commits (4 total)
1. ⏳ `test: add structured logging test helpers`
2. ⏳ `test: update enhanced features tests for structured logging`
3. ⏳ `test: update error scenario tests for structured logging`
4. ⏳ `test: update build workflow tests for structured logging`

### Actual Commits
- None yet

---

## Blockers

**Current Blockers**: None

**Potential Blockers**:
- None anticipated (straightforward test updates)

---

## Success Criteria

### Functional
- [ ] All 17 failed tests now pass
- [ ] Test suite reports 100% pass rate (265/265)
- [ ] No regression in previously passing tests
- [ ] Federation tests still pass (135/135)
- [ ] Unit tests still pass (78/78)

### Code Quality
- [ ] Helper functions follow existing patterns
- [ ] Updated tests remain readable
- [ ] Consistent code style throughout
- [ ] No hardcoded values in assertions

### Documentation
- [ ] Helper functions documented with JSDoc-style comments
- [ ] Usage examples provided
- [ ] Progress.md updated after each stage

### Testing
- [ ] Full test suite passes: `./scripts/test-bash.sh`
- [ ] Integration tests pass: `./scripts/test-bash.sh --suite integration`
- [ ] Test performance remains acceptable (< 3 minutes total)

---

## Commands

### Run Tests

```bash
# Run all tests
./scripts/test-bash.sh

# Run integration tests only
./scripts/test-bash.sh --suite integration

# Run specific test file (enhanced features)
./scripts/test-bash.sh --suite integration --file tests/bash/integration/enhanced-features-v2.bats

# Run specific test file (build workflows)
./scripts/test-bash.sh --suite integration --file tests/bash/integration/build-workflows.bats

# Count passing tests
./scripts/test-bash.sh 2>&1 | grep -c "^ok"

# Count failing tests
./scripts/test-bash.sh 2>&1 | grep -c "^not ok"
```

### Git Workflow

```bash
# Current branch
git branch --show-current
# Should show: bugfix/integration-tests-fix

# Commit after each stage
git add tests/bash/helpers/test-helpers.bash
git commit -m "test: add structured logging test helpers"

# Push to remote
git push origin bugfix/integration-tests-fix

# Create PR
gh pr create --base epic/federated-build-system \
  --title "fix: update integration tests for structured logging" \
  --body "Fixes #31"
```

---

## Next Actions

### Immediate Next Steps
1. ⏳ Start Stage 1: Create helper functions
2. ⏳ Add `assert_log_message()` to test-helpers.bash
3. ⏳ Add `assert_log_message_with_category()` to test-helpers.bash
4. ⏳ Test helpers with sample inputs
5. ⏳ Commit Stage 1

### After Stage 1
6. ⏳ Start Stage 2: Update enhanced features tests
7. ⏳ Update 5 tests in enhanced-features-v2.bats
8. ⏳ Run test file to verify
9. ⏳ Commit Stage 2

---

## Notes

### Why This Fix is Needed
- Child #20 introduced structured logging (timestamps, log levels, categories)
- Integration tests were not updated to match new format
- Tests expect old format messages (e.g., "ℹ️ Available templates:")
- Tests receive new format (e.g., "[INFO] [GENERAL] Available templates")

### Why This Doesn't Block Epic #15
- All **functionality** is tested and working (unit tests 100%)
- All **federation features** are tested and working (135/135)
- Failed tests are **UI/UX assertions only** (message format)
- No production bugs - all features work correctly

### Impact
- **Before**: 248/265 tests passing (93.6%)
- **After**: 265/265 tests passing (100%) ✅
- **Improvement**: +17 tests fixed (+6.4%)

---

**Last Updated**: 2025-10-20
**Status**: ⏳ **NOT STARTED - READY TO BEGIN**
**Next Action**: Start Stage 1 - Create test helper functions
**Branch**: `bugfix/integration-tests-fix`
**Target PR**: `bugfix/integration-tests-fix` → `epic/federated-build-system`
