#!/bin/bash
set -euo pipefail

#
# Hugo Template Factory Framework - Federated Build Script v1.0
# Multi-site federation orchestration for GitHub Pages
#
# This script orchestrates multiple Hugo site builds to create a federated
# GitHub Pages structure, enabling autonomous product documentation updates
# while maintaining a unified deployment.
#
# Part of Epic #15: Federated Build System for GitHub Pages Federation
#

# Script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load enhanced error handling system
source "$SCRIPT_DIR/error-handling.sh" || {
    echo "FATAL: Cannot load error handling system from $SCRIPT_DIR/error-handling.sh" >&2
    exit 1
}

# Load intelligent caching system
source "$SCRIPT_DIR/cache.sh" || {
    echo "FATAL: Cannot load caching system from $SCRIPT_DIR/cache.sh" >&2
    exit 1
}

# Load performance monitoring system
source "$SCRIPT_DIR/performance.sh" || {
    echo "FATAL: Cannot load performance monitoring system from $SCRIPT_DIR/performance.sh" >&2
    exit 1
}

# Initialize error handling
init_error_handling

# Initialize cache system
init_cache_system

# Initialize performance monitoring system
init_performance_monitoring

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m' # No Color

# Default values
CONFIG="modules.json"
OUTPUT="./public"
VERBOSE=false
QUIET=false
VALIDATE_ONLY=false
DEBUG_MODE=false
ENABLE_PARALLEL=false
ENABLE_PERFORMANCE_TRACKING=false
PRESERVE_BASE_SITE=false
DRY_RUN=false

# Federation state variables
TEMP_DIR=""
MODULES_COUNT=0
SUCCESSFUL_BUILDS=0
FAILED_BUILDS=0

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Logging functions
log_info() {
    [[ "$QUIET" == "true" ]] && return
    print_color "$BLUE" "ℹ️  $*"
}

log_success() {
    [[ "$QUIET" == "true" ]] && return
    print_color "$GREEN" "✅ $*"
}

log_warning() {
    [[ "$QUIET" == "true" ]] && return
    print_color "$YELLOW" "⚠️  $*"
}

log_error() {
    print_color "$RED" "❌ $*" >&2
}

log_verbose() {
    [[ "$VERBOSE" == "true" ]] || return 0
    print_color "$GRAY" "🔍 $*"
    return 0
}

log_federation() {
    [[ "$QUIET" == "true" ]] && return
    print_color "$CYAN" "🌐 $*"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Hugo Template Factory Framework - Federated Build Script

Build multiple Hugo sites from different repositories into a unified
federated GitHub Pages structure with automatic CSS path resolution.

OPTIONS:
    --config <path>             Path to modules.json configuration (default: modules.json)
    -o, --output <path>         Federation output directory (default: ./public)
    --preserve-base-site        Preserve existing base site content during merge
    --parallel                  Enable parallel module builds (experimental)
    --dry-run                   Show what would be built without executing
    --validate-only             Only validate configuration, don't build
    -v, --verbose               Enable verbose output
    -q, --quiet                 Suppress non-error output
    --debug                     Enable debug mode with detailed tracing
    --performance-track         Enable performance monitoring and tracking
    -h, --help                  Show this help message

EXAMPLES:
    # Basic federation build
    $0 --config=modules.json

    # Build with custom output directory
    $0 --config=federation.json --output=dist/

    # Validate configuration without building
    $0 --config=modules.json --validate-only

    # Build with verbose output and performance tracking
    $0 --verbose --performance-track

    # Dry run to see what would be built
    $0 --config=modules.json --dry-run

CONFIGURATION:
    The modules.json file defines the federation structure with:
    - Federation metadata (name, baseURL, strategy)
    - Array of modules with source repositories
    - Per-module configuration (destination, CSS paths, overrides)

    See docs/user-guides/modules-json-reference.md for full schema.

ARCHITECTURE:
    Layer 2 (Federation): federated-build.sh + modules.json
              ↓ orchestrates
    Layer 1 (Individual): build.sh + module.json (unchanged)

    Zero breaking changes to existing build system.

EOF
}

# Parse command-line arguments
parse_arguments() {
    enter_function "parse_arguments"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --config=*)
                CONFIG="${1#*=}"
                shift
                ;;
            --config)
                CONFIG="$2"
                shift 2
                ;;
            --output=*)
                OUTPUT="${1#*=}"
                shift
                ;;
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            --preserve-base-site)
                PRESERVE_BASE_SITE=true
                shift
                ;;
            --parallel)
                ENABLE_PARALLEL=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --validate-only)
                VALIDATE_ONLY=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                VERBOSE=true
                shift
                ;;
            --performance-track)
                ENABLE_PERFORMANCE_TRACKING=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    exit_function
}

# Load and validate modules.json configuration
load_modules_config() {
    enter_function "load_modules_config"

    set_error_context "Loading federation configuration from $CONFIG"

    # Validate configuration file exists and is readable
    if [[ ! -f "$CONFIG" ]]; then
        log_config_error "Configuration file not found: $CONFIG"
        exit_function
        return 1
    fi

    if [[ ! -r "$CONFIG" ]]; then
        log_config_error "Configuration file not readable: $CONFIG"
        exit_function
        return 1
    fi

    log_info "Loading federation configuration from: $CONFIG"

    # Use Node.js for JSON parsing with comprehensive error handling
    if ! command -v node >/dev/null 2>&1; then
        log_dependency_error "Node.js is required for JSON parsing but not found"
        log_error "Please install Node.js 18+ to use federated builds"
        exit_function
        return 1
    fi

    # Create temporary parsing script
    local temp_script
    temp_script=$(mktemp) || {
        log_io_error "Failed to create temporary script file"
        exit_function
        return 1
    }

    # Enhanced Node.js script for modules.json parsing
    cat > "$temp_script" << 'EOF'
const fs = require('fs');

try {
    // Read and validate file
    const configFile = process.argv[2];
    if (!fs.existsSync(configFile)) {
        console.error(`ERROR: Configuration file not found: ${configFile}`);
        process.exit(1);
    }

    const configContent = fs.readFileSync(configFile, 'utf8');
    if (!configContent.trim()) {
        console.error(`ERROR: Configuration file is empty: ${configFile}`);
        process.exit(1);
    }

    // Parse JSON with detailed error reporting
    let config;
    try {
        config = JSON.parse(configContent);
    } catch (parseError) {
        console.error(`ERROR: Invalid JSON in ${configFile}:`);
        console.error(`  ${parseError.message}`);
        process.exit(1);
    }

    // Validate top-level structure
    if (typeof config !== 'object' || config === null) {
        console.error(`ERROR: Configuration must be a JSON object`);
        process.exit(1);
    }

    // Validate federation section
    if (!config.federation || typeof config.federation !== 'object') {
        console.error(`ERROR: Missing or invalid 'federation' section in configuration`);
        process.exit(1);
    }

    const federation = config.federation;

    // Extract federation metadata
    if (federation.name) {
        console.log('FEDERATION_NAME=' + federation.name);
    }
    if (federation.baseURL) {
        console.log('FEDERATION_BASE_URL=' + federation.baseURL);
    }
    if (federation.strategy) {
        console.log('FEDERATION_STRATEGY=' + federation.strategy);
    }

    // Validate modules array
    if (!config.modules || !Array.isArray(config.modules)) {
        console.error(`ERROR: Missing or invalid 'modules' array in configuration`);
        process.exit(1);
    }

    if (config.modules.length === 0) {
        console.error(`ERROR: Modules array is empty - nothing to build`);
        process.exit(1);
    }

    console.log('MODULES_COUNT=' + config.modules.length);

    // Validate each module
    config.modules.forEach((module, index) => {
        if (typeof module !== 'object' || module === null) {
            console.error(`ERROR: Module at index ${index} is not a valid object`);
            process.exit(1);
        }

        // Required fields
        if (!module.name || typeof module.name !== 'string') {
            console.error(`ERROR: Module at index ${index} missing required 'name' field`);
            process.exit(1);
        }

        if (!module.source || typeof module.source !== 'object') {
            console.error(`ERROR: Module '${module.name}' missing required 'source' object`);
            process.exit(1);
        }

        if (!module.destination || typeof module.destination !== 'string') {
            console.error(`ERROR: Module '${module.name}' missing required 'destination' field`);
            process.exit(1);
        }

        // Output module information (will be parsed by bash)
        console.log(`MODULE_${index}_NAME=${module.name}`);
        console.log(`MODULE_${index}_DESTINATION=${module.destination}`);

        if (module.source.repository) {
            console.log(`MODULE_${index}_REPO=${module.source.repository}`);
        }
        if (module.source.path) {
            console.log(`MODULE_${index}_PATH=${module.source.path}`);
        }
        if (module.source.branch) {
            console.log(`MODULE_${index}_BRANCH=${module.source.branch}`);
        }
        if (module.module_json) {
            console.log(`MODULE_${index}_CONFIG=${module.module_json}`);
        }
        if (module.css_path_prefix) {
            console.log(`MODULE_${index}_CSS_PREFIX=${module.css_path_prefix}`);
        }
    });

    // Success
    process.exit(0);

} catch (error) {
    console.error(`FATAL: Unexpected error parsing configuration:`);
    console.error(`  ${error.message}`);
    process.exit(1);
}
EOF

    # Execute parsing script
    local parse_output
    if parse_output=$(node "$temp_script" "$CONFIG" 2>&1); then
        # Export parsed variables
        while IFS= read -r line; do
            if [[ "$line" =~ ^[A-Z_0-9]+= ]]; then
                eval "export $line"
                log_verbose "Parsed: $line"
            fi
        done <<< "$parse_output"

        rm -f "$temp_script"
        log_success "Configuration loaded: $MODULES_COUNT modules"
        exit_function
        return 0
    else
        log_config_error "Failed to parse configuration file"
        echo "$parse_output" >&2
        rm -f "$temp_script"
        exit_function
        return 1
    fi
}

# Validate configuration values
validate_configuration() {
    enter_function "validate_configuration"

    set_error_context "Validating federation configuration"

    # Check required variables
    if [[ -z "${FEDERATION_NAME:-}" ]]; then
        log_warning "Federation name not specified in configuration"
    fi

    if [[ -z "${MODULES_COUNT:-}" ]] || [[ "$MODULES_COUNT" -eq 0 ]]; then
        log_config_error "No modules defined in configuration"
        exit_function
        return 1
    fi

    log_info "Validating $MODULES_COUNT module(s)"

    # Validate each module has required fields
    for ((i=0; i<MODULES_COUNT; i++)); do
        local module_name_var="MODULE_${i}_NAME"
        local module_dest_var="MODULE_${i}_DESTINATION"

        if [[ -z "${!module_name_var:-}" ]]; then
            log_config_error "Module at index $i missing name"
            exit_function
            return 1
        fi

        if [[ -z "${!module_dest_var:-}" ]]; then
            log_config_error "Module '${!module_name_var}' missing destination"
            exit_function
            return 1
        fi

        log_verbose "Module $i: ${!module_name_var} -> ${!module_dest_var}"
    done

    # Check for destination conflicts
    declare -A destinations
    for ((i=0; i<MODULES_COUNT; i++)); do
        local module_name_var="MODULE_${i}_NAME"
        local module_dest_var="MODULE_${i}_DESTINATION"
        local dest="${!module_dest_var}"

        if [[ -n "${destinations[$dest]:-}" ]]; then
            log_config_error "Destination conflict: '${!module_name_var}' and '${destinations[$dest]}' both target '$dest'"
            exit_function
            return 1
        fi

        destinations[$dest]="${!module_name_var}"
    done

    log_success "Configuration validation passed"
    exit_function
    return 0
}

# Create output directory structure
setup_output_structure() {
    enter_function "setup_output_structure"

    set_error_context "Setting up output directory structure"

    # Create output directory if it doesn't exist
    if [[ ! -d "$OUTPUT" ]]; then
        log_info "Creating output directory: $OUTPUT"
        if [[ "$DRY_RUN" == "false" ]]; then
            if ! mkdir -p "$OUTPUT"; then
                log_io_error "Failed to create output directory: $OUTPUT"
                exit_function
                return 1
            fi
        else
            log_info "[DRY RUN] Would create: $OUTPUT"
        fi
    else
        if [[ "$PRESERVE_BASE_SITE" == "false" ]]; then
            log_warning "Output directory exists and will be overwritten: $OUTPUT"
        else
            log_info "Output directory exists, preserving base site content"
        fi
    fi

    # Create temporary working directory
    if [[ "$DRY_RUN" == "false" ]]; then
        TEMP_DIR=$(mktemp -d) || {
            log_io_error "Failed to create temporary directory"
            exit_function
            return 1
        }
        log_verbose "Created temporary directory: $TEMP_DIR"
    else
        log_info "[DRY RUN] Would create temporary working directory"
    fi

    log_success "Output structure ready"
    exit_function
    return 0
}

# Cleanup function for temporary files
cleanup_temp_files() {
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "$TEMP_DIR" ]]; then
        log_verbose "Cleaning up temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
}

# Register cleanup trap
trap cleanup_temp_files EXIT

# Show federation summary
show_federation_summary() {
    cat << EOF

╔══════════════════════════════════════════════════════════════╗
║          Hugo Template Factory - Federation Build            ║
╚══════════════════════════════════════════════════════════════╝

EOF

    if [[ -n "${FEDERATION_NAME:-}" ]]; then
        print_color "$CYAN" "Federation: $FEDERATION_NAME"
    fi

    if [[ -n "${FEDERATION_BASE_URL:-}" ]]; then
        print_color "$CYAN" "Base URL:   $FEDERATION_BASE_URL"
    fi

    echo ""
    print_color "$MAGENTA" "Modules:    $MODULES_COUNT"
    print_color "$BLUE" "Output:     $OUTPUT"

    if [[ "$ENABLE_PARALLEL" == "true" ]]; then
        print_color "$YELLOW" "Mode:       Parallel builds (experimental)"
    else
        print_color "$BLUE" "Mode:       Sequential builds"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        print_color "$YELLOW" "DRY RUN MODE - No actual builds will be performed"
    fi

    echo ""
}

# Main execution function
main() {
    enter_function "main"

    # Parse arguments
    parse_arguments "$@"

    # Show header
    if [[ "$QUIET" == "false" ]]; then
        show_federation_summary
    fi

    # Load and validate configuration
    if ! load_modules_config; then
        log_error "Failed to load federation configuration"
        exit 1
    fi

    if ! validate_configuration; then
        log_error "Configuration validation failed"
        exit 1
    fi

    # Exit if validation-only mode
    if [[ "$VALIDATE_ONLY" == "true" ]]; then
        log_success "Validation complete - configuration is valid"
        exit 0
    fi

    # Setup output structure
    if ! setup_output_structure; then
        log_error "Failed to setup output structure"
        exit 1
    fi

    # TODO: Stage 2 - Build orchestration will be implemented here
    log_info "Build orchestration not yet implemented (Stage 2)"

    # TODO: Stage 3 - Output management will be implemented here
    log_info "Output management not yet implemented (Stage 3)"

    log_success "Federation build script initialized successfully"
    log_info "Stage 1 complete - foundation ready for Stage 2 implementation"

    exit_function
    return 0
}

# Execute main function with all arguments
main "$@"
