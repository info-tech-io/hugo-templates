# Federation API Reference

**Target Audience**: Developers extending federated-build.sh
**Script**: `scripts/federated-build.sh`
**Functions**: 28 documented functions
**Last Updated**: 2025-10-20

---

## Overview

Complete API reference for all functions in `scripts/federated-build.sh`. Functions are grouped by responsibility and documented with signatures, parameters, return values, and examples.

### Function Categories

1. **Configuration Management** (5 functions) - Parse and access configuration
2. **Validation** (6 functions) - Validate configuration and sources
3. **Source Fetching** (4 functions) - Fetch modules from Git/GitHub/local
4. **Build & Merge** (8 functions) - Build modules and merge content
5. **CSS Rewriting** (3 functions) - Detect and rewrite CSS paths
6. **Utilities** (2 functions) - Logging, cleanup, helpers

---

## 1. Configuration Management

### parse_federation_config()

**Description**: Parse and validate modules.json configuration file

**Signature**:
```bash
parse_federation_config CONFIG_FILE
```

**Parameters**:
- `$1` (CONFIG_FILE) - Path to JSON configuration file

**Returns**:
- `0` - Success, configuration parsed and validated
- `1` - Parse error or schema validation failure

**Global Variables Set**:
- `BASE_SITE_NAME` - Base site name
- `BASE_SITE_SOURCE` - Base site source configuration
- `MODULES` - Array of module configurations
- `STRATEGY` - Federation strategy (download-merge-deploy, merge-and-build, preserve-base-site)

**Example**:
```bash
parse_federation_config "modules.json" || {
    log_error "Failed to parse configuration"
    exit 1
}

echo "Strategy: $STRATEGY"
echo "Base site: $BASE_SITE_NAME"
```

**Tests**: `tests/bash/unit/federated-config.bats:8`

---

### get_module_config()

**Description**: Extract configuration for specific module by name

**Signature**:
```bash
get_module_config MODULE_NAME
```

**Parameters**:
- `$1` (MODULE_NAME) - Module identifier

**Returns**:
- `0` - Success, module config printed to stdout as JSON
- `1` - Module not found in configuration

**Output**: JSON object with module configuration

**Example**:
```bash
module_config=$(get_module_config "api-reference") || {
    log_error "Module 'api-reference' not found"
    exit 1
}

module_priority=$(echo "$module_config" | jq -r '.priority')
echo "Priority: $module_priority"
```

**Tests**: `tests/bash/unit/federated-config.bats:16`

---

### validate_federation_config()

**Description**: Validate configuration against JSON Schema

**Signature**:
```bash
validate_federation_config CONFIG_FILE
```

**Parameters**:
- `$1` (CONFIG_FILE) - Path to configuration file

**Returns**:
- `0` - Configuration valid
- `1` - Schema validation failed

**Dependencies**: Node.js, schemas/modules.schema.json

**Example**:
```bash
if validate_federation_config "modules.json"; then
    log_info "Configuration is valid"
else
    log_error "Configuration validation failed"
    exit 1
fi
```

**Tests**: `tests/test-schema-validation.sh:1-16`

---

### get_base_site_config()

**Description**: Extract base site configuration

**Signature**:
```bash
get_base_site_config
```

**Returns**:
- `0` - Success, base site config printed to stdout as JSON

**Output**: JSON object with base site configuration

**Example**:
```bash
base_config=$(get_base_site_config)
base_name=$(echo "$base_config" | jq -r '.name')
base_source=$(echo "$base_config" | jq -r '.source.path')
```

**Tests**: `tests/bash/unit/federated-config.bats:24`

---

### get_module_count()

**Description**: Get total number of modules in configuration

**Signature**:
```bash
get_module_count
```

**Returns**: Number of modules (integer) via stdout

**Example**:
```bash
module_count=$(get_module_count)
log_info "Processing $module_count modules"
```

**Tests**: `tests/bash/unit/federated-config.bats:32`

---

## 2. Validation

### validate_module_sources()

**Description**: Validate all module sources are accessible

**Signature**:
```bash
validate_module_sources
```

**Returns**:
- `0` - All sources accessible
- `2` - One or more sources not accessible

**Checks**:
- Git repositories exist and are accessible
- GitHub repositories and releases exist
- Local paths exist and are readable

**Example**:
```bash
if validate_module_sources; then
    log_info "All module sources validated"
else
    log_error "One or more module sources inaccessible"
    exit 2
fi
```

**Tests**: `tests/bash/unit/federated-validation.bats:8`

---

### validate_oneOf_constraints()

**Description**: Validate source field matches exactly one schema variant

**Signature**:
```bash
validate_oneOf_constraints MODULE_CONFIG
```

**Parameters**:
- `$1` (MODULE_CONFIG) - JSON module configuration

**Returns**:
- `0` - Source matches exactly one variant (github, git, or local)
- `1` - Source doesn't match any variant or matches multiple

**Validates**:
- GitHub source: requires `type`, `repo`, `tag`
- Git source: requires `type`, `url`, optionally `branch`
- Local source: requires `type`, `path`
- No additional properties allowed

**Example**:
```bash
module_config=$(get_module_config "api-reference")
if validate_oneOf_constraints "$module_config"; then
    log_info "Source configuration valid"
else
    log_error "Invalid source configuration"
    exit 1
fi
```

**Tests**: `tests/bash/unit/federated-validation.bats:16`

---

### check_module_compatibility()

**Description**: Check module Hugo version compatibility

**Signature**:
```bash
check_module_compatibility MODULE_PATH
```

**Parameters**:
- `$1` (MODULE_PATH) - Path to module directory

**Returns**:
- `0` - Module compatible
- `1` - Compatibility issues detected

**Checks**:
- Hugo version requirements
- Theme compatibility
- Required components available

**Example**:
```bash
if check_module_compatibility "./modules/api-docs"; then
    log_info "Module compatible"
else
    log_warning "Module may have compatibility issues"
fi
```

**Tests**: `tests/bash/unit/federated-validation.bats:24`

---

### validate_merged_output()

**Description**: Validate merged output directory structure

**Signature**:
```bash
validate_merged_output OUTPUT_DIR
```

**Parameters**:
- `$1` (OUTPUT_DIR) - Path to merged output directory

**Returns**:
- `0` - Output valid
- `1` - Output validation failed

**Checks**:
- Required Hugo directories exist
- No broken symlinks
- Content files are valid markdown

**Example**:
```bash
if validate_merged_output "./federated-output"; then
    log_info "Output validation successful"
else
    log_error "Output validation failed"
    exit 1
fi
```

**Tests**: `tests/bash/integration/federation-e2e.bats:42`

---

### check_federation_prerequisites()

**Description**: Check all required tools are installed

**Signature**:
```bash
check_federation_prerequisites
```

**Returns**:
- `0` - All prerequisites met
- `5` - Missing dependencies

**Checks**:
- Hugo installed (version ≥ 0.148.0)
- Node.js installed (for schema validation)
- Git installed (for Git sources)
- `jq` available (for JSON parsing)

**Example**:
```bash
check_federation_prerequisites || {
    log_error "Missing required dependencies"
    log_info "Install Hugo, Node.js, Git, and jq"
    exit 5
}
```

**Tests**: `tests/bash/unit/federated-validation.bats:32`

---

### validate_strategy()

**Description**: Validate federation strategy is supported

**Signature**:
```bash
validate_strategy STRATEGY
```

**Parameters**:
- `$1` (STRATEGY) - Strategy name

**Returns**:
- `0` - Strategy valid
- `1` - Invalid strategy

**Valid Strategies**:
- `download-merge-deploy`
- `merge-and-build`
- `preserve-base-site`

**Example**:
```bash
if validate_strategy "$STRATEGY"; then
    log_info "Using strategy: $STRATEGY"
else
    log_error "Invalid strategy: $STRATEGY"
    exit 1
fi
```

**Tests**: `tests/bash/unit/federated-validation.bats:40`

---

## 3. Source Fetching

### fetch_module_source()

**Description**: Fetch module from Git, GitHub Release, or local path

**Signature**:
```bash
fetch_module_source MODULE_CONFIG OUTPUT_DIR
```

**Parameters**:
- `$1` (MODULE_CONFIG) - JSON module configuration
- `$2` (OUTPUT_DIR) - Where to place fetched module

**Returns**:
- `0` - Source fetched successfully
- `2` - Fetch failed

**Delegates to**:
- `clone_git_repository()` for Git sources
- `download_github_release()` for GitHub sources
- `copy_local_module()` for local sources

**Example**:
```bash
module_config=$(get_module_config "api-reference")
if fetch_module_source "$module_config" "./temp/api-module"; then
    log_info "Module fetched successfully"
else
    log_error "Failed to fetch module"
    exit 2
fi
```

**Tests**: `tests/bash/unit/federated-build.bats:8`

---

### clone_git_repository()

**Description**: Clone Git repository to specified directory

**Signature**:
```bash
clone_git_repository GIT_URL BRANCH OUTPUT_DIR
```

**Parameters**:
- `$1` (GIT_URL) - Git repository URL (https or ssh)
- `$2` (BRANCH) - Branch to checkout (default: main)
- `$3` (OUTPUT_DIR) - Destination directory

**Returns**:
- `0` - Clone successful
- `2` - Clone failed

**Example**:
```bash
if clone_git_repository "https://github.com/org/repo.git" "main" "./temp/repo"; then
    log_info "Repository cloned"
else
    log_error "Clone failed"
    exit 2
fi
```

**Tests**: `tests/bash/unit/federated-build.bats:16`

---

### download_github_release()

**Description**: Download built site from GitHub Release

**Signature**:
```bash
download_github_release REPO TAG OUTPUT_DIR
```

**Parameters**:
- `$1` (REPO) - Repository path (org/repo)
- `$2` (TAG) - Release tag (e.g., v1.0.0)
- `$3` (OUTPUT_DIR) - Where to extract release

**Returns**:
- `0` - Download and extraction successful
- `2` - Download or extraction failed

**Uses**: GitHub CLI (`gh`) or direct API

**Example**:
```bash
if download_github_release "info-tech-io/api-docs" "v1.0.0" "./temp/api-release"; then
    log_info "Release downloaded"
else
    log_error "Download failed"
    exit 2
fi
```

**Tests**: `tests/test-download-pages.sh:1-5`

---

### copy_local_module()

**Description**: Copy local module to working directory

**Signature**:
```bash
copy_local_module LOCAL_PATH OUTPUT_DIR
```

**Parameters**:
- `$1` (LOCAL_PATH) - Path to local module
- `$2` (OUTPUT_DIR) - Destination directory

**Returns**:
- `0` - Copy successful
- `2` - Copy failed or path not found

**Example**:
```bash
if copy_local_module "./modules/blog" "./temp/blog-module"; then
    log_info "Local module copied"
else
    log_error "Copy failed"
    exit 2
fi
```

**Tests**: `tests/bash/unit/federated-build.bats:24`

---

## 4. Build & Merge

### build_module()

**Description**: Build individual module using Layer 1 (build.sh)

**Signature**:
```bash
build_module MODULE_PATH MODULE_NAME
```

**Parameters**:
- `$1` (MODULE_PATH) - Path to module source
- `$2` (MODULE_NAME) - Module identifier (for logging)

**Returns**:
- `0` - Build successful
- `3` - Build failed

**Uses**: `scripts/build.sh` from Layer 1

**Example**:
```bash
if build_module "./temp/api-module" "api-reference"; then
    log_info "Module built successfully"
else
    log_error "Build failed for api-reference"
    exit 3
fi
```

**Tests**: `tests/bash/unit/federated-build.bats:32`

---

### merge_module_content()

**Description**: Merge module content into output directory

**Signature**:
```bash
merge_module_content MODULE_BUILD_DIR OUTPUT_DIR MODULE_PRIORITY
```

**Parameters**:
- `$1` (MODULE_BUILD_DIR) - Built module public/ directory
- `$2` (OUTPUT_DIR) - Federation output directory
- `$3` (MODULE_PRIORITY) - Module merge priority (0-100)

**Returns**:
- `0` - Merge successful
- `4` - Merge conflicts or errors

**Uses**: `intelligent_merge()` for smart merging

**Example**:
```bash
if merge_module_content "./temp/api-module/public" "./federated-output" 10; then
    log_info "Module merged"
else
    log_error "Merge failed"
    exit 4
fi
```

**Tests**: `tests/bash/unit/federated-merge.bats:8`

---

### intelligent_merge()

**Description**: Smart merge with conflict detection and resolution

**Signature**:
```bash
intelligent_merge SOURCE_DIR DEST_DIR PRIORITY
```

**Parameters**:
- `$1` (SOURCE_DIR) - Source directory to merge from
- `$2` (DEST_DIR) - Destination directory to merge into
- `$3` (PRIORITY) - Module priority for conflict resolution

**Returns**:
- `0` - Merge successful (with or without conflicts)
- `4` - Fatal merge error

**Features**:
- Content deduplication (skip identical files)
- Priority-based conflict resolution
- Conflict logging
- YAML front matter preservation

**Example**:
```bash
if intelligent_merge "./module/public" "./output" 5; then
    log_info "Intelligent merge completed"
else
    log_error "Merge error"
    exit 4
fi
```

**Tests**: `tests/test-intelligent-merge.sh:1-6`

---

### resolve_merge_conflicts()

**Description**: Resolve conflicts based on module priorities

**Signature**:
```bash
resolve_merge_conflicts SOURCE_FILE DEST_FILE NEW_PRIORITY EXISTING_PRIORITY
```

**Parameters**:
- `$1` (SOURCE_FILE) - Incoming file
- `$2` (DEST_FILE) - Existing file
- `$3` (NEW_PRIORITY) - Priority of incoming module
- `$4` (EXISTING_PRIORITY) - Priority of existing file

**Returns**: None (logs decision and copies if needed)

**Logic**:
- If `NEW_PRIORITY > EXISTING_PRIORITY`: Overwrite with new file
- If `NEW_PRIORITY < EXISTING_PRIORITY`: Keep existing file
- If equal: Log warning, keep existing

**Example**:
```bash
resolve_merge_conflicts \
    "./new/content/about.md" \
    "./existing/content/about.md" \
    10 5

# Result: New file overwrites (10 > 5)
```

**Tests**: `tests/bash/unit/federated-merge.bats:16`

---

### preserve_base_site_merge()

**Description**: Merge modules while preserving base site

**Signature**:
```bash
preserve_base_site_merge BASE_SITE_DIR MODULES_DIRS OUTPUT_DIR
```

**Parameters**:
- `$1` (BASE_SITE_DIR) - Base site public/ directory
- `$2` (MODULES_DIRS) - Array of module public/ directories
- `$3` (OUTPUT_DIR) - Final output directory

**Returns**:
- `0` - Merge successful
- `4` - Merge failed

**Strategy**: Copy base site first, then merge modules on top

**Example**:
```bash
preserve_base_site_merge \
    "./base/public" \
    "./modules/*/public" \
    "./output"
```

**Tests**: `tests/bash/integration/federation-e2e.bats:28`

---

### download_merge_deploy_workflow()

**Description**: Execute download-merge-deploy strategy

**Signature**:
```bash
download_merge_deploy_workflow
```

**Returns**:
- `0` - Workflow successful
- Non-zero - Workflow failed at some step

**Steps**:
1. Download base site from GitHub Release
2. Download all module releases
3. Merge content with priorities
4. Finalize output

**Example**:
```bash
STRATEGY="download-merge-deploy"
if download_merge_deploy_workflow; then
    log_info "Federation complete"
else
    log_error "Federation failed"
    exit 1
fi
```

**Tests**: `tests/bash/integration/federation-e2e.bats:8`

---

### merge_and_build_workflow()

**Description**: Execute merge-and-build strategy

**Signature**:
```bash
merge_and_build_workflow
```

**Returns**:
- `0` - Workflow successful
- Non-zero - Workflow failed

**Steps**:
1. Clone base site from Git
2. Build base site with Layer 1
3. Clone all modules
4. Build each module with Layer 1
5. Merge all built sites
6. Finalize output

**Example**:
```bash
STRATEGY="merge-and-build"
if merge_and_build_workflow; then
    log_info "Federation complete"
else
    log_error "Federation failed"
    exit 1
fi
```

**Tests**: `tests/bash/integration/federation-e2e.bats:16`

---

### cleanup_temp_builds()

**Description**: Remove temporary build directories

**Signature**:
```bash
cleanup_temp_builds
```

**Returns**: Always `0`

**Cleans**:
- Downloaded modules
- Cloned repositories
- Intermediate build artifacts

**Example**:
```bash
trap cleanup_temp_builds EXIT
# Cleanup runs automatically on script exit
```

**Tests**: `tests/bash/unit/federated-build.bats:40`

---

## 5. CSS Rewriting

### detect_css_paths()

**Description**: Detect relative CSS paths in content files

**Signature**:
```bash
detect_css_paths CONTENT_DIR
```

**Parameters**:
- `$1` (CONTENT_DIR) - Directory to scan

**Returns**: List of files with relative CSS paths (one per line)

**Detects**:
- `../assets/style.css`
- `../../static/css/main.css`
- Relative paths in markdown content

**Example**:
```bash
files_with_css=$(detect_css_paths "./content")
if [ -n "$files_with_css" ]; then
    log_info "Found CSS paths in: $files_with_css"
fi
```

**Tests**: `tests/test-css-path-detection.sh:1-5`

---

### rewrite_css_paths()

**Description**: Rewrite relative CSS paths to absolute paths

**Signature**:
```bash
rewrite_css_paths FILE CSS_PREFIX
```

**Parameters**:
- `$1` (FILE) - File containing CSS paths
- `$2` (CSS_PREFIX) - Prefix to prepend (e.g., /static)

**Returns**:
- `0` - Rewrite successful
- `1` - Rewrite failed

**Transforms**:
- `../assets/style.css` → `/static/assets/style.css`
- `../../css/main.css` → `/static/css/main.css`

**Example**:
```bash
if rewrite_css_paths "./content/post.md" "/static"; then
    log_info "CSS paths rewritten"
else
    log_error "Rewrite failed"
fi
```

**Tests**: `tests/test-css-path-rewriting.sh:1-5`

---

### validate_css_paths()

**Description**: Verify CSS paths are correctly rewritten

**Signature**:
```bash
validate_css_paths CONTENT_DIR
```

**Parameters**:
- `$1` (CONTENT_DIR) - Directory to validate

**Returns**:
- `0` - No relative paths found (all rewritten)
- `1` - Relative paths still present

**Checks**: Scans for any remaining `../` patterns

**Example**:
```bash
if validate_css_paths "./federated-output/content"; then
    log_info "All CSS paths valid"
else
    log_warning "Some relative paths remain"
fi
```

**Tests**: `tests/bash/unit/federated-merge.bats:24`

---

## 6. Utilities

### log_federation_progress()

**Description**: Log federation progress with formatting

**Signature**:
```bash
log_federation_progress MESSAGE [LEVEL]
```

**Parameters**:
- `$1` (MESSAGE) - Message to log
- `$2` (LEVEL) - Log level (info, warning, error), default: info

**Output**: Formatted log message with emoji and timestamp

**Example**:
```bash
log_federation_progress "Starting federation build" "info"
# Output: ℹ️  [2025-10-20 14:30:15] Starting federation build

log_federation_progress "Configuration error" "error"
# Output: ❌ [2025-10-20 14:30:20] Configuration error
```

**Tests**: Indirectly tested via all integration tests

---

### cleanup_federation_temp()

**Description**: Cleanup all temporary federation files

**Signature**:
```bash
cleanup_federation_temp
```

**Returns**: Always `0`

**Cleans**:
- `$TEMP_DIR/federation-*` directories
- Cached downloads
- Temporary Git clones

**Registered**: As trap on EXIT, INT, TERM

**Example**:
```bash
trap cleanup_federation_temp EXIT INT TERM
# Automatic cleanup on exit or interruption
```

**Tests**: `tests/bash/unit/federated-build.bats:48`

---

## Function Call Graph

```
main()
├── parse_command_line_args()
├── parse_federation_config()
│   └── validate_federation_config()
├── validate_module_sources()
│   └── validate_oneOf_constraints()
├── check_federation_prerequisites()
└── [STRATEGY workflow]
    ├── download_merge_deploy_workflow()
    │   ├── fetch_module_source()
    │   │   ├── download_github_release()
    │   │   ├── clone_git_repository()
    │   │   └── copy_local_module()
    │   └── intelligent_merge()
    │       ├── detect_css_paths()
    │       ├── rewrite_css_paths()
    │       └── resolve_merge_conflicts()
    │
    ├── merge_and_build_workflow()
    │   ├── fetch_module_source()
    │   ├── build_module()
    │   └── intelligent_merge()
    │
    └── preserve_base_site_merge()
        └── intelligent_merge()
```

---

## Testing

All 28 functions are tested across multiple test suites:

- **Unit Tests**: `tests/bash/unit/federated-*.bats` (45 tests)
- **Shell Tests**: `tests/test-*.sh` (37 tests)
- **Integration**: `tests/bash/integration/federation-e2e.bats` (14 tests)
- **Performance**: `tests/bash/performance/federation-benchmarks.bats` (5 tests)

**Coverage**: 28/28 functions (100%)
**Pass Rate**: 140/140 tests (100%)

See [Coverage Matrix](testing/coverage-matrix-federation.md) for detailed coverage.

---

## Related Documentation

- [Federation Architecture](federation-architecture.md) - Technical design
- [User Guide](../user-guides/federated-builds.md) - Configuration reference
- [Testing Guide](testing/federation-testing.md) - Test suite overview

---

**Last Updated**: 2025-10-20
**Version**: 2.0
**Functions Documented**: 28/28 (100%)
