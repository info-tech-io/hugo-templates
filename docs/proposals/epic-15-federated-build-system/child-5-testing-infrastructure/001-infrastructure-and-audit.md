# Stage 1: Test Infrastructure & Audit

**Status**: ⬜ NOT STARTED
**Estimated Duration**: 4 hours
**Dependencies**: Child #16-19 complete

## Objective

Establish test infrastructure foundation, audit existing tests, and prepare fixtures for federation testing.

## Scope

This stage creates the infrastructure needed for comprehensive federation testing while maintaining clear separation between Layer 1 (build.sh) and Layer 2 (federated-build.sh) tests.

---

## Step 1.1: Audit Existing Tests (1 hour)

### Tasks

**1.1.1 Analyze existing federation tests**
- Review all 5 shell script tests (37 total tests)
- Document which federation functions are covered
- Identify gaps in coverage

**1.1.2 Create federation function coverage matrix**
- List all functions in `federated-build.sh`
- Map existing tests to functions
- Identify untested functions
- Prioritize by criticality

**1.1.3 Document test organization strategy**
- Define Layer 1 vs Layer 2 test separation
- Define integration test category
- Create test naming conventions

### Deliverables

- `docs/proposals/.../child-5-.../audit-results.md`
- Coverage matrix spreadsheet (Markdown table)

### Success Criteria

- ✅ All 37 existing tests catalogued
- ✅ All federated-build.sh functions listed
- ✅ Coverage gaps identified (at least 10 untested functions expected)
- ✅ Test organization strategy documented

### Verification

```bash
# Count functions in federated-build.sh
grep -c "^[a-z_]*().*{" scripts/federated-build.sh

# Verify audit document exists
ls -la docs/proposals/epic-15-federated-build-system/child-5-testing-infrastructure/audit-results.md
```

---

## Step 1.2: Create Test Infrastructure (1.5 hours)

### Tasks

**1.2.1 Create BATS test structure for Layer 2**
```bash
tests/bash/unit/
├── federated-config.bats      # modules.json parsing
├── federated-build.bats       # build orchestration
├── federated-merge.bats       # merge logic
└── federated-validation.bats  # validation functions

tests/bash/integration/
└── federation-e2e.bats        # End-to-end tests
```

**1.2.2 Create test fixtures**
```bash
tests/bash/fixtures/federation/
├── modules/
│   ├── minimal.json           # Minimal valid config
│   ├── multi-module.json      # 3+ modules
│   ├── invalid-*.json         # Error cases
│   └── real-world.json        # InfoTech.io example
├── mock-repos/
│   ├── repo-a/                # Mock repository A
│   └── repo-b/                # Mock repository B
└── expected-outputs/
    └── merged-structure/      # Expected merge results
```

**1.2.3 Enhance test helpers**
- Add federation-specific helpers to `tests/bash/helpers/test-helpers.bash`
- Mock functions for federation operations
- Assertion helpers for federation output

### Deliverables

- Empty `.bats` files with setup/teardown boilerplate
- Complete `tests/bash/fixtures/federation/` structure
- Enhanced `test-helpers.bash` with federation helpers

### Success Criteria

- ✅ All 5 BATS files created with proper boilerplate
- ✅ At least 5 fixture configs created
- ✅ Mock repositories contain minimal viable structure
- ✅ Test helpers compile without errors

### Verification

```bash
# Check BATS files exist
ls tests/bash/unit/federated-*.bats | wc -l  # Should be 4

# Check fixtures
find tests/bash/fixtures/federation -name "*.json" | wc -l  # Should be ≥5

# Verify helpers load
bash -c "source tests/bash/helpers/test-helpers.bash && type assert_federation_output"
```

---

## Step 1.3: Create Unified Test Runner (1 hour)

### Tasks

**1.3.1 Create federation test runner**
- File: `tests/run-federation-tests.sh`
- Run all 37 existing shell script tests
- Run new BATS federation tests
- Unified output format
- Exit codes propagation

**1.3.2 Update main test script**
- Modify `scripts/test-bash.sh` to support `--suite federation`
- Add `--layer` filter: `layer1`, `layer2`, `integration`, `all`
- Maintain backward compatibility

**1.3.3 Test runner incrementally**
- Add existing tests one by one
- Verify each addition
- Document any failures

### Deliverables

- `tests/run-federation-tests.sh` (~200 lines)
- Updated `scripts/test-bash.sh`
- Test runner documentation

### Success Criteria

- ✅ Runner executes all 37 existing tests successfully
- ✅ `--layer` filter works correctly
- ✅ Exit code 0 if all pass, 1 if any fail
- ✅ Color-coded output maintained

### Verification

```bash
# Run all existing tests
./tests/run-federation-tests.sh
echo "Exit code: $?"  # Should be 0

# Test layer filtering
./scripts/test-bash.sh --suite federation --layer layer2
./scripts/test-bash.sh --suite federation --layer layer1
./scripts/test-bash.sh --suite federation --layer all
```

---

## Step 1.4: Document Test Organization (0.5 hours)

### Tasks

**1.4.1 Create federation testing guide**
- File: `docs/content/developer-docs/testing/federation-testing.md`
- Explain Layer 1 vs Layer 2 separation
- Document test fixtures usage
- Integration test guidelines

**1.4.2 Update existing documentation structure**
- Prepare structure for test-inventory.md updates
- Define sections: Layer 1, Layer 2, Integration

### Deliverables

- `docs/content/developer-docs/testing/federation-testing.md` (~300 lines)
- Documentation structure plan

### Success Criteria

- ✅ Federation testing guide complete
- ✅ Clear examples for each test type
- ✅ Layer separation documented
- ✅ Test fixture usage explained

### Verification

```bash
# Check documentation exists
ls docs/content/developer-docs/testing/federation-testing.md

# Verify word count
wc -w docs/content/developer-docs/testing/federation-testing.md  # Should be ~2000 words
```

---

## Stage 1 Completion Criteria

### Must Have
- [x] Audit complete with coverage matrix
- [x] Test infrastructure created (BATS files + fixtures)
- [x] Unified test runner working with existing tests
- [x] Federation testing guide written

### Quality Gates
- ✅ All 37 existing tests pass in new runner
- ✅ Test helpers load without errors
- ✅ Documentation clear and comprehensive
- ✅ No regressions in existing Layer 1 tests

### Ready for Stage 2
- ✅ Infrastructure ready to add new BATS tests
- ✅ Fixtures available for test implementation
- ✅ Test runner supports incremental additions
- ✅ Documentation framework established

---

## Risk Mitigation

**Risk**: Existing tests fail in new runner
**Mitigation**: Add tests one by one, fix integration issues immediately

**Risk**: Test fixtures incomplete
**Mitigation**: Start with minimal fixtures, expand as needed in Stage 2

**Risk**: Documentation structure unclear
**Mitigation**: Review with team before Stage 2, adjust if needed

---

**Estimated Lines of Code**: ~500 lines (helpers, runner, docs)
**Estimated Test Count**: 0 new tests (infrastructure only)
**Next Stage**: Stage 2 - Unit Tests for Federation Functions
