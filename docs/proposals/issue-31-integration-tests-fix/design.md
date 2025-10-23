# Issue #31: Fix Integration Tests for Enhanced Error Handling System

**Issue**: https://github.com/info-tech-io/hugo-templates/issues/31
**Status**: Planning
**Priority**: Medium
**Type**: Bugfix
**Estimated Duration**: 1-2 hours
**Created**: 2025-10-20

---

## Problem Statement

17 integration tests are failing due to outdated test assertions that don't match the new structured logging format introduced in Child #20 (Testing Infrastructure - Epic #15).

### Current Test Results

✅ **Layer 1 Unit Tests**: 78/78 passing (100%)
✅ **Layer 2 Federation Tests**: 135/135 passing (100%)
❌ **Layer 1 Integration Tests**: 35/52 passing (67%)

**Total**: 248/265 tests passing (93.6%)

### Root Cause

During Child #20, we introduced a **structured logging system** that changed the output format:

**Old Format**:
```bash
ℹ️  Available templates:
✅ Build completed successfully!
```

**New Format**:
```bash
[0;34m[2025-10-20T01:45:44+00:00] [INFO] [GENERAL] Available templates:[0m
[0;32m[2025-10-20T01:45:44+00:00] [SUCCESS] [BUILD] Build completed successfully![0m
```

Integration tests were **not updated** to match this new format, causing assertion failures.

---

## Analysis

### Failed Test Files

1. **tests/bash/integration/enhanced-features-v2.bats** (~10 tests)
2. **tests/bash/integration/build-workflows.bats** (~7 tests)

### Failed Test Categories

| Category | Tests | Example Test |
|----------|-------|--------------|
| Enhanced Features | 5 | `enhanced error messages provide user-friendly feedback` |
| Error Scenarios | 9 | `error scenario: missing Hugo binary` |
| Build Workflows | 3 | `build workflow provides comprehensive error information` |

### Assertion Pattern Issues

**Problematic Pattern**:
```bash
@test "enhanced error messages provide user-friendly feedback" {
  run ./scripts/build.sh --list-templates

  # This fails because format changed
  assert_contains "$output" "ℹ️  Available templates:"
  assert_success
}
```

**Why It Fails**:
1. ANSI color codes added: `[0;34m`
2. Timestamps added: `[2025-10-20T01:45:44+00:00]`
3. Log levels added: `[INFO]`
4. Categories added: `[GENERAL]`

---

## Solution Design

### Approach: Create Structured Logging Test Helper

Instead of updating 17 tests individually with brittle assertions, create a **reusable helper function** that:
1. Strips ANSI color codes
2. Strips timestamps
3. Verifies log level
4. Checks core message content

### Implementation Plan

#### Stage 1: Create Test Helper Function (30 minutes)

**File**: `tests/bash/helpers/test-helpers.bash`

Add new helper:

```bash
# Assert log message exists (handles structured logging format)
#
# Usage:
#   assert_log_message "$output" "Expected message" "INFO"
#   assert_log_message "$output" "Build completed" "SUCCESS"
#
# Arguments:
#   $1 - Output to search (typically $output from BATS run)
#   $2 - Expected message content (substring match)
#   $3 - Expected log level (INFO|SUCCESS|WARN|ERROR|FATAL) [optional]
#
# Returns:
#   0 - Message found with correct log level
#   1 - Message not found or incorrect log level
#
assert_log_message() {
  local output="$1"
  local expected_message="$2"
  local expected_level="${3:-}"  # Optional

  # Strip ANSI escape codes
  local clean_output
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')

  # Strip timestamps (format: [YYYY-MM-DDTHH:MM:SS+00:00])
  clean_output=$(echo "$clean_output" | sed 's/\[[0-9-]*T[0-9:+]*\]//g')

  # Check message exists
  if ! echo "$clean_output" | grep -qF "$expected_message"; then
    echo "Expected message not found: '$expected_message'"
    echo "Actual output (cleaned):"
    echo "$clean_output"
    return 1
  fi

  # Check log level if specified
  if [[ -n "$expected_level" ]]; then
    if ! echo "$clean_output" | grep -qF "[$expected_level]"; then
      echo "Expected log level not found: [$expected_level]"
      echo "Actual output (cleaned):"
      echo "$clean_output"
      return 1
    fi
  fi

  return 0
}

# Assert log message with category
#
# Usage:
#   assert_log_message_with_category "$output" "Build started" "INFO" "BUILD"
#
# Arguments:
#   $1 - Output to search
#   $2 - Expected message content
#   $3 - Expected log level
#   $4 - Expected category
#
assert_log_message_with_category() {
  local output="$1"
  local expected_message="$2"
  local expected_level="$3"
  local expected_category="$4"

  # First check message and level
  assert_log_message "$output" "$expected_message" "$expected_level" || return 1

  # Then check category
  local clean_output
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/\[[0-9-]*T[0-9:+]*\]//g')

  if ! echo "$clean_output" | grep -qF "[$expected_category]"; then
    echo "Expected category not found: [$expected_category]"
    return 1
  fi

  return 0
}
```

#### Stage 2: Update Enhanced Features Tests (20 minutes)

**File**: `tests/bash/integration/enhanced-features-v2.bats`

Update ~10 tests to use new helper:

**Before**:
```bash
@test "enhanced error messages provide user-friendly feedback" {
  run ./scripts/build.sh --list-templates

  assert_contains "$output" "ℹ️  Available templates:"
  assert_success
}
```

**After**:
```bash
@test "enhanced error messages provide user-friendly feedback" {
  run ./scripts/build.sh --list-templates

  # Use structured logging helper
  assert_log_message "$output" "Available templates" "INFO"
  assert_success
}
```

**Tests to Update** (5 tests):
1. `enhanced error messages provide user-friendly feedback`
2. `build progress indicators show step completion`
3. `error diagnostics file generation`
4. `comprehensive error context preservation`
5. `multi-step build process visualization`

#### Stage 3: Update Error Scenario Tests (30 minutes)

**File**: `tests/bash/integration/enhanced-features-v2.bats`

Update error scenario tests (9 tests):

**Example**:
```bash
@test "error scenario: missing Hugo binary" {
  # Temporarily hide Hugo
  export PATH="/tmp/empty:$PATH"

  run ./scripts/build.sh --template=minimal

  # Update to structured logging
  assert_log_message "$output" "Hugo not found" "ERROR"
  assert_failure
  assert [ "$status" -eq 1 ]
}
```

**Tests to Update** (9 tests):
6. `error scenario: unreadable module.json file`
7. `error scenario: missing Hugo binary`
8. `error scenario: missing Node.js for module.json processing`
9. `error scenario: GitHub Actions environment error reporting`
10. `error scenario: error state persistence`
11. `error scenario: verbose error reporting`
12. `error scenario: quiet mode error handling`
13. `error scenario: debug mode error diagnostics`
14. `error scenario: validation-only mode with errors`

#### Stage 4: Update Build Workflow Tests (20 minutes)

**File**: `tests/bash/integration/build-workflows.bats`

Update workflow tests (3 tests):

**Example**:
```bash
@test "build workflow provides comprehensive error information" {
  run ./scripts/build.sh --template=nonexistent

  # Update assertions
  assert_log_message "$output" "Template not found" "ERROR"
  assert_log_message "$output" "Available templates" "INFO"
  assert_failure
}
```

**Tests to Update** (3 tests):
15. `build workflow provides comprehensive error information`
16. `build workflow handles permission errors gracefully`
17. `build workflow performance is within acceptable limits`

---

## Acceptance Criteria

### Functional Requirements

- [ ] All 17 failed integration tests pass
- [ ] Test suite reports 100% pass rate (265/265 tests)
- [ ] No changes to `scripts/build.sh` (test-only changes)
- [ ] No breaking changes to existing passing tests

### Code Quality

- [ ] New helper function `assert_log_message()` added to test-helpers.bash
- [ ] New helper function `assert_log_message_with_category()` added
- [ ] Both helpers include JSDoc-style comments
- [ ] All 17 tests updated to use new helpers
- [ ] Code follows existing test patterns

### Documentation

- [ ] Helper functions documented in test-helpers.bash
- [ ] Usage examples provided in comments
- [ ] Updated tests remain readable and maintainable

### Testing

- [ ] Run full test suite: `./scripts/test-bash.sh`
- [ ] Verify all tests pass: 265/265 (100%)
- [ ] Verify federation tests still pass: 135/135
- [ ] Verify unit tests still pass: 78/78

---

## Implementation Strategy

### Workflow

1. Create bugfix branch: `bugfix/integration-tests-fix` (from `epic/federated-build-system`)
2. Stage 1: Create helper functions
3. Stage 2: Update enhanced features tests
4. Stage 3: Update error scenario tests
5. Stage 4: Update build workflow tests
6. Run full test suite
7. Commit and push
8. Create PR: `bugfix/integration-tests-fix` → `epic/federated-build-system`
9. Merge after approval

### Commit Strategy

4 commits (one per stage):

1. `test: add structured logging test helpers`
   - Add `assert_log_message()` and `assert_log_message_with_category()`

2. `test: update enhanced features tests for structured logging`
   - Update 5 tests in enhanced-features-v2.bats

3. `test: update error scenario tests for structured logging`
   - Update 9 error scenario tests

4. `test: update build workflow tests for structured logging`
   - Update 3 build workflow tests

### Testing Strategy

After each stage:
1. Run specific test file: `./scripts/test-bash.sh --suite integration --file tests/bash/integration/enhanced-features-v2.bats`
2. Verify updated tests pass
3. Commit immediately

After all stages:
1. Run full test suite: `./scripts/test-bash.sh`
2. Verify 265/265 tests pass
3. Final commit with test results

---

## Files to Modify

### Test Helper
- `tests/bash/helpers/test-helpers.bash` (+60 lines)

### Test Files
- `tests/bash/integration/enhanced-features-v2.bats` (~14 tests updated)
- `tests/bash/integration/build-workflows.bats` (~3 tests updated)

**Total Changes**: ~100 lines modified, 60 lines added

---

## Risk Assessment

### Low Risk
- **Scope**: Test-only changes, no production code modified
- **Impact**: Improves test reliability and maintainability
- **Reversibility**: Easy to revert if issues found

### Potential Issues

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Helper function bugs | Low | Test helpers before mass update |
| Breaking existing tests | Low | Run full suite after each stage |
| Performance degradation | Very Low | Helpers use simple string operations |
| Incomplete updates | Low | Systematic stage-by-stage approach |

---

## Success Metrics

### Before Fix
- Total Tests: 265
- Passing: 248 (93.6%)
- Failing: 17 (6.4%)

### After Fix (Target)
- Total Tests: 265
- Passing: 265 (100%) ✅
- Failing: 0 (0%) ✅

### Performance
- Test suite runtime should remain < 3 minutes
- No measurable performance impact from helpers

---

## Related Issues & PRs

- **Parent Epic**: #15 (Federated Build System)
- **Related Child Issue**: #20 (Testing Infrastructure)
- **Introduced By**: PR #29 (Child #20 implementation)
- **Issue**: #31 (this issue)
- **PR**: TBD (will be created)

---

## Notes

### Why This Approach?

1. **Reusable Helpers**: Future logging changes won't require mass test updates
2. **Maintainability**: Tests become more resilient to format changes
3. **Readability**: `assert_log_message()` is clearer than regex assertions
4. **Consistency**: All tests use same pattern for structured logging

### Alternative Approaches Considered

**Alternative 1**: Update each test individually without helpers
- ❌ Rejected: Not maintainable, brittle, verbose

**Alternative 2**: Disable structured logging in tests
- ❌ Rejected: Tests should verify actual production behavior

**Alternative 3**: Mock logging system in tests
- ❌ Rejected: Over-engineering, reduces test fidelity

**Selected Approach**: Create reusable test helpers ✅
- ✅ Maintainable, resilient, follows DRY principle

---

**Last Updated**: 2025-10-20
**Status**: Planning Complete - Ready for Implementation
**Next Step**: Implement Stage 1 (create helper functions)
**Branch**: `bugfix/integration-tests-fix`
**Target PR**: `bugfix/integration-tests-fix` → `epic/federated-build-system`
