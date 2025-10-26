# Stage 4: Performance Benchmarks & Documentation

**Status**: ⬜ NOT STARTED
**Estimated Duration**: 3 hours
**Dependencies**: Stage 3 complete

## Objective

Establish performance benchmarks for federation system, update all testing documentation with clear Layer 1/Layer 2/Integration separation, and create comprehensive test inventory.

## Scope

Final stage focuses on performance validation and documentation completeness, ensuring all tests are properly catalogued and testing guidelines are comprehensive for future maintainers.

---

## Step 4.1: Performance Benchmarks (1 hour)

### Test Category: Performance & Benchmarking

**4.1.1 Create Performance Test Suite**

File: `tests/bash/performance/federation-benchmarks.bats`

```bash
@test "Performance: single module build time" {
    local config="$TEST_FIXTURES/federation/minimal.json"
    local start_time=$(date +%s%N)

    run federated-build.sh --config="$config" --output="$TEST_TEMP_DIR/output" --dry-run

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # milliseconds

    [ "$status" -eq 0 ]
    echo "Duration: ${duration}ms" >&3

    # Verify: Should complete in < 10 seconds (dry-run)
    [ "$duration" -lt 10000 ]
}

@test "Performance: 3-module federation build time" {
    local config="$TEST_FIXTURES/federation/multi-module.json"
    local start_time=$(date +%s%N)

    run federated-build.sh --config="$config" --output="$TEST_TEMP_DIR/output" --dry-run

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))

    [ "$status" -eq 0 ]
    echo "3-module Duration: ${duration}ms" >&3

    # Verify: Should complete in < 30 seconds (dry-run)
    [ "$duration" -lt 30000 ]
}

@test "Performance: 5-module InfoTech.io simulation" {
    local config="$TEST_FIXTURES/federation/real-world.json"
    local start_time=$(date +%s%N)

    run federated-build.sh --config="$config" --output="$TEST_TEMP_DIR/output" --dry-run

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))

    [ "$status" -eq 0 ]
    echo "5-module Duration: ${duration}ms" >&3

    # Verify: Should complete in < 1 minute (dry-run)
    [ "$duration" -lt 60000 ]
}
```

**Verification**:
```bash
bats tests/bash/performance/federation-benchmarks.bats
# All tests PASS, record duration values
```

**4.1.2 Add Federation Overhead Measurement**

```bash
@test "Performance: federation overhead vs direct build" {
    # Measure: Direct build.sh call
    local start_direct=$(date +%s%N)
    run build.sh --template=minimal --output="$TEST_TEMP_DIR/direct" --dry-run
    local end_direct=$(date +%s%N)
    local duration_direct=$(( (end_direct - start_direct) / 1000000 ))

    # Measure: Same build via federation
    local config="$TEST_FIXTURES/federation/single-build.json"
    local start_fed=$(date +%s%N)
    run federated-build.sh --config="$config" --output="$TEST_TEMP_DIR/fed" --dry-run
    local end_fed=$(date +%s%N)
    local duration_fed=$(( (end_fed - start_fed) / 1000000 ))

    # Calculate overhead
    local overhead=$(( duration_fed - duration_direct ))
    local overhead_percent=$(( (overhead * 100) / duration_direct ))

    echo "Direct build: ${duration_direct}ms" >&3
    echo "Federation build: ${duration_fed}ms" >&3
    echo "Overhead: ${overhead}ms (${overhead_percent}%)" >&3

    # Verify: Overhead should be < 30%
    [ "$overhead_percent" -lt 30 ]
}
```

**4.1.3 Add CSS Path Resolution Performance Test**

Test time to rewrite CSS paths in 100 HTML files.

**4.1.4 Add Merge Performance Test**

Test time to merge 3 module outputs (1000 files each).

### Deliverables

- `tests/bash/performance/federation-benchmarks.bats` (5 tests, ~250 lines)
- Performance baseline document
- 5 incremental commits

### Success Criteria

- ✅ 5 performance tests passing
- ✅ Performance targets met:
  - Single module: < 10s (dry-run)
  - 3 modules: < 30s (dry-run)
  - 5 modules: < 60s (dry-run)
  - Overhead: < 30%
- ✅ Baseline values documented

### Verification

```bash
# Run performance suite
bats tests/bash/performance/federation-benchmarks.bats

# Record baseline
cat > docs/proposals/.../performance-baseline.md << 'EOF'
# Performance Baseline (Dry-Run Mode)

- Single module: ~5000ms
- 3 modules: ~15000ms
- 5 modules: ~45000ms
- Federation overhead: ~20%
- CSS path rewriting (100 files): ~500ms
- Merge operation (3000 files): ~1000ms

Recorded: 2025-10-17
Environment: Linux, Bash 5.0, Hugo 0.148.0
EOF
```

---

## Step 4.2: Update Test Inventory (1 hour)

### Task: Comprehensive Test Catalog Update

**4.2.1 Update `test-inventory.md` with Layer Separation**

File: `docs/content/developer-docs/testing/test-inventory.md`

**New Structure**:
```markdown
# Test Inventory

Complete catalog of all tests in Hugo Templates Framework.

## Overview

- **Total Tests**: 153
  - Layer 1 (Build System): 78 tests
  - Layer 2 (Federation): 58 tests
  - Integration (Layer 1+2): 12 tests
  - Performance: 5 tests
- **Pass Rate**: 100%
- **Last Updated**: 2025-10-17

---

## Layer 1: Build System Tests (78 tests)

### Purpose
Tests for existing build.sh functionality (pre-federation).

### Test Files
- `tests/bash/unit/build-functions.bats` (57 tests)
- `tests/bash/unit/error-handling.bats` (21 tests)

[... existing Layer 1 documentation ...]

---

## Layer 2: Federation Tests (95 tests)

### Purpose
Tests for federated-build.sh and federation-specific functionality.

### 2.1 Unit Tests (58 tests)

#### Configuration & Parsing (13 tests)
| # | Test Name | File | Function Tested |
|---|-----------|------|-----------------|
| #79 | load_modules_config: loads valid minimal config | federated-config.bats | load_modules_config() |
| #80 | load_modules_config: handles missing file | federated-config.bats | load_modules_config() |
[... continue for all 58 tests ...]

#### Build Orchestration (14 tests)
[... table of tests ...]

#### Merge & Conflict Handling (16 tests)
[... table of tests ...]

#### Validation & Deployment (15 tests)
[... table of tests ...]

### 2.2 Existing Shell Script Tests (37 tests)

These tests were created during Child Issues #17, #18, #19:

| # | Test File | Child Issue | Function Tested | Tests |
|---|-----------|-------------|-----------------|-------|
| #137 | test-schema-validation.sh | #17 | modules.json validation | 16 |
| #138 | test-css-path-detection.sh | #18 | CSS path detection | 5 |
| #139 | test-css-path-rewriting.sh | #18 | CSS path rewriting | 5 |
| #140 | test-download-pages.sh | #19 | Page downloading | 5 |
| #141 | test-intelligent-merge.sh | #19 | Merge strategies | 6 |

**Integration**: These tests run via `tests/run-federation-tests.sh`

---

## Layer 1+2 Integration Tests (12 tests)

### Purpose
Tests that verify Layer 1 (build.sh) and Layer 2 (federated-build.sh) work together correctly.

### Test File
- `tests/bash/integration/federation-e2e.bats` (12 tests)

| # | Test Name | Category | Validates |
|---|-----------|----------|-----------|
| #142 | Integration: single module federation build end-to-end | Basic | Complete workflow |
| #143 | Integration: two module federation build | Basic | Multi-module |
[... continue for all 12 tests ...]

---

## Performance & Benchmarks (5 tests)

### Purpose
Performance validation and regression detection.

### Test File
- `tests/bash/performance/federation-benchmarks.bats` (5 tests)

[... performance tests catalog ...]

---

## Running Tests

### By Layer
```bash
# Layer 1 only
./scripts/test-bash.sh --suite unit --layer layer1

# Layer 2 only
./scripts/test-bash.sh --suite unit --layer layer2

# Integration tests
./scripts/test-bash.sh --suite integration --layer integration

# All tests
./tests/run-federation-tests.sh --layer all
```

### By Category
```bash
# All federation tests (Layer 2 + Integration)
./tests/run-federation-tests.sh

# Only existing shell script tests
cd tests && ./test-schema-validation.sh && ./test-css-path-detection.sh ...

# Only BATS federation tests
bats tests/bash/unit/federated-*.bats
```
```

**4.2.2 Create Coverage Matrix for Layer 2**

New file: `docs/content/developer-docs/testing/coverage-matrix-federation.md`

```markdown
# Coverage Matrix: Federation (Layer 2)

## Function Coverage Overview

| Function | Unit Tests | Integration Tests | Coverage |
|----------|------------|-------------------|----------|
| load_modules_config() | 3 | 2 | ✅ 100% |
| validate_modules_json() | 4 | 1 | ✅ 100% |
| build_module() | 4 | 3 | ✅ 100% |
[... complete matrix ...]

## Test-to-Code Ratio

**Layer 2 Functions**: 20 major functions
**Unit Tests**: 58 tests
**Integration Tests**: 12 tests
**Ratio**: ~3.5 tests per function

## Coverage Gaps

None identified. All critical functions have minimum 3 test cases.
```

### Deliverables

- Updated `test-inventory.md` (~800 lines, added ~400)
- New `coverage-matrix-federation.md` (~300 lines)
- 2 commits

### Success Criteria

- ✅ All 153 tests catalogued
- ✅ Clear Layer 1/Layer 2/Integration separation
- ✅ Coverage matrix complete for Layer 2
- ✅ Running instructions updated

### Verification

```bash
# Check test inventory updated
grep -c "Layer 2" docs/content/developer-docs/testing/test-inventory.md  # Should be > 0

# Verify test counts
grep "Total Tests: 153" docs/content/developer-docs/testing/test-inventory.md

# Check coverage matrix exists
ls docs/content/developer-docs/testing/coverage-matrix-federation.md
```

---

## Step 4.3: Update Testing Guidelines (1 hour)

### Task: Extend Guidelines with Federation Patterns

**4.3.1 Update `guidelines.md`**

File: `docs/content/developer-docs/testing/guidelines.md`

**Add New Section** (~300 lines):
```markdown
## Federation Testing Patterns

### Pattern G: Testing Federation Functions

Federation functions have different testing requirements than Layer 1 functions.

#### Setup for Federation Tests

```bash
setup() {
    setup_test_environment

    # Federation-specific setup
    export TEST_FIXTURES="$BATS_TEST_DIRNAME/../fixtures/federation"
    export MODULES_CONFIG="$TEST_TEMP_DIR/modules.json"

    # Create minimal fixtures
    create_mock_federation_config "$MODULES_CONFIG"
}
```

#### Testing modules.json Parsing

```bash
@test "load_modules_config: loads valid config" {
    local config="$TEST_FIXTURES/minimal.json"

    run load_modules_config "$config"

    [ "$status" -eq 0 ]
    # Check specific fields parsed
    assert_contains "$output" "federation.name"
}
```

#### Testing Merge Operations

```bash
@test "merge_federation_output: merges two modules" {
    # Create mock module outputs
    mkdir -p "$TEST_TEMP_DIR/module-a/public"
    mkdir -p "$TEST_TEMP_DIR/module-b/public"
    echo "A" > "$TEST_TEMP_DIR/module-a/public/index.html"
    echo "B" > "$TEST_TEMP_DIR/module-b/public/index.html"

    # Execute merge
    run merge_federation_output "$TEST_TEMP_DIR/module-a" "$TEST_TEMP_DIR/module-b" "$TEST_TEMP_DIR/output"

    # Verify merge successful
    [ "$status" -eq 0 ]
    [ -f "$TEST_TEMP_DIR/output/public/index.html" ]
}
```

#### Testing Integration Scenarios

```bash
@test "Integration: complete federation build" {
    # Use more realistic fixtures
    local config="$TEST_FIXTURES/real-world.json"

    # Run complete workflow
    run federated-build.sh --config="$config" --output="$TEST_TEMP_DIR/output" --dry-run

    # Verify all components
    [ "$status" -eq 0 ]
    [ -f "$TEST_TEMP_DIR/output/federation-manifest.json" ]
}
```

### Pattern H: Performance Testing

#### Measuring Execution Time

```bash
@test "Performance: function executes within time limit" {
    local start_time=$(date +%s%N)

    run time_sensitive_function

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # ms

    echo "Duration: ${duration}ms" >&3
    [ "$duration" -lt 1000 ]  # Must complete in < 1 second
}
```

### Best Practices for Federation Tests

1. **Layer Separation**: Keep Layer 1 and Layer 2 tests in separate files
2. **Incremental Addition**: Add one test at a time, verify, commit
3. **Realistic Fixtures**: Use production-like configurations
4. **Mock External Services**: Don't rely on GitHub API, network
5. **Test Isolation**: Each test uses unique TEST_TEMP_DIR subdirectory
```

**4.3.2 Update `federation-testing.md`** (created in Stage 1)

Add sections:
- Test organization by layer
- How to add new tests incrementally
- Common pitfalls in federation testing
- Debugging federation tests

### Deliverables

- Updated `guidelines.md` (+300 lines, ~1,290 total)
- Updated `federation-testing.md` (+200 lines, ~500 total)
- 2 commits

### Success Criteria

- ✅ Federation testing patterns documented
- ✅ Layer separation guidelines clear
- ✅ Performance testing patterns included
- ✅ Examples for all common scenarios

### Verification

```bash
# Check guidelines updated
wc -l docs/content/developer-docs/testing/guidelines.md  # Should be ~1290

# Verify federation patterns section exists
grep "Pattern G: Testing Federation Functions" docs/content/developer-docs/testing/guidelines.md
```

---

## Stage 4 Completion Criteria

### Documentation Completeness

**Must Update**:
- ✅ test-inventory.md (Layer 1/2/Integration sections)
- ✅ coverage-matrix-federation.md (new file)
- ✅ guidelines.md (federation patterns)
- ✅ federation-testing.md (complete guide)

### Performance Baselines

**Must Establish**:
- ✅ Single module build time
- ✅ Multi-module build time
- ✅ Federation overhead measurement
- ✅ CSS rewriting performance
- ✅ Merge operation performance

### Final Test Count

**Total**: 153 tests
- Layer 1: 78 (existing, unchanged)
- Layer 2 Unit: 58 (new BATS)
- Layer 2 Shell Scripts: 37 (existing, integrated)
- Integration: 12 (new)
- Performance: 5 (new)
- **New tests added**: 75

### Quality Gates

- ✅ All 153 tests passing (100% pass rate)
- ✅ Performance targets met
- ✅ Documentation comprehensive and clear
- ✅ Layer separation maintained throughout
- ✅ Test runner supports all categories

### Ready for PR

- ✅ All stages complete
- ✅ All tests passing
- ✅ Documentation complete
- ✅ No regressions in existing functionality

---

## Final Verification Checklist

```bash
# 1. Run all tests
./tests/run-federation-tests.sh --layer all
# Expected: 153/153 tests PASS

# 2. Verify test counts
grep -c "^@test" tests/bash/unit/*.bats  # Should total 136 (78 + 58)
grep -c "^@test" tests/bash/integration/*.bats  # Should be 12
grep -c "^@test" tests/bash/performance/federation-benchmarks.bats  # Should be 5

# 3. Check documentation
ls -la docs/content/developer-docs/testing/
# Should contain: test-inventory.md, guidelines.md, coverage-matrix-federation.md, federation-testing.md

# 4. Performance baseline
cat docs/proposals/.../performance-baseline.md
# Should contain all 5 benchmark values

# 5. Layer separation
grep -A5 "## Layer 1" docs/content/developer-docs/testing/test-inventory.md
grep -A5 "## Layer 2" docs/content/developer-docs/testing/test-inventory.md
grep -A5 "## Layer 1+2 Integration" docs/content/developer-docs/testing/test-inventory.md
# All three sections should exist
```

---

## Risk Mitigation

**Risk**: Documentation updates incomplete
**Mitigation**: Use checklist, verify each section

**Risk**: Performance tests fail on different hardware
**Mitigation**: Use relative benchmarks (% overhead), not absolute times

**Risk**: Test counts don't match documentation
**Mitigation**: Automated verification scripts

---

**Estimated Lines of Code**: ~1,050 lines (documentation updates)
**Estimated Test Count**: 5 performance tests
**Incremental Commits**: 9 commits total (5 tests + 4 documentation)
**Final Outcome**: Complete testing infrastructure for Child #20
