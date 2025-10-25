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

    # Save original PROJECT_ROOT (set by tests)
    export ORIGINAL_PROJECT_ROOT="$PROJECT_ROOT"

    # Create isolated PROJECT_ROOT in temp directory
    export PROJECT_ROOT="$TEST_TEMP_DIR/project"
    mkdir -p "$PROJECT_ROOT"

    # Create isolated template and themes directories
    export TEST_TEMPLATES_DIR="$PROJECT_ROOT/templates"
    export TEST_THEMES_DIR="$PROJECT_ROOT/themes"
    mkdir -p "$TEST_TEMPLATES_DIR"
    mkdir -p "$TEST_THEMES_DIR"

    # Copy real templates if they exist
    if [[ -d "$ORIGINAL_PROJECT_ROOT/templates" ]]; then
        cp -r "$ORIGINAL_PROJECT_ROOT/templates"/* "$TEST_TEMPLATES_DIR/" 2>/dev/null || true
    fi

    # Copy real themes if they exist
    if [[ -d "$ORIGINAL_PROJECT_ROOT/themes" ]]; then
        cp -r "$ORIGINAL_PROJECT_ROOT/themes"/* "$TEST_THEMES_DIR/" 2>/dev/null || true
    fi

    # Copy scripts to isolated project root
    if [[ -d "$ORIGINAL_PROJECT_ROOT/scripts" ]]; then
        cp -r "$ORIGINAL_PROJECT_ROOT/scripts" "$PROJECT_ROOT/" 2>/dev/null || true
    fi

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

    # Restore original PROJECT_ROOT
    if [[ -n "$ORIGINAL_PROJECT_ROOT" ]]; then
        export PROJECT_ROOT="$ORIGINAL_PROJECT_ROOT"
    fi

    # Cleanup temporary files
    [[ -n "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"

    # Restore original directory
    [[ -n "$ORIGINAL_PWD" ]] && cd "$ORIGINAL_PWD"

    # Clear test variables
    unset TEST_TEMP_DIR ORIGINAL_PWD TEST_TEMPLATES_DIR TEST_THEMES_DIR ORIGINAL_PROJECT_ROOT
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
# Use real Node.js for actual execution
REAL_NODE=$(command -v nodejs || command -v node | grep -v "^$TEST_TEMP_DIR" | head -1)

# If real Node.js exists and script is being executed, use it
if [[ -n "$REAL_NODE" && -f "$1" ]]; then
    exec "$REAL_NODE" "$@"
fi

# Fallback for --version check
if [[ "$1" == "--version" ]]; then
    echo "v18.0.0"
    exit 0
fi

# Fallback mock for simple cases (shouldn't be reached with real node)
config_file="$2"
if [[ -f "$config_file" ]]; then
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

# Function to run a command with 'set -e' temporarily disabled.
# This is crucial for tests that need to check for non-zero exit codes,
# as the main scripts use 'set -e' which would terminate the script
# before BATS can capture the status.
run_safely() {
    # Disable 'set -e' for this function's scope
    set +e

    # Execute all arguments passed to this function as a command
    "$@"

    # Capture the exit code of the command
    local exit_code=$?

    # Re-enable 'set -e' if it was active before
    # (This depends on the shell's behavior, often 'set -e' is inherited)
    # A simple 'set -e' might be too broad, so we just return the code.

    return $exit_code
}

# Helper functions for build function tests (Stage 5)

# Create a test hugo.toml configuration file
create_test_hugo_config() {
    local hugo_config="$1"
    local base_url="${2:-http://localhost:1313}"
    local theme="${3:-compose}"
    local title="${4:-Test Site}"

    cat > "$hugo_config" << EOF
baseURL = '$base_url'
languageCode = 'en-us'
title = '$title'
theme = '$theme'
EOF
}

# Create an invalid/malformed hugo.toml
create_invalid_hugo_config() {
    local hugo_config="$1"
    echo "invalid toml syntax [[[" > "$hugo_config"
}

# Assert file contains specific string
assert_file_contains() {
    local file="$1"
    local expected="$2"

    [[ -f "$file" ]] || {
        echo "File does not exist: $file" >&2
        return 1
    }

    local content
    content=$(cat "$file")

    [[ "$content" == *"$expected"* ]] || {
        echo "Expected file '$file' to contain '$expected'" >&2
        echo "File content:" >&2
        echo "$content" >&2
        return 1
    }
}

# Assert file does NOT contain specific string
assert_file_not_contains() {
    local file="$1"
    local unexpected="$2"

    [[ -f "$file" ]] || {
        echo "File does not exist: $file" >&2
        return 1
    }

    local content
    content=$(cat "$file")

    [[ "$content" != *"$unexpected"* ]] || {
        echo "Expected file '$file' to NOT contain '$unexpected'" >&2
        return 1
    }
}

# Create minimal test template structure for build tests
create_minimal_test_template() {
    local template_dir="$1"
    local template_name="${2:-minimal}"

    mkdir -p "$template_dir/$template_name"
    echo "# $template_name" > "$template_dir/$template_name/README.md"

    # Create minimal hugo.toml
    create_test_hugo_config "$template_dir/$template_name/hugo.toml"

    # Create minimal content
    mkdir -p "$template_dir/$template_name/content"
    echo "# Home" > "$template_dir/$template_name/content/_index.md"
}

# Structured Logging Test Helpers (Issue #31)
# These helpers handle the structured logging format introduced in Child #20

# Assert log message exists (handles structured logging format)
#
# Usage:
#   assert_log_message "$output" "Expected message" "INFO"
#   assert_log_message "$output" "Build completed" "SUCCESS"
#
# Arguments:
#   $1 - Output to search (typically $output from BATS run)
#   $2 - Expected message content (substring match)
#   $3 - Expected log level (INFO|SUCCESS|WARN|ERROR|FATAL) [optional]
#
# Returns:
#   0 - Message found with correct log level
#   1 - Message not found or incorrect log level
#
assert_log_message() {
  local output="$1"
  local expected_message="$2"
  local expected_level="${3:-}"  # Optional

  # Strip ANSI escape codes
  local clean_output
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')

  # Strip timestamps (format: [YYYY-MM-DDTHH:MM:SS+00:00])
  clean_output=$(echo "$clean_output" | sed 's/\[[0-9-]*T[0-9:+]*\]//g')

  # Check message exists
  if ! echo "$clean_output" | grep -qF "$expected_message"; then
    echo "Expected message not found: '$expected_message'"
    echo "Actual output (cleaned):"
    echo "$clean_output"
    return 1
  fi

  # Check log level if specified
  if [[ -n "$expected_level" ]]; then
    if ! echo "$clean_output" | grep -qF "[$expected_level]"; then
      echo "Expected log level not found: [$expected_level]"
      echo "Actual output (cleaned):"
      echo "$clean_output"
      return 1
    fi
  fi

  return 0
}

# Assert log message with category
#
# Usage:
#   assert_log_message_with_category "$output" "Build started" "INFO" "BUILD"
#
# Arguments:
#   $1 - Output to search
#   $2 - Expected message content
#   $3 - Expected log level
#   $4 - Expected category
#
# Returns:
#   0 - Message found with correct level and category
#   1 - Message/level/category not found
#
assert_log_message_with_category() {
  local output="$1"
  local expected_message="$2"
  local expected_level="$3"
  local expected_category="$4"

  # First check message and level
  assert_log_message "$output" "$expected_message" "$expected_level" || return 1

  # Then check category
  local clean_output
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/\[[0-9-]*T[0-9:+]*\]//g')

  if ! echo "$clean_output" | grep -qF "[$expected_category]"; then
    echo "Expected category not found: [$expected_category]"
    return 1
  fi

  return 0
}