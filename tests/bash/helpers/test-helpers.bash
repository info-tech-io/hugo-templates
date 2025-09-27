#!/usr/bin/env bash

#
# Test Helpers for Hugo Templates Framework
# Provides common utilities and mock functions for bash testing
#

# Load error handling system for tests
ERROR_HANDLING_SCRIPT=""
if [[ -f "$BATS_TEST_DIRNAME/../../../scripts/error-handling.sh" ]]; then
    ERROR_HANDLING_SCRIPT="$BATS_TEST_DIRNAME/../../../scripts/error-handling.sh"
elif [[ -f "${BATS_TEST_DIRNAME%/*/*/*}/scripts/error-handling.sh" ]]; then
    ERROR_HANDLING_SCRIPT="${BATS_TEST_DIRNAME%/*/*/*}/scripts/error-handling.sh"
elif [[ -f "scripts/error-handling.sh" ]]; then
    ERROR_HANDLING_SCRIPT="scripts/error-handling.sh"
fi

if [[ -n "$ERROR_HANDLING_SCRIPT" ]]; then
    source "$ERROR_HANDLING_SCRIPT" 2>/dev/null || true
fi

# Safe error handling initialization for tests
init_test_error_handling() {
    # Avoid double initialization
    if [[ "$ERROR_HANDLING_INITIALIZED" == "true" ]]; then
        return 0
    fi

    # Initialize error handling without trap conflicts and readonly conflicts
    if command -v init_error_handling >/dev/null 2>&1; then
        # Set flag to skip readonly variable initialization in tests
        export TEST_MODE="true"
        init_error_handling 2>/dev/null || true
    fi

    # Set safe defaults for testing
    export ERROR_COUNT=0
    export WARNING_COUNT=0
    export ERROR_CONTEXT=""
    export ERROR_FUNCTION=""
    export ERROR_HANDLING_INITIALIZED="true"
}

# Safe error handling cleanup for tests
cleanup_test_error_handling() {
    if command -v cleanup_error_handling >/dev/null 2>&1; then
        cleanup_error_handling 2>/dev/null || true
    fi
    export ERROR_HANDLING_INITIALIZED="false"
}

# Test environment setup
setup_test_environment() {
    # Create temporary test directory
    export TEST_TEMP_DIR=$(mktemp -d)
    export ORIGINAL_PWD="$PWD"

    # Mock external dependencies
    setup_mocks

    # Initialize error handling safely for tests
    init_test_error_handling

    # Initialize test-specific variables
    export LOG_LEVEL="debug"
    export DEBUG_MODE="false"
    export VERBOSE="false"
}

teardown_test_environment() {
    # Cleanup error handling safely
    cleanup_test_error_handling

    # Cleanup temporary files
    [[ -n "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"

    # Restore original directory
    [[ -n "$ORIGINAL_PWD" ]] && cd "$ORIGINAL_PWD"

    # Clear test variables
    unset TEST_TEMP_DIR ORIGINAL_PWD
}

# Mock external dependencies
setup_mocks() {
    # Create mock Hugo binary
    mkdir -p "$TEST_TEMP_DIR/bin"
    cat > "$TEST_TEMP_DIR/bin/hugo" << 'EOF'
#!/bin/bash
echo "Hugo Static Site Generator v0.148.0 linux/amd64 BuildDate=2024-09-01T00:00:00Z"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/bin/hugo"

    # Create mock Node.js binary
    cat > "$TEST_TEMP_DIR/bin/node" << 'EOF'
#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "v18.0.0"
    exit 0
fi

# Mock Node.js script execution
script_content=$(cat "$1" 2>/dev/null || echo "")
config_file="$2"

# Simple JSON parsing mock
if [[ -f "$config_file" ]]; then
    # Return mock configuration
    echo "TEMPLATE=corporate"
    echo "THEME=compose"
    echo "BASE_URL=http://localhost:1313"
fi
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/bin/node"

    # Add mock binaries to PATH
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
}

# Create test fixtures
create_test_module_config() {
    local config_file="$1"
    local template="${2:-corporate}"
    local theme="${3:-compose}"

    cat > "$config_file" << EOF
{
  "hugo_config": {
    "template": "$template",
    "theme": "$theme",
    "components": ["quiz-engine"]
  },
  "site": {
    "baseURL": "http://localhost:1313",
    "language": "en"
  }
}
EOF
}

create_test_components_yml() {
    local components_file="$1"

    cat > "$components_file" << 'EOF'
components:
  - name: quiz-engine
    version: "1.0.0"
    source: "github:info-tech-io/quiz"
    enabled: true
EOF
}

create_test_template_structure() {
    local template_dir="$1"
    local template_name="${2:-corporate}"

    mkdir -p "$template_dir/$template_name"

    # Create basic template files
    echo "# $template_name Template" > "$template_dir/$template_name/README.md"

    # Create hugo.toml
    cat > "$template_dir/$template_name/hugo.toml" << EOF
baseURL = 'http://localhost:1313'
languageCode = 'en-us'
title = 'Test Site'
theme = 'compose'
EOF

    # Create content structure
    mkdir -p "$template_dir/$template_name/content"
    echo "# Test Content" > "$template_dir/$template_name/content/_index.md"

    # Create components.yml if needed
    if [[ "$template_name" == "corporate" ]]; then
        create_test_components_yml "$template_dir/$template_name/components.yml"
    fi
}

# Assertion helpers
assert_file_exists() {
    local file="$1"
    [[ -f "$file" ]] || {
        echo "Expected file to exist: $file" >&2
        return 1
    }
}

assert_directory_exists() {
    local dir="$1"
    [[ -d "$dir" ]] || {
        echo "Expected directory to exist: $dir" >&2
        return 1
    }
}

assert_command_succeeds() {
    local cmd="$1"
    eval "$cmd" || {
        echo "Expected command to succeed: $cmd" >&2
        return 1
    }
}

assert_command_fails() {
    local cmd="$1"
    eval "$cmd" && {
        echo "Expected command to fail: $cmd" >&2
        return 1
    } || return 0
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" == *"$needle"* ]] || {
        echo "Expected '$haystack' to contain '$needle'" >&2
        return 1
    }
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" != *"$needle"* ]] || {
        echo "Expected '$haystack' to not contain '$needle'" >&2
        return 1
    }
}

# Error condition helpers
simulate_missing_file() {
    local file="$1"
    [[ -f "$file" ]] && rm "$file"
}

simulate_permission_error() {
    local file="$1"
    [[ -f "$file" ]] && chmod 000 "$file"
}

simulate_malformed_json() {
    local file="$1"
    echo '{"invalid": json syntax' > "$file"
}

# Performance testing helpers
time_command() {
    local cmd="$1"
    local start_time=$(date +%s%N)
    eval "$cmd"
    local end_time=$(date +%s%N)
    local duration=$((end_time - start_time))
    echo $((duration / 1000000)) # Return milliseconds
}

assert_performance_threshold() {
    local actual_ms="$1"
    local threshold_ms="$2"
    local cmd_description="$3"

    [[ $actual_ms -le $threshold_ms ]] || {
        echo "Performance threshold exceeded: $cmd_description took ${actual_ms}ms (threshold: ${threshold_ms}ms)" >&2
        return 1
    }
}