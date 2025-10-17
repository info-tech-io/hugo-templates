# Stage 3: Integration & E2E Tests

**Status**: ⬜ NOT STARTED
**Estimated Duration**: 3 hours
**Dependencies**: Stage 2 complete

## Objective

Implement integration tests that verify complete federation workflows, including Layer 1 + Layer 2 interaction, real-world scenarios, and end-to-end builds.

## Scope

Create integration tests that combine multiple components, test real federation scenarios, and verify Layer 1 & Layer 2 work together correctly. These tests belong to separate "Integration" category in documentation.

---

## Step 3.1: Basic Integration Tests (1 hour)

### Test Category: Layer 1 + Layer 2 Integration

These tests verify that federated-build.sh correctly orchestrates build.sh.

### Tasks

**3.1.1 Test: Single Module Federation Build**

File: `tests/bash/integration/federation-e2e.bats`

```bash
@test "Integration: single module federation build end-to-end" {
    # Setup: Create mock module with valid module.json
    local workspace="$TEST_TEMP_DIR/federation-workspace"
    local config="$TEST_TEMP_DIR/modules.json"

    create_mock_federation_config "$config" "single-module"
    create_mock_module "$workspace/module-a" "minimal"

    # Execute: Run complete federation build
    run federated-build.sh --config="$config" --output="$TEST_TEMP_DIR/output"

    # Verify: Build completed successfully
    [ "$status" -eq 0 ]
    [ -d "$TEST_TEMP_DIR/output/public" ]
    [ -f "$TEST_TEMP_DIR/output/public/index.html" ]

    # Verify: Manifest created
    [ -f "$TEST_TEMP_DIR/output/federation-manifest.json" ]

    # Verify: Build.sh was called correctly
    assert_contains "$output" "Building module: module-a"
    assert_contains "$output" "Federation build complete"
}
```

**Verification**:
```bash
bats tests/bash/integration/federation-e2e.bats -f "single module"
# Test must PASS
```

**Commit**: After test passes

**3.1.2 Test: Two Module Federation Build**

Add test for 2-module scenario:
- Different destinations (/a/, /b/)
- No conflicts
- Both modules build successfully
- Correct merge

**Verification**:
```bash
bats tests/bash/integration/federation-e2e.bats -f "two module"
```

**3.1.3 Test: Module with Components**

Add test that verifies:
- Module uses quiz component
- Component correctly integrated
- CSS paths rewritten for subdirectory

**Verification**:
```bash
bats tests/bash/integration/federation-e2e.bats -f "with components"
```

### Deliverables

- 3 integration tests in `federation-e2e.bats`
- 3 incremental commits
- All tests passing

### Success Criteria

- ✅ 3 integration tests passing
- ✅ Layer 1 (build.sh) calls verified
- ✅ Layer 2 (federated-build.sh) orchestration working
- ✅ Output structure correct

---

## Step 3.2: Advanced Integration Tests (1 hour)

### Test Category: Complex Federation Scenarios

**3.2.1 Test: Multi-Module with Merge Conflicts**

```bash
@test "Integration: multi-module with merge conflict detection" {
    # Setup: Two modules targeting same destination
    local config="$TEST_TEMP_DIR/conflict-modules.json"

    create_federation_config_with_conflicts "$config"

    # Execute: Run with preserve strategy
    run federated-build.sh --config="$config" --output="$TEST_TEMP_DIR/output"

    # Verify: Conflicts detected and handled
    [ "$status" -eq 0 ]
    assert_contains "$output" "conflicts detected"
    assert_contains "$output" "merge strategy: preserve"

    # Verify: First module content preserved
    [ -f "$TEST_TEMP_DIR/output/public/conflicting-file.html" ]
}
```

**Verification**: Test passes → Commit

**3.2.2 Test: CSS Path Resolution in Real Build**

Add test that:
- Builds module to /subdir/
- Verifies CSS paths rewritten from /css/ to /subdir/css/
- Checks all HTML files
- Validates external URLs unchanged

**3.2.3 Test: Download-Preserve-Merge Pattern**

Add test for incremental federation:
- Download existing federation output
- Add new module
- Merge with preserve strategy
- Verify existing content untouched

**3.2.4 Test: Deployment Artifacts Generation**

Add test that verifies complete deployment readiness:
- Checksums generated
- Metadata JSON created
- Manifest v2.0 complete
- verify_deployment_ready() passes

### Deliverables

- 4 additional integration tests
- 4 incremental commits
- All tests passing

### Success Criteria

- ✅ 4 complex scenario tests passing
- ✅ Merge strategies tested in real scenarios
- ✅ CSS path resolution verified end-to-end
- ✅ Deployment readiness confirmed

---

## Step 3.3: Real-World Scenario Tests (1 hour)

### Test Category: Production-Like Scenarios

**3.3.1 Test: InfoTech.io Federation Simulation**

```bash
@test "Integration: InfoTech.io 5-module federation (simulated)" {
    # Setup: Simulate info-tech-io.github.io configuration
    local config="$TEST_FIXTURES/federation/real-world.json"

    # 5 modules:
    # - info-tech (/) - corporate site
    # - quiz (/quiz/)
    # - hugo-templates (/hugo-templates/)
    # - web-terminal (/web-terminal/)
    # - info-tech-cli (/info-tech-cli/)

    # Execute: Build complete federation
    run federated-build.sh --config="$config" --output="$TEST_TEMP_DIR/output" --dry-run

    # Verify: All modules processed
    [ "$status" -eq 0 ]
    assert_contains "$output" "5 modules"
    assert_contains "$output" "info-tech"
    assert_contains "$output" "quiz"
    assert_contains "$output" "hugo-templates"

    # Verify: Correct directory structure
    [ -d "$TEST_TEMP_DIR/output/public" ]
    [ -d "$TEST_TEMP_DIR/output/public/quiz" ]
    [ -d "$TEST_TEMP_DIR/output/public/hugo-templates" ]
}
```

**Verification**: Test passes → Commit

**3.3.2 Test: Error Recovery Scenarios**

Add 3 tests for error handling:
- One module fails, others continue (fail_fast=false)
- All modules fail with fail_fast=true
- Network error during module clone

**3.3.3 Test: Performance with Multiple Modules**

Add benchmark test:
- Build 3 modules sequentially
- Measure total time
- Verify < 3 minutes target
- Log performance metrics

### Deliverables

- 5 real-world scenario tests
- 5 incremental commits
- Performance baseline established

### Success Criteria

- ✅ InfoTech.io simulation passes
- ✅ Error recovery working correctly
- ✅ Performance target met (<3 min for 5 modules in dry-run)
- ✅ Real-world config validated

---

## Stage 3 Completion Criteria

### Test Coverage

**Total Integration Tests**: 12 tests
- Basic integration: 3 tests
- Advanced scenarios: 4 tests
- Real-world scenarios: 5 tests

### Categories Established

**Documentation must separate**:
1. **Layer 1 Tests** (existing 78 BATS tests)
2. **Layer 2 Tests** (58 new unit tests from Stage 2)
3. **Integration Tests** (12 tests from Stage 3) ← NEW CATEGORY

### Quality Gates

- ✅ All 12 integration tests passing
- ✅ No regressions in Layer 1 (78 tests still pass)
- ✅ No regressions in Layer 2 (58 tests still pass)
- ✅ Real-world scenarios validated
- ✅ Performance benchmarks recorded

### Incremental Verification

Must verify after each test:
```bash
# After each test addition
bats tests/bash/integration/federation-e2e.bats -f "<new test name>"

# Full suite verification
bats tests/bash/integration/federation-e2e.bats

# Full regression check
./tests/run-federation-tests.sh --layer all
```

### Ready for Stage 4

- ✅ All integration tests passing
- ✅ Test categories clearly defined
- ✅ Performance baselines established
- ✅ Documentation structure ready

---

## Test Implementation Guidelines

### Integration Test Principles

1. **Use Real Components**: Call actual federated-build.sh and build.sh
2. **Minimal Mocking**: Only mock external services (GitHub API)
3. **Complete Workflows**: Test from config load to deployment artifacts
4. **Realistic Data**: Use production-like configurations
5. **Performance Aware**: Track execution time

### Test Isolation

Each integration test must:
- Create isolated workspace in TEST_TEMP_DIR
- Clean up completely after execution
- Not depend on other tests
- Be runnable individually

### Mock Strategy

**Mock These**:
- GitHub API calls (git clone from external repos)
- Network requests (download existing pages)
- External command availability checks

**Don't Mock These**:
- build.sh execution
- federated-build.sh logic
- File system operations
- Hugo builds (use --dry-run if needed)

---

## Risk Mitigation

**Risk**: Integration tests too slow
**Mitigation**: Use --dry-run mode, minimal Hugo builds

**Risk**: Tests fail due to environment differences
**Mitigation**: Use fixtures, not real repositories

**Risk**: Flaky tests (timing issues)
**Mitigation**: Add explicit waits, deterministic test data

**Risk**: Integration tests break unit tests
**Mitigation**: Strict isolation via TEST_TEMP_DIR, verify regression after each addition

---

**Estimated Lines of Code**: ~800 lines (integration tests)
**Estimated Test Count**: 12 integration tests
**Incremental Commits**: 12 commits (one per test)
**Next Stage**: Stage 4 - Performance & Documentation
