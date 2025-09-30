# Design: Child #2 - Modules.json Schema Definition

## Problem Statement
Define and implement a comprehensive `modules.json` schema that supports federated build configuration while maintaining integration with existing `module.json` files.

## Technical Solution

### Schema Architecture
- **modules.json**: Federation-level configuration
- **module.json**: Individual module configuration (unchanged)
- **Inheritance**: modules.json can reference and extend module.json configurations

### Core Schema Structure

```json
{
  "federation": {
    "name": "info-tech-io-pages",
    "baseURL": "https://info-tech-io.github.io",
    "strategy": "download-merge-deploy",
    "build_settings": {
      "parallel": true,
      "cache_enabled": true,
      "performance_tracking": true
    }
  },
  "modules": [
    {
      "name": "corporate-site",
      "source": {
        "repository": "info-tech-io/info-tech",
        "path": "docs",
        "branch": "main"
      },
      "module_json": "module.json",
      "destination": "/",
      "css_path_prefix": "",
      "overrides": {
        "baseURL": "https://info-tech-io.github.io",
        "theme": "compose"
      }
    }
  ]
}
```

## Implementation Stages

### Stage 1: Schema Definition
- Create JSON Schema for modules.json validation
- Define federation configuration options
- Define module configuration options

### Stage 2: Validation Implementation
- Implement Node.js validation in federated-build.sh
- Add comprehensive error reporting
- Create schema validation tests

## Files to Create
- `schemas/modules.schema.json` (JSON Schema definition)
- `docs/examples/modules.json` (example configuration)

**Estimated Time**: 0.5 days