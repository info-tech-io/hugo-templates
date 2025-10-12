# Issue #27: Fix CI Configuration - Remove Unnecessary npm Cache Requirement

**Type**: Infrastructure / CI/CD
**Status**: Planning
**Priority**: Medium-High
**Assignee**: TBD

---

## Problem Statement

GitHub Actions workflow `bash-tests.yml` fails during "Setup Build Environment" step with error:
```
Dependencies lock file is not found.
Supported file patterns: package-lock.json, npm-shrinkwrap.json, yarn.lock
```

**Impact**:
- CI pipeline cannot validate test suite
- Automated testing blocked
- Manual testing required for all PRs
- All tests pass locally (78/78, 100%)

**Root Cause**: The `setup-build-env` composite action is configured for npm projects but hugo-templates has no root-level npm dependencies.

---

## Context

### Discovery
- **Found During**: Issue #26 Stage 6 (CI/CD Validation)
- **Date**: October 12, 2025
- **Status**: Issue #26 code is correct, CI configuration is the problem

### Current State
- ✅ All 78 tests pass locally (100%)
- ✅ Code merged to epic/federated-build-system
- ❌ CI workflow fails in setup step
- ❌ Cannot validate PRs automatically

### Why This Exists
The `setup-build-env` action was likely created for projects with npm dependencies. Hugo-templates is Hugo-only but the action assumes all projects need npm.

**Problem Lines** in `.github/actions/setup-build-env/action.yml`:
- Line 28: `cache: 'npm'` - Forces npm cache requirement
- Line 94: `npm ci` - Requires package-lock.json file

---

## Solution Overview

We will implement a **dual-phase approach**:

### Phase 1: Quick Fix (Immediate)
Add minimal npm configuration files to unblock CI now.

### Phase 2: Proper Solution (Long-term)
Refactor `setup-build-env` action to make npm setup optional.

This approach:
- ✅ Unblocks CI immediately (Phase 1)
- ✅ Provides proper long-term solution (Phase 2)
- ✅ Maintains backward compatibility
- ✅ Keeps action flexible for different project types

---

## Technical Design

### Phase 1: Quick Fix (Stage 1)

**Objective**: Unblock CI within 30 minutes

**Implementation**:

1. Create minimal `package.json`:
```json
{
  "name": "hugo-templates",
  "version": "1.0.0",
  "description": "Hugo Template Factory Framework",
  "private": true,
  "repository": {
    "type": "git",
    "url": "https://github.com/info-tech-io/hugo-templates"
  },
  "scripts": {
    "test": "echo \"No npm tests - see scripts/test-bash.sh for test execution\""
  },
  "keywords": ["hugo", "templates", "static-site"],
  "author": "InfoTech.io",
  "license": "MIT"
}
```

2. Generate `package-lock.json`:
```bash
npm install --package-lock-only
```

3. Add note in README explaining why these files exist

**Pros**:
- ⚡ Quick to implement (30 minutes)
- ✅ Unblocks CI immediately
- ✅ Minimal risk
- ✅ Small changeset

**Cons**:
- ⚠️ Adds files that shouldn't be needed
- ⚠️ Doesn't fix root cause
- ⚠️ Requires Phase 2 cleanup

**Success Criteria**:
- [ ] CI workflow completes successfully
- [ ] All 78 tests run and pass in CI
- [ ] Test artifacts generated correctly

---

### Phase 2: Proper Solution (Stage 2)

**Objective**: Make npm setup optional in setup-build-env action

**Implementation**:

#### Step 1: Update Action Inputs

`.github/actions/setup-build-env/action.yml`:
```yaml
inputs:
  hugo-version:
    description: 'Hugo version to install'
    required: false
    default: '0.148.0'
  node-version:
    description: 'Node.js version to install'
    required: false
    default: '18'
  install-bats:
    description: 'Whether to install BATS testing framework'
    required: false
    default: 'false'
  enable-npm-cache:
    description: 'Enable npm caching (requires package.json)'
    required: false
    default: 'false'  # NEW INPUT
  cache-key-suffix:
    description: 'Additional suffix for cache key'
    required: false
    default: ''
```

#### Step 2: Refactor Node.js Setup

Replace single Node.js setup step with conditional steps:

```yaml
steps:
  # Option A: With npm cache (for projects with package.json)
  - name: Setup Node.js with npm cache
    if: inputs.enable-npm-cache == 'true'
    uses: actions/setup-node@v4
    with:
      node-version: ${{ inputs.node-version }}
      cache: 'npm'

  # Option B: Without npm cache (for Hugo-only projects)
  - name: Setup Node.js without cache
    if: inputs.enable-npm-cache != 'true'
    uses: actions/setup-node@v4
    with:
      node-version: ${{ inputs.node-version }}
      # No cache specified - won't fail without package-lock.json
```

#### Step 3: Conditional npm Install

```yaml
  - name: Install Node.js dependencies
    if: inputs.enable-npm-cache == 'true'
    shell: bash
    run: |
      echo "📦 Installing Node.js dependencies..."
      npm ci --prefer-offline --no-audit
      echo "✅ Dependencies installed successfully"

  - name: Skip npm dependencies
    if: inputs.enable-npm-cache != 'true'
    shell: bash
    run: |
      echo "ℹ️ Skipping npm dependencies (Hugo-only project)"
```

#### Step 4: Update Workflows

Update all workflows to use new parameter:

`.github/workflows/bash-tests.yml`:
```yaml
- name: Setup Build Environment
  uses: ./.github/actions/setup-build-env
  with:
    hugo-version: ${{ env.HUGO_VERSION }}
    node-version: ${{ env.NODE_VERSION }}
    install-bats: 'true'
    enable-npm-cache: 'false'  # Hugo project, no npm deps needed
```

#### Step 5: Remove Phase 1 Files

Once Phase 2 is validated:
```bash
git rm package.json package-lock.json
```

**Pros**:
- ✅ Addresses root cause properly
- ✅ Action works for both Hugo and npm projects
- ✅ Clean, maintainable solution
- ✅ No unnecessary files in repository

**Cons**:
- ⏰ Takes longer to implement and test
- ⚠️ Requires testing across multiple workflows
- ⚠️ Need to update all workflow files

**Success Criteria**:
- [ ] Action works without package.json (enable-npm-cache: false)
- [ ] Action still works for npm projects (enable-npm-cache: true)
- [ ] All workflows updated
- [ ] Documentation updated
- [ ] package.json/package-lock.json removed

---

## Implementation Stages

### Stage 1: Quick Fix Implementation
**Duration**: 30 minutes
**Priority**: HIGH

**Steps**:
1. Create package.json with minimal configuration
2. Generate package-lock.json
3. Commit both files with clear commit message
4. Push to epic branch
5. Verify CI passes

**Deliverables**:
- package.json
- package-lock.json
- Commit documenting temporary nature of fix

---

### Stage 2: Proper Solution Implementation
**Duration**: 2-3 hours
**Priority**: MEDIUM

**Steps**:
1. Create detailed implementation plan
2. Update setup-build-env action with new input
3. Add conditional logic for npm setup
4. Update all workflows to use new parameter
5. Test with Hugo-only project (hugo-templates)
6. Test with npm project (if available)
7. Remove Phase 1 files (package.json, package-lock.json)
8. Update action documentation

**Deliverables**:
- Updated setup-build-env action
- Updated workflows
- Action README with usage examples
- Removal of temporary fix files

---

### Stage 3: Documentation & Validation
**Duration**: 1 hour
**Priority**: MEDIUM

**Steps**:
1. Document action usage in action README
2. Add examples for both Hugo and npm projects
3. Update workflow documentation
4. Run full CI validation
5. Document lessons learned

**Deliverables**:
- Action README.md
- Updated workflow documentation
- CI validation report
- Lessons learned document

---

## Dependencies

### Required
- GitHub Actions access
- Node.js 18 (already installed)
- Hugo 0.148.0 (already installed)
- BATS testing framework (already installed)

### Optional
- npm project for testing Phase 2 with cache enabled

---

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Phase 1 files committed permanently | Low | Medium | Clear commit message noting temporary nature |
| Phase 2 breaks npm projects | High | Low | Test with both project types before deploying |
| Other workflows also need updates | Medium | High | Audit all workflows before Phase 2 |
| Forget to remove Phase 1 files | Low | Medium | Add removal as acceptance criteria for Phase 2 |

---

## Testing Strategy

### Phase 1 Testing
1. Push changes to epic branch
2. Wait for CI run
3. Verify all jobs complete successfully
4. Check test artifacts are generated
5. Validate 78/78 tests pass

### Phase 2 Testing
1. **Hugo Project Test** (hugo-templates):
   - Set enable-npm-cache: false
   - Verify workflow succeeds without package.json
   - All tests pass (78/78)

2. **npm Project Test** (if available):
   - Set enable-npm-cache: true
   - Verify npm cache works
   - npm ci succeeds

3. **Backward Compatibility**:
   - Verify default behavior (enable-npm-cache: false)
   - Ensure no breaking changes

---

## Documentation Requirements

### Action Documentation
- Update `.github/actions/setup-build-env/README.md`
- Document new `enable-npm-cache` input
- Provide usage examples for both cases
- Migration guide for existing workflows

### Workflow Documentation
- Update workflow comments explaining parameter choice
- Document when to use enable-npm-cache: true vs false

---

## Definition of Done

### Phase 1 (Quick Fix)
- [ ] package.json created and committed
- [ ] package-lock.json generated and committed
- [ ] Changes pushed to epic/federated-build-system
- [ ] CI workflow passes all jobs
- [ ] All 78 tests execute and pass
- [ ] Test artifacts generated correctly

### Phase 2 (Proper Solution)
- [ ] setup-build-env action updated with optional npm cache
- [ ] All workflows updated to use new parameter
- [ ] Tested with Hugo-only project (working without package.json)
- [ ] Action README.md updated with documentation
- [ ] Phase 1 files (package.json, package-lock.json) removed
- [ ] CI workflow passes all jobs after removal
- [ ] All 78 tests still passing

### Phase 3 (Documentation)
- [ ] Action usage documented
- [ ] Workflow migration guide created
- [ ] Lessons learned documented
- [ ] Issue #27 closed

---

## Success Metrics

- ✅ CI pipeline functional on all branches
- ✅ All 78 tests execute in CI (100% pass rate)
- ✅ Test artifacts generated (JUnit XML, coverage reports)
- ✅ Build time remains under 2 minutes per job
- ✅ Action works for both Hugo and npm projects
- ✅ No unnecessary files in repository (after Phase 2)

---

## Next Actions

1. **Immediate**: Implement Phase 1 (Quick Fix) to unblock CI
2. **Short-term**: Plan and implement Phase 2 (Proper Solution)
3. **Follow-up**: Document and validate Phase 3

---

**Created**: October 12, 2025
**Version**: 1.0
**Status**: Ready for implementation
