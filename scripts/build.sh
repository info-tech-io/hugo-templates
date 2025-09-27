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

# Initialize error handling
init_error_handling

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

    # Copy template files
    local template_path="$PROJECT_ROOT/templates/$TEMPLATE"
    log_verbose "Copying template files from: $template_path"

    # Copy all files except .git directories
    log_verbose "Attempting to copy template files..."
    log_verbose "Template path: $template_path"
    log_verbose "Output path: $OUTPUT"

    # Try different copy methods with better error reporting
    if rsync --version >/dev/null 2>&1 && rsync -av --exclude='.git' "$template_path/" "$OUTPUT/" 2>/dev/null; then
        log_verbose "Template files copied successfully with rsync"
    elif cp -r "$template_path/"* "$OUTPUT/" 2>/dev/null; then
        log_verbose "Template files copied successfully with cp -r"
    else
        log_error "Failed to copy template files from $template_path to $OUTPUT"
        log_verbose "Template directory contents:"
        ls -la "$template_path" || true
        return 1
    fi

    # Copy custom content if specified
    if [[ -n "$CONTENT" ]]; then
        log_verbose "Copying custom content from: $CONTENT"
        mkdir -p "$OUTPUT/content"
        if cp -r "$CONTENT"/* "$OUTPUT/content/" 2>/dev/null; then
            log_verbose "Custom content copied successfully"
        else
            log_warning "Failed to copy custom content (may be expected if no content files exist)"
        fi
    fi

    # Initialize Git submodules if they exist
    if [[ -f "$PROJECT_ROOT/.gitmodules" ]]; then
        log_verbose "Initializing Git submodules..."
        cd "$PROJECT_ROOT"
        git submodule update --init --recursive 2>/dev/null || {
            log_warning "Failed to initialize Git submodules"
        }
        cd - >/dev/null
    fi

    # Copy theme if it exists as submodule
    local theme_path="$PROJECT_ROOT/themes/$THEME"
    if [[ -d "$theme_path" ]]; then
        log_verbose "Copying theme: $THEME"
        mkdir -p "$OUTPUT/themes"
        if cp -r "$theme_path" "$OUTPUT/themes/" 2>/dev/null; then
            log_verbose "Theme copied successfully"
        else
            log_warning "Failed to copy theme: $THEME"
        fi
    else
        log_verbose "Theme directory not found: $theme_path"
    fi

    # Copy components if they exist
    if [[ -n "$COMPONENTS" ]]; then
        IFS=',' read -ra COMP_ARRAY <<< "$COMPONENTS"
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

    # Check build output (Hugo now outputs directly to OUTPUT directory)
    if [[ -d "$OUTPUT" ]]; then
        local file_count=0
        local size="unknown"

        # Safe file counting with error handling
        if ! file_count=$(safe_execute "find '$OUTPUT' -type f ! -path '*/.git/*' 2>/dev/null | wc -l" "counting generated files" "true"); then
            log_warning "Could not count generated files in $OUTPUT"
            file_count="unknown"
        fi

        echo "   Files generated: $file_count"

        # Safe size calculation
        if command -v du >/dev/null 2>&1; then
            if ! size=$(safe_execute "du -sh '$OUTPUT' 2>/dev/null | cut -f1" "calculating directory size" "true"); then
                size="unknown"
            fi
        fi
        echo "   Total size: $size"

        # Verbose file listing with safe error handling
        if [[ "$VERBOSE" == "true" ]] && [[ "$file_count" != "unknown" ]] && [[ $file_count -gt 0 ]]; then
            echo ""
            log_info "Generated files:"

            local file_list
            if file_list=$(safe_execute "find '$OUTPUT' -type f ! -path '*/.git/*' 2>/dev/null | head -10" "listing generated files" "true"); then
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

    # Run Hugo build
    log_info "Starting Hugo build..."
    if ! run_hugo_build; then
        log_error "Hugo build failed"
        exit 1
    fi
    log_success "Hugo build completed"

    # Show build summary
    show_build_summary

    # Cleanup error handling system
    cleanup_error_handling
}

# Run main function with all arguments
main "$@"