#!/bin/bash
set -euo pipefail

#
# Hugo Template Factory Framework - Main Build Script
# The first parametrized scaffolding tool for Hugo ecosystem
#
# This script provides a bash-based interface for building Hugo sites
# with specified templates, themes, and components.
#

# Colors for output
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

# Script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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
    if [[ -z "$CONFIG" ]]; then
        log_verbose "No module configuration file specified"
        return 0
    fi

    if [[ ! -f "$CONFIG" ]]; then
        log_error "Configuration file not found: $CONFIG"
        return 1
    fi

    log_verbose "Loading module configuration from: $CONFIG"

    # Use Node.js to parse JSON if available
    if command -v node >/dev/null 2>&1; then
        # Extract configuration values using node
        local temp_script=$(mktemp)
        cat > "$temp_script" << 'EOF'
const fs = require('fs');
const config = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));

// Support both hugo_config (new format) and build (old format) for compatibility
const buildConfig = config.hugo_config || config.build;
if (buildConfig && buildConfig.template) {
    console.log('TEMPLATE=' + buildConfig.template);
}
if (buildConfig && buildConfig.theme) {
    console.log('THEME=' + buildConfig.theme);
}
if (buildConfig && buildConfig.components && Array.isArray(buildConfig.components)) {
    console.log('COMPONENTS=' + buildConfig.components.join(','));
}
if (config.site && config.site.baseURL) {
    console.log('BASE_URL=' + config.site.baseURL);
}
if (config.site && config.site.language) {
    console.log('LANGUAGE=' + config.site.language);
}
EOF

        # Parse configuration and apply values
        local config_vars
        config_vars=$(node "$temp_script" "$CONFIG" 2>/dev/null) || {
            log_warning "Failed to parse module.json with Node.js"
            rm -f "$temp_script"
            return 1
        }

        # Apply extracted configuration
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                log_verbose "Applying config: $line"
                eval "$line"
            fi
        done <<< "$config_vars"

        rm -f "$temp_script"
        log_success "Module configuration loaded successfully"
    else
        log_warning "Node.js not available, skipping detailed module.json parsing"
    fi

    return 0
}

# Function to parse components.yml
parse_components() {
    local template_path="$PROJECT_ROOT/templates/$TEMPLATE"
    local components_file="$template_path/components.yml"

    if [[ ! -f "$components_file" ]]; then
        log_verbose "No components.yml file found, skipping component processing"
        return 0
    fi

    log_verbose "Parsing components from $components_file"

    # Use Node.js to parse YAML if available, otherwise skip detailed parsing
    if command -v node >/dev/null 2>&1; then
        local js_parser="$SCRIPT_DIR/parse-components.js"
        if [[ -f "$js_parser" ]]; then
            log_verbose "Using Node.js YAML parser"
            node "$js_parser" "$components_file"
        else
            log_verbose "Node.js YAML parser not found, using basic parsing"
        fi
    else
        log_verbose "Node.js not available, skipping advanced component parsing"
    fi
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
    log_info "Build Summary:"
    echo "   Template: $TEMPLATE"
    echo "   Theme: $THEME"
    [[ -n "$COMPONENTS" ]] && echo "   Components: $COMPONENTS"
    echo "   Environment: $ENVIRONMENT"
    echo "   Output: $OUTPUT"

    # Check build output (Hugo now outputs directly to OUTPUT directory)
    if [[ -d "$OUTPUT" ]]; then
        local file_count
        file_count=$(find "$OUTPUT" -type f ! -path "*/.git/*" 2>/dev/null | wc -l)
        echo "   Files generated: $file_count"

        if command -v du >/dev/null 2>&1; then
            local size
            size=$(du -sh "$OUTPUT" 2>/dev/null | cut -f1 || echo "unknown")
            echo "   Total size: $size"
        fi

        if [[ "$VERBOSE" == "true" ]]; then
            echo ""
            log_info "Generated files:"
            find "$OUTPUT" -type f ! -path "*/.git/*" 2>/dev/null | head -10 | sed 's|^|   |'
            if [[ $file_count -gt 10 ]]; then
                echo "   ... and $((file_count - 10)) more files"
            fi
        fi
    fi

    echo ""
    log_success "Build completed successfully!"
    echo "   Run: hugo server -s $OUTPUT to preview locally"
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
    parse_components

    # Prepare build environment
    prepare_build_environment

    # Update Hugo configuration
    update_hugo_config

    # Run Hugo build
    run_hugo_build

    # Show build summary
    show_build_summary
}

# Run main function with all arguments
main "$@"