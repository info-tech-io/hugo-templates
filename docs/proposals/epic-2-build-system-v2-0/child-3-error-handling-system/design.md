# Error Handling System Design v2.0

## Overview
This document outlines the comprehensive error handling system for hugo-templates build script, addressing current stability issues and providing robust diagnostics.

## Current Problems Identified

### 1. Insufficient Error Diagnostics
- Generic error messages without context
- No structured error information
- Missing file/line information for JSON parsing errors
- No actionable suggestions for resolution

### 2. Inconsistent Error Handling
- Mix of `set +e` / `set -e` patterns
- Some functions fail silently, others abort entire build
- No standardized error classification (fatal vs warning vs info)

### 3. GitHub Actions Integration Issues
- Error messages not compatible with GitHub Actions annotations
- No structured output for CI/CD systems
- Missing artifact preservation for failed builds

### 4. Missing Error Context
- No function call stack tracking
- No build state preservation during failures
- No recovery suggestions or next steps

## Proposed Architecture

### 1. Structured Error System

```bash
# Error levels with numeric codes
readonly ERROR_LEVEL_DEBUG=0
readonly ERROR_LEVEL_INFO=1
readonly ERROR_LEVEL_WARN=2
readonly ERROR_LEVEL_ERROR=3
readonly ERROR_LEVEL_FATAL=4

# Error categories
readonly ERROR_CAT_CONFIG="CONFIG"
readonly ERROR_CAT_DEPENDENCY="DEPENDENCY"
readonly ERROR_CAT_BUILD="BUILD"
readonly ERROR_CAT_IO="IO"
readonly ERROR_CAT_VALIDATION="VALIDATION"
```

### 2. Error Context Tracking

```bash
# Global error context
declare -g ERROR_CONTEXT=""
declare -g ERROR_FUNCTION=""
declare -g ERROR_LINE=""
declare -g ERROR_STATE_FILE=""

# Function entry/exit tracking
function enter_function() {
    ERROR_FUNCTION="$1"
    ERROR_LINE="${BASH_LINENO[1]}"
    log_debug "ENTER: $ERROR_FUNCTION:$ERROR_LINE"
}

function exit_function() {
    log_debug "EXIT: $ERROR_FUNCTION"
    ERROR_FUNCTION=""
}
```

### 3. Comprehensive Logging Infrastructure

```bash
# Structured logging with context
log_structured() {
    local level="$1"
    local category="$2"
    local message="$3"
    local context="${4:-}"

    # Build structured log entry
    local timestamp=$(date -Iseconds)
    local log_entry="[$timestamp] [$level] [$category] $message"

    # Add context if available
    [[ -n "$context" ]] && log_entry="$log_entry | Context: $context"
    [[ -n "$ERROR_FUNCTION" ]] && log_entry="$log_entry | Function: $ERROR_FUNCTION:$ERROR_LINE"

    # Output handling
    case "$level" in
        "ERROR"|"FATAL")
            echo "$log_entry" >&2
            [[ "$CI" == "true" ]] && github_actions_error "$message" "$context"
            ;;
        "WARN")
            echo "$log_entry" >&2
            [[ "$CI" == "true" ]] && github_actions_warning "$message"
            ;;
        *)
            echo "$log_entry"
            ;;
    esac

    # Log to file if configured
    [[ -n "${LOG_FILE:-}" ]] && echo "$log_entry" >> "$LOG_FILE"
}
```

### 4. GitHub Actions Integration

```bash
# GitHub Actions annotations
github_actions_error() {
    local message="$1"
    local context="${2:-}"
    echo "::error file=${BASH_SOURCE[2]},line=${BASH_LINENO[1]}::$message${context:+ ($context)}"
}

github_actions_warning() {
    local message="$1"
    echo "::warning file=${BASH_SOURCE[2]},line=${BASH_LINENO[1]}::$message"
}

github_actions_notice() {
    local message="$1"
    echo "::notice::$message"
}
```

### 5. Error Recovery and State Preservation

```bash
# Error state management
preserve_error_state() {
    local error_code="$1"
    local error_file="${ERROR_STATE_FILE:-/tmp/hugo-build-error.json}"

    cat > "$error_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "error_code": $error_code,
    "function": "${ERROR_FUNCTION:-unknown}",
    "line": "${ERROR_LINE:-unknown}",
    "context": "${ERROR_CONTEXT:-}",
    "pwd": "$(pwd)",
    "environment": {
        "TEMPLATE": "${TEMPLATE:-}",
        "THEME": "${THEME:-}",
        "OUTPUT": "${OUTPUT:-}",
        "ENVIRONMENT": "${ENVIRONMENT:-}"
    },
    "system": {
        "os": "$(uname -s)",
        "arch": "$(uname -m)",
        "hugo_version": "$(hugo version 2>/dev/null || echo 'not found')",
        "node_version": "$(node --version 2>/dev/null || echo 'not found')"
    }
}
EOF

    log_structured "INFO" "STATE" "Error state preserved in $error_file"
}
```

### 6. Improved Function Error Handling

```bash
# Enhanced error handling for critical functions
safe_node_parse() {
    local script_file="$1"
    local input_file="$2"
    local operation="$3"

    enter_function "safe_node_parse"
    ERROR_CONTEXT="Parsing $input_file for $operation"

    # Validate prerequisites
    if ! command -v node >/dev/null 2>&1; then
        log_structured "ERROR" "DEPENDENCY" "Node.js not available for $operation"
        exit_function
        return 1
    fi

    if [[ ! -f "$input_file" ]]; then
        log_structured "ERROR" "IO" "Input file not found: $input_file"
        exit_function
        return 1
    fi

    # Execute with comprehensive error capture
    local output
    local error_output
    local exit_code

    exec 5>&1 6>&2  # Save stdout/stderr
    {
        output=$(node "$script_file" "$input_file" 2>&6)
        exit_code=$?
    } 6>&1

    if [[ $exit_code -ne 0 ]]; then
        log_structured "ERROR" "BUILD" "Node.js parsing failed for $operation" "Exit code: $exit_code"
        preserve_error_state $exit_code
        exit_function
        return $exit_code
    fi

    echo "$output"
    exit_function
    return 0
}
```

## Implementation Plan

### Phase 1: Foundation (2 days)
- [ ] Implement structured logging system
- [ ] Add error context tracking
- [ ] Create GitHub Actions annotation functions

### Phase 2: Function Enhancement (2 days)
- [ ] Refactor `load_module_config` with robust error handling
- [ ] Improve `parse_components` error management
- [ ] Add comprehensive validation functions

### Phase 3: Integration & Testing (1 day)
- [ ] Test error scenarios in GitHub Actions
- [ ] Validate error state preservation
- [ ] Ensure backward compatibility

## Success Metrics

1. **Error Clarity**: All error messages include actionable next steps
2. **GitHub Actions**: 100% compatibility with CI/CD annotations
3. **Diagnostics**: Error state preservation enables rapid troubleshooting
4. **Stability**: No unexpected script termination due to non-critical errors
5. **Performance**: Error handling adds <5% overhead to build time

## Backward Compatibility

All existing log functions (`log_info`, `log_error`, etc.) will be preserved as aliases to new structured logging system, ensuring no breaking changes for existing scripts or templates.