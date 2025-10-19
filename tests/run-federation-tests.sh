#!/usr/bin/env bash
set -euo pipefail

#
# Federation Test Runner
# Runs both legacy shell script tests and new BATS tests for federation
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default configuration
LAYER="all"  # all, layer1, layer2, shell, integration
VERBOSE="false"
QUIET="false"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

print_usage() {
    cat << EOF
Federation Test Runner - Hugo Templates Framework

Usage: $0 [OPTIONS]

Options:
  -l, --layer LAYER    Layer filter: all, layer1, layer2, shell, integration (default: all)
  -v, --verbose        Enable verbose output
  -q, --quiet          Suppress non-essential output
  -h, --help           Show this help message

Layer Filters:
  all           - Run all federation tests (legacy shell + BATS)
  layer1        - Run Layer 1 tests only (build.sh BATS tests - 78 tests)
  layer2        - Run Layer 2 tests only (federated-build.sh BATS tests)
  shell         - Run legacy shell script tests only (37 tests)
  integration   - Run integration tests only (Layer 1 + Layer 2 interaction)

Examples:
  $0                    # Run all federation tests
  $0 -l shell           # Run legacy shell tests only
  $0 -l layer2 -v       # Run Layer 2 BATS tests with verbose output
  $0 -l integration     # Run integration tests only

EOF
}

log_info() {
    [[ "$QUIET" == "true" ]] && return
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $*"
}

run_shell_tests() {
    log_info "Running legacy shell script tests..."

    local shell_tests=(
        "$SCRIPT_DIR/test-schema-validation.sh"
        "$SCRIPT_DIR/test-css-path-detection.sh"
        "$SCRIPT_DIR/test-css-path-rewriting.sh"
        "$SCRIPT_DIR/test-download-pages.sh"
        "$SCRIPT_DIR/test-intelligent-merge.sh"
    )

    local tests_run=0
    local tests_passed=0
    local tests_failed=0

    for test_file in "${shell_tests[@]}"; do
        if [[ ! -f "$test_file" ]]; then
            log_warning "Test file not found: $test_file (skipping)"
            continue
        fi

        local test_name=$(basename "$test_file" .sh)
        log_info "Running: $test_name"

        if [[ "$VERBOSE" == "true" ]]; then
            if bash "$test_file"; then
                ((tests_passed++))
                log_success "$test_name"
            else
                ((tests_failed++))
                log_error "$test_name FAILED"
            fi
        else
            if bash "$test_file" >/dev/null 2>&1; then
                ((tests_passed++))
                log_success "$test_name"
            else
                ((tests_failed++))
                log_error "$test_name FAILED"
            fi
        fi

        ((tests_run++))
    done

    TOTAL_TESTS=$((TOTAL_TESTS + tests_run))
    PASSED_TESTS=$((PASSED_TESTS + tests_passed))
    FAILED_TESTS=$((FAILED_TESTS + tests_failed))

    log_info "Shell tests complete: $tests_passed/$tests_run passed"
    return $(( tests_failed > 0 ? 1 : 0 ))
}

run_bats_tests() {
    local layer="$1"
    log_info "Running BATS tests for layer: $layer"

    # Use the main test runner with federation suite
    local runner="$PROJECT_ROOT/scripts/test-bash.sh"

    if [[ ! -f "$runner" ]]; then
        log_error "Test runner not found: $runner"
        return 1
    fi

    local args=("-s" "federation" "-l" "$layer")

    if [[ "$VERBOSE" == "true" ]]; then
        args+=("-v")
    fi

    # Run BATS tests
    if bash "$runner" "${args[@]}"; then
        log_success "BATS tests passed for layer: $layer"
        return 0
    else
        log_error "BATS tests failed for layer: $layer"
        return 1
    fi
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--layer)
                LAYER="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -q|--quiet)
                QUIET="true"
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    # Validation
    if [[ ! "$LAYER" =~ ^(all|layer1|layer2|shell|integration)$ ]]; then
        log_error "Invalid layer filter: $LAYER"
        exit 1
    fi

    echo "════════════════════════════════════════════════════════════"
    echo "  Federation Test Runner"
    echo "════════════════════════════════════════════════════════════"
    echo "Layer: $LAYER"
    echo "Verbose: $VERBOSE"
    echo ""

    local overall_result=0

    # Execute tests based on layer filter
    case "$LAYER" in
        "all")
            # Run all federation tests
            log_info "Running ALL federation tests (shell + BATS)"

            # 1. Legacy shell tests
            if ! run_shell_tests; then
                overall_result=1
            fi

            echo ""

            # 2. BATS tests (all layers)
            if ! run_bats_tests "all"; then
                overall_result=1
            fi
            ;;

        "shell")
            # Run legacy shell tests only
            if ! run_shell_tests; then
                overall_result=1
            fi
            ;;

        "layer1"|"layer2"|"integration")
            # Run BATS tests for specific layer
            if ! run_bats_tests "$LAYER"; then
                overall_result=1
            fi
            ;;
    esac

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  Test Summary"
    echo "════════════════════════════════════════════════════════════"

    if [[ $overall_result -eq 0 ]]; then
        log_success "ALL TESTS PASSED"
        echo "Status: ✅ SUCCESS"
    else
        log_error "SOME TESTS FAILED"
        echo "Status: ❌ FAILURE"
    fi

    echo "════════════════════════════════════════════════════════════"

    exit $overall_result
}

# Run main function
main "$@"
