---
title: "Testing Documentation"
description: "Comprehensive testing guide for Hugo Templates Framework"
weight: 40
---

# Testing Documentation

Welcome to the Hugo Templates Framework testing documentation. This section provides comprehensive information about our testing infrastructure, standards, and best practices.

## Overview

Our testing strategy ensures code quality, prevents regressions, and maintains system reliability through a comprehensive suite of automated tests. The test suite was significantly enhanced to support a new federated build system and improve reliability after a series of critical bug fixes.

**Current Test Status:**
- **Total Tests**: 185 BATS tests (78 unit, 52 integration, 55 federation)
- **Pass Rate**: 100% ✅ (185/185 passing in CI)
- **Test Suites**:
  - **Unit Tests**: 78 tests for core build and error handling logic.
  - **Integration Tests**: 52 tests covering full build workflows and error scenarios.
  - **Federation Tests**: 55 tests for the multi-module federated build system.
- **Test Framework**: BATS (Bash Automated Testing System)

**Key Recent Improvements (Issues #31, #32, #35)**:
- ✅ **CI Reliability**: Fixed 7 critical CI-only test failures, achieving a 100% pass rate.
- ✅ **Test Isolation**: Implemented a robust test isolation pattern, preventing tests from modifying the project's working directory.
- ✅ **Graceful Error Handling**: Adapted all integration tests to support the new graceful error handling system, where the build can complete successfully while reporting errors in structured logs.
- ✅ **New Test Helpers**: Added `assert_log_message()` to reliably test structured log output, making tests more resilient to format changes.

## Quick Start

### Running Tests

```bash
# Run all 185 tests (unit, integration, federation)
./scripts/test-bash.sh --suite all

# Run only the integration test suite
./scripts/test-bash.sh --suite integration

# Run a specific test file
./scripts/test-bash.sh --file tests/bash/integration/error-scenarios.bats

# Run with verbose output
./scripts/test-bash.sh --suite all --verbose
```

### Test Organization

Tests are organized by architectural layer and functionality:

```
tests/bash/
├── unit/
│   ���── build-functions.bats      # Core build system unit tests (57 tests)
│   └── error-handling.bats       # Error handling unit tests (21 tests)
├── integration/
│   ├── full-build-workflow.bats  # E2E build workflow tests (17 tests)
│   ├── enhanced-features-v2.bats # Tests for v2 features (16 tests)
│   └── error-scenarios.bats      # Integration tests for errors (18 tests)
├── federation/
│   ├── federated-config.bats     # Federation config tests
│   └── ...                       # 55 tests total for federation
└── helpers/
    └── test-helpers.bash         # Shared test utilities and mocks
```

## Testing Philosophy

Our testing approach follows these core principles:

### 1. **Comprehensive Coverage**
- Test all critical functionality
- Cover both happy paths and error scenarios
- Include edge cases and boundary conditions

### 2. **Quality Over Quantity**
- Tests must validate real functionality, not just execute code
- Each test should have a clear purpose
- Write tests that fail when they should

### 3. **Test Isolation**
- Each test runs independently in a temporary, isolated directory
- No shared state between tests
- Proper setup and teardown ensures a clean environment

### 4. **Maintainability**
- Clear, descriptive test names
- Well-organized test structure
- Follow established patterns (e.g., graceful error handling)

### 5. **CI-First Approach**
- Tests must pass in the GitHub Actions CI environment
- Test design accounts for CI-specific behaviors and environments
- All changes are validated against the full CI test suite before merging

## Documentation Sections

### [Test Inventory](test-inventory/)
Complete catalog of all 185 tests in the project, including unit, integration, and federation suites.

**Contents:**
- Full list of all tests with descriptions
- Test metadata (category, complexity, file location)
- What each test validates

### [Testing Guidelines](guidelines/)
Detailed standards and best practices for writing and maintaining tests, including new patterns.

**Contents:**
- **Graceful Error Handling Pattern**: How to test code that logs errors instead of exiting.
- **Test Isolation Pattern**: Best practices for writing isolated tests.
- **CI-Specific Testing**: Considerations for writing tests that run reliably in CI.
- Helper function documentation (e.g., `assert_log_message`).

### [Coverage Matrix](coverage-matrix/)
Analysis of test coverage with identification of gaps and priorities.

**Contents:**
- Function-by-function coverage mapping
- Coverage percentages by file and test suite
- Scenario coverage analysis (happy path, error scenarios, edge cases)

## Test Categories

Our tests are organized into the following categories:

### **Unit Tests**
Tests that verify individual functions or modules in isolation.
- Core build logic
- Error handling functions
- Parameter parsing

### **Integration Tests**
Tests that verify end-to-end functionality and interactions between different parts of the system.
- Complete build workflows
- Real-world error scenarios
- Component and theme integration

### **Federation Tests**
A dedicated suite for the multi-module federated build system.
- Federation configuration parsing
- Module downloading and merging
- Path rewriting and conflict resolution

## Testing Tools

### BATS (Bash Automated Testing System)
Our primary testing framework for shell scripts.

**Key Features:**
- TAP-compliant output
- Simple, readable test syntax
- Built-in assertions
- Setup/teardown support

**Example Test:**
```bash
@test "error scenario: missing template directory" {
    run "$SCRIPT_DIR/build.sh" --template nonexistent

    [ "$status" -eq 1 ]
    assert_log_message "$output" "Template 'nonexistent' not found" "ERROR"
}
```

### Test Helpers
Shared utilities in `tests/bash/helpers/test-helpers.bash`:

- `assert_log_message` - Check structured log output for a message and level.
- `run_safely` - Run commands and capture error codes correctly.
- `setup_test_environment` - Creates a fully isolated test environment.

## Best Practices Summary

✅ **DO:**
- Write descriptive test names
- Test both success and failure cases
- Use the established test isolation pattern (`TEST_TEMP_DIR`)
- Use `assert_log_message` for checking log output
- Add `--template nonexistent` to force failures in error tests

❌ **DON'T:**
- Write tests that modify the project's working directory
- Rely on hard-coded exit codes when graceful error handling is used
- Write brittle tests that check for exact string matches in logs

## Contributing to Tests

When contributing code to Hugo Templates Framework:

1. **Write tests for new features** - All new functionality requires tests
2. **Update tests for changes** - Modify existing tests when changing behavior
3. **Add tests for bug fixes** - Prevent regressions with test coverage
4. **Follow testing guidelines** - Use established patterns and standards
5. **Ensure tests pass in CI** - All tests must pass in the GitHub Actions environment

See [Testing Guidelines](guidelines/) for detailed contribution standards.

## Continuous Integration

All 185 tests run automatically in our CI/CD pipeline:

- **On every push** - Full test suite execution
- **On pull requests** - Must pass before merging
- **On releases** - Comprehensive validation

CI configuration: `.github/workflows/bash-tests.yml`

## Getting Help

If you have questions about testing:

- **Read the guidelines** - [Testing Guidelines](guidelines/) has detailed examples of new patterns.
- **Check test inventory** - [Test Inventory](test-inventory/) shows all existing tests.
- **Review coverage matrix** - [Coverage Matrix](coverage-matrix/) identifies gaps.
- **Ask in discussions** - [GitHub Discussions](https://github.com/info-tech-io/hugo-templates/discussions)
- **Check existing tests** - Look at similar tests in the codebase, especially in the integration suite.

## Related Documentation

- **[Contributing Guide](../contributing/)** - General contribution guidelines
- **[Build System Guide](../../user-guides/build-system/)** - Understanding the build system
- **[Error Handling Guide](../error-handling/)** - Error handling system details

---

**Testing is essential to maintaining high-quality code.** Every test contributes to system reliability and developer confidence. Thank you for helping us maintain excellent test coverage! 🧪

**Ready to start testing?** Check out our [Testing Guidelines](guidelines/) to get started!
