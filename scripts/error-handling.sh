#!/bin/bash

#
# Hugo Template Factory Framework - Error Handling System v2.0
# Comprehensive error handling and logging infrastructure
#

# Error levels with numeric codes
readonly ERROR_LEVEL_DEBUG=0
readonly ERROR_LEVEL_INFO=1
readonly ERROR_LEVEL_WARN=2
readonly ERROR_LEVEL_ERROR=3
readonly ERROR_LEVEL_FATAL=4

# Error categories for structured logging
readonly ERROR_CAT_CONFIG="CONFIG"
readonly ERROR_CAT_DEPENDENCY="DEPENDENCY"
readonly ERROR_CAT_BUILD="BUILD"
readonly ERROR_CAT_IO="IO"
readonly ERROR_CAT_VALIDATION="VALIDATION"
readonly ERROR_CAT_NETWORK="NETWORK"
readonly ERROR_CAT_SYSTEM="SYSTEM"

# Global error context tracking
declare -g ERROR_CONTEXT=""
declare -g ERROR_FUNCTION=""
declare -g ERROR_LINE=""
declare -g ERROR_STATE_FILE="${TMPDIR:-/tmp}/hugo-build-error-$$.json"
declare -g LOG_FILE="${LOG_FILE:-}"
declare -g ERROR_COUNT=0
declare -g WARNING_COUNT=0

# Colors for terminal output (redefine for consistency)
readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_GRAY='\033[0;90m'
readonly LOG_NC='\033[0m' # No Color

# Function entry/exit tracking for debugging
enter_function() {
    local func_name="$1"
    ERROR_FUNCTION="$func_name"
    ERROR_LINE="${BASH_LINENO[1]}"
    [[ "${DEBUG_MODE:-false}" == "true" ]] && log_debug "ENTER: $func_name:$ERROR_LINE"
    return 0
}

exit_function() {
    [[ "${DEBUG_MODE:-false}" == "true" ]] && log_debug "EXIT: $ERROR_FUNCTION"
    ERROR_FUNCTION=""
    ERROR_LINE=""
}

# Set error context for better diagnostics
set_error_context() {
    ERROR_CONTEXT="$1"
    [[ "${DEBUG_MODE:-false}" == "true" ]] && log_debug "CONTEXT: $ERROR_CONTEXT"
    return 0
}

clear_error_context() {
    ERROR_CONTEXT=""
}

# GitHub Actions integration functions
github_actions_error() {
    local message="$1"
    local context="${2:-}"
    local file="${BASH_SOURCE[2]:-unknown}"
    local line="${BASH_LINENO[1]:-0}"
    echo "::error file=$file,line=$line::$message${context:+ ($context)}"
}

github_actions_warning() {
    local message="$1"
    local file="${BASH_SOURCE[2]:-unknown}"
    local line="${BASH_LINENO[1]:-0}"
    echo "::warning file=$file,line=$line::$message"
}

github_actions_notice() {
    local message="$1"
    echo "::notice::$message"
}

github_actions_debug() {
    local message="$1"
    echo "::debug::$message"
}

# Core structured logging function
log_structured() {
    local level="$1"
    local category="$2"
    local message="$3"
    local context="${4:-}"

    # Build structured log entry
    local timestamp=$(date -Iseconds 2>/dev/null || date)
    local log_entry="[$timestamp] [$level] [$category] $message"

    # Add context information
    [[ -n "$context" ]] && log_entry="$log_entry | Context: $context"
    [[ -n "$ERROR_FUNCTION" ]] && log_entry="$log_entry | Function: $ERROR_FUNCTION:$ERROR_LINE"
    [[ -n "$ERROR_CONTEXT" ]] && log_entry="$log_entry | Operation: $ERROR_CONTEXT"

    # Color selection for terminal output
    local color=""
    case "$level" in
        "FATAL"|"ERROR")
            color="$LOG_RED"
            ((ERROR_COUNT++))
            ;;
        "WARN")
            color="$LOG_YELLOW"
            ((WARNING_COUNT++))
            ;;
        "INFO") color="$LOG_BLUE" ;;
        "DEBUG") color="$LOG_GRAY" ;;
        *) color="$LOG_NC" ;;
    esac

    # Output handling based on level and environment
    local formatted_message="${color}${log_entry}${LOG_NC}"

    case "$level" in
        "FATAL"|"ERROR")
            echo -e "$formatted_message" >&2
            [[ "${CI:-false}" == "true" ]] && github_actions_error "$message" "$context"
            ;;
        "WARN")
            echo -e "$formatted_message" >&2
            [[ "${CI:-false}" == "true" ]] && github_actions_warning "$message"
            ;;
        "INFO")
            [[ "${QUIET:-false}" != "true" ]] && echo -e "$formatted_message"
            [[ "${CI:-false}" == "true" ]] && github_actions_notice "$message"
            ;;
        "DEBUG")
            [[ "${DEBUG_MODE:-false}" == "true" ]] && echo -e "$formatted_message"
            [[ "${CI:-false}" == "true" ]] && github_actions_debug "$message"
            ;;
    esac

    # Log to file if configured
    if [[ -n "$LOG_FILE" ]]; then
        echo "$log_entry" >> "$LOG_FILE" || true
    fi

    # Explicit return for successful logging
    return 0
}

# Convenience logging functions (maintain backward compatibility)
log_debug() {
    log_structured "DEBUG" "GENERAL" "$*"
}

log_info() {
    log_structured "INFO" "GENERAL" "$*"
}

log_success() {
    [[ "${QUIET:-false}" == "true" ]] && return
    echo -e "${LOG_GREEN}✅ $*${LOG_NC}"
    [[ "${CI:-false}" == "true" ]] && github_actions_notice "✅ $*"
}

log_warning() {
    log_structured "WARN" "GENERAL" "$*"
}

log_error() {
    log_structured "ERROR" "GENERAL" "$*"
}

log_fatal() {
    log_structured "FATAL" "GENERAL" "$*"
}

log_verbose() {
    [[ "${VERBOSE:-false}" == "true" ]] && log_debug "$*"
    return 0
}

# Specialized logging functions for different categories
log_config_error() {
    log_structured "ERROR" "$ERROR_CAT_CONFIG" "$1" "${2:-$ERROR_CONTEXT}"
}

log_dependency_error() {
    log_structured "ERROR" "$ERROR_CAT_DEPENDENCY" "$1" "${2:-$ERROR_CONTEXT}"
}

log_build_error() {
    log_structured "ERROR" "$ERROR_CAT_BUILD" "$1" "${2:-$ERROR_CONTEXT}"
}

log_io_error() {
    log_structured "ERROR" "$ERROR_CAT_IO" "$1" "${2:-$ERROR_CONTEXT}"
}

log_validation_error() {
    log_structured "ERROR" "$ERROR_CAT_VALIDATION" "$1" "${2:-$ERROR_CONTEXT}"
}

# Error state preservation for debugging
preserve_error_state() {
    local error_code="${1:-$?}"
    local additional_info="${2:-}"

    local error_file="$ERROR_STATE_FILE"

    # Create comprehensive error state dump
    cat > "$error_file" << EOF
{
    "error": {
        "timestamp": "$(date -Iseconds 2>/dev/null || date)",
        "code": $error_code,
        "function": "${ERROR_FUNCTION:-unknown}",
        "line": "${ERROR_LINE:-unknown}",
        "context": "${ERROR_CONTEXT:-}",
        "additional_info": "${additional_info:-}"
    },
    "build_state": {
        "pwd": "$(pwd)",
        "template": "${TEMPLATE:-}",
        "theme": "${THEME:-}",
        "components": "${COMPONENTS:-}",
        "output": "${OUTPUT:-}",
        "environment": "${ENVIRONMENT:-}",
        "config": "${CONFIG:-}",
        "content": "${CONTENT:-}"
    },
    "system": {
        "os": "$(uname -s 2>/dev/null || echo 'unknown')",
        "arch": "$(uname -m 2>/dev/null || echo 'unknown')",
        "shell": "${BASH_VERSION:-unknown}",
        "hugo_version": "$(hugo version 2>/dev/null || echo 'not found')",
        "node_version": "$(node --version 2>/dev/null || echo 'not found')",
        "git_version": "$(git --version 2>/dev/null || echo 'not found')"
    },
    "environment_vars": {
        "CI": "${CI:-false}",
        "GITHUB_ACTIONS": "${GITHUB_ACTIONS:-false}",
        "GITHUB_WORKSPACE": "${GITHUB_WORKSPACE:-}",
        "RUNNER_OS": "${RUNNER_OS:-}",
        "HOME": "${HOME:-}",
        "PATH": "${PATH:-}"
    },
    "statistics": {
        "error_count": $ERROR_COUNT,
        "warning_count": $WARNING_COUNT
    }
}
EOF

    log_structured "INFO" "STATE" "Error state preserved in $error_file"

    # In CI environment, upload as artifact if possible
    if [[ "${CI:-false}" == "true" ]]; then
        log_structured "INFO" "STATE" "Error state available for artifact collection"
        echo "::notice::Error diagnostics saved to $error_file"
    fi

    # Explicit return for successful state preservation
    return 0
}

# Enhanced command execution with error handling
safe_execute() {
    local cmd="$1"
    local operation="${2:-command execution}"
    local allow_failure="${3:-false}"

    enter_function "safe_execute"
    set_error_context "$operation"

    log_debug "Executing: $cmd"

    local output
    local error_output
    local exit_code

    # Capture both stdout and stderr
    {
        output=$(eval "$cmd" 2>&1)
        exit_code=$?
    }

    if [[ $exit_code -ne 0 ]]; then
        if [[ "$allow_failure" == "true" ]]; then
            log_structured "WARN" "GENERAL" "Command failed but continuing" "Exit code: $exit_code, Command: $cmd"
        else
            log_structured "ERROR" "GENERAL" "Command execution failed" "Exit code: $exit_code, Command: $cmd"
            preserve_error_state $exit_code "Command execution failure"
            clear_error_context
            exit_function
            return $exit_code
        fi
    else
        log_debug "Command completed successfully"
    fi

    echo "$output"
    clear_error_context
    exit_function
    return $exit_code
}

# Safe Node.js execution with comprehensive error handling
safe_node_parse() {
    local script_file="$1"
    local input_file="$2"
    local operation="${3:-Node.js parsing}"

    enter_function "safe_node_parse"
    set_error_context "$operation"

    # Validate prerequisites
    if ! command -v node >/dev/null 2>&1; then
        log_dependency_error "Node.js not available for $operation"
        exit_function
        return 1
    fi

    if [[ ! -f "$script_file" ]]; then
        log_io_error "Script file not found: $script_file"
        exit_function
        return 1
    fi

    if [[ ! -f "$input_file" ]]; then
        log_io_error "Input file not found: $input_file"
        exit_function
        return 1
    fi

    # Execute with comprehensive error capture
    local output
    local exit_code

    log_debug "Parsing $input_file with $script_file"

    output=$(node "$script_file" "$input_file" 2>&1)
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_build_error "Node.js parsing failed for $operation" "Exit code: $exit_code, Output: $output"
        preserve_error_state $exit_code "Node.js parsing failure"
        exit_function
        return $exit_code
    fi

    log_debug "Node.js parsing completed successfully"
    echo "$output"

    clear_error_context
    exit_function
    return 0
}

# File operation safety wrapper
safe_file_operation() {
    local operation="$1"
    local file_path="$2"
    shift 2
    local additional_args=("$@")

    enter_function "safe_file_operation"
    set_error_context "$operation on $file_path"

    case "$operation" in
        "read")
            if [[ ! -f "$file_path" ]]; then
                log_io_error "File not found for reading: $file_path"
                exit_function
                return 1
            fi
            if [[ ! -r "$file_path" ]]; then
                log_io_error "File not readable: $file_path"
                exit_function
                return 1
            fi
            ;;
        "write"|"create")
            local dir_path=$(dirname "$file_path")
            if [[ ! -d "$dir_path" ]]; then
                log_debug "Creating directory: $dir_path"
                mkdir -p "$dir_path" || {
                    log_io_error "Failed to create directory: $dir_path"
                    exit_function
                    return 1
                }
            fi
            ;;
        "delete")
            if [[ ! -e "$file_path" ]]; then
                log_debug "File does not exist, nothing to delete: $file_path"
                exit_function
                return 0
            fi
            ;;
    esac

    log_debug "File operation: $operation on $file_path"
    clear_error_context
    exit_function
    return 0
}

# Trap handler for unexpected errors
error_trap_handler() {
    local exit_code=$?
    local line_number=$1

    if [[ $exit_code -ne 0 ]]; then
        log_structured "FATAL" "SYSTEM" "Unexpected script termination" "Exit code: $exit_code, Line: $line_number"
        preserve_error_state $exit_code "Unexpected termination"

        # Show brief help message
        echo ""
        echo "🔍 Build failed unexpectedly. Error diagnostics saved to: $ERROR_STATE_FILE"
        echo "💡 For troubleshooting help, check the documentation or run with --debug flag"
        echo ""
    fi
}

# Initialize error handling system
init_error_handling() {
    # Set up trap for unexpected errors, unless disabled for testing
    if [[ "${DISABLE_ERROR_TRAP:-false}" != "true" ]]; then
        trap 'error_trap_handler $LINENO' ERR
    fi

    # Initialize error counters
    ERROR_COUNT=0
    WARNING_COUNT=0

    # Create log file if specified
    if [[ -n "${LOG_FILE:-}" ]]; then
        safe_file_operation "create" "$LOG_FILE"
        log_debug "Logging to file: $LOG_FILE"
    fi

    log_debug "Error handling system initialized"

    # Explicit return for successful initialization
    return 0
}

# Cleanup function
cleanup_error_handling() {
    # Show summary if there were issues
    if [[ $ERROR_COUNT -gt 0 ]] || [[ $WARNING_COUNT -gt 0 ]]; then
        echo ""
        log_structured "INFO" "SUMMARY" "Build completed with issues" "Errors: $ERROR_COUNT, Warnings: $WARNING_COUNT"

        if [[ $ERROR_COUNT -gt 0 ]]; then
            echo "🔍 Error diagnostics available in: $ERROR_STATE_FILE"
        fi
    fi

    # Clean up temporary files (keep error state for debugging)
    # Only clean up on successful builds
    if [[ $ERROR_COUNT -eq 0 ]] && [[ -f "$ERROR_STATE_FILE" ]]; then
        rm -f "$ERROR_STATE_FILE" 2>/dev/null || true
    fi

    # Explicit return for successful cleanup
    return 0
}

# Export functions for use in main script
export -f enter_function exit_function set_error_context clear_error_context
export -f log_structured log_debug log_info log_success log_warning log_error log_fatal
export -f log_config_error log_dependency_error log_build_error log_io_error log_validation_error
export -f preserve_error_state safe_execute safe_node_parse safe_file_operation
export -f init_error_handling cleanup_error_handling