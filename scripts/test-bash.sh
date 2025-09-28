#!/bin/bash
set -euo pipefail

#
# Bash Test Runner for Hugo Templates Framework
# Executes BATS tests with comprehensive reporting
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TESTS_DIR="$PROJECT_ROOT/tests/bash"

# Default configuration
TEST_SUITE="all"
VERBOSE=false
COVERAGE=false
PERFORMANCE=false
PARALLEL=false
OUTPUT_FORMAT="tap"
RESULTS_FILE=""

# Colors for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

print_usage() {
    cat << EOF
Hugo Templates Framework - Bash Test Runner

Usage: $0 [OPTIONS]

Options:
  -s, --suite SUITE      Test suite to run: all, unit, integration, performance (default: all)
  -v, --verbose          Enable verbose output
  -c, --coverage         Enable coverage reporting (requires kcov)
  -p, --performance      Run performance benchmarks
  -j, --parallel         Run tests in parallel (requires bats-core)
  -f, --format FORMAT    Output format: tap, junit, pretty (default: tap)
  -o, --output FILE      Write results to file
  -h, --help             Show this help message

Examples:
  $0                              # Run all tests
  $0 -s unit -v                   # Run unit tests with verbose output
  $0 -s performance -p            # Run performance benchmarks
  $0 -s integration -f junit      # Run integration tests with JUnit output
  $0 -c -o results.xml            # Run with coverage and save results

Test Suites:
  unit          - Unit tests for individual functions
  integration   - End-to-end workflow tests
  performance   - Performance benchmarks and regression tests
  all           - All test suites

Requirements:
  - bats-core (https://github.com/bats-core/bats-core)
  - kcov (optional, for coverage reporting)

EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

check_dependencies() {
    log_info "Checking dependencies..."

    # Check for bats
    if ! command -v bats >/dev/null 2>&1; then
        log_error "bats not found. Please install bats-core:"
        echo "  Ubuntu/Debian: sudo apt-get install bats"
        echo "  macOS: brew install bats-core"
        echo "  Manual: https://github.com/bats-core/bats-core"
        return 1
    fi

    local bats_version
    bats_version=$(bats --version 2>/dev/null | head -1 || echo "unknown")
    log_info "Found bats: $bats_version"

    # Check for kcov if coverage requested
    if [[ "$COVERAGE" == "true" ]]; then
        if ! command -v kcov >/dev/null 2>&1; then
            log_warning "kcov not found. Coverage reporting disabled."
            log_warning "Install kcov for coverage reports: https://github.com/SimonKagstrom/kcov"
            COVERAGE=false
        else
            local kcov_version
            kcov_version=$(kcov --version 2>/dev/null | head -1 || echo "unknown")
            log_info "Found kcov: $kcov_version"
        fi
    fi
}

setup_test_environment() {
    log_info "Setting up test environment..."

    # Create temporary directories
    export BATS_TMPDIR="${TMPDIR:-/tmp}/hugo-tests-$$"
    mkdir -p "$BATS_TMPDIR"

    # Set test-specific environment variables
    export BATS_TEST_TIMEOUT=${BATS_TEST_TIMEOUT:-300}  # 5 minutes per test
    export HUGO_TEMPLATES_TEST_MODE=true

    # Create mock binaries directory
    export MOCK_BINS_DIR="$BATS_TMPDIR/mock-bins"
    mkdir -p "$MOCK_BINS_DIR"

    log_info "Test environment ready: $BATS_TMPDIR"
}

cleanup_test_environment() {
    if [[ -n "${BATS_TMPDIR:-}" ]] && [[ -d "$BATS_TMPDIR" ]]; then
        log_info "Cleaning up test environment: $BATS_TMPDIR"
        rm -rf "$BATS_TMPDIR"
    fi
}

get_test_files() {
    local suite="$1"
    local test_files=()

    case "$suite" in
        "unit")
            test_files=("$TESTS_DIR/unit"/*.bats)
            ;;
        "integration")
            test_files=("$TESTS_DIR/integration"/*.bats)
            ;;
        "performance")
            test_files=("$TESTS_DIR/performance"/*.bats)
            ;;
        "all")
            test_files=(
                "$TESTS_DIR/unit"/*.bats
                "$TESTS_DIR/integration"/*.bats
            )
            if [[ "$PERFORMANCE" == "true" ]]; then
                test_files+=("$TESTS_DIR/performance"/*.bats)
            fi
            ;;
        *)
            log_error "Unknown test suite: $suite"
            return 1
            ;;
    esac

    # Filter out non-existent files
    local existing_files=()
    for file in "${test_files[@]}"; do
        [[ -f "$file" ]] && existing_files+=("$file")
    done

    if [[ ${#existing_files[@]} -eq 0 ]]; then
        log_error "No test files found for suite: $suite"
        return 1
    fi

    printf '%s\n' "${existing_files[@]}"
}

run_bats_tests() {
    local test_files=("$@")
    local bats_args=()

    # Configure BATS arguments
    if [[ "$VERBOSE" == "true" ]]; then
        bats_args+=("--verbose-run")
    fi

    if [[ "$PARALLEL" == "true" ]]; then
        bats_args+=("--jobs" "$(nproc 2>/dev/null || echo 4)")
    fi

    case "$OUTPUT_FORMAT" in
        "tap")
            bats_args+=("--formatter" "tap")
            ;;
        "junit")
            bats_args+=("--formatter" "junit")
            ;;
        "pretty")
            bats_args+=("--formatter" "pretty")
            ;;
    esac

    if [[ -n "$RESULTS_FILE" ]]; then
        log_info "Running tests and saving results to: $RESULTS_FILE"
        bats "${bats_args[@]}" "${test_files[@]}" | tee "$RESULTS_FILE"
        local exit_code=${PIPESTATUS[0]}
    else
        log_info "Running tests..."
        bats "${bats_args[@]}" "${test_files[@]}"
        local exit_code=$?
    fi

    return $exit_code
}

run_coverage_tests() {
    local test_files=("$@")
    local coverage_dir="$PROJECT_ROOT/coverage/bash"

    log_info "Running tests with coverage analysis..."
    mkdir -p "$coverage_dir"

    # Run each test file with kcov
    local overall_exit_code=0
    for test_file in "${test_files[@]}"; do
        local test_name
        test_name=$(basename "$test_file" .bats)
        local test_coverage_dir="$coverage_dir/$test_name"

        log_info "Running coverage for: $test_name"

        if ! kcov \
            --exclude-pattern=/tmp,/usr \
            --include-pattern="$PROJECT_ROOT/scripts" \
            "$test_coverage_dir" \
            bats "$test_file"; then
            overall_exit_code=1
        fi
    done

    # Generate combined coverage report
    if command -v kcov >/dev/null 2>&1; then
        log_info "Generating combined coverage report..."
        kcov --merge "$coverage_dir/combined" "$coverage_dir"/*/
        log_success "Coverage report available at: $coverage_dir/combined/index.html"
    fi

    return $overall_exit_code
}

generate_test_report() {
    local exit_code="$1"
    local start_time="$2"
    local end_time="$3"

    local duration=$((end_time - start_time))
    local duration_formatted="${duration}s"

    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "Suite: $TEST_SUITE"
    echo "Duration: $duration_formatted"
    echo "Coverage: $([ "$COVERAGE" == "true" ] && echo "enabled" || echo "disabled")"
    echo "Performance: $([ "$PERFORMANCE" == "true" ] && echo "enabled" || echo "disabled")"

    if [[ $exit_code -eq 0 ]]; then
        log_success "All tests passed!"
        echo "Status: PASSED"
    else
        log_error "Some tests failed!"
        echo "Status: FAILED"
    fi

    if [[ -n "$RESULTS_FILE" ]]; then
        echo "Results: $RESULTS_FILE"
    fi

    if [[ "$COVERAGE" == "true" ]]; then
        echo "Coverage Report: $PROJECT_ROOT/coverage/bash/combined/index.html"
    fi

    echo "=========================================="
}

main() {
    local start_time
    start_time=$(date +%s)

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--suite)
                TEST_SUITE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -c|--coverage)
                COVERAGE=true
                shift
                ;;
            -p|--performance)
                PERFORMANCE=true
                shift
                ;;
            -j|--parallel)
                PARALLEL=true
                shift
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -o|--output)
                RESULTS_FILE="$2"
                shift 2
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
    if [[ ! "$TEST_SUITE" =~ ^(all|unit|integration|performance)$ ]]; then
        log_error "Invalid test suite: $TEST_SUITE"
        exit 1
    fi

    if [[ ! "$OUTPUT_FORMAT" =~ ^(tap|junit|pretty)$ ]]; then
        log_error "Invalid output format: $OUTPUT_FORMAT"
        exit 1
    fi

    # Main execution
    log_info "Hugo Templates Framework - Bash Test Runner"
    log_info "Test suite: $TEST_SUITE"

    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    # Setup environment
    setup_test_environment
    trap cleanup_test_environment EXIT

    # Get test files
    local test_files
    if ! test_files=($(get_test_files "$TEST_SUITE")); then
        exit 1
    fi

    log_info "Found ${#test_files[@]} test file(s)"

    # Run tests
    local exit_code=0
    if [[ "$COVERAGE" == "true" ]]; then
        run_coverage_tests "${test_files[@]}" || exit_code=$?
    else
        run_bats_tests "${test_files[@]}" || exit_code=$?
    fi

    # Generate report
    local end_time
    end_time=$(date +%s)
    generate_test_report "$exit_code" "$start_time" "$end_time"

    exit $exit_code
}

# Run main function
main "$@"