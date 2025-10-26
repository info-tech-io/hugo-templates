# JSON Schemas for Hugo Templates Framework

This directory contains JSON Schema definitions for configuration files used by the Hugo Templates Framework.

## Available Schemas

### modules.schema.json

JSON Schema for `modules.json` - the configuration file for federated GitHub Pages builds.

**Version**: 1.0.0
**Spec**: JSON Schema Draft-07

#### Usage in Configuration Files

Add a `$schema` reference to your `modules.json` file for IDE support (autocomplete, validation):

```json
{
  "$schema": "./schemas/modules.schema.json",
  "federation": {
    ...
  },
  "modules": [
    ...
  ]
}
```

#### Validation

Validate your configuration using `federated-build.sh`:

```bash
./scripts/federated-build.sh --config=modules.json --validate-only
```

#### Schema Structure

**Federation Section** (required):
- `name` (string): Federation name
- `baseURL` (string, URI): Base URL (no trailing slash)
- `strategy` (enum): Build strategy
  - `download-merge-deploy` (default)
  - `preserve-base-site`
- `build_settings` (object, optional): Build configuration
  - `parallel` (boolean): Enable parallel builds
  - `max_parallel_builds` (integer, 1-10): Max parallel builds
  - `cache_enabled` (boolean): Enable caching
  - `performance_tracking` (boolean): Track performance
  - `fail_fast` (boolean): Stop on first failure

**Modules Section** (required array, min 1 item):

Each module must have:
- `name` (string): Unique identifier (lowercase-with-hyphens)
- `source` (object):
  - `repository` (string): GitHub URL or "local"
  - `path` (string): Path within repo
  - `branch` (string): Git branch
- `destination` (string): URL path (starts with /)
- `module_json` (string): Path to module.json

Optional fields:
- `css_path_prefix` (string): CSS path for subdirectories
- `overrides` (object): Override module.json settings
- `build_options` (object): Per-module build settings

## Examples

See [docs/content/examples/](../docs/content/examples/) for complete examples:

- **modules-simple.json**: Minimal 2-module configuration
- **modules-infotech.json**: Real InfoTech.io federation (5 modules)
- **modules-advanced.json**: All advanced features

## Validation Rules

### Federation

- `name`: 3-100 characters, alphanumeric with spaces/hyphens
- `baseURL`: Valid URI, must NOT end with `/`
- `strategy`: Must be one of the allowed enum values

### Modules

- `name`: 2-50 characters, lowercase letters, numbers, hyphens only (pattern: `^[a-z0-9]+(-[a-z0-9]+)*$`)
- `destination`: Must start with `/`
- `repository`: Valid GitHub URL or literal "local"
- All module names must be unique (validated at runtime)

## IDE Support

Modern IDEs recognize the `$schema` property and provide:
- ✅ Autocomplete for all fields
- ✅ Inline validation and error highlighting
- ✅ Documentation tooltips
- ✅ Enum value suggestions

**Supported IDEs**:
- Visual Studio Code (built-in)
- JetBrains IDEs (IntelliJ, WebStorm, etc.)
- Sublime Text (with plugin)
- Vim/Neovim (with plugin)

## Extending the Schema

When adding new features to the federation system:

1. Update `modules.schema.json` with new fields
2. Increment schema version
3. Add examples demonstrating new fields
4. Update this README
5. Update federated-build.sh parser if needed

## References

- JSON Schema Specification: https://json-schema.org/draft-07/schema
- Hugo Templates Framework: https://github.com/info-tech-io/hugo-templates
- Epic #15 - Federated Build System: https://github.com/info-tech-io/hugo-templates/issues/15
