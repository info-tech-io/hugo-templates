---
title: "Federation Testing Guide"
description: "Testing standards and patterns for Layer 2 federation functionality"
weight: 40
---

# Federation Testing Guide

Comprehensive guide for testing Layer 2 federation functionality in Hugo Templates Framework.

## Table of Contents

1. [Overview](#overview)
2. [Layer Architecture](#layer-architecture)
3. [Test Organization](#test-organization)
4. [Writing Federation Tests](#writing-federation-tests)
5. [Test Fixtures](#test-fixtures)
6. [Running Tests](#running-tests)
7. [Best Practices](#best-practices)

---

## Overview

Federation testing ensures that the federated build system (`scripts/federated-build.sh`) works correctly, maintains backward compatibility, and integrates seamlessly with the core build system.

### Testing Goals

- **Comprehensive Coverage**: ≥85% function coverage for federation code
- **Backward Compatibility**: Ensure Layer 1 (build.sh) continues to work unchanged
- **Integration Validation**: Verify Layer 1 and Layer 2 work together correctly
- **Performance**: Establish benchmarks for multi-module federation builds

### Test Statistics

**Current Status** (as of Stages 1-4 completion):
- **Layer 1 (build.sh)**: 78 BATS tests, 100% coverage ✅
- **Layer 2 (federated-build.sh)**: 82 tests (37 shell + 45 BATS), 100% coverage ✅
- **Integration**: 14 E2E tests, 100% coverage ✅
- **Performance**: 5 benchmark tests, baselines established ✅
- **Total**: 140 tests, all passing (100%) 🎉

---

## Layer Architecture

### Layer 1: Core Build System

**File**: `scripts/build.sh`
**Purpose**: Single-module Hugo site building
**Tests**: `tests/bash/unit/build-functions.bats`, `error-handling.bats`
**Status**: ✅ Complete (78 tests, 79% coverage)

**Key Functions**:
- `validate_parameters()`
- `prepare_build_environment()`
- `update_hugo_config()`
- `run_hugo_build()`

### Layer 2: Federation System

**File**: `scripts/federated-build.sh`
**Purpose**: Multi-module federation and deployment
**Tests**: `tests/bash/unit/federated-*.bats`
**Status**: ⏳ Infrastructure ready, tests to be implemented

**Key Functions**:
- `load_modules_config()`
- `orchestrate_builds()`
- `build_module()`
- `merge_federation_output()`
- `validate_federation_output()`

### Integration Layer

**Purpose**: Verify Layer 1 and Layer 2 work together
**Tests**: `tests/bash/integration/federation-e2e.bats`
**Status**: ⏳ Framework ready

---

## Test Organization

### Directory Structure

```
tests/
├── bash/
│   ├── unit/
│   │   ├── build-functions.bats         # Layer 1 tests
│   │   ├── error-handling.bats          # Layer 1 tests
│   │   ├── federated-config.bats        # Layer 2 - Configuration
│   │   ├── federated-build.bats         # Layer 2 - Build orchestration
│   │   ├── federated-merge.bats         # Layer 2 - Merge & deploy
│   │   └── federated-validation.bats    # Layer 2 - Validation
│   ├── integration/
│   │   └── federation-e2e.bats          # Integration tests
│   ├── fixtures/
│   │   └── federation/
│   │       ├── modules/                 # Test configurations
│   │       ├── mock-repos/              # Mock module repositories
│   │       └── expected-outputs/        # Expected results
│   └── helpers/
│       └── test-helpers.bash            # Shared test utilities
├── test-schema-validation.sh            # Legacy shell tests
├── test-css-path-detection.sh
├── test-css-path-rewriting.sh
├── test-download-pages.sh
├── test-intelligent-merge.sh
└── run-federation-tests.sh              # Federation test runner
```

### Test File Purposes

| File | Purpose | Test Count (Target) |
|------|---------|---------------------|
| `federated-config.bats` | Configuration loading and validation | 13 |
| `federated-build.bats` | Build orchestration and module builds | 14 |
| `federated-merge.bats` | Download, merge, and deploy logic | 16 |
| `federated-validation.bats` | Output validation and path resolution | 15 |
| `federation-e2e.bats` | End-to-end integration scenarios | 12 |
| **Total Layer 2** | | **70 tests** |

---

## Writing Federation Tests

### Test Naming Convention

Follow Layer 1 conventions for consistency:

```bash
@test "function_name does_something_specific" {
    # Test implementation
}
```

**Examples**:
```bash
@test "load_modules_config processes valid modules.json"
@test "load_modules_config handles missing config file"
@test "orchestrate_builds builds all modules sequentially"
@test "merge_federation_output combines module outputs correctly"
```

### Basic Test Structure

```bash
@test "descriptive test name" {
    # 1. Setup
    local modules_config="$TEST_TEMP_DIR/test-modules.json"
    create_test_modules_config "$modules_config"

    # 2. Execute
    run load_modules_config "$modules_config"

    # 3. Assert
    [ "$status" -eq 0 ]
    assert_contains "$output" "Modules configuration loaded"

    # 4. Verify side effects
    [ -n "$MODULES_LOADED" ]
}
```

### Federation-Specific Patterns

#### Pattern 1: Testing Configuration Loading

```bash
@test "load_modules_config validates JSON schema" {
    local config="$TEST_TEMP_DIR/modules.json"

    # Create invalid config (missing required field)
    cat > "$config" << 'EOF'
{
  "federation": {
    "baseURL": "http://localhost:1313"
  },
  "modules": []
}
EOF

    # Should fail validation
    run_safely load_modules_config "$config"
    [ "$status" -eq 1 ]
    assert_contains "$output" "required" || assert_contains "$output" "name"
}
```

#### Pattern 2: Testing Build Orchestration

```bash
@test "orchestrate_builds handles module build failures gracefully" {
    # Setup modules config with 3 modules
    create_multi_module_config "$TEST_TEMP_DIR/modules.json"

    # Mock build_module to fail on second module
    build_module() {
        if [[ "$1" == "module-b" ]]; then
            log_error "Build failed for module-b"
            return 1
        fi
        return 0
    }

    # Run orchestration
    run_safely orchestrate_builds

    # Should fail gracefully
    [ "$status" -eq 1 ]
    assert_contains "$output" "Build failed for module-b"
}
```

#### Pattern 3: Testing Merge Logic

```bash
@test "merge_with_strategy applies overwrite strategy correctly" {
    local source="$TEST_TEMP_DIR/source"
    local target="$TEST_TEMP_DIR/target"

    # Create source and target with conflicting file
    mkdir -p "$source" "$target"
    echo "old content" > "$target/index.html"
    echo "new content" > "$source/index.html"

    # Merge with overwrite strategy
    run merge_with_strategy "$source" "$target" "overwrite"
    [ "$status" -eq 0 ]

    # Verify old content was replaced
    assert_file_contains "$target/index.html" "new content"
    assert_file_not_contains "$target/index.html" "old content"
}
```

#### Pattern 4: Testing Path Rewriting

```bash
@test "rewrite_asset_paths rewrites CSS links with prefix" {
    local test_file="$TEST_TEMP_DIR/test.html"
    local prefix="/quiz"

    # Create HTML with local CSS link
    cat > "$test_file" << 'EOF'
<link href="/css/style.css" rel="stylesheet">
<script src="/js/main.js"></script>
EOF

    # Rewrite paths
    run rewrite_asset_paths "$test_file" "$prefix"
    [ "$status" -eq 0 ]

    # Verify paths were rewritten
    assert_file_contains "$test_file" 'href="/quiz/css/style.css"'
    assert_file_contains "$test_file" 'src="/quiz/js/main.js"'
}
```

---

## Test Fixtures

### Configuration Fixtures

Located in `tests/bash/fixtures/federation/modules/`:

| Fixture | Purpose |
|---------|---------|
| `minimal.json` | Minimal valid federation config (1 module) |
| `multi-module.json` | Multiple modules with different destinations |
| `real-world.json` | InfoTech.io production-like scenario |
| `invalid-empty.json` | Invalid: empty modules array |
| `invalid-bad-json.json` | Invalid: malformed JSON |

### Using Fixtures in Tests

```bash
@test "validate_configuration accepts minimal valid config" {
    local config="$BATS_TEST_DIRNAME/../fixtures/federation/modules/minimal.json"

    run validate_configuration "$config"

    [ "$status" -eq 0 ]
    assert_contains "$output" "Configuration validated successfully"
}
```

### Creating Custom Fixtures

```bash
# In test setup or individual test
create_test_modules_config() {
    local config_file="$1"

    cat > "$config_file" << 'EOF'
{
  "federation": {
    "name": "Test Federation",
    "baseURL": "http://localhost:1313",
    "strategy": "download-merge-deploy"
  },
  "modules": [
    {
      "name": "test-module",
      "source": {
        "repository": "local",
        "path": "docs",
        "branch": "main"
      },
      "destination": "/",
      "module_json": "module.json"
    }
  ]
}
EOF
}
```

### Mock Repositories

Located in `tests/bash/fixtures/federation/mock-repos/`:

- `repo-a/`: Simple mock repository with README and module.json
- `repo-b/`: Another mock for multi-module scenarios

**Usage**:
```bash
@test "download_module_source clones local repository" {
    local source_repo="$BATS_TEST_DIRNAME/../fixtures/federation/mock-repos/repo-a"
    local dest="$TEST_TEMP_DIR/downloaded"

    run download_module_source "$source_repo" "$dest"

    [ "$status" -eq 0 ]
    assert_directory_exists "$dest"
    assert_file_exists "$dest/module.json"
}
```

---

## Running Tests

### Using Main Test Runner

```bash
# Run all federation tests (all layers)
./scripts/test-bash.sh --suite federation

# Run Layer 2 tests only
./scripts/test-bash.sh --suite federation --layer layer2

# Run integration tests only
./scripts/test-bash.sh --suite federation --layer integration

# Run with verbose output
./scripts/test-bash.sh --suite federation --layer all --verbose
```

### Using Federation Test Runner

```bash
# Run all federation tests (legacy + BATS)
./tests/run-federation-tests.sh

# Run Layer 2 BATS tests only
./tests/run-federation-tests.sh --layer layer2

# Run legacy shell tests only
./tests/run-federation-tests.sh --layer shell

# Quiet mode
./tests/run-federation-tests.sh --layer all --quiet
```

### Running Individual BATS Files

```bash
# Run specific Layer 2 test file
bats tests/bash/unit/federated-config.bats

# Run specific test by name
bats -f "load_modules_config processes valid modules.json" \
     tests/bash/unit/federated-config.bats

# Verbose output
bats -t tests/bash/unit/federated-merge.bats
```

### Running Legacy Shell Tests

```bash
# Run individual shell test
bash tests/test-schema-validation.sh

# Run all shell tests via federation runner
./tests/run-federation-tests.sh --layer shell
```

---

## Best Practices

### 1. Maintain Layer Separation

**DO**: Keep Layer 1 and Layer 2 tests separate
```bash
# Layer 1 tests in build-functions.bats
@test "prepare_build_environment creates output directory" { ... }

# Layer 2 tests in federated-build.bats
@test "orchestrate_builds calls build_module for each module" { ... }
```

**DON'T**: Mix Layer 1 and Layer 2 logic in same test file

### 2. Use Appropriate Test Helpers

```bash
# Available helpers (from test-helpers.bash)
assert_contains "$output" "expected string"
assert_file_exists "$file_path"
assert_file_contains "$file" "content"
assert_directory_exists "$dir"
run_safely function_that_might_fail  # Handles 'set -e' properly
```

### 3. Test Isolation

```bash
@test "isolated test example" {
    # Use TEST_TEMP_DIR for all file operations
    local config="$TEST_TEMP_DIR/isolated-config.json"
    local output="$TEST_TEMP_DIR/isolated-output"

    # Create isolated resources
    mkdir -p "$output"
    create_test_config "$config"

    # Test logic...

    # Cleanup automatic via teardown_test_environment
}
```

### 4. Incremental Development

**CRITICAL**: Add tests one at a time

```bash
# 1. Write test
@test "new federation function works" { ... }

# 2. Run test - verify it passes
bats -f "new federation function works" tests/bash/unit/federated-config.bats

# 3. Commit
git add tests/bash/unit/federated-config.bats
git commit -m "test: add test for new federation function"

# 4. Move to next test
```

**NEVER**: Write all tests at once and run at the end.

### 5. Error Testing

Always test both success and failure paths:

```bash
# Success path
@test "function succeeds with valid input" { ... }

# Failure paths
@test "function handles missing config file" { ... }
@test "function handles malformed JSON" { ... }
@test "function handles network errors" { ... }
```

### 6. Mock External Dependencies

```bash
# Mock wget for download tests
wget() {
    local url="$2"
    local output_dir="$4"

    # Simulate download
    mkdir -p "$output_dir"
    echo "Mock downloaded from $url" > "$output_dir/index.html"
    return 0
}
```

### 7. Document Test Purpose

```bash
@test "merge_with_strategy applies preserve strategy" {
    # Purpose: Verify that existing files are NOT overwritten
    # when using 'preserve' merge strategy

    local source="$TEST_TEMP_DIR/source"
    local target="$TEST_TEMP_DIR/target"

    # ... test implementation
}
```

---

## Migration from Shell Tests to BATS

When migrating existing shell script tests to BATS:

### Before (Shell Script)

```bash
# tests/test-schema-validation.sh
test_valid_config() {
    if validate_configuration "test-config.json"; then
        pass_test "Valid config accepted"
    else
        fail_test "Valid config rejected"
    fi
}
```

### After (BATS)

```bash
# tests/bash/unit/federated-config.bats
@test "validate_configuration accepts valid schema" {
    local config="$TEST_TEMP_DIR/test-config.json"
    create_test_modules_config "$config"

    run validate_configuration "$config"

    [ "$status" -eq 0 ]
    assert_contains "$output" "Configuration validated successfully"
}
```

### Migration Checklist

- [ ] Convert test functions to @test blocks
- [ ] Replace custom assertions with test-helpers functions
- [ ] Use TEST_TEMP_DIR instead of /tmp
- [ ] Update to use run/run_safely for command execution
- [ ] Add proper setup/teardown
- [ ] Update test names to follow convention
- [ ] Add to appropriate BATS file (federated-*.bats)

---

## Troubleshooting

### Common Issues

#### Issue 1: "No test files found"

**Cause**: Wrong layer filter or missing BATS files

**Solution**:
```bash
# Check what files exist
ls tests/bash/unit/federated-*.bats

# Verify layer filter is correct
./scripts/test-bash.sh --suite federation --layer layer2
```

#### Issue 2: Tests Skip Instead of Run

**Cause**: Tests marked with `skip "To be implemented"`

**Solution**: Implement the test or remove the skip directive

```bash
# Before
@test "function does something" {
    skip "To be implemented in Stage 2"
}

# After
@test "function does something" {
    run function_under_test
    [ "$status" -eq 0 ]
}
```

#### Issue 3: Fixture Not Found

**Cause**: Incorrect fixture path

**Solution**:
```bash
# Use BATS_TEST_DIRNAME for reliable paths
local fixture="$BATS_TEST_DIRNAME/../fixtures/federation/modules/minimal.json"

# Verify fixture exists
[ -f "$fixture" ] || fail "Fixture not found: $fixture"
```

---

## Related Documentation

- [Test Inventory](../test-inventory/) - Complete catalog of all tests
- [Testing Guidelines](../guidelines/) - General testing best practices
- [Coverage Matrix](../coverage-matrix/) - Layer 1 coverage analysis

---

## Contributing Federation Tests

When adding new federation tests:

1. **Choose appropriate file**: Based on function category
   - Configuration → `federated-config.bats`
   - Build orchestration → `federated-build.bats`
   - Merge/deploy → `federated-merge.bats`
   - Validation → `federated-validation.bats`

2. **Follow naming conventions**: `"function_name does_something"`

3. **Add fixtures if needed**: Place in `tests/bash/fixtures/federation/`

4. **Update documentation**: Add test to test-inventory.md

5. **Test incrementally**: One test at a time, commit after each passes

6. **Maintain layer separation**: Don't mix Layer 1 and Layer 2 tests

---

**Last Updated**: 2025-10-19
**Maintainer**: Hugo Templates Framework Team
**Test Framework**: BATS (Bash Automated Testing System)
