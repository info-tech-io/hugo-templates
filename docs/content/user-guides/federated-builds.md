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
