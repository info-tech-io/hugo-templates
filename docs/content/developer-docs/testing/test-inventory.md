---
title: "Test Inventory"
description: "Complete catalog of all tests in Hugo Templates Framework"
weight: 10
---

---
title: "Test Inventory"
description: "Complete catalog of all tests in Hugo Templates Framework"
weight: 10
---

# Test Inventory

Complete catalog of all tests in the Hugo Templates Framework, organized by test suite. This document reflects the current state after significant reliability improvements and the addition of a comprehensive integration test suite.

## Overview

- **Total Tests**: 185
- **Test Pass Rate**: 100% (185/185 Passing in CI)
- **Last Updated**: 2025-10-25

### Test Distribution by Suite

| Suite | Description | Test Count | Status |
|---|---|---|---|
| **Unit Tests** | Core build and error handling logic | 78 | ✅ All Passing |
| **Integration Tests** | End-to-end workflows and error scenarios | 52 | ✅ All Passing |
| **Federation Tests** | Multi-module federated build system | 55 | ✅ All Passing |

---

## Unit Test Suite (78 tests)

Tests for the core build system (`scripts/build.sh`) and error handling (`scripts/error-handling.sh`). These tests focus on individual functions in isolation.

### `build-functions.bats` (57 tests)
**Location**: `tests/bash/unit/build-functions.bats`
**Purpose**: To test the core functions of the main build script.

**Key Functions Tested**:
- `validate_parameters()`: 4 tests covering valid and invalid parameters.
- `load_module_config()`: 4 tests for loading `module.json`.
- `parse_components()`: 4 tests for `components.yml` parsing.
- `update_hugo_config()`: 8 tests, including edge cases.
- `prepare_build_environment()`: 11 tests, including permission errors.
- `run_hugo_build()`: 6 tests for the Hugo build execution wrapper.
- `parse_arguments()`: 3 tests for CLI argument parsing.
- `check_build_cache()` / `store_build_cache()`: 4 tests for caching logic.

### `error-handling.bats` (21 tests)
**Location**: `tests/bash/unit/error-handling.bats`
**Purpose**: To test the structured error handling and logging system.

**Key Functions Tested**:
- `log_structured()`: Core logging functionality.
- `enter_function()` / `exit_function()`: 2 tests for call stack tracking.
- `set_error_context()` / `clear_error_context()`: 2 tests for context management.
- `safe_execute()` / `safe_file_operation()`: 3 tests for safe wrappers.
- `error_trap_handler()`: 2 tests for the global error trap.

---

## Integration Test Suite (52 tests)

End-to-end tests that validate the interaction between all parts of the build system. These tests are critical for ensuring reliability and catching regressions.

### `full-build-workflow.bats` (17 tests)
**Location**: `tests/bash/integration/full-build-workflow.bats`
**Purpose**: To test the complete build process from start to finish under various conditions.

**Key Scenarios Tested**:
- Full build with `corporate` and `minimal` templates.
- Build driven by `module.json` configuration.
- Graceful handling of missing templates.
- `--validate-only` mode stops before build.
- `--force` flag correctly overwrites existing output.
- Correct processing of components.
- Graceful handling of permission errors.

### `enhanced-features-v2.bats` (16 tests)
**Location**: `tests/bash/integration/enhanced-features-v2.bats`
**Purpose**: To test the enhanced UI, logging, and error reporting features.

**Key Scenarios Tested**:
- Enhanced UI header and progress indicators.
- User-friendly feedback for errors (e.g., template not found).
- Structured logging with categories (e.g., `[INFO] [BUILD]`).
- GitHub Actions annotation generation (`::error::`).
- Smart template suggestions for typos.

### `error-scenarios.bats` (19 tests)
**Location**: `tests/bash/integration/error-scenarios.bats`
**Purpose**: To ensure the build system is resilient and handles a wide range of real-world errors gracefully.

**Key Scenarios Tested**:
- **Configuration Errors**: Corrupted, empty, or unreadable `module.json`.
- **Dependency Errors**: Missing `hugo` or `node` binaries.
- **Filesystem Errors**: Disk space exhaustion and permission errors.
- **Component Errors**: Malformed `components.yml`.
- **Complex Failures**: Multiple simultaneous errors.
- **Output Modes**: Verbose, quiet, and debug modes during a failure.

---

## Federation Test Suite (55 tests)

Tests for the multi-module federated build system (`scripts/federated-build.sh`).

*Note: This section is a summary. For a detailed breakdown, see the `federation-testing.md` guide.*

### `federated-config.bats` & `federated-validation.bats`
**Purpose**: Test federation configuration loading and schema validation.

### `federated-build.bats`
**Purpose**: Test the orchestration of multi-module builds, including different strategies (`download-merge-deploy`, etc.).

### `federated-merge.bats`
**Purpose**: Test the logic for merging content from multiple modules, including conflict resolution and path rewriting.

### `federation-e2e.bats` (14 tests)
**Location**: `tests/bash/integration/federation-e2e.bats`
**Purpose**: End-to-end tests for complete, real-world federation scenarios.

**Key Scenarios Tested**:
- Single and multi-module federation builds.
- Real-world simulation of the 5-module InfoTech.io corporate site.
- Error recovery (fail-fast vs. continue on error).
- CSS path resolution for modules deployed in subdirectories.

---

## Test Execution

### Run All Tests
```bash
# Run all 185 tests
./scripts/test-bash.sh --suite all
```

### Run a Specific Suite
```bash
# Run only the 52 integration tests
./scripts/test-bash.sh --suite integration

# Run only the 78 unit tests
./scripts/test-bash.sh --suite unit
```

### Run a Specific File
```bash
# Run the error scenarios integration tests
./scripts/test-bash.sh --file tests/bash/integration/error-scenarios.bats
```

---

## Related Documentation

- [Testing Guidelines](./guidelines.md) - Best practices and key patterns for writing tests.
- [Coverage Matrix](./coverage-matrix.md) - Detailed breakdown of test coverage.
