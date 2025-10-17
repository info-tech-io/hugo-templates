# Stage 2: Unit Tests for Federation Functions

**Status**: ⬜ NOT STARTED
**Estimated Duration**: 4 hours
**Dependencies**: Stage 1 complete

## Objective

Implement comprehensive unit tests for all critical federation functions in `federated-build.sh`, following incremental test-add-verify approach.

## Scope

Create BATS unit tests for Layer 2 (federation) functions, maintaining strict separation from Layer 1 tests. Each function tested individually before moving to next.

---

## Step 2.1: Configuration & Parsing Tests (1 hour)

### Functions to Test
- `load_modules_config()`
- `validate_modules_json()`
- `parse_module_config()`
- `get_module_field()`

### Test Implementation Strategy

**INCREMENTAL APPROACH** (critical!):
1. Write tests for ONE function
2. Run tests → verify pass
3. Commit
4. Move to next function

### Tasks

**2.1.1 Test `load_modules_config()`**

File: `tests/bash/unit/federated-config.bats`

```bash
@test "load_modules_config: loads valid minimal config" {
    local config="$TEST_FIXTURES/federation/minimal.json"

    run load_modules_config "$config"

    [ "$status" -eq 0 ]
    assert_contains "$output" "Loaded"
}

@test "load_modules_config: handles missing file" {
    run_safely load_modules_config "/nonexistent/config.json"

    [ "$status" -eq 1 ]
    assert_contains "$output" "not found"
}

@test "load_modules_config: validates JSON syntax" {
    local config="$TEST_TEMP_DIR/invalid.json"
    echo "{ invalid json }" > "$config"

    run_safely load_modules_config "$config"

    [ "$status" -eq 1 ]
    assert_contains "$output" "invalid JSON"
}
```

**Verification after 2.1.1**:
```bash
bats tests/bash/unit/federated-config.bats -f "load_modules_config"
# All 3 tests must pass before continuing
```

**2.1.2 Test `validate_modules_json()`**

Add 4 tests:
- Valid schema
- Missing required field
- Invalid field type
- Schema version mismatch

**Verification after 2.1.2**:
```bash
bats tests/bash/unit/federated-config.bats -f "validate_modules_json"
# All 4 tests pass → continue
```

**2.1.3 Test `parse_module_config()`**

Add 3 tests:
- Extract module name
- Extract source info
- Handle missing fields

**2.1.4 Test `get_module_field()`**

Add 3 tests:
- Get existing field
- Handle missing field
- Handle nested fields

### Deliverables

- `tests/bash/unit/federated-config.bats` (~13 tests, ~250 lines)
- 4 incremental commits

### Success Criteria

- ✅ 13 tests written and passing
- ✅ Each function has 3-4 test cases
- ✅ Error cases covered
- ✅ 4 commits made (one per function group)

### Verification

```bash
# Count tests in file
grep -c "^@test" tests/bash/unit/federated-config.bats  # Should be 13

# Run all config tests
bats tests/bash/unit/federated-config.bats
# All tests PASS
```

---

## Step 2.2: Build Orchestration Tests (1 hour)

### Functions to Test
- `build_module()`
- `prepare_module_workspace()`
- `clone_module_source()`
- `execute_module_build()`

### Tasks

**2.2.1 Test `build_module()`**

File: `tests/bash/unit/federated-build.bats`

Add 4 tests:
- Successful single module build
- Build with overrides
- Build failure handling
- Dry-run mode

**Verification**:
```bash
bats tests/bash/unit/federated-build.bats -f "build_module"
```

**2.2.2 Test `prepare_module_workspace()`**

Add 3 tests:
- Create workspace structure
- Handle existing workspace
- Permission errors

**2.2.3 Test `clone_module_source()`**

Add 4 tests:
- Clone GitHub repo (mocked)
- Local repository path
- Branch selection
- Clone failure handling

**2.2.4 Test `execute_module_build()`**

Add 3 tests:
- Call build.sh successfully
- Handle build.sh failure
- Pass module config correctly

### Deliverables

- `tests/bash/unit/federated-build.bats` (~14 tests, ~300 lines)
- 4 incremental commits

### Success Criteria

- ✅ 14 tests passing
- ✅ Mock build.sh works correctly
- ✅ All error paths tested

### Verification

```bash
grep -c "^@test" tests/bash/unit/federated-build.bats  # Should be 14
bats tests/bash/unit/federated-build.bats  # All PASS
```

---

## Step 2.3: Merge & Conflict Tests (1 hour)

### Functions to Test
- `merge_federation_output()`
- `detect_merge_conflicts()`
- `merge_with_strategy()`
- `apply_merge_strategy()`

### Tasks

**2.3.1 Test `merge_federation_output()`**

File: `tests/bash/unit/federated-merge.bats`

Add 4 tests:
- Merge two modules successfully
- Handle empty destination
- Preserve existing content
- Merge statistics reporting

**2.3.2 Test `detect_merge_conflicts()`**

Add 5 tests:
- No conflicts scenario
- File-file conflict
- Directory-file conflict
- Multiple conflicts
- Conflict reporting format

**2.3.3 Test `merge_with_strategy()`**

Add 4 tests (one per strategy):
- Overwrite strategy
- Preserve strategy
- Merge strategy
- Error strategy

**2.3.4 Test `apply_merge_strategy()`**

Add 3 tests:
- Apply to single file
- Apply to directory
- Strategy precedence

### Deliverables

- `tests/bash/unit/federated-merge.bats` (~16 tests, ~350 lines)
- 4 incremental commits

### Success Criteria

- ✅ 16 tests passing
- ✅ All 4 merge strategies tested
- ✅ Conflict detection accurate

### Verification

```bash
grep -c "^@test" tests/bash/unit/federated-merge.bats  # Should be 16
bats tests/bash/unit/federated-merge.bats  # All PASS
```

---

## Step 2.4: Validation & Deployment Tests (1 hour)

### Functions to Test
- `validate_federation_output()`
- `generate_deployment_artifacts()`
- `create_federation_manifest()`
- `verify_deployment_ready()`

### Tasks

**2.4.1 Test `validate_federation_output()`**

File: `tests/bash/unit/federated-validation.bats`

Add 5 tests:
- Valid output structure
- Missing index.html
- Invalid HTML files
- Asset path validation
- Validation report format

**2.4.2 Test `generate_deployment_artifacts()`**

Add 3 tests:
- Generate checksums
- Create metadata JSON
- Handle empty output

**2.4.3 Test `create_federation_manifest()`**

Add 4 tests:
- Manifest v2.0 structure
- Module metadata included
- Build statistics correct
- JSON validity

**2.4.4 Test `verify_deployment_ready()`**

Add 3 tests:
- All checks pass
- Missing artifacts
- Invalid manifest

### Deliverables

- `tests/bash/unit/federated-validation.bats` (~15 tests, ~330 lines)
- 4 incremental commits

### Success Criteria

- ✅ 15 tests passing
- ✅ Validation coverage complete
- ✅ Deployment readiness verified

### Verification

```bash
grep -c "^@test" tests/bash/unit/federated-validation.bats  # Should be 15
bats tests/bash/unit/federated-validation.bats  # All PASS
```

---

## Stage 2 Completion Criteria

### Test Coverage

**Total New Tests**: 58 unit tests
- federated-config.bats: 13 tests
- federated-build.bats: 14 tests
- federated-merge.bats: 16 tests
- federated-validation.bats: 15 tests

### Quality Gates

- ✅ All 58 tests passing (100% pass rate)
- ✅ Each function has minimum 3 test cases
- ✅ Error paths comprehensively tested
- ✅ 16 incremental commits made (one per function group)

### Incremental Verification Log

Must maintain log of each verification:
```
tests/bash/unit/VERIFICATION.log

2025-10-17 14:00 - load_modules_config: 3/3 tests PASS ✓
2025-10-17 14:15 - validate_modules_json: 4/4 tests PASS ✓
2025-10-17 14:30 - parse_module_config: 3/3 tests PASS ✓
... (continue for all 16 function groups)
```

### Ready for Stage 3

- ✅ All unit tests passing
- ✅ No regressions in Layer 1 tests
- ✅ Test runner integrates new tests
- ✅ Verification log complete

---

## Risk Mitigation

**Risk**: Test fails after addition
**Mitigation**: Revert commit, fix test, re-add

**Risk**: Mock functions inadequate
**Mitigation**: Enhance test-helpers.bash as needed

**Risk**: Function behavior unclear
**Mitigation**: Review implementation, add debug output

---

## Test Implementation Principles

### CRITICAL: Incremental Approach

**DO THIS** ✅:
```bash
# 1. Write 3 tests for function_a
# 2. Run tests
bats tests/bash/unit/federated-config.bats -f "function_a"
# 3. All pass? Commit
git add tests/bash/unit/federated-config.bats
git commit -m "test: add unit tests for function_a"
# 4. Move to function_b
```

**DON'T DO THIS** ❌:
```bash
# Write all 58 tests at once
# Run all at end
# Many failures, hard to debug
```

### Test Isolation

Each test must:
- Use TEST_TEMP_DIR
- Clean up after itself
- Not depend on other tests
- Be runnable individually

---

**Estimated Lines of Code**: ~1,230 lines (4 BATS files)
**Estimated Test Count**: 58 new unit tests
**Incremental Commits**: 16 commits (one per function group)
**Next Stage**: Stage 3 - Integration & E2E Tests
