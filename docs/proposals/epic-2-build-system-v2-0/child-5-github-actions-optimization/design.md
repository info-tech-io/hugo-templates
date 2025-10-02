# GitHub Actions Optimization Design

## Overview

This document outlines the comprehensive GitHub Actions optimization strategy to achieve **50%+ setup time reduction** and **38% total timeout reduction** through reusable composite actions, smart caching, and workflow consolidation.

## Current Problems Identified

### 1. Duplicate Setup Code

- **12+ duplicate setup steps** across workflows
- Each workflow independently installs Hugo
- Each workflow independently sets up Node.js
- Inconsistent Hugo installation strategies (peaceiris/actions-hugo@v2 vs manual)
- Maintenance burden: Changes require updates in multiple places

### 2. Inefficient Dependency Management

- Hugo binary downloaded fresh on every CI run (2-3 minutes per job)
- No caching of Hugo binaries across jobs
- NPM dependencies not cached efficiently
- No shared dependency management strategy

### 3. Excessive Workflow Timeouts

- Total timeouts across all workflows: **165 minutes**
  - bash-unit-tests: 30 minutes
  - bash-integration-tests: 30 minutes
  - bash-performance-tests: 30 minutes
  - test suite: 30 minutes
  - compatibility: 25 minutes
  - docs: 10 minutes

- Overly conservative timeouts set "just in case"
- No performance optimization considered in timeout values

### 4. Lack of Conditional Execution

- All workflows run on every change
- No path-based filtering
- Docs tests run even for code-only changes
- Wasted CI/CD minutes and resources

## Proposed Architecture

### 1. Reusable Composite Action: setup-build-env

Create a centralized, reusable composite action that handles all environment setup:

**Location**: `.github/actions/setup-build-env/action.yml`

**Features**:
- Hugo installation with smart caching
- Node.js setup with NPM caching
- Optional BATS installation for testing workflows
- Cross-platform support (Linux, macOS, Windows)
- Parameterized Hugo and Node.js versions

**Benefits**:
- **DRY Principle**: Single source of truth for setup logic
- **Consistency**: Same setup across all workflows
- **Maintainability**: Update once, apply everywhere
- **Performance**: Built-in caching strategies

### 2. Smart Hugo Caching Strategy

**Problem**: Hugo downloads take 2-3 minutes per job

**Solution**: Cache Hugo binary based on version

```yaml
- name: Cache Hugo binary
  id: cache-hugo
  uses: actions/cache@v3
  with:
    path: ~/hugo-bin
    key: hugo-${{ inputs.hugo-version }}-${{ runner.os }}-${{ runner.arch }}
```

**Expected Impact**:
- **First run**: 2-3 minutes (download Hugo)
- **Subsequent runs**: 5-10 seconds (cache hit)
- **Improvement**: ~95% download time reduction

### 3. NPM Dependencies Caching

**Problem**: NPM dependencies installed fresh on every run

**Solution**: Use actions/setup-node@v4 built-in caching

```yaml
- name: Setup Node.js with caching
  uses: actions/setup-node@v4
  with:
    node-version: ${{ inputs.node-version }}
    cache: 'npm'
```

**Expected Impact**:
- Automatic NPM cache management
- Faster dependency installation
- Reduced network bandwidth usage

### 4. Optimized Workflow Timeouts

**Strategy**: Right-size timeouts based on actual performance data

**Proposed Timeouts** (from 165min total to 103min total):
- bash-unit-tests: 30min → 8min
- bash-integration-tests: 30min → 12min
- bash-performance-tests: 30min → 15min
- test suite: 30min → 20min
- compatibility: 25min → 18min
- docs: 10min → 8min

**Rationale**:
- Based on actual test execution times
- Includes reasonable buffer (2x actual time)
- Prevents runaway processes
- Reduces queue time for other jobs

### 5. Conditional Workflow Execution

**Implementation**: Path-based filtering for docs workflow

```yaml
on:
  push:
    paths:
      - 'docs/**'
      - '**.md'
  pull_request:
    paths:
      - 'docs/**'
      - '**.md'
```

**Expected Impact**:
- Docs tests skip when only code changes
- Reduced unnecessary CI/CD runs
- Faster feedback for developers

## Implementation Plan

### Phase 1: Reusable Setup Action (2-3 hours)

**Scope**: Create composite action for environment setup

**Deliverables**:
1. `.github/actions/setup-build-env/action.yml`
2. Hugo binary caching implementation
3. NPM dependencies caching integration
4. Optional BATS installation support
5. Cross-platform compatibility

**Success Criteria**:
- Action can be called from any workflow
- Hugo caching achieves 95% download time reduction
- NPM caching functional
- All platforms supported (Linux, macOS, Windows)

### Phase 2: Workflow Integration & Performance Tuning (2-3 hours)

**Scope**: Apply setup action to all workflows and optimize

**Deliverables**:
1. Update bash-tests.yml (all jobs)
2. Update test.yml (all jobs)
3. Optimize workflow timeouts
4. Add conditional execution for docs workflow
5. Remove duplicate setup code

**Success Criteria**:
- All workflows use setup-build-env action
- 12+ duplicate steps eliminated
- Timeouts reduced by 38%
- Conditional execution working

## Technical Specifications

### Composite Action Interface

**Inputs**:
```yaml
inputs:
  hugo-version:
    description: 'Hugo version to install'
    required: false
    default: '0.148.0'

  hugo-extended:
    description: 'Install Hugo extended version'
    required: false
    default: 'true'

  node-version:
    description: 'Node.js version to setup'
    required: false
    default: '18'

  install-bats:
    description: 'Install BATS for testing'
    required: false
    default: 'false'
```

**Outputs**:
```yaml
outputs:
  cache-hit:
    description: 'Whether Hugo was loaded from cache'
    value: ${{ steps.cache-hugo.outputs.cache-hit }}
```

### Caching Strategy

**Cache Keys**:
- Hugo: `hugo-<version>-<os>-<arch>`
- NPM: Managed automatically by actions/setup-node@v4

**Cache Paths**:
- Hugo binary: `~/hugo-bin`
- NPM: `~/.npm` (default)

**TTL**: GitHub Actions default (7 days)

## Performance Targets

### Setup Time Reduction

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Setup Time (per job) | 5-8 min | 2-3 min | **50%+** |
| Hugo Download | 2-3 min | 5-10 sec | **95%** |
| Setup Code | 60+ lines/job | 7 lines/job | **88%** |
| Duplicate Steps | 12+ | 0 | **100%** |

### Total Workflow Optimization

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Total Timeouts | 165 min | 103 min | **38%** |
| Actual Runtime | ~10-15 min | ~8-12 min | **20-25%** |
| CI/CD Efficiency | Low | High | Significant |

## Risk Assessment

### Technical Risks

**Risk 1: Cache Invalidation Issues**
- **Impact**: Hugo updates not reflected if cache stale
- **Probability**: Low
- **Mitigation**: Cache key includes Hugo version, OS, and arch

**Risk 2: Cross-Platform Compatibility**
- **Impact**: Action fails on some platforms
- **Probability**: Low
- **Mitigation**: Test on Linux, macOS, Windows during implementation

**Risk 3: Breaking Existing Workflows**
- **Impact**: CI/CD broken during migration
- **Probability**: Low
- **Mitigation**: Test composite action thoroughly before applying to all workflows

### Operational Risks

**Risk 4: Increased Complexity**
- **Impact**: Harder to understand workflow setup
- **Probability**: Low
- **Mitigation**: Well-documented composite action with clear interface

## Success Metrics

**Must Achieve**:
- ✅ 50%+ setup time reduction
- ✅ 95% Hugo download time reduction
- ✅ 38% total timeout reduction
- ✅ Zero duplicate setup steps
- ✅ All workflows using setup-build-env

**Nice to Have**:
- ✅ Conditional execution for docs workflow
- ✅ Cross-platform compatibility verified
- ✅ Documentation for composite action usage

## Backward Compatibility

**Approach**: Gradual migration, not breaking changes

1. Create composite action
2. Test composite action in one workflow
3. Migrate all workflows one by one
4. Remove old setup code

**No Breaking Changes**: All existing functionality preserved

## Future Enhancements

**Not in scope, but possible**:
- Additional caching for Git submodules
- Shared artifact caching across jobs
- Matrix testing optimization
- Parallel job execution improvements
- Docker layer caching for containerized builds

This optimization lays the foundation for future CI/CD improvements while delivering immediate, measurable performance gains.
