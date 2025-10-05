#!/bin/bash
set -euo pipefail

#
# Hugo Template Factory Framework - Main Build Script v2.0
# The first parametrized scaffolding tool for Hugo ecosystem
#
# This script provides a bash-based interface for building Hugo sites
# with specified templates, themes, and components.
# Enhanced with comprehensive error handling and diagnostics.
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

# Legacy color definitions (maintained for backward compatibility)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m' # No Color

# Default values
TEMPLATE="default"
THEME="compose"
COMPONENTS=""
OUTPUT="./site"
CONTENT=""
CONFIG=""
MINIFY=false
DRAFT=false
FUTURE=false
BASE_URL=""
ENVIRONMENT="development"
VERBOSE=false
QUIET=false
LOG_LEVEL="info"
VALIDATE_ONLY=false
FORCE=false
DEBUG_MODE=false
ENABLE_CACHE=true
CACHE_CLEAR=false
CACHE_STATS=false
CACHE_HIT=false
ENABLE_PARALLEL=true
ENABLE_PERFORMANCE_TRACKING=false
PERFORMANCE_REPORT=false
PERFORMANCE_HISTORY=false

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
    [[ "$VERBOSE" == "true" ]] || return
    print_color "$GRAY" "🔍 $*"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Hugo Template Factory Framework - Build Script

OPTIONS:
    -t, --template <name>       Template to use (default: default)
    --theme <name>              Hugo theme to apply (default: compose)
    -c, --components <list>     Comma-separated list of components to include
    -o, --output <path>         Output directory (default: ./site)
    --content <path>            Path to content directory
    --config <path>             Path to custom configuration file
    --minify                    Enable Hugo minification
    --draft                     Include draft content
    --future                    Include future content
    --base-url <url>            Base URL for the site
    -e, --environment <env>     Hugo environment (default: development)
    -v, --verbose               Enable verbose output
    -q, --quiet                 Suppress non-error output
    --log-level <level>         Log level (debug|info|warn|error)
    --validate-only             Only validate configuration, don't build
    --force                     Force build even if output directory exists
    --debug                     Enable debug mode with detailed tracing
    --no-cache                  Disable intelligent caching system
    --cache-clear              Clear all cache data before build
    --cache-stats              Show cache statistics after build
    --no-parallel              Disable parallel processing optimizations
    --performance-track         Enable performance monitoring and tracking
    --performance-report        Show detailed performance analysis after build
    --performance-history       Display historical performance data
    -h, --help                  Show this help message

EXAMPLES:
    # Basic build with default template
    $0

    # Build with minimal template
    $0 --template=minimal --theme=compose

    # Build with specific components
    $0 --template=default --components=quiz-engine,analytics

    # Build with custom content directory
    $0 --content=/path/to/content --output=/path/to/output

    # Production build with minification
    $0 --environment=production --minify --base-url=https://example.com

    # Validate configuration only
    $0 --validate-only --verbose

    # Performance optimization examples
    $0 --template=minimal --performance-track --performance-report
    $0 --cache-clear --no-parallel --performance-track
    $0 --performance-history  # Show historical performance data

AVAILABLE TEMPLATES:
$(list_templates)

EOF
}

# Function to list available templates
list_templates() {
    local templates_dir="$PROJECT_ROOT/templates"
    if [[ -d "$templates_dir" ]]; then
        find "$templates_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | sed 's/^/    - /'
    else
        echo "    - No templates found"
    fi
}

# Function to validate input parameters
validate_parameters() {
    log_verbose "Validating input parameters..."

    # Check if template exists
    local template_path="$PROJECT_ROOT/templates/$TEMPLATE"
    if [[ ! -d "$template_path" ]]; then
        log_error "Template '$TEMPLATE' not found in $PROJECT_ROOT/templates/"
        log_info "Available templates:"
        list_templates
        return 1
    fi

    # Check if components.yml exists in template
    local components_file="$template_path/components.yml"
    if [[ ! -f "$components_file" ]]; then
        log_warning "No components.yml found in template '$TEMPLATE'"
    fi

    # Validate output directory
    if [[ "$OUTPUT" == "." || "$OUTPUT" == "./" ]]; then
        log_error "Output directory cannot be current directory"
        return 1
    fi

    # Check if output directory already exists and is not empty
    if [[ -d "$OUTPUT" && "$(ls -A "$OUTPUT" 2>/dev/null)" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            log_warning "Output directory '$OUTPUT' already exists and is not empty - continuing due to --force flag"
            if [[ "$VERBOSE" == "true" ]]; then
                echo "Contents will be overwritten:"
                ls -la "$OUTPUT" | head -5
            fi
        else
            log_error "Output directory '$OUTPUT' already exists and is not empty"
            log_info "Use --force to overwrite existing directory or choose a different output path"
            return 1
        fi
    fi

    # Validate content directory if specified
    if [[ -n "$CONTENT" && ! -d "$CONTENT" ]]; then
        log_error "Content directory '$CONTENT' not found"
        return 1
    fi

    # Validate configuration file if specified
    if [[ -n "$CONFIG" && ! -f "$CONFIG" ]]; then
        log_error "Configuration file '$CONFIG' not found"
        return 1
    fi

    # Check Hugo installation
    if ! command -v hugo >/dev/null 2>&1; then
        log_error "Hugo is not installed or not in PATH"
        log_info "Please install Hugo: https://gohugo.io/getting-started/installing/"
        return 1
    fi

    local hugo_version
    hugo_version=$(hugo version 2>/dev/null | head -1)
    log_verbose "Found Hugo: $hugo_version"

    log_success "Parameter validation completed"
    return 0
}

# Function to load configuration from module.json
load_module_config() {
    enter_function "load_module_config"

    if [[ -z "$CONFIG" ]]; then
        log_verbose "No module configuration file specified"
        exit_function
        return 0
    fi

    set_error_context "Loading module configuration from $CONFIG"

    # Validate configuration file exists and is readable
    if ! safe_file_operation "read" "$CONFIG"; then
        log_config_error "Configuration file validation failed: $CONFIG"
        exit_function
        return 1
    fi

    log_info "Loading module configuration from: $CONFIG"

    # Use enhanced Node.js parsing with comprehensive error handling
    if command -v node >/dev/null 2>&1; then
        # Create temporary parsing script with enhanced error handling
        local temp_script
        temp_script=$(mktemp) || {
            log_io_error "Failed to create temporary script file"
            exit_function
            return 1
        }

        # Enhanced Node.js script with better error reporting
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
        console.error(`  Line: ${parseError.message}`);
        console.error(`  Content preview: ${configContent.substring(0, 100)}...`);
        process.exit(1);
    }

    // Validate configuration structure
    if (typeof config !== 'object' || config === null) {
        console.error(`ERROR: Configuration must be a JSON object, got: ${typeof config}`);
        process.exit(1);
    }

    // Support both hugo_config (new format) and build (old format) for compatibility
    const buildConfig = config.hugo_config || config.build;

    // Extract and validate configuration values
    if (buildConfig && typeof buildConfig === 'object') {
        if (buildConfig.template && typeof buildConfig.template === 'string') {
            console.log('TEMPLATE=' + buildConfig.template);
        }
        if (buildConfig.theme && typeof buildConfig.theme === 'string') {
            console.log('THEME=' + buildConfig.theme);
        }
        if (buildConfig.components && Array.isArray(buildConfig.components)) {
            console.log('COMPONENTS=' + buildConfig.components.join(','));
        }
    }

    if (config.site && typeof config.site === 'object') {
        if (config.site.baseURL && typeof config.site.baseURL === 'string') {
            console.log('BASE_URL=' + config.site.baseURL);
        }
        if (config.site.language && typeof config.site.language === 'string') {
            console.log('LANGUAGE=' + config.site.language);
        }
    }

    // Success - configuration parsed successfully
    process.exit(0);

} catch (error) {
    console.error(`ERROR: Unexpected error parsing configuration: ${error.message}`);
    console.error(`Stack: ${error.stack}`);
    process.exit(1);
}
EOF

        # Execute Node.js parser with enhanced error capture
        local config_vars
        config_vars=$(safe_node_parse "$temp_script" "$CONFIG" "module.json configuration parsing") || {
            log_config_error "Module.json parsing failed" "Check JSON syntax and structure"
            rm -f "$temp_script"
            clear_error_context
            exit_function
            return 1
        }

        # Apply extracted configuration values
        if [[ -n "$config_vars" ]]; then
            while IFS= read -r line; do
                if [[ -n "$line" && "$line" =~ ^[A-Z_]+=.+ ]]; then
                    log_verbose "Applying config: $line"
                    eval "$line" || {
                        log_config_error "Failed to apply configuration line: $line"
                        rm -f "$temp_script"
                        clear_error_context
                        exit_function
                        return 1
                    }
                fi
            done <<< "$config_vars"
        fi

        rm -f "$temp_script"
        log_success "Module configuration loaded successfully"
    else
        log_dependency_error "Node.js not available for module.json parsing" "Install Node.js 16+ for advanced configuration features"
        clear_error_context
        exit_function
        return 1
    fi

    clear_error_context
    exit_function
    return 0
}

# Function to parse components.yml
parse_components() {
    enter_function "parse_components"

    local template_path="$PROJECT_ROOT/templates/$TEMPLATE"
    local components_file="$template_path/components.yml"

    set_error_context "Parsing components for template $TEMPLATE"

    log_verbose "Template path: $template_path"
    log_verbose "Looking for components file: $components_file"

    # Check if template directory exists
    if [[ ! -d "$template_path" ]]; then
        log_validation_error "Template directory not found: $template_path" "Check if template '$TEMPLATE' exists"
        clear_error_context
        exit_function
        return 1
    fi

    # Components file is optional - if not found, continue without component processing
    if [[ ! -f "$components_file" ]]; then
        log_verbose "No components.yml file found, skipping component processing"
        clear_error_context
        exit_function
        return 0
    fi

    log_info "Parsing components from $components_file"

    # Use Node.js to parse YAML if available
    if command -v node >/dev/null 2>&1; then
        local js_parser="$SCRIPT_DIR/parse-components.js"

        # Validate parser script exists
        if [[ ! -f "$js_parser" ]]; then
            log_dependency_error "Node.js YAML parser not found: $js_parser" "Ensure parse-components.js is present in scripts directory"
            clear_error_context
            exit_function
            return 1
        fi

        log_verbose "Using Node.js YAML parser: $js_parser"

        # Use safe_node_parse for comprehensive error handling
        local parse_output
        parse_output=$(safe_node_parse "$js_parser" "$components_file" "components.yml parsing") || {
            # Component parsing failure is not fatal - log warning and continue
            log_structured "WARN" "BUILD" "Component parsing failed, continuing without component processing" "Template: $TEMPLATE"
            clear_error_context
            exit_function
            return 0
        }

        # Process successful parsing output
        if [[ -n "$parse_output" ]]; then
            log_verbose "Component parsing successful"
            [[ "$VERBOSE" == "true" ]] && echo "$parse_output"
            log_success "Components processed successfully"
        else
            log_verbose "No component output generated (empty components.yml)"
        fi
    else
        log_dependency_error "Node.js not available for component parsing" "Install Node.js 16+ for component processing features"
        clear_error_context
        exit_function
        return 1
    fi

    clear_error_context
    exit_function
    return 0
}

# Function to prepare build environment
prepare_build_environment() {
    [[ "$DEBUG_MODE" == "true" ]] && set -x
    log_info "Preparing build environment..."

    # Create output directory
    mkdir -p "$OUTPUT"
    log_verbose "Created output directory: $OUTPUT"

    # Parallel copying optimization: template, content, and theme files
    local template_path="$PROJECT_ROOT/templates/$TEMPLATE"
    local theme_path="$PROJECT_ROOT/themes/$THEME"
    local copy_pids=()

    log_verbose "Starting parallel file copying operations..."

    # Function to copy template files (background job)
    copy_template_files() {
        log_verbose "Copying template files from: $template_path"
        # Try different copy methods with better error reporting
        if rsync --version >/dev/null 2>&1 && rsync -av --exclude='.git' "$template_path/" "$OUTPUT/" 2>/dev/null; then
            log_verbose "Template files copied successfully with rsync"
            return 0
        elif cp -r "$template_path/"* "$OUTPUT/" 2>/dev/null; then
            log_verbose "Template files copied successfully with cp -r"
            return 0
        else
            log_error "Failed to copy template files from $template_path to $OUTPUT"
            log_verbose "Template directory contents:"
            ls -la "$template_path" || true
            return 1
        fi
    }

    # Function to copy theme files (background job)
    copy_theme_files() {
        if [[ -d "$theme_path" ]]; then
            log_verbose "Copying theme: $THEME"
            mkdir -p "$OUTPUT/themes"
            if cp -r "$theme_path" "$OUTPUT/themes/" 2>/dev/null; then
                log_verbose "Theme copied successfully"
                return 0
            else
                log_warning "Failed to copy theme: $THEME"
                return 1
            fi
        else
            log_verbose "Theme directory not found: $theme_path"
            return 0
        fi
    }

    # Function to copy custom content (background job)
    copy_custom_content() {
        if [[ -n "$CONTENT" ]]; then
            log_verbose "Copying custom content from: $CONTENT"
            mkdir -p "$OUTPUT/content"
            if cp -r "$CONTENT"/* "$OUTPUT/content/" 2>/dev/null; then
                log_verbose "Custom content copied successfully"
                return 0
            else
                log_warning "Failed to copy custom content (may be expected if no content files exist)"
                return 1
            fi
        else
            return 0
        fi
    }

    # Function to initialize Git submodules (background job)
    init_git_submodules() {
        if [[ -f "$PROJECT_ROOT/.gitmodules" ]]; then
            log_verbose "Initializing Git submodules..."
            cd "$PROJECT_ROOT"
            git submodule update --init --recursive 2>/dev/null || {
                log_warning "Failed to initialize Git submodules"
                return 1
            }
            cd - >/dev/null
            return 0
        else
            return 0
        fi
    }

    # Start template copying (must complete first as other operations depend on it)
    copy_template_files
    local template_result=$?

    if [[ $template_result -eq 0 ]]; then
        # Choose parallel or sequential execution based on ENABLE_PARALLEL
        if [[ "$ENABLE_PARALLEL" == "true" ]]; then
            # Initialize process tracking array
            local copy_pids=()

            # Start parallel operations for theme, content, and submodules
            copy_theme_files &
            copy_pids+=($!)

            copy_custom_content &
            copy_pids+=($!)

            init_git_submodules &
            copy_pids+=($!)

            # Wait for all parallel operations to complete
            local failed_operations=0
            for pid in "${copy_pids[@]}"; do
                if ! wait "$pid"; then
                    ((failed_operations++))
                fi
            done

            if [[ $failed_operations -eq 0 ]]; then
                log_verbose "All file copying operations completed successfully in parallel"
            else
                log_warning "$failed_operations parallel file operations encountered issues"
            fi
        else
            # Sequential execution (original behavior)
            log_verbose "Using sequential file copying (parallel processing disabled)"
            copy_theme_files
            copy_custom_content
            init_git_submodules
        fi
    else
        log_error "Template copying failed, skipping dependent operations"
        return 1
    fi

    # Copy components if they exist (with parallel processing optimization)
    if [[ -n "$COMPONENTS" ]]; then
        IFS=',' read -ra COMP_ARRAY <<< "$COMPONENTS"
        local component_count=${#COMP_ARRAY[@]}

        # Use parallel processing for multiple components (if enabled)
        if [[ $component_count -gt 1 && "$ENABLE_PARALLEL" == "true" ]]; then
            log_verbose "Copying $component_count components in parallel..."
            local pids=()
            local max_parallel_jobs=4  # Limit concurrent jobs to avoid overwhelming system
            local current_jobs=0

            # Function to copy a single component (runs in background)
            copy_component_parallel() {
                local component="$1"
                local comp_path="$PROJECT_ROOT/components/$component"

                if [[ -d "$comp_path" ]]; then
                    # Copy component files to appropriate locations
                    if [[ -d "$comp_path/static" ]]; then
                        mkdir -p "$OUTPUT/static"
                        cp -r "$comp_path/static"/* "$OUTPUT/static/" 2>/dev/null || true
                    fi
                    if [[ -d "$comp_path/layouts" ]]; then
                        mkdir -p "$OUTPUT/layouts"
                        cp -r "$comp_path/layouts"/* "$OUTPUT/layouts/" 2>/dev/null || true
                    fi
                    log_verbose "Component copied: $component"
                else
                    log_warning "Component '$component' not found in $PROJECT_ROOT/components/"
                fi
            }

            # Launch parallel component copying jobs
            for component in "${COMP_ARRAY[@]}"; do
                component=$(echo "$component" | xargs) # trim whitespace

                # Wait if we've reached max parallel jobs
                if [[ $current_jobs -ge $max_parallel_jobs ]]; then
                    wait "${pids[0]}"  # Wait for first job to complete
                    pids=("${pids[@]:1}")  # Remove first PID from array
                    ((current_jobs--))
                fi

                # Start new background job
                copy_component_parallel "$component" &
                pids+=($!)
                ((current_jobs++))
            done

            # Wait for all remaining jobs to complete
            for pid in "${pids[@]}"; do
                wait "$pid"
            done

            log_verbose "All $component_count components copied in parallel"
        else
            # Single component - use original sequential method
            for component in "${COMP_ARRAY[@]}"; do
                component=$(echo "$component" | xargs) # trim whitespace
                local comp_path="$PROJECT_ROOT/components/$component"
                if [[ -d "$comp_path" ]]; then
                    log_verbose "Copying component: $component"
                    # Copy component files to appropriate locations
                    if [[ -d "$comp_path/static" ]]; then
                        mkdir -p "$OUTPUT/static"
                        cp -r "$comp_path/static"/* "$OUTPUT/static/" 2>/dev/null || log_verbose "No static files to copy for component $component"
                    fi
                    if [[ -d "$comp_path/layouts" ]]; then
                        mkdir -p "$OUTPUT/layouts"
                        cp -r "$comp_path/layouts"/* "$OUTPUT/layouts/" 2>/dev/null || log_verbose "No layout files to copy for component $component"
                    fi
                else
                    log_warning "Component '$component' not found in $PROJECT_ROOT/components/"
                fi
            done
        fi
    fi

    log_success "Build environment prepared"
}

# Function to update Hugo configuration
update_hugo_config() {
    log_info "Updating Hugo configuration..."

    local hugo_config="$OUTPUT/hugo.toml"
    if [[ ! -f "$hugo_config" ]]; then
        log_warning "No hugo.toml found, creating minimal configuration"
        cat > "$hugo_config" << EOF
baseURL = '${BASE_URL:-http://localhost:1313}'
languageCode = 'en-us'
title = 'Hugo Template Factory Site'
theme = '$THEME'
EOF
    fi

    # Update configuration based on parameters
    if [[ -n "$BASE_URL" ]]; then
        log_verbose "Setting baseURL to: $BASE_URL"
        sed -i "s|baseURL = .*|baseURL = '$BASE_URL'|" "$hugo_config"
    fi

    if [[ "$THEME" != "compose" ]]; then
        log_verbose "Setting theme to: $THEME"
        sed -i "s|theme = .*|theme = '$THEME'|" "$hugo_config"
    fi

    # Add environment-specific settings
    if [[ "$ENVIRONMENT" == "production" ]]; then
        echo "" >> "$hugo_config"
        echo "# Production environment settings" >> "$hugo_config"
        echo "environment = \"production\"" >> "$hugo_config"
    fi

    log_success "Hugo configuration updated"
}

# Function to check and use cached build if available
check_build_cache() {
    if [[ "$ENABLE_CACHE" != "true" ]]; then
        log_verbose "Cache disabled, skipping cache check"
        return 1
    fi

    log_info "Checking build cache..."

    # Generate cache key based on template, theme, components, and config
    local template_hash
    template_hash=$(find "$PROJECT_ROOT/templates/$TEMPLATE" -type f \( -name "*.md" -o -name "*.toml" -o -name "*.yml" -o -name "*.yaml" -o -name "*.html" \) -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1 || echo "notfound")

    local config_hash
    config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}_${CONTENT}" | sha256sum | cut -d' ' -f1)

    local hugo_version
    hugo_version=$(hugo version 2>/dev/null | head -1 | cut -d' ' -f1 || echo "unknown")

    local cache_key
    cache_key=$(generate_build_cache_key "${template_hash}_${config_hash}" "$hugo_version" "$ENVIRONMENT" "$MINIFY")

    log_verbose "Generated cache key: $cache_key"

    # Check if cached build exists
    if cache_exists "$cache_key" "l2"; then
        log_info "Found cached build, retrieving..."
        if cache_retrieve "$cache_key" "$OUTPUT" "l2"; then
            log_success "Build restored from cache"
            return 0
        else
            log_warning "Cache retrieval failed, proceeding with full build"
            return 1
        fi
    else
        log_verbose "No cached build found"
        return 1
    fi
}

# Function to store build in cache
store_build_cache() {
    if [[ "$ENABLE_CACHE" != "true" ]]; then
        return 0
    fi

    log_info "Storing build in cache..."

    # Generate same cache key as in check_build_cache
    local template_hash
    template_hash=$(find "$PROJECT_ROOT/templates/$TEMPLATE" -type f \( -name "*.md" -o -name "*.toml" -o -name "*.yml" -o -name "*.yaml" -o -name "*.html" \) -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1 || echo "notfound")

    local config_hash
    config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}_${CONTENT}" | sha256sum | cut -d' ' -f1)

    local hugo_version
    hugo_version=$(hugo version 2>/dev/null | head -1 | cut -d' ' -f1 || echo "unknown")

    local cache_key
    cache_key=$(generate_build_cache_key "${template_hash}_${config_hash}" "$hugo_version" "$ENVIRONMENT" "$MINIFY")

    # Create metadata
    local metadata
    metadata=$(cat <<EOF
{
    "template": "$TEMPLATE",
    "theme": "$THEME",
    "components": "$COMPONENTS",
    "environment": "$ENVIRONMENT",
    "minify": $MINIFY,
    "hugo_version": "$hugo_version",
    "base_url": "$BASE_URL"
}
EOF
    )

    # Store build in cache
    if cache_store "$cache_key" "$OUTPUT" "l2" "$metadata"; then
        log_success "Build cached successfully"
    else
        log_warning "Failed to cache build"
    fi
}

# Function to run Hugo build
run_hugo_build() {
    log_info "Running Hugo build..."

    cd "$OUTPUT"

    # Build Hugo command
    local hugo_cmd="hugo"

    # Add flags based on parameters
    [[ "$MINIFY" == "true" ]] && hugo_cmd+=" --minify"
    [[ "$DRAFT" == "true" ]] && hugo_cmd+=" --draft"
    [[ "$FUTURE" == "true" ]] && hugo_cmd+=" --future"
    [[ -n "$BASE_URL" ]] && hugo_cmd+=" --baseURL \"$BASE_URL\""
    [[ "$ENVIRONMENT" != "development" ]] && hugo_cmd+=" --environment $ENVIRONMENT"

    # Set log level (Hugo 0.110+ uses different flags)
    case "$LOG_LEVEL" in
        debug) hugo_cmd+=" --verboseLog" ;;
        warn) hugo_cmd+=" --quiet" ;;
        error) hugo_cmd+=" --quiet" ;;
        *) # info level - no special flags needed
            ;;
    esac

    # Set destination (output to current directory since we're already in OUTPUT)
    hugo_cmd+=" --destination ."

    log_verbose "Running: $hugo_cmd"

    # Execute Hugo build
    if [[ "$VERBOSE" == "true" ]]; then
        eval "$hugo_cmd"
    else
        # Capture both stdout and stderr for error reporting
        local build_output
        build_output=$(eval "$hugo_cmd" 2>&1) || {
            log_error "Hugo build failed with output:"
            echo "$build_output" | sed 's/^/   /' >&2
            return 1
        }
        # Only show success message in non-verbose mode
        log_verbose "Hugo build output: $build_output"
    fi

    cd - >/dev/null

    log_success "Hugo build completed"
}

# Function to show build summary
show_build_summary() {
    enter_function "show_build_summary"
    set_error_context "Generating build summary"

    log_info "Build Summary:"
    echo "   Template: $TEMPLATE"
    echo "   Theme: $THEME"
    [[ -n "$COMPONENTS" ]] && echo "   Components: $COMPONENTS"
    echo "   Environment: $ENVIRONMENT"
    echo "   Output: $OUTPUT"
    if [[ "$ENABLE_CACHE" == "true" ]]; then
        if [[ "$CACHE_HIT" == "true" ]]; then
            echo "   Cache: ✅ Hit (restored from cache)"
        else
            echo "   Cache: ⚡ Miss (built from source, cached for future)"
        fi
    else
        echo "   Cache: ❌ Disabled"
    fi
    if [[ "$ENABLE_PARALLEL" == "true" ]]; then
        echo "   Parallel Processing: ✅ Enabled"
    else
        echo "   Parallel Processing: ❌ Disabled"
    fi
    if [[ "$ENABLE_PERFORMANCE_TRACKING" == "true" ]]; then
        echo "   Performance Tracking: ✅ Enabled"
    else
        echo "   Performance Tracking: ❌ Disabled"
    fi

    # Check build output (Hugo now outputs directly to OUTPUT directory)
    if [[ -d "$OUTPUT" ]]; then
        local file_count=0
        local size="unknown"

        # Safe file counting with error handling
        if ! file_count=$(find "$OUTPUT" -type f ! -path '*/.git/*' 2>/dev/null | wc -l); then
            log_warning "Could not count generated files in $OUTPUT"
            file_count="unknown"
        fi

        echo "   Files generated: $file_count"

        # Safe size calculation
        if command -v du >/dev/null 2>&1; then
            if ! size=$(du -sh "$OUTPUT" 2>/dev/null | cut -f1); then
                size="unknown"
            fi
        fi
        echo "   Total size: $size"

        # Verbose file listing with safe error handling
        if [[ "$VERBOSE" == "true" ]] && [[ "$file_count" != "unknown" ]] && [[ $file_count -gt 0 ]]; then
            echo ""
            log_info "Generated files:"

            local file_list
            if file_list=$(find "$OUTPUT" -type f ! -path '*/.git/*' 2>/dev/null | head -10); then
                echo "$file_list" | sed 's|^|   |'
                if [[ $file_count -gt 10 ]]; then
                    echo "   ... and $((file_count - 10)) more files"
                fi
            else
                log_warning "Could not list generated files"
            fi
        fi
    else
        log_warning "Output directory not found: $OUTPUT"
    fi

    # Show error/warning summary
    if [[ $ERROR_COUNT -gt 0 ]] || [[ $WARNING_COUNT -gt 0 ]]; then
        echo ""
        echo "   Issues encountered:"
        [[ $ERROR_COUNT -gt 0 ]] && echo "   Errors: $ERROR_COUNT"
        [[ $WARNING_COUNT -gt 0 ]] && echo "   Warnings: $WARNING_COUNT"
    fi

    echo ""
    if [[ $ERROR_COUNT -eq 0 ]]; then
        log_success "Build completed successfully!"
        echo "   Run: hugo server -s $OUTPUT to preview locally"
    else
        log_warning "Build completed with errors. Check error log for details."
        echo "   Error diagnostics: $ERROR_STATE_FILE"
    fi

    clear_error_context
    exit_function
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--template)
                TEMPLATE="$2"
                shift 2
                ;;
            --theme)
                THEME="$2"
                shift 2
                ;;
            -c|--components)
                COMPONENTS="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            --content)
                CONTENT="$2"
                shift 2
                ;;
            --config)
                CONFIG="$2"
                shift 2
                ;;
            --minify)
                MINIFY=true
                shift
                ;;
            --draft)
                DRAFT=true
                shift
                ;;
            --future)
                FUTURE=true
                shift
                ;;
            --base-url)
                BASE_URL="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            --log-level)
                LOG_LEVEL="$2"
                shift 2
                ;;
            --validate-only)
                VALIDATE_ONLY=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                VERBOSE=true
                shift
                ;;
            --no-cache)
                ENABLE_CACHE=false
                shift
                ;;
            --cache-clear)
                CACHE_CLEAR=true
                shift
                ;;
            --cache-stats)
                CACHE_STATS=true
                shift
                ;;
            --no-parallel)
                ENABLE_PARALLEL=false
                shift
                ;;
            --performance-track)
                ENABLE_PERFORMANCE_TRACKING=true
                shift
                ;;
            --performance-report)
                PERFORMANCE_REPORT=true
                shift
                ;;
            --performance-history)
                PERFORMANCE_HISTORY=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Handle cache operations
    if [[ "$CACHE_CLEAR" == "true" ]]; then
        log_info "Clearing cache..."
        clear_cache
    fi

    # Disable caching if requested
    if [[ "$ENABLE_CACHE" == "false" ]]; then
        export HUGO_TEMPLATE_CACHE_ENABLED=false
        log_info "Intelligent caching disabled"
    fi

    # Handle performance history request
    if [[ "$PERFORMANCE_HISTORY" == "true" ]]; then
        show_performance_history
        exit 0
    fi

    # Initialize performance session if tracking is enabled
    if [[ "$ENABLE_PERFORMANCE_TRACKING" == "true" ]]; then
        init_performance_session "$TEMPLATE" "$THEME" "$COMPONENTS" "$ENVIRONMENT" "$ENABLE_CACHE" "$ENABLE_PARALLEL"
        log_verbose "Performance tracking initialized"
    fi

    # Show header
    if [[ "$QUIET" != "true" ]]; then
        print_color "$BLUE" "🏗️  Hugo Template Factory Build Script"
        print_color "$GRAY" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi

    # Load module configuration first (before validation)
    if ! load_module_config; then
        exit 1
    fi

    # Validate parameters
    if ! validate_parameters; then
        exit 1
    fi

    # If validation only, exit here
    if [[ "$VALIDATE_ONLY" == "true" ]]; then
        log_success "Validation completed successfully"
        exit 0
    fi

    # Parse components configuration
    log_info "Starting component parsing..."

    # Ensure parse_components doesn't fail the entire build
    set +e
    parse_components
    local parse_result=$?
    set -e

    if [[ $parse_result -eq 0 ]]; then
        log_success "Component parsing completed"
    else
        log_warning "Component parsing encountered issues but continuing build..."
    fi

    # Prepare build environment
    log_info "Starting build environment preparation..."
    if ! prepare_build_environment; then
        log_error "Build environment preparation failed"
        exit 1
    fi
    log_success "Build environment preparation completed"

    # Update Hugo configuration
    log_info "Starting Hugo configuration update..."
    if ! update_hugo_config; then
        log_error "Hugo configuration update failed"
        exit 1
    fi
    log_success "Hugo configuration update completed"

    # Check for cached build
    if check_build_cache; then
        CACHE_HIT=true
        log_success "Build completed using cached data"
    else
        # Run Hugo build
        log_info "Starting Hugo build..."
        if ! run_hugo_build; then
            log_error "Hugo build failed"
            exit 1
        fi
        log_success "Hugo build completed"

        # Store build in cache for future use
        store_build_cache
    fi

    # Show build summary
    show_build_summary

    # Show cache statistics if requested
    if [[ "$CACHE_STATS" == "true" || "$VERBOSE" == "true" ]]; then
        echo ""
        show_cache_stats
    fi

    # Finalize performance session and show reports if enabled
    if [[ "$ENABLE_PERFORMANCE_TRACKING" == "true" ]]; then
        finalize_performance_session "$CACHE_HIT"

        if [[ "$PERFORMANCE_REPORT" == "true" || "$VERBOSE" == "true" ]]; then
            echo ""
            show_performance_analysis
        fi
    fi

    # Cleanup error handling system
    cleanup_error_handling

    # Explicit success exit for successful builds
    return 0
}

# Run main function with all arguments
main "$@"