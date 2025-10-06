#!/bin/bash
#
# Test Suite for modules.json Schema Validation
# Tests JSON Schema validation in federated-build.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
BUILD_SCRIPT="$PROJECT_ROOT/scripts/federated-build.sh"

echo "═══════════════════════════════════════════════════════════"
echo "  modules.json Schema Validation Test Suite"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Helper function to run a test
run_test() {
    local test_name=$1
    local expected_result=$2  # "pass" or "fail"
    local config_file=$3

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -n "Test $TESTS_RUN: $test_name ... "

    if $BUILD_SCRIPT --config="$config_file" --validate-only >/dev/null 2>&1; then
        actual_result="pass"
    else
        actual_result="fail"
    fi

    if [[ "$actual_result" == "$expected_result" ]]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC} (expected: $expected_result, got: $actual_result)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Create temporary test files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Test 1: Valid minimal configuration
cat > "$TEMP_DIR/valid-minimal.json" << 'EOF'
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
run_test "Valid minimal configuration" "pass" "$TEMP_DIR/valid-minimal.json"

# Test 2: Valid full configuration with all optional fields
cat > "$TEMP_DIR/valid-full.json" << 'EOF'
{
  "federation": {
    "name": "Full Test Federation",
    "baseURL": "https://example.com",
    "strategy": "download-merge-deploy",
    "build_settings": {
      "parallel": true,
      "max_parallel_builds": 5,
      "cache_enabled": true,
      "performance_tracking": true,
      "fail_fast": false
    }
  },
  "modules": [
    {
      "name": "test-module",
      "source": {
        "repository": "https://github.com/example/repo",
        "path": "docs",
        "branch": "main"
      },
      "destination": "/test/",
      "module_json": "module.json",
      "css_path_prefix": "/test",
      "overrides": {
        "baseURL": "https://example.com",
        "theme": "compose"
      },
      "build_options": {
        "cache_enabled": true,
        "skip_on_error": false,
        "build_timeout": 600,
        "priority": 100
      }
    }
  ]
}
EOF
run_test "Valid full configuration" "pass" "$TEMP_DIR/valid-full.json"

# Test 3: Missing required field (federation.name)
cat > "$TEMP_DIR/missing-federation-name.json" << 'EOF'
{
  "federation": {
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
run_test "Missing federation.name" "fail" "$TEMP_DIR/missing-federation-name.json"

# Test 4: Invalid baseURL (trailing slash)
cat > "$TEMP_DIR/invalid-baseurl.json" << 'EOF'
{
  "federation": {
    "name": "Test",
    "baseURL": "https://example.com/",
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
run_test "Invalid baseURL (trailing slash)" "fail" "$TEMP_DIR/invalid-baseurl.json"

# Test 5: Invalid strategy enum
cat > "$TEMP_DIR/invalid-strategy.json" << 'EOF'
{
  "federation": {
    "name": "Test",
    "baseURL": "https://example.com",
    "strategy": "invalid-strategy"
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
run_test "Invalid strategy enum" "fail" "$TEMP_DIR/invalid-strategy.json"

# Test 6: Invalid module name (uppercase)
cat > "$TEMP_DIR/invalid-module-name.json" << 'EOF'
{
  "federation": {
    "name": "Test",
    "baseURL": "https://example.com",
    "strategy": "download-merge-deploy"
  },
  "modules": [
    {
      "name": "Test_Module_With_Uppercase",
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
run_test "Invalid module name (uppercase)" "fail" "$TEMP_DIR/invalid-module-name.json"

# Test 7: Invalid destination (no leading slash)
cat > "$TEMP_DIR/invalid-destination.json" << 'EOF'
{
  "federation": {
    "name": "Test",
    "baseURL": "https://example.com",
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
      "destination": "no-slash",
      "module_json": "module.json"
    }
  ]
}
EOF
run_test "Invalid destination (no leading slash)" "fail" "$TEMP_DIR/invalid-destination.json"

# Test 8: Empty modules array
cat > "$TEMP_DIR/empty-modules.json" << 'EOF'
{
  "federation": {
    "name": "Test",
    "baseURL": "https://example.com",
    "strategy": "download-merge-deploy"
  },
  "modules": []
}
EOF
run_test "Empty modules array" "fail" "$TEMP_DIR/empty-modules.json"

# Test 9: Missing required module field (source)
cat > "$TEMP_DIR/missing-module-source.json" << 'EOF'
{
  "federation": {
    "name": "Test",
    "baseURL": "https://example.com",
    "strategy": "download-merge-deploy"
  },
  "modules": [
    {
      "name": "test-module",
      "destination": "/",
      "module_json": "module.json"
    }
  ]
}
EOF
run_test "Missing module.source" "fail" "$TEMP_DIR/missing-module-source.json"

# Test 10: Valid GitHub repository URL
cat > "$TEMP_DIR/valid-github-url.json" << 'EOF'
{
  "federation": {
    "name": "Test",
    "baseURL": "https://example.com",
    "strategy": "download-merge-deploy"
  },
  "modules": [
    {
      "name": "test-module",
      "source": {
        "repository": "https://github.com/info-tech-io/hugo-templates",
        "path": "docs",
        "branch": "main"
      },
      "destination": "/",
      "module_json": "module.json"
    }
  ]
}
EOF
run_test "Valid GitHub repository URL" "pass" "$TEMP_DIR/valid-github-url.json"

# Test 11: Invalid repository URL (not GitHub)
cat > "$TEMP_DIR/invalid-repo-url.json" << 'EOF'
{
  "federation": {
    "name": "Test",
    "baseURL": "https://example.com",
    "strategy": "download-merge-deploy"
  },
  "modules": [
    {
      "name": "test-module",
      "source": {
        "repository": "https://gitlab.com/example/repo",
        "path": "docs",
        "branch": "main"
      },
      "destination": "/",
      "module_json": "module.json"
    }
  ]
}
EOF
run_test "Invalid repository URL (not GitHub)" "fail" "$TEMP_DIR/invalid-repo-url.json"

# Test 12: Valid empty css_path_prefix
cat > "$TEMP_DIR/valid-empty-css-prefix.json" << 'EOF'
{
  "federation": {
    "name": "Test",
    "baseURL": "https://example.com",
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
      "module_json": "module.json",
      "css_path_prefix": ""
    }
  ]
}
EOF
run_test "Valid empty css_path_prefix" "pass" "$TEMP_DIR/valid-empty-css-prefix.json"

# Test 13-16: Test existing example files
run_test "Example: test-modules.json" "pass" "$PROJECT_ROOT/test-modules.json"
run_test "Example: modules-simple.json" "pass" "$PROJECT_ROOT/docs/content/examples/modules-simple.json"
run_test "Example: modules-infotech.json" "pass" "$PROJECT_ROOT/docs/content/examples/modules-infotech.json"
run_test "Example: modules-advanced.json" "pass" "$PROJECT_ROOT/docs/content/examples/modules-advanced.json"

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Test Summary"
echo "═══════════════════════════════════════════════════════════"
echo "Total tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed:    $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Tests failed:    $TESTS_FAILED${NC}"
    echo ""
    echo "Some tests failed. Please review the errors above."
    exit 1
else
    echo "Tests failed:    0"
    echo ""
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
fi
