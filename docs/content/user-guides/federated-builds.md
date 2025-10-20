# Federated Build System Guide

## Overview

The Federated Build System enables you to orchestrate multiple Hugo sites from different Git repositories into a single unified GitHub Pages deployment. This guide covers configuration, validation, and best practices for federated builds.

## Configuration File: modules.json

The `modules.json` file defines your federation configuration, including global settings and individual module definitions.

### JSON Schema Validation

All `modules.json` files are validated against a JSON Schema to ensure configuration correctness. The schema provides:

- **Type checking**: Validates data types for all fields
- **Pattern validation**: Enforces naming conventions and URL formats
- **Required fields**: Ensures all mandatory configuration is present
- **IDE support**: Autocomplete and inline validation in modern editors

### Basic Structure

```json
{
  "$schema": "./schemas/modules.schema.json",
  "federation": {
    "name": "My Federation",
    "baseURL": "https://example.github.io",
    "strategy": "download-merge-deploy"
  },
  "modules": [
    {
      "name": "module-name",
      "source": {
        "repository": "https://github.com/user/repo",
        "path": "docs",
        "branch": "main"
      },
      "destination": "/module-path/",
      "module_json": "module.json"
    }
  ]
}
```

## Federation Configuration

### Required Fields

#### `name`
- **Type**: String
- **Pattern**: `^[a-zA-Z0-9][a-zA-Z0-9 ._-]*[a-zA-Z0-9]$`
- **Description**: Human-readable name for your federation
- **Examples**:
  - `"InfoTech.io Pages"`
  - `"Corporate Documentation"`
  - `"Multi-Project Federation"`

#### `baseURL`
- **Type**: String (URI)
- **Pattern**: `^https?://[^/]+[^/]$` (no trailing slash)
- **Description**: Base URL where the federation will be deployed
- **Examples**:
  - `"https://info-tech-io.github.io"`
  - `"https://example.com"`
  - `"http://localhost:1313"` (for local development)

#### `strategy`
- **Type**: String (enum)
- **Allowed values**:
  - `"download-merge-deploy"`: Download all modules and merge into single site
  - `"preserve-base-site"`: Preserve existing base site and add modules
- **Default**: `"download-merge-deploy"`

### Optional Fields

#### `build_settings`
Optional federation-wide build configuration:

```json
{
  "build_settings": {
    "parallel": true,
    "max_parallel_builds": 5,
    "cache_enabled": true,
    "performance_tracking": true,
    "fail_fast": false
  }
}
```

- **`parallel`**: Enable parallel module builds (experimental)
- **`max_parallel_builds`**: Maximum concurrent builds (1-10)
- **`cache_enabled`**: Enable build caching system
- **`performance_tracking`**: Enable performance monitoring
- **`fail_fast`**: Stop on first module failure

## Module Configuration

### Required Fields

#### `name`
- **Type**: String
- **Pattern**: `^[a-z0-9]+(-[a-z0-9]+)*$` (lowercase with hyphens)
- **Description**: Unique identifier for this module
- **Examples**:
  - `"corporate-site"`
  - `"quiz-docs"`
  - `"hugo-templates-docs"`

#### `source`
Repository source configuration:

```json
{
  "source": {
    "repository": "https://github.com/info-tech-io/repo",
    "path": "docs",
    "branch": "main"
  }
}
```

- **`repository`**: GitHub URL or `"local"` for local sources
  - GitHub pattern: `^(https://github\.com/|git@github\.com:)[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+(\.git)?$`
- **`path`**: Path within repository to content directory
- **`branch`**: Git branch name (default: `"main"`)

#### `destination`
- **Type**: String
- **Pattern**: `^/[a-zA-Z0-9/_-]*$` (must start with `/`)
- **Description**: URL path where module will be deployed
- **Examples**:
  - `"/"` (root path)
  - `"/quiz/"`
  - `"/docs/hugo-templates/"`

#### `module_json`
- **Type**: String
- **Pattern**: `^[^/].*\.json$` (relative path ending in .json)
- **Default**: `"module.json"`
- **Description**: Path to module.json within source
- **Examples**:
  - `"module.json"`
  - `"docs/module.json"`
  - `"config/module.json"`

### Optional Fields

#### `css_path_prefix`
- **Type**: String
- **Pattern**: `^(/[a-zA-Z0-9/_-]*)?$` (empty string or path with leading `/`)
- **Default**: `""`
- **Description**: CSS path prefix for theme assets in subdirectory deployments
- **Examples**:
  - `""` (no prefix)
  - `"/"`
  - `"/quiz"`
  - `"/docs/hugo-templates"`

#### `overrides`
Override specific module.json settings:

```json
{
  "overrides": {
    "baseURL": "https://info-tech-io.github.io",
    "theme": "compose",
    "components": ["quiz-engine", "code-highlighter"],
    "title": "InfoTech.io Documentation"
  }
}
```

#### `build_options`
Per-module build configuration:

```json
{
  "build_options": {
    "cache_enabled": true,
    "skip_on_error": false,
    "build_timeout": 600,
    "priority": 100
  }
}
```

- **`cache_enabled`**: Enable caching for this module
- **`skip_on_error`**: Continue federation build if module fails
- **`build_timeout`**: Build timeout in seconds (30-3600)
- **`priority`**: Build priority, higher builds first (0-100)

## IDE Integration

### Visual Studio Code

Add the `$schema` reference to get autocomplete and validation:

```json
{
  "$schema": "./schemas/modules.schema.json",
  "federation": { ... }
}
```

VSCode will automatically:
- Validate your configuration as you type
- Provide autocomplete suggestions
- Show field descriptions on hover
- Highlight errors and warnings

### Other Editors

Most modern editors support JSON Schema:
- **IntelliJ IDEA**: Automatic detection via `$schema`
- **Sublime Text**: Install "LSP-json" package
- **Vim/Neovim**: Use coc-json or ALE with jsonlint

## Validation Commands

### Validate Configuration Only

Test your configuration without running the build:

```bash
./scripts/federated-build.sh --config=modules.json --validate-only
```

This will:
1. Parse the JSON file
2. Validate against the schema
3. Report any errors with helpful messages
4. Exit without building

### Example Output

**Valid configuration:**
```
ℹ️  Loading federation configuration from: modules.json
✅ Configuration validated successfully against schema
```

**Invalid configuration:**
```
❌ Failed to load federation configuration
ERROR: Configuration validation failed against JSON Schema:
  • root.federation.baseURL: String "https://example.com/" does not match required pattern
  • root.modules[0].name: String "Test_Module" does not match required pattern

Please fix these errors and try again.
Schema reference: schemas/modules.schema.json
```

## Common Validation Errors

### Trailing Slash in baseURL

❌ **Error**: `baseURL: String does not match required pattern`

```json
{
  "federation": {
    "baseURL": "https://example.com/"  // ❌ Trailing slash
  }
}
```

✅ **Fix**: Remove trailing slash
```json
{
  "federation": {
    "baseURL": "https://example.com"  // ✅ No trailing slash
  }
}
```

### Invalid Module Name

❌ **Error**: `modules[0].name: String does not match required pattern`

```json
{
  "modules": [{
    "name": "Test_Module_With_Uppercase"  // ❌ Uppercase and underscores
  }]
}
```

✅ **Fix**: Use lowercase with hyphens
```json
{
  "modules": [{
    "name": "test-module-with-hyphens"  // ✅ Lowercase with hyphens
  }]
}
```

### Missing Leading Slash in Destination

❌ **Error**: `modules[0].destination: String does not match required pattern`

```json
{
  "modules": [{
    "destination": "no-slash"  // ❌ No leading slash
  }]
}
```

✅ **Fix**: Add leading slash
```json
{
  "modules": [{
    "destination": "/no-slash"  // ✅ Leading slash
  }]
}
```

### Invalid Repository URL

❌ **Error**: `modules[0].source.repository: Value does not match any of the allowed schemas`

```json
{
  "modules": [{
    "source": {
      "repository": "https://gitlab.com/user/repo"  // ❌ Not GitHub
    }
  }]
}
```

✅ **Fix**: Use GitHub URL or "local"
```json
{
  "modules": [{
    "source": {
      "repository": "https://github.com/user/repo"  // ✅ GitHub URL
    }
  }]
}
```

or for local development:
```json
{
  "modules": [{
    "source": {
      "repository": "local"  // ✅ Local source
    }
  }]
}
```

## Examples

See complete examples in `docs/content/examples/`:

- **`modules-simple.json`**: Minimal configuration with required fields only
- **`modules-infotech.json`**: Real production configuration with 5 modules
- **`modules-advanced.json`**: Showcases all advanced features (build_settings, overrides, build_options)

## Testing Your Configuration

### 1. Validate Schema

```bash
./scripts/federated-build.sh --config=modules.json --validate-only
```

### 2. Dry Run

```bash
./scripts/federated-build.sh --config=modules.json --dry-run
```

### 3. Full Build

```bash
./scripts/federated-build.sh --config=modules.json
```

## Command-Line Reference

Complete reference for `federated-build.sh` command-line options.

### Basic Syntax

```bash
./scripts/federated-build.sh [OPTIONS]
```

### Required Options

#### `--config=FILE`
**Description**: Path to modules.json configuration file
**Example**: `--config=modules.json`
**Default**: None (required)

### Output Options

#### `--output=DIR`
**Description**: Output directory for merged site
**Example**: `--output=public`
**Default**: `./federated-output`

#### `--minify`
**Description**: Minify HTML/CSS/JS in final output
**Example**: `--minify`
**Default**: false (no minification)

### Execution Modes

#### `--dry-run`
**Description**: Test configuration without building
**Example**: `--dry-run`
**Effect**:
- Validates configuration
- Checks module sources accessible
- Reports what would be done
- Does not build or download anything

#### `--validate-only`
**Description**: Validate configuration and exit
**Example**: `--validate-only`
**Effect**:
- Schema validation only
- Faster than `--dry-run`
- Does not check module accessibility

### Advanced Options

#### `--strategy=STRATEGY`
**Description**: Override strategy from config
**Values**: `download-merge-deploy`, `merge-and-build`, `preserve-base-site`
**Example**: `--strategy=merge-and-build`
**Default**: Value from modules.json

#### `--verbose`
**Description**: Enable verbose logging
**Example**: `--verbose`
**Effect**: Show detailed build progress

#### `--quiet`
**Description**: Suppress non-error output
**Example**: `--quiet`
**Effect**: Only show errors and warnings

#### `--parallel=N`
**Description**: Maximum parallel module builds
**Example**: `--parallel=3`
**Default**: 1 (sequential builds)
**Range**: 1-10

### Environment Variables

#### `TEMP_DIR`
**Description**: Override temporary directory
**Example**: `TEMP_DIR=/tmp/federation ./scripts/federated-build.sh --config=modules.json`
**Default**: System temp directory

#### `NODE_PATH`
**Description**: Path to Node.js executable
**Example**: `NODE_PATH=/usr/local/bin/node`
**Default**: Detected from PATH

#### `HUGO_PATH`
**Description**: Path to Hugo executable
**Example**: `HUGO_PATH=/usr/local/bin/hugo`
**Default**: Detected from PATH

### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| `0` | Success | Build completed successfully |
| `1` | Configuration error | Check modules.json syntax/validation |
| `2` | Module source error | Verify repository URLs or paths |
| `3` | Build failure | Check individual module build logs |
| `4` | Merge conflict | Review conflict resolution in output |
| `5` | Missing dependency | Install Hugo, Node.js, or Git |
| `6` | Permission error | Check file/directory permissions |
| `7` | Timeout | Increase build timeout or check network |

### Complete Examples

**Production Build**:
```bash
./scripts/federated-build.sh \
  --config=modules-prod.json \
  --output=public \
  --minify \
  --strategy=download-merge-deploy
```

**Development Build**:
```bash
./scripts/federated-build.sh \
  --config=modules-dev.json \
  --output=dev-output \
  --verbose \
  --strategy=merge-and-build
```

**CI/CD Validation**:
```bash
./scripts/federated-build.sh \
  --config=modules.json \
  --validate-only \
  --quiet
```

**Parallel Build**:
```bash
./scripts/federated-build.sh \
  --config=modules.json \
  --parallel=5 \
  --output=public
```

---

## Error Handling

Understanding and resolving common federation errors.

### Configuration Errors (Exit Code 1)

#### Error: JSON Parse Failure
```
ERROR: Failed to parse modules.json
Syntax error at line 15: Unexpected token }
```

**Cause**: Invalid JSON syntax
**Solution**: Validate JSON with `jsonlint` or online validator

#### Error: Schema Validation Failure
```
ERROR: Configuration validation failed against JSON Schema:
  • root.modules[0].name: String does not match required pattern
```

**Cause**: Configuration doesn't meet schema requirements
**Solution**: Review field requirements in this guide or use IDE autocomplete

### Module Source Errors (Exit Code 2)

#### Error: Repository Not Found
```
ERROR: Failed to clone repository https://github.com/user/nonexistent
fatal: repository not found
```

**Cause**: Repository doesn't exist or is private without credentials
**Solution**:
- Verify repository URL is correct
- For private repos, configure Git credentials or SSH keys
- Use GitHub Personal Access Token in CI/CD

#### Error: Branch Not Found
```
ERROR: Branch 'feature-branch' not found in repository
```

**Cause**: Specified branch doesn't exist
**Solution**: Check branch name, use `main` or `master` for default branch

#### Error: Local Path Not Found
```
ERROR: Local module path './modules/api-docs' does not exist
```

**Cause**: Local path is incorrect or directory missing
**Solution**: Verify path relative to project root

### Build Errors (Exit Code 3)

#### Error: Hugo Build Failed
```
ERROR: Module 'module-api' build failed
Hugo error: ERROR 2024/01/15 12:34:56 Transformation failed: SCSS processing failed
```

**Cause**: Individual module has Hugo build error
**Solution**:
- Test module builds independently
- Review module's hugo.toml/yaml/json configuration
- Check for missing dependencies or themes

#### Error: Theme Not Found
```
ERROR: Module 'docs' build failed: theme "compose" not found
```

**Cause**: Hugo theme not available in module
**Solution**:
- Add theme as Git submodule in module repository
- Or use overrides to specify alternate theme
- Or centralize themes in base site

### Merge Errors (Exit Code 4)

#### Error: Path Conflict Detected
```
WARNING: Conflict detected in path: content/about.md
Module 'module-b' overwrites file from 'module-a'
Resolution: Using version from higher priority module
```

**Cause**: Multiple modules have same file path
**Solution**:
- Adjust module priorities (higher priority wins)
- Restructure module content to avoid overlaps
- Review conflict resolution strategy

#### Error: CSS Path Rewriting Failed
```
WARNING: Failed to rewrite CSS path in content/posts/style.md
Path: ../assets/style.css
```

**Cause**: CSS path detection couldn't determine correct rewrite
**Solution**: Use absolute paths or verify css_path_prefix configuration

### Dependency Errors (Exit Code 5)

#### Error: Hugo Not Found
```
ERROR: Hugo not found. Please install Hugo Extended ≥ 0.148.0
```

**Cause**: Hugo not installed or not in PATH
**Solution**:
```bash
# macOS (Homebrew)
brew install hugo

# Linux (Snap)
snap install hugo

# Or download from https://github.com/gohugoio/hugo/releases
```

#### Error: Node.js Not Found
```
ERROR: Node.js not found. Required for JSON Schema validation
```

**Cause**: Node.js not installed or not in PATH
**Solution**: Install Node.js ≥ 18.0.0 from https://nodejs.org/

---

## Performance Tips

Optimize federation builds for speed and efficiency.

### Strategy Selection

**Fastest: download-merge-deploy**
```json
{
  "strategy": "download-merge-deploy"
}
```
- Downloads pre-built modules from GitHub Releases
- Skips individual module builds (fastest)
- **Best for**: CI/CD, production deployments
- **Speedup**: 5-10x faster than merge-and-build

**Most Control: merge-and-build**
```json
{
  "strategy": "merge-and-build"
}
```
- Clones and builds each module from source
- Full control over build process
- **Best for**: Development, testing, full rebuilds
- **Tradeoff**: Slower but always uses latest source

**Incremental: preserve-base-site**
```json
{
  "strategy": "preserve-base-site"
}
```
- Keeps existing base site, merges modules on top
- Skips base site rebuild
- **Best for**: Adding modules to existing site
- **Speedup**: Faster when base site doesn't change

### Parallel Builds

Enable parallel module builds for faster processing:

```bash
./scripts/federated-build.sh --config=modules.json --parallel=5
```

**Recommendations**:
- Local machine: `--parallel=3` (avoid overloading)
- CI/CD (4 cores): `--parallel=4`
- CI/CD (8+ cores): `--parallel=6`
- Do not exceed number of CPU cores

**Note**: Parallel builds are experimental and may have race conditions with shared resources.

### Caching

Federation builds support multiple cache levels:

**L1 Cache** (Hugo's built-in):
- Enabled automatically
- Caches Hugo processing (SCSS, images, etc.)
- Persists in `/tmp/hugo_cache`

**L2 Cache** (Module builds):
- Cache individual module builds
- Enable in configuration:
```json
{
  "build_settings": {
    "cache_enabled": true
  }
}
```

**CI/CD Caching**:
```yaml
- name: Cache Federation Builds
  uses: actions/cache@v3
  with:
    path: |
      /tmp/hugo_cache
      ~/.cache/hugo_cache
      ./federated-output
    key: federation-${{ hashFiles('modules.json') }}
```

### Resource Optimization

**Reduce Module Size**:
- Exclude unnecessary files in `.gitignore`
- Use `download-merge-deploy` to avoid cloning large repos
- Minimize static assets in modules

**Timeout Configuration**:
```json
{
  "modules": [{
    "build_options": {
      "build_timeout": 300
    }
  }]
}
```
- Default: 600 seconds (10 minutes)
- Reduce for small modules: 60-120 seconds
- Increase for large sites: 900-1800 seconds

### Monitoring Performance

Enable performance tracking:

```bash
./scripts/federated-build.sh --config=modules.json --verbose
```

Review build times in output:
```
Module 'main-docs': 45.2s
Module 'api-reference': 12.8s
Module 'tutorials': 8.3s
Total federation time: 66.3s
```

Optimize slowest modules first for maximum impact.

---

## What's New

Latest features and improvements in the federated build system.

### Version 2.0 (Current) - October 2025

**Major Features**:
- ✅ **Local Repository Support**: Use local paths for module sources
- ✅ **oneOf Source Validation**: Proper Git vs GitHub vs local source validation
- ✅ **140 Comprehensive Tests**: 100% test coverage (Layer 1 + Layer 2 + Integration)
- ✅ **Performance Benchmarks**: Baseline performance tracking for regression detection

**Enhancements**:
- Improved CSS path rewriting for complex layouts
- Better error messages with exit codes
- Dry-run mode for configuration testing
- Parallel build support (experimental)

**Bug Fixes**:
- Fixed oneOf schema validation for source types
- Fixed local repository path resolution
- Fixed merge conflicts with preserve-base-site strategy
- Fixed CSS path detection for nested directories

**Testing**:
- Unit tests: 45 BATS tests (Layer 2)
- Integration tests: 14 E2E tests
- Shell script tests: 37 tests
- Performance tests: 5 benchmarks
- **Total**: 140 tests, all passing

### Upcoming Features (Roadmap)

**Planned for v2.1**:
- Incremental builds (build only changed modules)
- Distributed caching (shared cache across CI/CD runs)
- Module dependency resolution
- Automatic conflict resolution strategies

**Under Consideration**:
- Support for non-GitHub Git providers (GitLab, Bitbucket)
- Module versioning and pinning
- Webhook-triggered federation builds
- Federation status dashboard

**Community Requests**:
- YAML configuration support (in addition to JSON)
- Docker container for federation builds
- Windows native support (currently requires Git Bash)

### Migration from v1.x

If upgrading from earlier version:

1. **Configuration Changes**:
   - `source.repository` now requires GitHub URL or "local"
   - New `source` field structure with oneOf validation
   - `strategy` field added (defaults to `download-merge-deploy`)

2. **Breaking Changes**:
   - Local sources must use `"type": "local"` and `"path": "..."`
   - Module names must be lowercase-with-hyphens
   - baseURL must not have trailing slash

3. **Migration Script**:
```bash
# Validate old configuration
./scripts/federated-build.sh --config=old-modules.json --validate-only

# Review errors and update configuration
# Then test with dry-run
./scripts/federated-build.sh --config=new-modules.json --dry-run
```

4. **See Also**: [Migration Checklist](../tutorials/federation-migration-checklist.md)

---

## CI/CD Integration

The schema validation is automatically run in CI/CD:

```yaml
- name: Validate configuration
  run: |
    ./scripts/federated-build.sh --config=modules.json --validate-only
```

See `.github/workflows/validate-schemas.yml` for the complete CI/CD workflow.

## Best Practices

1. **Always use `$schema` reference** for IDE support
2. **Validate before committing** using `--validate-only`
3. **Use descriptive federation names** (e.g., "InfoTech.io Documentation")
4. **Follow naming conventions**:
   - Federation names: Mixed case with spaces, periods, hyphens
   - Module names: lowercase-with-hyphens
5. **Test with dry-run** before deploying
6. **Use cache for faster builds** (default: enabled)
7. **Set appropriate timeouts** based on module size
8. **Use priorities** to build critical modules first

## Troubleshooting

For common issues and solutions, see [Schema Validation Troubleshooting](../troubleshooting/schema-validation.md).

For general build issues, see [Common Issues](../troubleshooting/common-issues.md).
