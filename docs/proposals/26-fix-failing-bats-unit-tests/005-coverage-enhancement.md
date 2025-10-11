# Stage 5: Test Coverage Enhancement

**Objective**: Add missing tests based on coverage analysis from Stage 4

**Duration**: Estimated 1-3 days (depends on gaps identified)
**Dependencies**: Stage 4 (coverage matrix) complete
**Priority**: HIGH - Ensures comprehensive test coverage and quality

---

## Background

Stage 4 will reveal gaps in test coverage through the coverage matrix analysis. This stage focuses on filling those gaps by adding new test cases for untested functions and scenarios.

**The Problem**:
- Current test suite focuses on specific functions
- Many functions in build.sh and error-handling.sh may lack coverage
- Edge cases and error scenarios may not be tested
- Integration scenarios may be missing

**The Solution**: Use the coverage matrix from Stage 4 to systematically add tests for:
1. Untested functions (Priority: HIGH)
2. Partially tested functions (Priority: MEDIUM)
3. Missing edge cases (Priority: MEDIUM)
4. Integration scenarios (Priority: LOW)

---

## Objectives

### Primary Goals

1. **Achieve ≥95% Test Coverage** - Cover all critical functions
2. **Fill Critical Gaps** - Test previously untested core functionality
3. **Add Edge Cases** - Cover error scenarios and boundary conditions
4. **Improve Test Quality** - Ensure tests validate real functionality
5. **Maintain 100% Pass Rate** - All new tests must pass

### Success Criteria

- ✅ ≥95% test coverage achieved for build.sh and error-handling.sh
- ✅ All HIGH priority gaps filled
- ✅ All MEDIUM priority gaps addressed or documented
- ✅ All new tests passing (100% pass rate maintained)
- ✅ Test inventory updated with new tests
- ✅ Coverage matrix updated to reflect new coverage

---

## Detailed Steps

### Step 5.1: Analyze Coverage Gaps

**Action**: Review coverage matrix from Stage 4 and prioritize gaps

**Process**:

1. Read `docs/content/developer-docs/testing/coverage-matrix.md`
2. List all untested functions
3. Categorize gaps by priority:
   - **HIGH**: Core build functions, critical error handling
   - **MEDIUM**: Important but with workarounds
   - **LOW**: Nice to have, non-critical
4. Estimate effort for each gap
5. Create implementation plan

**Deliverable**: Gap analysis document

**Structure**:
```markdown
# Coverage Gap Analysis

## HIGH Priority Gaps (Must Fix)
- build_site() - Core build logic [Estimate: 4-6 hours]
- deploy_site() - Deployment logic [Estimate: 2-3 hours]
- ...

## MEDIUM Priority Gaps (Should Fix)
- helper_function_1() [Estimate: 1-2 hours]
- ...

## LOW Priority Gaps (Nice to Have)
- utility_function_1() [Estimate: 30 min]
- ...

## Total Estimated Effort
- HIGH: ~XX hours
- MEDIUM: ~XX hours
- LOW: ~XX hours
- **Total**: ~XX hours (X-Y days)
```

**Verification**:
- [ ] All gaps from coverage matrix catalogued
- [ ] Priority assigned to each gap
- [ ] Effort estimated
- [ ] Implementation order determined

---

### Step 5.2: Design New Test Cases

**Action**: Design tests for HIGH and MEDIUM priority gaps

**Process**:

1. For each untested function:
   - Understand function purpose and behavior
   - Identify inputs and expected outputs
   - Determine edge cases and error conditions
   - Design test scenarios

2. Create test specifications:
   - Test name and description
   - Setup requirements
   - Test steps
   - Assertions
   - Cleanup requirements

**Deliverable**: Test specifications document

**Test Specification Template**:
```markdown
### Test: [Function Name] - [Scenario]

**Category**: [Validation/Configuration/Error Handling/Integration]
**Priority**: [HIGH/MEDIUM/LOW]
**Complexity**: [Simple/Medium/Complex]

**Purpose**: What this test validates

**Setup**:
- Create test fixtures
- Set environment variables
- Mock dependencies

**Test Steps**:
1. Call function with specific inputs
2. Capture output/status
3. Verify behavior

**Assertions**:
- [ ] Status code is correct
- [ ] Output contains expected values
- [ ] Side effects are correct
- [ ] Error messages are helpful

**Cleanup**:
- Remove test files
- Reset environment
```

**Verification**:
- [ ] Test spec created for each HIGH priority gap
- [ ] Test spec created for each MEDIUM priority gap
- [ ] Edge cases identified
- [ ] Mock requirements documented

---

### Step 5.3: Implement HIGH Priority Tests

**Action**: Write and verify tests for critical gaps

**Process**:

1. **Create test files or extend existing**:
   - Add to `tests/bash/unit/build-functions.bats` for build.sh functions
   - Add to `tests/bash/unit/error-handling.bats` for error-handling.sh functions
   - Create new `.bats` files if needed for integration tests

2. **Implement each test**:
   - Follow BATS best practices from Stage 4 guidelines
   - Use proper error handling patterns
   - Include descriptive test names
   - Add comments explaining test purpose

3. **Verify individually**:
   - Run each test in isolation
   - Verify it actually validates the function
   - Ensure it can detect real failures (negative testing)

**Example Test Structure**:
```bash
@test "build_site successfully builds with default template" {
    # Setup
    TEMPLATE="corporate"
    PROJECT_ROOT="$TEST_TEMP_DIR"
    OUTPUT_DIR="$TEST_TEMP_DIR/output"

    # Create minimal template structure
    mkdir -p "$PROJECT_ROOT/templates/$TEMPLATE"
    echo 'baseURL = "http://example.com"' > "$PROJECT_ROOT/templates/$TEMPLATE/config.toml"

    # Execute
    run_safely build_site

    # Verify
    [ "$status" -eq 0 ]
    [ -d "$OUTPUT_DIR" ]
    assert_contains "$output" "Build completed successfully"

    # Cleanup
    rm -rf "$PROJECT_ROOT/templates" "$OUTPUT_DIR"
}

@test "build_site handles missing template gracefully" {
    # Setup
    TEMPLATE="nonexistent"
    PROJECT_ROOT="$TEST_TEMP_DIR"

    # Execute
    run_safely build_site

    # Verify
    [ "$status" -eq 1 ]
    assert_contains "$output" "Template not found"
    assert_contains "$output" "Check available templates"
}
```

**Implementation Order**:
1. Core build functions (build_site, deploy_site, etc.)
2. Critical error handling functions
3. Validation and configuration functions
4. Utility functions

**Verification**:
- [ ] All HIGH priority tests implemented
- [ ] Each test runs in isolation
- [ ] All new tests passing
- [ ] Negative tests verify error detection
- [ ] Code follows guidelines from Stage 4

---

### Step 5.4: Implement MEDIUM Priority Tests

**Action**: Add tests for important but non-critical gaps

**Process**:

1. Same process as Step 5.3 but for MEDIUM priority gaps
2. Focus on:
   - Helper functions
   - Secondary validation logic
   - Less common error scenarios
   - Configuration edge cases

**Implementation Strategy**:
- Batch similar tests together
- Reuse test fixtures where possible
- Keep tests focused and simple

**Verification**:
- [ ] All MEDIUM priority tests implemented
- [ ] Tests follow same quality standards
- [ ] All tests passing
- [ ] Coverage significantly improved

---

### Step 5.5: Add Integration and Edge Case Tests

**Action**: Add tests for full workflow scenarios

**Process**:

1. **Integration Tests**:
   - Test complete build workflows
   - Test error recovery scenarios
   - Test configuration loading → validation → build pipeline

2. **Edge Case Tests**:
   - Boundary conditions (empty files, large files)
   - Unusual but valid inputs
   - Rare error conditions

**Example Integration Test**:
```bash
@test "full build workflow with components and custom content" {
    # Setup complete environment
    setup_complete_test_environment

    # Execute full workflow
    run_safely bash -c "
        source scripts/build.sh
        validate_parameters &&
        load_module_config \"\$CONFIG\" &&
        parse_components \"\$TEMPLATE\" &&
        build_site
    "

    # Verify complete output
    [ "$status" -eq 0 ]
    [ -d "$OUTPUT_DIR/public" ]
    # ... more assertions
}
```

**Verification**:
- [ ] Integration tests cover main workflows
- [ ] Edge cases documented and tested
- [ ] Tests are stable and repeatable
- [ ] All tests passing

---

### Step 5.6: Update Test Documentation

**Action**: Update test inventory and coverage matrix

**Process**:

1. **Update test-inventory.md**:
   - Add all new tests to inventory table
   - Update test counts
   - Update categorization
   - Add new tests to "Tests by Category" sections

2. **Update coverage-matrix.md**:
   - Mark newly tested functions as "✅ Yes"
   - Update test ID references
   - Recalculate coverage percentages
   - Update "Coverage Gaps" section
   - Move addressed gaps from HIGH/MEDIUM to completed

3. **Update _index.md**:
   - Update test count statistics
   - Update coverage percentage
   - Update "What's Tested" summary

**Verification**:
- [ ] test-inventory.md includes all new tests
- [ ] coverage-matrix.md reflects new coverage
- [ ] Coverage percentages recalculated
- [ ] Documentation accurate and complete

---

### Step 5.7: Validation and Quality Assurance

**Action**: Verify all tests pass and coverage goals met

**Process**:

1. **Run Full Test Suite**:
```bash
./scripts/test-bash.sh --suite unit --verbose
```

2. **Verify Results**:
   - All tests passing (100% pass rate)
   - No flaky tests (run 3+ times)
   - Performance acceptable (not too slow)

3. **Coverage Validation**:
   - Calculate actual coverage percentage
   - Verify ≥95% target met for core files
   - Document any remaining gaps with justification

4. **Quality Check**:
   - Review test code for quality
   - Ensure tests follow guidelines
   - Verify tests actually validate functionality
   - Check for proper error messages and comments

**Deliverable**: Validation report

**Structure**:
```markdown
# Stage 5 Validation Report

## Test Execution Results
- Total Tests: XX
- Passing: XX (100%)
- Failing: 0
- Duration: XXs

## Coverage Achievement
- build.sh coverage: XX% (target: ≥95%)
- error-handling.sh coverage: XX% (target: ≥95%)
- Overall coverage: XX%

## Quality Metrics
- Tests following guidelines: 100%
- Tests with proper error messages: 100%
- Tests with negative testing: XX%
- Flaky tests: 0

## Remaining Gaps
- [Function name]: [Justification for not testing]
- ...

## Conclusion
✅ Stage 5 objectives achieved
✅ Coverage target met
✅ All tests passing
```

**Verification**:
- [ ] All tests passing (100%)
- [ ] Coverage ≥95% achieved
- [ ] No flaky tests
- [ ] Validation report complete
- [ ] Quality standards met

---

## Deliverables

1. ✅ Gap analysis document (Step 5.1)
2. ✅ Test specifications for new tests (Step 5.2)
3. ✅ HIGH priority tests implemented (Step 5.3)
4. ✅ MEDIUM priority tests implemented (Step 5.4)
5. ✅ Integration and edge case tests (Step 5.5)
6. ✅ Updated test-inventory.md (Step 5.6)
7. ✅ Updated coverage-matrix.md (Step 5.6)
8. ✅ Validation report (Step 5.7)

---

## Timeline

| Step | Duration | Dependencies |
|------|----------|--------------|
| 5.1 Gap Analysis | 30-60 min | Stage 4 complete |
| 5.2 Test Design | 1-2 hours | 5.1 |
| 5.3 HIGH Priority Tests | 4-8 hours | 5.2 |
| 5.4 MEDIUM Priority Tests | 2-4 hours | 5.3 |
| 5.5 Integration Tests | 2-3 hours | 5.4 |
| 5.6 Update Docs | 1 hour | 5.5 |
| 5.7 Validation | 30-60 min | 5.6 |

**Total Estimated**: 11-19 hours (1.5-2.5 days)

**Note**: Timeline heavily depends on number and complexity of gaps identified in Stage 4.

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Coverage gaps are extensive | High | Prioritize ruthlessly; defer LOW priority gaps |
| Functions are difficult to test in isolation | High | Create comprehensive mocks; consider refactoring if needed |
| Integration tests are flaky | Medium | Use proper test isolation; add retries if needed |
| New tests break existing functionality | High | Run full suite after each batch; use git to track changes |
| Estimated effort significantly underestimated | Medium | Re-prioritize after Step 5.1; communicate with stakeholders |

---

## Definition of Done

- [ ] Gap analysis complete with priorities
- [ ] Test specifications created for all new tests
- [ ] All HIGH priority gaps tested
- [ ] All MEDIUM priority gaps tested
- [ ] Integration tests added for main workflows
- [ ] Test inventory updated
- [ ] Coverage matrix updated
- [ ] ≥95% test coverage achieved
- [ ] All tests passing (100% pass rate)
- [ ] Validation report complete
- [ ] No flaky tests
- [ ] All documentation updated

---

**Next Stage**: Stage 6 will perform CI/CD validation and final quality assurance

**Dependencies for Stage 6**:
- All tests passing locally
- Coverage targets met
- Documentation complete
