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

log_section() {
    [[ "$QUIET" == "true" ]] && return
    log_info "$*"
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

    # Enhanced Node.js script for modules.json parsing with JSON Schema validation
    cat > "$temp_script" << 'EOF'
const fs = require('fs');
const path = require('path');

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

    // Load JSON Schema if available
    let schema = null;
    const schemaPath = path.join(path.dirname(configFile), 'schemas', 'modules.schema.json');
    const altSchemaPath = path.join(process.cwd(), 'schemas', 'modules.schema.json');

    if (fs.existsSync(schemaPath)) {
        try {
            schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
        } catch (e) {
            // Schema file exists but couldn't be loaded - non-fatal
        }
    } else if (fs.existsSync(altSchemaPath)) {
        try {
            schema = JSON.parse(fs.readFileSync(altSchemaPath, 'utf8'));
        } catch (e) {
            // Schema file exists but couldn't be loaded - non-fatal
        }
    }

    // Simple JSON Schema validation function
    function validateSchema(schema, data, path = 'root') {
        const errors = [];

        // Type validation
        if (schema.type) {
            const actualType = Array.isArray(data) ? 'array' : typeof data;
            if (schema.type === 'object' && actualType !== 'object') {
                errors.push(`${path}: Expected object, got ${actualType}`);
                return errors;
            }
            if (schema.type === 'array' && !Array.isArray(data)) {
                errors.push(`${path}: Expected array, got ${actualType}`);
                return errors;
            }
            if (schema.type === 'integer') {
                if (typeof data !== 'number' || !Number.isInteger(data)) {
                    errors.push(`${path}: Expected integer, got ${actualType}`);
                    return errors;
                }
            } else if (schema.type !== 'object' && schema.type !== 'array' && actualType !== schema.type) {
                errors.push(`${path}: Expected ${schema.type}, got ${actualType}`);
                return errors;
            }
        }

        // Required properties
        if (schema.required && typeof data === 'object') {
            for (const req of schema.required) {
                if (!(req in data)) {
                    errors.push(`${path}: Missing required property "${req}"`);
                }
            }
        }

        // Object properties
        if (schema.properties && typeof data === 'object' && !Array.isArray(data)) {
            for (const [key, value] of Object.entries(data)) {
                if (schema.properties[key]) {
                    errors.push(...validateSchema(schema.properties[key], value, `${path}.${key}`));
                }
            }
        }

        // Additional properties check
        if (schema.additionalProperties === false && typeof data === 'object' && !Array.isArray(data)) {
            for (const key of Object.keys(data)) {
                if (schema.properties && !schema.properties.hasOwnProperty(key)) {
                    errors.push(`${path}: Additional property "${key}" is not allowed`);
                }
            }
        }

        // Array items
        if (schema.items && Array.isArray(data)) {
            if (schema.minItems && data.length < schema.minItems) {
                errors.push(`${path}: Array must have at least ${schema.minItems} items, got ${data.length}`);
            }
            if (schema.maxItems && data.length > schema.maxItems) {
                errors.push(`${path}: Array must have at most ${schema.maxItems} items, got ${data.length}`);
            }
            data.forEach((item, idx) => {
                errors.push(...validateSchema(schema.items, item, `${path}[${idx}]`));
            });
        }

        // Pattern validation
        if (schema.pattern && typeof data === 'string') {
            const regex = new RegExp(schema.pattern);
            if (!regex.test(data)) {
                errors.push(`${path}: String "${data}" does not match required pattern`);
            }
        }

        // Const validation
        if (schema.const !== undefined && data !== schema.const) {
            errors.push(`${path}: Value must be exactly "${schema.const}"`);
        }

        // Enum validation
        if (schema.enum && !schema.enum.includes(data)) {
            errors.push(`${path}: Value must be one of: ${schema.enum.join(', ')}`);
        }

        // MinLength/MaxLength
        if (schema.minLength && typeof data === 'string' && data.length < schema.minLength) {
            errors.push(`${path}: String length must be at least ${schema.minLength}`);
        }
        if (schema.maxLength && typeof data === 'string' && data.length > schema.maxLength) {
            errors.push(`${path}: String length must be at most ${schema.maxLength}`);
        }

        // oneOf validation
        if (schema.oneOf && Array.isArray(schema.oneOf)) {
            const matchCount = schema.oneOf.filter(subSchema => {
                const subErrors = validateSchema(subSchema, data, path);
                return subErrors.length === 0;
            }).length;

            if (matchCount === 0) {
                errors.push(`${path}: Value does not match any of the allowed schemas`);
            } else if (matchCount > 1) {
                errors.push(`${path}: Value matches multiple schemas (should match exactly one)`);
            }
        }

        return errors;
    }

    // Perform schema validation if schema is available
    if (schema) {
        const validationErrors = validateSchema(schema, config);
        if (validationErrors.length > 0) {
            console.error(`ERROR: Configuration validation failed against JSON Schema:`);
            validationErrors.forEach(err => console.error(`  • ${err}`));
            console.error(``);
            console.error(`Please fix these errors and try again.`);
            console.error(`Schema reference: schemas/modules.schema.json`);
            process.exit(1);
        }
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
        if (module.source.local_path) {
            console.log(`MODULE_${index}_LOCAL_PATH=${module.source.local_path}`);
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
        if (module.merge_strategy) {
            const validStrategies = ['overwrite', 'preserve', 'merge', 'error'];
            if (!validStrategies.includes(module.merge_strategy)) {
                console.error(`ERROR: Invalid merge_strategy for '${module.name}': ${module.merge_strategy}`);
                console.error(`  Valid strategies: ${validStrategies.join(', ')}`);
                process.exit(1);
            }
            console.log(`MODULE_${index}_MERGE_STRATEGY=${module.merge_strategy}`);
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

# Register cleanup trap (only when script is run directly, not when sourced for testing)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap cleanup_temp_files EXIT
fi

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

# ============================================================================
# CSS PATH RESOLUTION SYSTEM
# ============================================================================
# Functions for detecting and analyzing asset paths in HTML files to support
# subdirectory deployment with correct CSS/JS path prefixes.
# Part of Child Issue #18 - CSS Path Resolution System

# Detect local asset paths requiring rewriting in an HTML file
# Arguments:
#   $1 - HTML file path
#   $2 - Output variable name (array of paths)
# Returns:
#   Populates the named array with detected local asset paths
detect_asset_paths() {
    local html_file="$1"
    local -n paths_array="$2"

    # Check if file exists
    if [[ ! -f "$html_file" ]]; then
        log_error "HTML file not found: $html_file"
        return 1
    fi

    # Pattern: matches href="/...", src="/...", or data-*="/..."
    # Excludes: protocol-relative URLs (//), external URLs, data URIs
    # Uses grep for reliable extraction

    # Track unique paths to avoid duplicates
    declare -A seen_paths

    # Extract all href="/path", src="/path", data-*="/path" patterns using grep
    # grep -oE extracts only matching parts, one per line
    local matches
    matches=$(grep -oE '(href|src|data-[a-zA-Z-]+)=["\x27](/[^/][^"\x27]*)' "$html_file" 2>/dev/null || true)

    # Process each match
    while IFS= read -r match; do
        # Extract the path part (after =" or =')
        if [[ "$match" =~ =[\"\'](/[^\"\']+) ]]; then
            local path="${BASH_REMATCH[1]}"

            # Skip if it's an external URL, data URI, or SVG fragment
            if [[ ! "$path" =~ ^(https?:|data:|#) ]] && [[ -z "${seen_paths[$path]:-}" ]]; then
                paths_array+=("$path")
                seen_paths["$path"]=1
            fi
        fi
    done <<< "$matches"

    return 0
}

# Calculate CSS path prefix from module destination path
# Arguments:
#   $1 - Module destination path (e.g., "/quiz/", "/", "/docs/product/")
# Returns:
#   CSS prefix string via stdout (e.g., "/quiz", "", "/docs/product")
calculate_css_prefix() {
    local destination="$1"

    # Root destination "/" needs empty prefix
    if [[ "$destination" == "/" ]]; then
        echo ""
        return 0
    fi

    # Remove trailing slash, ensure single leading slash
    local prefix="${destination%/}"  # Remove trailing /
    prefix="${prefix#/}"             # Remove leading /
    prefix="/${prefix}"              # Add back single leading /

    echo "$prefix"
}

# Analyze module asset paths and generate report
# Arguments:
#   $1 - Module output directory
#   $2 - CSS path prefix
# Returns:
#   0 on success, 1 on error
analyze_module_paths() {
    local output_dir="$1"
    local css_prefix="$2"

    if [[ ! -d "$output_dir" ]]; then
        log_error "Output directory not found: $output_dir"
        return 1
    fi

    log_info "Analyzing asset paths in: $output_dir"
    if [[ -n "$css_prefix" ]]; then
        log_info "CSS prefix: $css_prefix"
    else
        log_info "CSS prefix: (none - root deployment)"
    fi

    local html_count=0
    local asset_count=0
    declare -A unique_patterns

    # Scan all HTML files
    while IFS= read -r html_file; do
        ((html_count++)) || true

        declare -a paths=()
        if detect_asset_paths "$html_file" paths; then
            for path in "${paths[@]}"; do
                ((asset_count++)) || true
                # Track unique path patterns (first part of path)
                local pattern
                pattern="$(echo "$path" | cut -d'/' -f2)"
                unique_patterns["$pattern"]=1
            done
        fi
    done < <(find "$output_dir" -name "*.html" -type f 2>/dev/null)

    log_info "Analysis complete:"
    log_info "  - HTML files scanned: $html_count"
    log_info "  - Asset references found: $asset_count"
    log_info "  - Unique path types: ${#unique_patterns[@]}"

    if [[ ${#unique_patterns[@]} -gt 0 ]]; then
        log_info "  - Path types: ${!unique_patterns[*]}"
    fi

    # Estimate rewrite operations
    if [[ -n "$css_prefix" ]]; then
        log_info "  - Rewrite operations required: $asset_count"
    else
        log_info "  - No rewrites needed (root deployment)"
    fi

    return 0
}

# Rewrite asset paths in HTML files with CSS prefix
# Arguments:
#   $1 - Output directory path
#   $2 - CSS path prefix (e.g., "/quiz", empty for root)
# Returns:
#   0 on success, 1 on failure
rewrite_asset_paths() {
    local output_dir="$1"
    local css_prefix="$2"

    enter_function "rewrite_asset_paths"
    set_error_context "Rewriting asset paths in '$output_dir'"

    # Skip if root deployment (no prefix needed)
    if [[ -z "$css_prefix" ]]; then
        log_info "Root deployment - no path rewriting needed"
        exit_function
        return 0
    fi

    log_info "Rewriting asset paths with prefix: $css_prefix"

    if [[ ! -d "$output_dir" ]]; then
        log_error "Output directory does not exist: $output_dir"
        exit_function
        return 1
    fi

    local files_processed=0
    local rewrites_made=0

    # Find all HTML files and process them
    shopt -s globstar nullglob
    local html_files=("$output_dir"/**/*.html)

    if [[ ${#html_files[@]} -eq 0 ]]; then
        log_warning "No HTML files found in: $output_dir"
        exit_function
        return 0
    fi

    for html_file in "${html_files[@]}"; do
        [[ -f "$html_file" ]] || continue

        files_processed=$((files_processed + 1))

        # Count paths before rewriting (for metrics)
        local before_count=$(grep -cE '(href|src)="/' "$html_file" 2>/dev/null || echo 0)

        # Rewrite href="/..." to href="/prefix/..."
        # Pattern matches: href="/path" or href='/path'
        # Excludes: href="//..." (protocol-relative URLs)
        sed -i -E \
            "s|href=(['\"])/([ ^/][^'\"]*)\1|href=\"${css_prefix}/\2\"|g" \
            "$html_file"

        # Rewrite src="/..." to src="/prefix/..."
        sed -i -E \
            "s|src=(['\"])/([ ^/][^'\"]*)\1|src=\"${css_prefix}/\2\"|g" \
            "$html_file"

        # Rewrite data-* attributes with paths
        sed -i -E \
            "s|data-([a-zA-Z-]+)=(['\"])/([ ^/][^'\"]*)\2|data-\1=\"${css_prefix}/\3\"|g" \
            "$html_file"

        # Rewrite CSS url(/...) to url(/prefix/...)
        sed -i -E \
            "s|url\(/([ ^/)][^\)]*)\)|url(${css_prefix}/\1)|g" \
            "$html_file"

        # Count paths after rewriting
        local after_count=$(grep -cE "(href|src)=\"${css_prefix}/" "$html_file" 2>/dev/null || echo 0)
        rewrites_made=$((rewrites_made + after_count))

    done

    log_success "Path rewriting complete:"
    log_info "  - Files processed: $files_processed"
    log_info "  - Paths rewritten: $rewrites_made"

    exit_function
    return 0
}

# Validate rewritten paths for common issues
# Arguments:
#   $1 - Output directory path
#   $2 - CSS path prefix
# Returns:
#   0 if validation passes, 1 if issues found
validate_rewritten_paths() {
    local output_dir="$1"
    local css_prefix="$2"

    enter_function "validate_rewritten_paths"
    set_error_context "Validating rewritten paths in '$output_dir'"

    log_info "Validating rewritten asset paths..."

    local errors=0
    local warnings=0

    # Check for double slashes (rewriting error) - excluding protocol URLs
    local double_slash_count=0
    while IFS= read -r line; do
        # Skip lines with https:// or http://
        if [[ "$line" =~ https?:// ]]; then
            continue
        fi
        double_slash_count=$((double_slash_count + 1))
        if [[ $double_slash_count -le 3 ]]; then
            log_error "Found double slash: $line"
        fi
    done < <(grep -r 'href="//' "$output_dir" --include="*.html" 2>/dev/null || true)

    if [[ $double_slash_count -gt 0 ]]; then
        log_error "Found $double_slash_count double slashes in href attributes (rewriting error)"
        errors=$((errors + 1))
    fi

    # Check src attributes for double slashes
    double_slash_count=0
    while IFS= read -r line; do
        if [[ "$line" =~ https?:// ]]; then
            continue
        fi
        double_slash_count=$((double_slash_count + 1))
    done < <(grep -r 'src="//' "$output_dir" --include="*.html" 2>/dev/null || true)

    if [[ $double_slash_count -gt 0 ]]; then
        log_error "Found $double_slash_count double slashes in src attributes (rewriting error)"
        errors=$((errors + 1))
    fi

    # Check for missing prefix (incomplete rewriting) - only if prefix expected
    if [[ -n "$css_prefix" ]]; then
        local expected_prefix="href=\"${css_prefix}/"
        local total_prefixed=$(grep -r "$expected_prefix" "$output_dir" --include="*.html" 2>/dev/null | wc -l)

        if [[ $total_prefixed -eq 0 ]]; then
            log_warning "No paths with expected prefix found - possible rewriting failure or no local assets"
            warnings=$((warnings + 1))
        else
            log_info "Found $total_prefixed paths with expected prefix: $css_prefix"
        fi
    fi

    # Check for malformed paths (paths with spaces - possible encoding issue)
    local malformed_count=$(grep -r 'href="[^"]*\s[^"]*"' "$output_dir" --include="*.html" 2>/dev/null | wc -l)
    if [[ $malformed_count -gt 0 ]]; then
        log_error "Found $malformed_count paths with spaces (possible encoding issue)"
        errors=$((errors + 1))
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "Path validation passed - no issues detected"
        if [[ $warnings -gt 0 ]]; then
            log_info "  - Warnings: $warnings (non-critical)"
        fi
        exit_function
        return 0
    else
        log_error "Path validation failed - $errors issue(s) detected"
        exit_function
        return 1
    fi
}

# ============================================================================
# STAGE 1.5: DOWNLOAD MANAGEMENT
# ============================================================================
# Functions for downloading existing GitHub Pages content to support
# incremental federation updates with --preserve-base-site functionality.
# Part of Child Issue #19 - Download-Merge-Deploy Logic

# Download existing GitHub Pages content for preservation
# Arguments:
#   $1 - Base URL (e.g., https://info-tech-io.github.io)
#   $2 - Output directory for downloaded content
# Returns:
#   0 on success, 1 on failure
download_existing_pages() {
    local base_url="$1"
    local output_dir="$2"

    enter_function "download_existing_pages"
    set_error_context "Downloading existing pages from $base_url"

    log_info "Downloading existing site content from: $base_url"

    # Validate base URL
    if [[ ! "$base_url" =~ ^https?:// ]]; then
        log_error "Invalid base URL: $base_url"
        log_error "URL must start with http:// or https://"
        exit_function
        return 1
    fi

    # Create output directory
    mkdir -p "$output_dir" || {
        log_io_error "Failed to create download directory: $output_dir"
        exit_function
        return 1
    }

    # Check if wget is available
    if ! command -v wget >/dev/null 2>&1; then
        log_dependency_error "wget is required for downloading existing pages"
        log_error "Please install wget: apt-get install wget  or  brew install wget"
        exit_function
        return 1
    fi

    # Check available disk space (use output_dir if TEMP_DIR is not set)
    local check_dir="${TEMP_DIR:-$output_dir}"
    local available_kb
    available_kb=$(df -k "$check_dir" 2>/dev/null | tail -1 | awk '{print $4}')
    if [[ -n "$available_kb" ]] && [[ $available_kb -lt 102400 ]]; then
        log_error "Insufficient disk space for download (< 100MB available)"
        log_error "Available space: $(df -h "$check_dir" | tail -1 | awk '{print $4}')"
        exit_function
        return 1
    fi

    log_info "Available disk space: $(df -h "$check_dir" 2>/dev/null | tail -1 | awk '{print $4}' || echo 'unknown')"

    # Dry-run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would download: $base_url -> $output_dir"
        log_info "[DRY RUN] wget options: --mirror --no-parent --convert-links --page-requisites"
        exit_function
        return 0
    fi

    # Download with wget (mirror mode)
    log_verbose "Executing wget mirror: $base_url -> $output_dir"

    local wget_opts=(
        --mirror                    # Enable mirroring mode
        --no-parent                 # Don't ascend to parent directory
        --convert-links             # Convert links for local browsing
        --adjust-extension          # Add .html extension if needed
        --page-requisites           # Download CSS, JS, images
        --no-host-directories       # Don't create hostname directory
        --directory-prefix="$output_dir"  # Output to specific directory
        --no-verbose                # Quiet output
        --no-check-certificate      # Allow self-signed certificates
        --timeout=30                # 30 second timeout
        --tries=3                   # 3 retries
        --waitretry=2               # 2 seconds between retries
    )

    # Add user-agent to avoid blocking
    wget_opts+=(--user-agent="Hugo-Federation-Builder/1.0")

    # Execute wget with progress monitoring and error handling
    log_info "Download progress:"

    local download_start
    download_start=$(date +%s)
    local wget_log="/tmp/wget-download-$$.log"

    if wget "${wget_opts[@]}" "$base_url" 2>&1 | \
        while IFS= read -r line; do
            # Parse wget progress (if verbose mode)
            if [[ "$VERBOSE" == "true" ]]; then
                if [[ "$line" =~ saved ]]; then
                    log_verbose "  $line"
                fi
            fi
            echo "$line" >> "$wget_log"
        done; then

        local download_end
        download_end=$(date +%s)
        local download_time=$((download_end - download_start))

        # Count downloaded files
        local file_count
        file_count=$(find "$output_dir" -type f 2>/dev/null | wc -l)

        if [[ $file_count -eq 0 ]]; then
            log_warning "No files downloaded - site may be empty or inaccessible"
            log_warning "Continuing with normal build (no existing content to preserve)"
            exit_function
            return 0  # Not fatal - just means fresh build
        fi

        log_success "Downloaded existing site content successfully"
        log_info "  - Files downloaded: $file_count"
        log_info "  - Download time: ${download_time}s"

        # Clean up log file
        rm -f "$wget_log"

        exit_function
        return 0
    else
        local wget_exit_code=$?
        log_error "wget failed with exit code: $wget_exit_code"

        # Provide specific error messages based on exit code
        case $wget_exit_code in
            4)
                log_error "Network timeout - unable to download existing pages"
                log_error "Check network connection or disable --preserve-base-site"
                ;;
            6)
                log_error "Authentication required for accessing $base_url"
                log_error "Set GITHUB_TOKEN environment variable or disable --preserve-base-site"
                ;;
            8)
                log_error "Server returned error (404, 500, etc.)"
                log_error "Verify the base URL is correct: $base_url"
                ;;
            *)
                log_error "See $wget_log for details"
                ;;
        esac

        exit_function
        return 1
    fi
}

# ============================================================================
# STAGE 2: BUILD ORCHESTRATION
# ============================================================================

# Download module source from repository
# Sets global variable: MODULE_WORK_DIR
download_module_source() {
    local module_index=$1
    local module_name_var="MODULE_${module_index}_NAME"
    local module_repo_var="MODULE_${module_index}_REPO"
    local module_local_path_var="MODULE_${module_index}_LOCAL_PATH"
    local module_path_var="MODULE_${module_index}_PATH"
    local module_branch_var="MODULE_${module_index}_BRANCH"

    local module_name="${!module_name_var}"
    local module_repo="${!module_repo_var:-}"
    local module_local_path="${!module_local_path_var:-}"
    local module_path="${!module_path_var:-.}"
    local module_branch="${!module_branch_var:-main}"

    enter_function "download_module_source"
    set_error_context "Downloading source for module '$module_name'"

    # Create module working directory
    if [[ "$DRY_RUN" == "true" ]]; then
        MODULE_WORK_DIR="/tmp/dry-run/module-$module_index-$module_name"
        if [[ "$module_repo" == "local" ]]; then
            log_info "[DRY RUN] Would copy from local: $module_local_path/$module_path -> $MODULE_WORK_DIR"
        else
            log_info "[DRY RUN] Would download: $module_repo ($module_branch) -> $MODULE_WORK_DIR"
        fi
        exit_function
        return 0
    fi

    MODULE_WORK_DIR="$TEMP_DIR/module-$module_index-$module_name"

    mkdir -p "$MODULE_WORK_DIR" || {
        log_io_error "Failed to create module work directory: $MODULE_WORK_DIR"
        exit_function
        return 1
    }

    # If repository is specified and not "local", clone it
    if [[ -n "$module_repo" ]] && [[ "$module_repo" != "local" ]]; then
        log_info "Cloning $module_name from $module_repo (branch: $module_branch)"

        local clone_dir="$MODULE_WORK_DIR/source"

        if ! git clone --depth 1 --branch "$module_branch" "$module_repo" "$clone_dir" 2>&1 | grep -v "^Cloning" || true; then
            log_error "Failed to clone repository: $module_repo"
            exit_function
            return 1
        fi

        # Extract the specific path if specified
        if [[ "$module_path" != "." ]]; then
            local source_path="$clone_dir/$module_path"
            if [[ ! -d "$source_path" ]]; then
                log_error "Specified path not found in repository: $module_path"
                exit_function
                return 1
            fi

            # Move the specific path to module work directory
            cp -r "$source_path"/* "$MODULE_WORK_DIR/" || {
                log_error "Failed to extract path from repository: $module_path"
                exit_function
                return 1
            }

            # Clean up clone directory
            rm -rf "$clone_dir"
        else
            # Move everything from clone to work directory
            mv "$clone_dir"/* "$MODULE_WORK_DIR/" 2>/dev/null || true
            mv "$clone_dir"/.* "$MODULE_WORK_DIR/" 2>/dev/null || true
            rm -rf "$clone_dir"
        fi

        log_success "Downloaded: $module_name"
    else
        # repository == "local" - use local_path
        if [[ -z "$module_local_path" ]]; then
            log_config_error "Local repository specified but local_path not provided for module '$module_name'"
            exit_function
            return 1
        fi

        if [[ ! -d "$module_local_path" ]]; then
            log_io_error "Local path does not exist: $module_local_path"
            exit_function
            return 1
        fi

        log_info "Copying $module_name from local path: $module_local_path"

        # Copy from local_path/module_path to work directory
        local source_path="$module_local_path/$module_path"

        if [[ ! -d "$source_path" ]]; then
            log_io_error "Specified path not found in local directory: $source_path"
            log_info "Local path: $module_local_path"
            log_info "Relative path: $module_path"
            exit_function
            return 1
        fi

        # Copy all contents from source_path to MODULE_WORK_DIR
        cp -r "$source_path"/* "$MODULE_WORK_DIR/" 2>/dev/null || {
            log_io_error "Failed to copy from local path: $source_path"
            exit_function
            return 1
        }

        # Also copy hidden files if they exist
        cp -r "$source_path"/.[!.]* "$MODULE_WORK_DIR/" 2>/dev/null || true

        log_success "Copied from local: $module_name (from $source_path)"
    fi

    exit_function
    return 0
}

# Build a single module
# Takes module_index and module_work_dir as arguments
# Sets global variable: MODULE_OUTPUT_DIR
build_module() {
    local module_index=$1
    local module_work_dir=$2

    local module_name_var="MODULE_${module_index}_NAME"
    local module_config_var="MODULE_${module_index}_CONFIG"
    local module_dest_var="MODULE_${module_index}_DESTINATION"

    local module_name="${!module_name_var}"
    local module_config="${!module_config_var:-module.json}"
    local module_dest="${!module_dest_var}"

    enter_function "build_module"
    set_error_context "Building module '$module_name'"

    log_federation "Building module: $module_name"

    # Prepare output directory for this module
    if [[ "$DRY_RUN" == "true" ]]; then
        MODULE_OUTPUT_DIR="/tmp/dry-run/output-$module_index-$module_name"
        log_info "[DRY RUN] Would build module: $module_name"
        log_info "[DRY RUN]   Config: $module_config"
        log_info "[DRY RUN]   Output: $MODULE_OUTPUT_DIR"
        log_info "[DRY RUN]   Destination: $module_dest"
        SUCCESSFUL_BUILDS=$((SUCCESSFUL_BUILDS + 1))
        exit_function
        return 0
    fi

    MODULE_OUTPUT_DIR="$TEMP_DIR/output-$module_index-$module_name"

    mkdir -p "$MODULE_OUTPUT_DIR" || {
        log_io_error "Failed to create module output directory: $MODULE_OUTPUT_DIR"
        exit_function
        return 1
    }

    # Prepare build.sh parameters
    local build_params=()

    # Add config path (relative to module work directory)
    if [[ -f "$module_work_dir/$module_config" ]]; then
        build_params+=("--config=$module_work_dir/$module_config")
    else
        log_warning "Module config not found: $module_work_dir/$module_config, using defaults"
    fi

    # Add output directory
    build_params+=("--output=$MODULE_OUTPUT_DIR")

    # Add content directory (if module work directory has content)
    if [[ -d "$module_work_dir/content" ]]; then
        build_params+=("--content=$module_work_dir/content")
    fi

    # Add verbosity settings
    if [[ "$VERBOSE" == "true" ]]; then
        build_params+=("--verbose")
    fi

    if [[ "$QUIET" == "true" ]]; then
        build_params+=("--quiet")
    fi

    # Add performance tracking if enabled
    if [[ "$ENABLE_PERFORMANCE_TRACKING" == "true" ]]; then
        build_params+=("--performance-track")
    fi

    log_verbose "Executing: build.sh ${build_params[*]}"

    # Execute build.sh
    local build_start
    build_start=$(date +%s)

    if "$SCRIPT_DIR/build.sh" "${build_params[@]}"; then
        local build_end
        build_end=$(date +%s)
        local build_time=$((build_end - build_start))

        log_success "Built $module_name in ${build_time}s"
        SUCCESSFUL_BUILDS=$((SUCCESSFUL_BUILDS + 1))

        # Apply CSS path resolution (Stage 2)
        local css_prefix=$(calculate_css_prefix "$module_dest")

        if [[ -n "$css_prefix" ]]; then
            log_section "Applying CSS Path Resolution"
            log_info "Module: $module_name"
            log_info "Destination: $module_dest"
            log_info "CSS Prefix: $css_prefix"

            # Analyze paths before rewriting (if verbose)
            if [[ "$VERBOSE" == "true" ]]; then
                analyze_module_paths "$MODULE_OUTPUT_DIR" "$css_prefix"
            fi

            # Perform path rewriting
            if ! rewrite_asset_paths "$MODULE_OUTPUT_DIR" "$css_prefix"; then
                log_error "CSS path rewriting failed for module: $module_name"
                FAILED_BUILDS=$((FAILED_BUILDS + 1))
                exit_function
                return 1
            fi

            # Validate rewritten paths
            if ! validate_rewritten_paths "$MODULE_OUTPUT_DIR" "$css_prefix"; then
                log_warning "CSS path validation failed for module: $module_name (non-critical)"
                # Don't fail the build, just warn
            fi

            log_success "CSS path resolution complete for module: $module_name"
        else
            log_info "Module deployed at root - no CSS path rewriting needed"
        fi

        exit_function
        return 0
    else
        log_error "Failed to build module: $module_name"
        FAILED_BUILDS=$((FAILED_BUILDS + 1))

        exit_function
        return 1
    fi
}

# Orchestrate builds for all modules
orchestrate_builds() {
    enter_function "orchestrate_builds"
    set_error_context "Orchestrating federation builds"

    log_federation "Starting build orchestration for $MODULES_COUNT module(s)"

    # Arrays to track module states
    declare -a module_work_dirs
    declare -a module_output_dirs
    declare -a module_build_status

    # Sequential build execution
    for ((i=0; i<MODULES_COUNT; i++)); do
        local module_name_var="MODULE_${i}_NAME"
        local module_name="${!module_name_var}"

        log_info "Processing module $((i+1))/$MODULES_COUNT: $module_name"

        # Download module source
        if download_module_source "$i"; then
            module_work_dirs[$i]="$MODULE_WORK_DIR"
            log_verbose "Module $module_name source: $MODULE_WORK_DIR"
        else
            log_error "Failed to download source for module: $module_name"
            module_build_status[$i]="download_failed"
            FAILED_BUILDS=$((FAILED_BUILDS + 1))
            continue
        fi

        # Build module
        if build_module "$i" "$MODULE_WORK_DIR"; then
            module_output_dirs[$i]="$MODULE_OUTPUT_DIR"
            module_build_status[$i]="success"
        else
            module_build_status[$i]="build_failed"
            # Continue with other modules even if one fails
        fi
    done

    # Check if at least one module succeeded
    if [[ $SUCCESSFUL_BUILDS -eq 0 ]]; then
        log_error "All module builds failed"
        exit_function
        return 1
    fi

    if [[ $FAILED_BUILDS -gt 0 ]]; then
        log_warning "Some modules failed to build ($FAILED_BUILDS/$MODULES_COUNT)"
    else
        log_success "All modules built successfully ($SUCCESSFUL_BUILDS/$MODULES_COUNT)"
    fi

    # Export module output directories for Stage 3
    export MODULE_OUTPUT_DIRS="${module_output_dirs[*]}"
    export MODULE_BUILD_STATUS="${module_build_status[*]}"

    exit_function
    return 0
}

# Generate build report
generate_build_report() {
    cat << EOF

╔══════════════════════════════════════════════════════════════╗
║                  Federation Build Report                     ║
╚══════════════════════════════════════════════════════════════╝

EOF

    print_color "$CYAN" "Federation: ${FEDERATION_NAME:-Unnamed}"
    print_color "$BLUE" "Modules:    $MODULES_COUNT"
    echo ""

    if [[ $SUCCESSFUL_BUILDS -gt 0 ]]; then
        print_color "$GREEN" "✅ Successful: $SUCCESSFUL_BUILDS"
    fi

    if [[ $FAILED_BUILDS -gt 0 ]]; then
        print_color "$RED" "❌ Failed:     $FAILED_BUILDS"
    fi

    echo ""

    # Per-module status
    if [[ -n "${MODULE_BUILD_STATUS:-}" ]]; then
        IFS=' ' read -ra statuses <<< "$MODULE_BUILD_STATUS"
        for ((i=0; i<MODULES_COUNT; i++)); do
            local module_name_var="MODULE_${i}_NAME"
            local module_name="${!module_name_var}"
            local status="${statuses[$i]:-unknown}"

            case "$status" in
                success)
                    print_color "$GREEN" "  ✅ $module_name"
                    ;;
                build_failed)
                    print_color "$RED" "  ❌ $module_name (build failed)"
                    ;;
                download_failed)
                    print_color "$RED" "  ❌ $module_name (download failed)"
                    ;;
                *)
                    print_color "$YELLOW" "  ⚠️  $module_name (unknown)"
                    ;;
            esac
        done
    fi

    echo ""
}

# ==========================================
# Stage 2.5: Intelligent Merging System
# ==========================================
# Functions for intelligent content merging with conflict detection
# and merge strategies (overwrite|preserve|merge|error).
# Part of Child Issue #19 - Download-Merge-Deploy Logic

# Detect conflicts between existing and new content directories
# Arguments:
#   $1 - Existing content directory
#   $2 - New content directory
#   $3 - Output array variable for conflict paths
# Returns:
#   0 if no conflicts, 1 if conflicts detected
detect_merge_conflicts() {
    local existing_dir="$1"
    local new_dir="$2"
    local -n conflicts_array="$3"

    enter_function "detect_merge_conflicts"
    set_error_context "Detecting merge conflicts"

    # Check if directories exist
    if [[ ! -d "$existing_dir" ]]; then
        log_verbose "No existing content - no conflicts possible"
        exit_function
        return 0
    fi

    if [[ ! -d "$new_dir" ]]; then
        log_error "New content directory not found: $new_dir"
        exit_function
        return 1
    fi

    local conflict_count=0

    # Find all files/directories in new content
    while IFS= read -r new_item; do
        # Get relative path
        local rel_path="${new_item#$new_dir/}"

        # Check if exists in existing content
        local existing_item="$existing_dir/$rel_path"

        if [[ -e "$existing_item" ]]; then
            # Conflict detected
            conflicts_array+=("$rel_path")
            ((conflict_count++)) || true

            # Determine conflict type
            if [[ -f "$new_item" ]] && [[ -f "$existing_item" ]]; then
                log_verbose "  File conflict: $rel_path"
            elif [[ -d "$new_item" ]] && [[ -d "$existing_item" ]]; then
                log_verbose "  Directory conflict: $rel_path (may contain sub-conflicts)"
            else
                log_verbose "  Type conflict: $rel_path (file vs directory)"
            fi
        fi
    done < <(find "$new_dir" -mindepth 1 2>/dev/null)

    if [[ $conflict_count -gt 0 ]]; then
        log_warning "Detected $conflict_count potential merge conflicts"
        exit_function
        return 1
    else
        log_success "No merge conflicts detected"
        exit_function
        return 0
    fi
}

# Merge content using specified strategy
# Arguments:
#   $1 - Source directory (new content)
#   $2 - Target directory (existing content)
#   $3 - Merge strategy (overwrite|preserve|merge|error)
# Returns:
#   0 on success, 1 on failure
merge_with_strategy() {
    local source_dir="$1"
    local target_dir="$2"
    local strategy="${3:-overwrite}"

    enter_function "merge_with_strategy"
    set_error_context "Merging with strategy: $strategy"

    log_info "Applying merge strategy: $strategy"
    log_verbose "  Source: $source_dir"
    log_verbose "  Target: $target_dir"

    # Detect conflicts first
    declare -a conflicts=()
    local has_conflicts=0
    if ! detect_merge_conflicts "$target_dir" "$source_dir" conflicts 2>/dev/null; then
        has_conflicts=1
    fi

    # Apply strategy
    case "$strategy" in
        overwrite)
            log_info "Strategy: Overwrite - new content replaces existing"

            if [[ $has_conflicts -eq 1 ]]; then
                log_warning "Overwriting ${#conflicts[@]} conflicting items"
            fi

            # Use rsync for better control (use -I to ignore times, transfer based on content)
            if command -v rsync >/dev/null 2>&1; then
                rsync -aI --delete-during "$source_dir/" "$target_dir/"
            else
                # Fallback to cp
                cp -rf "$source_dir"/* "$target_dir/" 2>/dev/null || true
            fi
            ;;

        preserve)
            log_info "Strategy: Preserve - keep existing, skip conflicting new content"

            if [[ $has_conflicts -eq 1 ]]; then
                log_warning "Preserving ${#conflicts[@]} existing items, skipping new versions"
            fi

            # Copy only non-conflicting files (use -I to ignore times)
            if command -v rsync >/dev/null 2>&1; then
                rsync -aI --ignore-existing "$source_dir/" "$target_dir/"
            else
                # Fallback: manual copy of non-conflicting files
                find "$source_dir" -type f | while IFS= read -r source_file; do
                    local rel_path="${source_file#$source_dir/}"
                    local target_file="$target_dir/$rel_path"

                    if [[ ! -e "$target_file" ]]; then
                        mkdir -p "$(dirname "$target_file")"
                        cp "$source_file" "$target_file"
                    fi
                done
            fi
            ;;

        merge)
            log_info "Strategy: Merge - combine compatible content"

            # For directories: recursive merge
            # For files: depends on format (HTML can be merged, binaries cannot)

            find "$source_dir" -type f | while IFS= read -r source_file; do
                local rel_path="${source_file#$source_dir/}"
                local target_file="$target_dir/$rel_path"

                if [[ ! -e "$target_file" ]]; then
                    # No conflict - copy directly
                    mkdir -p "$(dirname "$target_file")"
                    cp "$source_file" "$target_file"
                elif [[ -f "$target_file" ]]; then
                    # Both exist - attempt merge based on file type
                    if [[ "$source_file" =~ \.(html|htm|xml|txt)$ ]]; then
                        log_warning "Merging text file: $rel_path (experimental)"
                        # Simple concatenation for text files
                        cat "$source_file" >> "$target_file"
                    else
                        # Binary or unknown - overwrite
                        log_verbose "Overwriting non-mergeable file: $rel_path"
                        cp "$source_file" "$target_file"
                    fi
                fi
            done
            ;;

        error)
            log_info "Strategy: Error - fail on any conflict"

            if [[ $has_conflicts -eq 1 ]]; then
                log_error "Merge conflicts detected with 'error' strategy"
                log_error "Conflicting paths:"
                for conflict in "${conflicts[@]}"; do
                    log_error "  - $conflict"
                done
                exit_function
                return 1
            fi

            # No conflicts - safe to merge
            cp -r "$source_dir"/* "$target_dir"/ 2>/dev/null || true
            ;;

        *)
            log_error "Unknown merge strategy: $strategy"
            exit_function
            return 1
            ;;
    esac

    log_success "Merge completed with strategy: $strategy"
    exit_function
    return 0
}

# ==========================================
# Stage 3: Output Management Functions
# ==========================================

# Merge all module outputs into the final federation structure
merge_federation_output() {
    enter_function "merge_federation_output"
    set_error_context "Merging federation output"

    log_federation "Merging module outputs into federation structure"

    # If preserve-base-site, merge existing content first
    if [[ "$PRESERVE_BASE_SITE" == "true" ]] && [[ -n "${EXISTING_PAGES_DIR:-}" ]]; then
        log_info "Merging existing base site content"

        if [[ -d "$EXISTING_PAGES_DIR" ]]; then
            log_verbose "Existing content: $EXISTING_PAGES_DIR"

            # Copy existing content to output (base layer)
            if [[ ! -d "$OUTPUT" ]]; then
                mkdir -p "$OUTPUT"
            fi

            # Use rsync or cp to copy base content
            if command -v rsync >/dev/null 2>&1; then
                rsync -a "$EXISTING_PAGES_DIR/" "$OUTPUT/"
            else
                cp -r "$EXISTING_PAGES_DIR"/* "$OUTPUT"/ 2>/dev/null || true
            fi

            local existing_count
            existing_count=$(find "$OUTPUT" -type f | wc -l)
            log_success "Merged $existing_count existing files into base"
        else
            log_warning "Existing pages directory not found, skipping base merge"
        fi
    fi

    # Convert exported space-separated strings back to arrays
    local -a output_dirs
    local -a build_status
    read -ra output_dirs <<< "$MODULE_OUTPUT_DIRS"
    read -ra build_status <<< "$MODULE_BUILD_STATUS"

    local merged_count=0
    local skipped_count=0
    local conflict_count=0

    # Process each module
    for ((i=0; i<MODULES_COUNT; i++)); do
        local module_name_var="MODULE_${i}_NAME"
        local module_dest_var="MODULE_${i}_DESTINATION"
        local module_strategy_var="MODULE_${i}_MERGE_STRATEGY"

        local module_name="${!module_name_var}"
        local module_dest="${!module_dest_var:-/}"
        local module_strategy="${!module_strategy_var:-overwrite}"

        # Skip failed builds
        if [[ "${build_status[$i]}" != "success" ]]; then
            log_warning "Skipping merge for failed module: $module_name"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        local module_output="${output_dirs[$i]}"

        # Determine target directory
        local dest_path="${module_dest#/}"
        local target_dir="$OUTPUT"

        if [[ -n "$dest_path" && "$dest_path" != "/" ]]; then
            target_dir="$OUTPUT/$dest_path"
        fi

        log_info "Merging $module_name → $target_dir (strategy: $module_strategy)"

        # In dry-run mode, just show what would happen
        if [[ "$DRY_RUN" == "true" ]]; then
            log_verbose "[DRY-RUN] Would merge: $module_output → $target_dir"
            merged_count=$((merged_count + 1))
            continue
        fi

        # Create target directory
        if ! mkdir -p "$target_dir"; then
            log_error "Failed to create target directory: $target_dir"
            continue
        fi

        # Apply intelligent merge with strategy
        if merge_with_strategy "$module_output" "$target_dir" "$module_strategy"; then
            log_success "Merged $module_name successfully"
            merged_count=$((merged_count + 1))
        else
            log_error "Failed to merge module: $module_name"
            conflict_count=$((conflict_count + 1))
        fi
    done

    log_info "Merge summary:"
    log_info "  - Modules merged: $merged_count"
    log_info "  - Modules skipped: $skipped_count"
    log_info "  - Merge conflicts: $conflict_count"

    if [[ $merged_count -eq 0 ]] && [[ $conflict_count -gt 0 ]]; then
        log_error "All module merges failed due to conflicts"
        exit_function
        return 1
    fi

    if [[ $merged_count -eq 0 ]]; then
        log_error "No modules were merged successfully"
        exit_function
        return 1
    fi

    exit_function
    return 0
}

# ==========================================
# Stage 3.5: Deployment Preparation
# ==========================================
# Functions for generating deployment artifacts, enhanced manifests,
# and deployment readiness verification.
# Part of Child Issue #19 - Download-Merge-Deploy Logic

# Generate deployment artifacts (checksums, metadata, statistics)
# Returns: 0 on success, 1 on failure
generate_deployment_artifacts() {
    enter_function "generate_deployment_artifacts"
    set_error_context "Generating deployment artifacts"

    log_info "Generating deployment artifacts"

    # In dry-run mode, skip
    if [[ "$DRY_RUN" == "true" ]]; then
        log_verbose "[DRY-RUN] Would generate deployment artifacts"
        exit_function
        return 0
    fi

    local artifacts_dir="$OUTPUT/.federation"
    mkdir -p "$artifacts_dir" || {
        log_io_error "Failed to create artifacts directory"
        exit_function
        return 1
    }

    # Artifact 1: File checksums (SHA256)
    log_info "Generating checksums..."

    local checksum_file="$artifacts_dir/checksums.sha256"

    if command -v sha256sum >/dev/null 2>&1; then
        find "$OUTPUT" -type f ! -path "$artifacts_dir/*" -exec sha256sum {} \; > "$checksum_file" 2>/dev/null
    elif command -v shasum >/dev/null 2>&1; then
        find "$OUTPUT" -type f ! -path "$artifacts_dir/*" -exec shasum -a 256 {} \; > "$checksum_file" 2>/dev/null
    else
        log_warning "sha256sum/shasum not available - skipping checksums"
        echo "# Checksums not available" > "$checksum_file"
    fi

    local checksum_count
    checksum_count=$(wc -l < "$checksum_file" 2>/dev/null || echo 0)
    log_info "  Generated checksums for $checksum_count files"

    # Artifact 2: Deployment metadata
    log_info "Generating metadata..."

    local metadata_file="$artifacts_dir/deployment.json"

    # Calculate federation statistics
    local total_size
    total_size=$(du -sh "$OUTPUT" 2>/dev/null | cut -f1 || echo "unknown")
    local file_count
    file_count=$(find "$OUTPUT" -type f ! -path "$artifacts_dir/*" 2>/dev/null | wc -l)
    local html_count
    html_count=$(find "$OUTPUT" -name "*.html" ! -path "$artifacts_dir/*" 2>/dev/null | wc -l)
    local css_count
    css_count=$(find "$OUTPUT" -name "*.css" ! -path "$artifacts_dir/*" 2>/dev/null | wc -l)
    local js_count
    js_count=$(find "$OUTPUT" -name "*.js" ! -path "$artifacts_dir/*" 2>/dev/null | wc -l)
    local image_count
    image_count=$(find "$OUTPUT" \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" \) ! -path "$artifacts_dir/*" 2>/dev/null | wc -l)

    # Generate JSON metadata
    cat > "$metadata_file" << EOF
{
  "federation": {
    "name": "${FEDERATION_NAME:-Unknown}",
    "baseURL": "${FEDERATION_BASE_URL:-}",
    "buildDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "buildHost": "$(hostname)",
    "preserveBaseSite": $PRESERVE_BASE_SITE
  },
  "statistics": {
    "totalSize": "$total_size",
    "totalFiles": $file_count,
    "htmlFiles": $html_count,
    "cssFiles": $css_count,
    "jsFiles": $js_count,
    "imageFiles": $image_count
  },
  "modules": {
    "total": $MODULES_COUNT,
    "successful": $SUCCESSFUL_BUILDS,
    "failed": $FAILED_BUILDS
  },
  "artifacts": {
    "checksumsFile": "checksums.sha256",
    "manifestFile": "federation-manifest.json",
    "metadataFile": "deployment.json"
  }
}
EOF

    log_success "Deployment artifacts generated in: $artifacts_dir"
    log_info "  - Checksums: $checksum_count files"
    log_info "  - Total size: $total_size"
    log_info "  - Total files: $file_count"

    exit_function
    return 0
}

# Validate the final federation output structure with comprehensive 3-phase validation
validate_federation_output() {
    enter_function "validate_federation_output"
    set_error_context "Validating federation output"

    log_federation "Running comprehensive federation validation"

    local validation_passed=true
    local warnings=0
    local errors=0

    # Convert exported space-separated strings back to arrays
    local -a build_status
    read -ra build_status <<< "$MODULE_BUILD_STATUS"

    # =================================================================
    # Phase 1: Structure Validation
    # =================================================================
    log_section "Phase 1: Structure Validation"

    # Check each successful module has content in its destination
    for ((i=0; i<MODULES_COUNT; i++)); do
        # Skip failed builds
        if [[ "${build_status[$i]}" != "success" ]]; then
            continue
        fi

        local module_name_var="MODULE_${i}_NAME"
        local module_dest_var="MODULE_${i}_DESTINATION"
        local module_name="${!module_name_var}"
        local module_dest="${!module_dest_var:-/}"

        # Determine target directory
        local dest_path="${module_dest#/}"
        local target_dir="$OUTPUT"

        if [[ -n "$dest_path" && "$dest_path" != "/" ]]; then
            target_dir="$OUTPUT/$dest_path"
        fi

        # In dry-run mode, skip validation
        if [[ "$DRY_RUN" == "true" ]]; then
            log_verbose "[DRY-RUN] Would validate: $target_dir"
            continue
        fi

        # Check 1: Directory exists
        if [[ ! -d "$target_dir" ]]; then
            log_error "✗ Missing directory for $module_name at $target_dir"
            errors=$((errors + 1))
            validation_passed=false
            continue
        fi

        # Check 2: Directory has content
        if [[ -z "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
            log_error "✗ Empty directory for $module_name at $target_dir"
            errors=$((errors + 1))
            validation_passed=false
            continue
        fi

        # Check 3: Has index.html or index.htm
        if [[ ! -f "$target_dir/index.html" ]] && [[ ! -f "$target_dir/index.htm" ]]; then
            log_warning "⚠ No index file for $module_name at $target_dir"
            warnings=$((warnings + 1))
        else
            log_verbose "✓ $module_name structure valid"
        fi
    done

    log_info "Structure validation: $errors errors, $warnings warnings"

    # =================================================================
    # Phase 2: Content Validation
    # =================================================================
    log_section "Phase 2: Content Validation"

    local html_count=0
    local broken_html=0

    # Validate HTML files
    while IFS= read -r html_file; do
        ((html_count++)) || true

        # Basic HTML validation (check for closing html tag)
        if ! grep -q "</html>" "$html_file" 2>/dev/null; then
            if [[ "$VERBOSE" == "true" ]]; then
                log_warning "⚠ Possibly malformed HTML: ${html_file#$OUTPUT/}"
            fi
            warnings=$((warnings + 1))
            ((broken_html++)) || true
        fi
    done < <(find "$OUTPUT" -name "*.html" -type f 2>/dev/null)

    log_info "Content validation: $html_count HTML files checked, $broken_html warnings"

    # =================================================================
    # Phase 3: Asset Path Validation
    # =================================================================
    log_section "Phase 3: Asset Path Validation"

    local broken_assets=0

    # Check for common asset path issues (double slashes)
    while IFS= read -r html_file; do
        # Check for double slashes (excluding https://)
        if grep -qE 'href="//[^h]' "$html_file" 2>/dev/null || grep -qE 'src="//[^h]' "$html_file" 2>/dev/null; then
            if [[ "$VERBOSE" == "true" ]]; then
                log_warning "⚠ Possible double-slash in: ${html_file#$OUTPUT/}"
            fi
            warnings=$((warnings + 1))
            ((broken_assets++)) || true
        fi
    done < <(find "$OUTPUT" -name "*.html" -type f 2>/dev/null | head -50)

    log_info "Asset validation: $broken_assets potential issues detected"

    # =================================================================
    # Validation Summary
    # =================================================================
    log_section "Validation Summary"

    if [[ "$validation_passed" == "true" ]]; then
        log_success "✅ Federation output validation passed"
        log_info "  - Errors: $errors"
        log_info "  - Warnings: $warnings"
        log_info "  - HTML files: $html_count"

        exit_function
        return 0
    else
        log_error "❌ Federation output validation failed"
        log_error "  - Errors: $errors (critical)"
        log_error "  - Warnings: $warnings (non-critical)"

        exit_function
        return 1
    fi
}

# Create enhanced federation manifest file with deployment-ready information
# Enhanced for Stage 3: Deployment Preparation
# Includes schema version, deployment metadata, per-module sizes, and instructions
create_federation_manifest() {
    enter_function "create_federation_manifest"
    set_error_context "Creating federation manifest"

    log_info "Creating enhanced federation manifest"

    local manifest_file="$OUTPUT/.federation/federation-manifest.json"

    # In dry-run mode, skip manifest creation
    if [[ "$DRY_RUN" == "true" ]]; then
        log_verbose "[DRY-RUN] Would create manifest at: $manifest_file"
        exit_function
        return 0
    fi

    # Ensure .federation directory exists
    mkdir -p "$(dirname "$manifest_file")" || {
        log_io_error "Failed to create manifest directory"
        exit_function
        return 1
    }

    # Convert exported space-separated strings back to arrays
    local -a build_status
    local -a output_dirs
    read -ra build_status <<< "$MODULE_BUILD_STATUS"
    read -ra output_dirs <<< "$MODULE_OUTPUT_DIRS"

    # Calculate build duration (if start time available)
    local build_duration_sec=0
    if [[ -n "${BUILD_START_TIME:-}" ]]; then
        local current_time
        current_time=$(date +%s)
        build_duration_sec=$((current_time - BUILD_START_TIME))
    fi

    # Calculate total deployed size
    local total_size
    total_size=$(du -sh "$OUTPUT" 2>/dev/null | cut -f1 || echo "unknown")

    # Determine deployment readiness
    local deployment_ready="true"
    if [[ "$FAILED_BUILDS" -gt 0 ]] || [[ "$SUCCESSFUL_BUILDS" -eq 0 ]]; then
        deployment_ready="false"
    fi

    # Build JSON manifest with heredoc for better formatting
    cat > "$manifest_file" << EOF
{
  "version": "1.0",
  "schemaVersion": "2.0",
  "generatedBy": "Hugo Template Factory - Federated Build System",
  "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "federation": {
    "name": "${FEDERATION_NAME:-Unknown}",
    "baseURL": "${FEDERATION_BASE_URL:-}",
    "buildDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "buildHost": "$(hostname)",
    "buildDurationSeconds": $build_duration_sec,
    "preserveBaseSite": $PRESERVE_BASE_SITE,
    "totalModules": $MODULES_COUNT,
    "successfulBuilds": $SUCCESSFUL_BUILDS,
    "failedBuilds": $FAILED_BUILDS
  },
  "deployment": {
    "ready": $deployment_ready,
    "validated": true,
    "totalSize": "$total_size",
    "artifactsDir": ".federation",
    "deploymentInstructions": [
      "1. Verify all module builds succeeded (check successfulBuilds == totalModules)",
      "2. Review deployment artifacts in .federation/ directory",
      "3. Validate checksums: sha256sum -c .federation/checksums.sha256",
      "4. Deploy entire public/ directory to GitHub Pages repository",
      "5. Verify deployment at: ${FEDERATION_BASE_URL:-https://your-site.github.io}",
      "6. Monitor federation-manifest.json for deployment metadata"
    ]
  },
  "modules": [
EOF

    # Add each module to manifest with enhanced metadata
    for ((i=0; i<MODULES_COUNT; i++)); do
        local module_name_var="MODULE_${i}_NAME"
        local module_dest_var="MODULE_${i}_DESTINATION"
        local module_repo_var="MODULE_${i}_REPO"
        local module_branch_var="MODULE_${i}_BRANCH"
        local module_strategy_var="MODULE_${i}_MERGE_STRATEGY"

        local module_name="${!module_name_var}"
        local module_dest="${!module_dest_var:-/}"
        local module_repo="${!module_repo_var:-local}"
        local module_branch="${!module_branch_var:-main}"
        local module_strategy="${!module_strategy_var:-overwrite}"
        local module_status="${build_status[$i]}"

        # Calculate module deployment size
        local module_size="unknown"
        local deployed_status="false"

        if [[ "$module_status" == "success" ]]; then
            deployed_status="true"

            # Determine target directory for size calculation
            local dest_path="${module_dest#/}"
            local target_dir="$OUTPUT"

            if [[ -n "$dest_path" && "$dest_path" != "/" ]]; then
                target_dir="$OUTPUT/$dest_path"
            fi

            if [[ -d "$target_dir" ]]; then
                module_size=$(du -sh "$target_dir" 2>/dev/null | cut -f1 || echo "unknown")
            fi
        fi

        # Write module JSON
        cat >> "$manifest_file" << MODULE_EOF
    {
      "name": "$module_name",
      "destination": "$module_dest",
      "repository": "$module_repo",
      "branch": "$module_branch",
      "buildStatus": "$module_status",
      "mergeStrategy": "$module_strategy",
      "deployedSize": "$module_size",
      "deployed": $deployed_status
    }
MODULE_EOF

        # Add comma if not last module
        if [[ $i -lt $((MODULES_COUNT - 1)) ]]; then
            echo "," >> "$manifest_file"
        else
            echo "" >> "$manifest_file"
        fi
    done

    # Close modules array and JSON
    cat >> "$manifest_file" << 'EOF'
  ]
}
EOF

    log_success "Enhanced federation manifest created: $manifest_file"
    log_info "  - Schema version: 2.0"
    log_info "  - Deployment ready: $deployment_ready"
    log_info "  - Total size: $total_size"

    # Also create a copy in the root output directory for backward compatibility
    if [[ ! -f "$OUTPUT/federation-manifest.json" ]]; then
        cp "$manifest_file" "$OUTPUT/federation-manifest.json" 2>/dev/null || true
        log_verbose "Manifest copied to output root for backward compatibility"
    fi

    exit_function
    return 0
}

# Verify deployment readiness with comprehensive pre-deployment checks
# Performs 5-phase validation before deployment
# Returns: 0 if ready, 1 if not ready
verify_deployment_ready() {
    enter_function "verify_deployment_ready"
    set_error_context "Verifying deployment readiness"

    log_federation "Running deployment readiness verification"

    local checks_passed=0
    local checks_failed=0
    local total_checks=5

    # =================================================================
    # Check 1: Output Directory Validation
    # =================================================================
    log_section "Check 1/5: Output Directory"

    if [[ ! -d "$OUTPUT" ]]; then
        log_error "✗ Output directory does not exist: $OUTPUT"
        checks_failed=$((checks_failed + 1))
    elif [[ -z "$(ls -A "$OUTPUT" 2>/dev/null)" ]]; then
        log_error "✗ Output directory is empty: $OUTPUT"
        checks_failed=$((checks_failed + 1))
    else
        local file_count
        file_count=$(find "$OUTPUT" -type f 2>/dev/null | wc -l)
        log_success "✓ Output directory valid ($file_count files)"
        checks_passed=$((checks_passed + 1))
    fi

    # =================================================================
    # Check 2: Manifest Validation
    # =================================================================
    log_section "Check 2/5: Federation Manifest"

    local manifest_file="$OUTPUT/.federation/federation-manifest.json"

    if [[ ! -f "$manifest_file" ]]; then
        log_error "✗ Manifest file not found: $manifest_file"
        checks_failed=$((checks_failed + 1))
    else
        # Validate JSON syntax
        if command -v node >/dev/null 2>&1; then
            if node -e "JSON.parse(require('fs').readFileSync('$manifest_file', 'utf8'))" 2>/dev/null; then
                log_success "✓ Manifest file valid JSON"
                checks_passed=$((checks_passed + 1))
            else
                log_error "✗ Manifest file contains invalid JSON"
                checks_failed=$((checks_failed + 1))
            fi
        elif command -v python3 >/dev/null 2>&1; then
            if python3 -c "import json; json.load(open('$manifest_file'))" 2>/dev/null; then
                log_success "✓ Manifest file valid JSON"
                checks_passed=$((checks_passed + 1))
            else
                log_error "✗ Manifest file contains invalid JSON"
                checks_failed=$((checks_failed + 1))
            fi
        else
            log_warning "⚠ Cannot validate JSON (node/python3 not available)"
            log_info "✓ Manifest file exists (syntax not validated)"
            checks_passed=$((checks_passed + 1))
        fi
    fi

    # =================================================================
    # Check 3: Build Success Validation
    # =================================================================
    log_section "Check 3/5: Build Success"

    if [[ "$SUCCESSFUL_BUILDS" -eq 0 ]]; then
        log_error "✗ No successful builds (cannot deploy)"
        checks_failed=$((checks_failed + 1))
    elif [[ "$FAILED_BUILDS" -gt 0 ]]; then
        log_warning "⚠ Some builds failed ($FAILED_BUILDS/$MODULES_COUNT)"
        log_success "✓ At least one build succeeded ($SUCCESSFUL_BUILDS/$MODULES_COUNT)"
        checks_passed=$((checks_passed + 1))
    else
        log_success "✓ All builds succeeded ($SUCCESSFUL_BUILDS/$MODULES_COUNT)"
        checks_passed=$((checks_passed + 1))
    fi

    # =================================================================
    # Check 4: Deployment Artifacts Validation
    # =================================================================
    log_section "Check 4/5: Deployment Artifacts"

    local artifacts_dir="$OUTPUT/.federation"
    local checksum_file="$artifacts_dir/checksums.sha256"
    local metadata_file="$artifacts_dir/deployment.json"

    local artifacts_ok=true

    if [[ ! -d "$artifacts_dir" ]]; then
        log_error "✗ Artifacts directory not found: $artifacts_dir"
        artifacts_ok=false
    fi

    if [[ ! -f "$checksum_file" ]]; then
        log_error "✗ Checksum file not found: $checksum_file"
        artifacts_ok=false
    fi

    if [[ ! -f "$metadata_file" ]]; then
        log_error "✗ Metadata file not found: $metadata_file"
        artifacts_ok=false
    fi

    if [[ "$artifacts_ok" == "true" ]]; then
        log_success "✓ All deployment artifacts present"
        checks_passed=$((checks_passed + 1))
    else
        log_error "✗ Missing deployment artifacts"
        checks_failed=$((checks_failed + 1))
    fi

    # =================================================================
    # Check 5: Root Index File
    # =================================================================
    log_section "Check 5/5: Root Index File"

    if [[ -f "$OUTPUT/index.html" ]]; then
        log_success "✓ Root index.html exists"
        checks_passed=$((checks_passed + 1))
    elif [[ -f "$OUTPUT/index.htm" ]]; then
        log_success "✓ Root index.htm exists"
        checks_passed=$((checks_passed + 1))
    else
        log_warning "⚠ No root index file (GitHub Pages may show 404)"
        log_info "  This is acceptable if base site module provides index"
        # Don't fail on this - it's a warning
        checks_passed=$((checks_passed + 1))
    fi

    # =================================================================
    # Verification Summary
    # =================================================================
    log_section "Deployment Readiness Summary"

    log_info "Checks passed: $checks_passed/$total_checks"
    log_info "Checks failed: $checks_failed/$total_checks"

    if [[ $checks_failed -eq 0 ]]; then
        log_success "✅ Deployment verification PASSED"
        log_success "Federation is ready for deployment!"

        # Show deployment instructions
        log_section "Next Steps"
        log_info "To deploy this federation:"
        log_info "  1. Review artifacts in: $OUTPUT/.federation/"
        log_info "  2. Verify checksums: cd $OUTPUT && sha256sum -c .federation/checksums.sha256"
        log_info "  3. Deploy to GitHub Pages: Copy $OUTPUT/* to your gh-pages branch"
        log_info "  4. Verify at: ${FEDERATION_BASE_URL:-https://your-site.github.io}"

        exit_function
        return 0
    else
        log_error "❌ Deployment verification FAILED"
        log_error "Please fix the issues above before deploying"

        exit_function
        return 1
    fi
}

# Main execution function
main() {
    enter_function "main"

    # Track build start time for deployment manifest
    export BUILD_START_TIME=$(date +%s)

    # Parse arguments
    parse_arguments "$@"

    # Load and validate configuration
    if ! load_modules_config; then
        log_error "Failed to load federation configuration"
        exit 1
    fi

    if ! validate_configuration; then
        log_error "Configuration validation failed"
        exit 1
    fi

    # Show header (after config loaded so we have module count)
    if [[ "$QUIET" == "false" ]]; then
        show_federation_summary
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

    # Stage 1.5: Download existing pages (if preserve-base-site enabled)
    if [[ "$PRESERVE_BASE_SITE" == "true" ]]; then
        log_federation "Stage 1.5: Downloading Existing Pages"

        # Determine base URL from federation config
        local base_url="${FEDERATION_BASE_URL:-}"

        if [[ -z "$base_url" ]]; then
            log_error "Cannot preserve base site: baseURL not specified in modules.json"
            log_error "Add 'baseURL' to federation configuration or disable --preserve-base-site"
            exit 1
        fi

        # Create directory for existing content
        local existing_dir="$TEMP_DIR/existing-pages"

        if ! download_existing_pages "$base_url" "$existing_dir"; then
            log_error "Failed to download existing pages"
            log_error "Consider running without --preserve-base-site for full rebuild"
            exit 1
        fi

        # Store path for later merge
        export EXISTING_PAGES_DIR="$existing_dir"

        log_success "Existing pages preserved for merge"
    fi

    # Stage 2: Build orchestration
    if ! orchestrate_builds; then
        log_error "Build orchestration failed"
        exit 1
    fi

    # Stage 3: Output management
    log_federation "Stage 3: Output Management"

    # Merge module outputs into federation structure
    if ! merge_federation_output; then
        log_error "Failed to merge federation output"
        exit 1
    fi

    # Validate the merged output
    if ! validate_federation_output; then
        log_error "Federation output validation failed"
        exit 1
    fi

    # Stage 3.5: Deployment Preparation
    log_federation "Stage 3.5: Deployment Preparation"

    # Generate deployment artifacts (checksums, metadata)
    if ! generate_deployment_artifacts; then
        log_error "Failed to generate deployment artifacts"
        exit 1
    fi

    # Create enhanced federation manifest with deployment info
    if ! create_federation_manifest; then
        log_error "Failed to create federation manifest"
        exit 1
    fi

    # Verify deployment readiness (skip in dry-run mode)
    if [[ "$DRY_RUN" != "true" ]]; then
        if ! verify_deployment_ready; then
            log_error "Deployment readiness verification failed"
            log_error "Please review the issues above before deploying"
            exit 1
        fi
    else
        log_info "[DRY RUN] Skipping deployment readiness verification"
    fi

    # Generate final build report
    generate_build_report

    if [[ "$DRY_RUN" == "true" ]]; then
        log_success "Dry-run completed successfully - no files were created"
    else
        log_success "Federation build completed successfully"
        log_success "Output is deployment-ready - see deployment instructions above"
    fi

    exit_function
    return 0
}

# Execute main function with all arguments (only if script is run directly, not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
