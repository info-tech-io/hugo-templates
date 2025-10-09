# Issue #26: Fix Failing BATS Unit Tests in epic/federated-build-system

**Type**: Bug Fix
**Status**: Planning → Implementation
**Priority**: High (blocks Epic #15)
**Assignee**: AI Assistant

## Problem Statement

During Epic #15 (Federated Build System) development, BATS unit tests in the `epic/federated-build-system` branch are failing. These failures are blocking the epic merge to main and must be resolved before Epic #15 can be completed.

**Current State**:
- ~11 out of 35 unit tests failing
- New CSS tests (Child #18): 10/10 passing ✅
- Old BATS tests: ~11/35 failing ❌

**Impact**:
- Blocks Epic #15 merge to main
- Prevents CI/CD pipeline from passing
- Affects development velocity

## Root Cause Hypothesis

The tests were likely:
1. Created during Epic #2 (Build System v2.0)
2. Started failing during Epic #15 child issues (#16, #17, or #18)
3. Failure point needs to be identified through timeline analysis

## Solution Overview

Three-stage approach to identify, analyze, and fix the failing tests:

### High-Level Approach
1. **Timeline Investigation** (Stage 1): Find when tests were created and when they started failing
2. **Root Cause Analysis** (Stage 2): Analyze why tests are failing
3. **Fix Implementation** (Stage 3): Implement fixes and verify

## Technical Design

### Stage 1: Timeline Investigation

**Objective**: Identify when tests were created and when they started failing

**Method**:
- Review git history for test file creation
- Check Epic #2 progress reports (when tests were added)
- Check Epic #15 child issue progress reports (#16, #17, #18)
- Identify the commit where tests started failing

**Deliverables**:
- Timeline document showing:
  - When tests were created (commit hash, date)
  - What changes were made in Epic #15 that might affect tests
  - Exact commit where tests started failing

### Stage 2: Root Cause Analysis

**Objective**: Understand why tests are failing

**Method**:
- Run failing tests locally with verbose output
- Compare test expectations vs actual behavior
- Analyze code changes in Epic #15 that affect tested functions
- Identify if tests need fixing or code needs fixing

**Deliverables**:
- Root cause document for each failing test
- Classification: test issue vs code issue
- Fix strategy for each test

### Stage 3: Fix Implementation

**Objective**: Fix all failing tests

**Method**:
- Implement fixes based on root cause analysis
- Update tests if expectations changed
- Fix code if behavior is incorrect
- Verify all tests pass locally
- Verify CI passes

**Deliverables**:
- All 35/35 tests passing
- Documentation of changes made
- Verification report

## Implementation Stages

### Stage 1: Timeline Investigation (Estimated: 1 hour)
- **Objective**: Find when tests were created and when they started failing
- **Actions**: Git log analysis, progress report review
- **Success Criteria**: Complete timeline documented

### Stage 2: Root Cause Analysis (Estimated: 1-2 hours)
- **Objective**: Understand failure reasons
- **Actions**: Test execution, code analysis, comparison
- **Success Criteria**: Root cause identified for each failing test

### Stage 3: Fix Implementation (Estimated: 2-3 hours)
- **Objective**: Resolve all test failures
- **Actions**: Code/test fixes, verification
- **Success Criteria**: 35/35 tests passing, CI green

## Dependencies

**Blocks**:
- Epic #15 merge to main
- Child #19 start (per workflow decision)

**Depends On**:
- Child #18 merge (completed ✅)

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Tests require extensive refactoring | High | Start with simple fixes, escalate complex ones |
| Code changes needed in federated-build.sh | Medium | Careful analysis before modifying production code |
| Tests may be flaky | Medium | Run multiple times to verify stability |

## Testing Strategy

**Verification Steps**:
1. Run tests locally: `./scripts/test-bash.sh --suite unit --verbose`
2. Verify all 35 tests pass
3. Run on clean environment
4. Check CI pipeline (GitHub Actions)
5. Verify no regressions in other test suites

## Success Metrics

- ✅ All BATS unit tests passing (35/35)
- ✅ CI pipeline green on epic/federated-build-system
- ✅ No regressions in other functionality
- ✅ Tests pass on all platforms (ubuntu, macos)
- ✅ Root cause documented and understood

## Timeline

- **Stage 1**: 1 hour
- **Stage 2**: 1-2 hours
- **Stage 3**: 2-3 hours
- **Total**: 4-6 hours estimated

## Context

This issue emerged during Epic #15 development. Child #18 (CSS Path Resolution) was completed and merged, but CI revealed pre-existing test failures. Following the workflow, we're fixing these before proceeding to Child #19.

**Related Issues**:
- Epic #15: Federated Build System
- Child #16: Federated Build Script Foundation
- Child #17: Modules.json Schema
- Child #18: CSS Path Resolution System

---

**Version**: 1.0
**Created**: October 9, 2025
**Last Updated**: October 9, 2025
