# Schema Validation Troubleshooting

This guide helps you diagnose and fix JSON Schema validation errors in your `modules.json` configuration files.

## Quick Diagnosis

### Step 1: Run Validation

```bash
./scripts/federated-build.sh --config=modules.json --validate-only
```

### Step 2: Read Error Messages

The validator provides detailed error messages with:
- **Field path**: Exact location of the error (e.g., `root.modules[0].name`)
- **Error description**: What validation rule failed
- **Pattern/constraint**: The expected format or value

### Step 3: Fix and Re-validate

Make the necessary changes and run validation again until all errors are resolved.

## Common Validation Errors

### Federation Errors

#### Error: "federation.name: String does not match required pattern"

**Cause**: Federation name contains invalid characters or format.

**Valid pattern**: `^[a-zA-Z0-9][a-zA-Z0-9 ._-]*[a-zA-Z0-9]$`

**Allowed**:
- Letters: `a-z`, `A-Z`
- Numbers: `0-9`
- Spaces, periods, underscores, hyphens: ` ._-`
- Must start and end with alphanumeric character

**Examples**:

❌ **Invalid**:
```json
{
  "name": "_InvalidName"        // Starts with underscore
}
{
  "name": "Invalid Name!"       // Contains exclamation mark
}
{
  "name": "Invalid-"            // Ends with hyphen
}
```

✅ **Valid**:
```json
{
  "name": "InfoTech.io Pages"   // Alphanumeric with period and space
}
{
  "name": "My-Federation_v2"    // Alphanumeric with hyphen and underscore
}
{
  "name": "Project 123"         // Alphanumeric with space and number
}
```

#### Error: "federation.baseURL: String does not match required pattern"

**Cause**: baseURL has incorrect format, usually a trailing slash.

**Valid pattern**: `^https?://[^/]+[^/]$` (no trailing slash)

**Examples**:

❌ **Invalid**:
```json
{
  "baseURL": "https://example.com/"        // Trailing slash
}
{
  "baseURL": "example.com"                 // Missing protocol
}
{
  "baseURL": "https://example.com/path"    // Contains path
}
```

✅ **Valid**:
```json
{
  "baseURL": "https://example.com"
}
{
  "baseURL": "http://localhost:1313"
}
{
  "baseURL": "https://user.github.io"
}
```

#### Error: "federation.strategy: Value must be one of [...]"

**Cause**: Invalid strategy value.

**Allowed values**:
- `"download-merge-deploy"`
- `"preserve-base-site"`

**Examples**:

❌ **Invalid**:
```json
{
  "strategy": "merge-and-deploy"    // Typo
}
{
  "strategy": "custom-strategy"     // Not supported
}
```

✅ **Valid**:
```json
{
  "strategy": "download-merge-deploy"
}
{
  "strategy": "preserve-base-site"
}
```

### Module Errors

#### Error: "modules[N].name: String does not match required pattern"

**Cause**: Module name not in lowercase-with-hyphens format.

**Valid pattern**: `^[a-z0-9]+(-[a-z0-9]+)*$`

**Rules**:
- Only lowercase letters: `a-z`
- Only numbers: `0-9`
- Only hyphens as separators: `-`
- Cannot start or end with hyphen
- Cannot have consecutive hyphens

**Examples**:

❌ **Invalid**:
```json
{
  "name": "Test_Module"             // Underscores not allowed
}
{
  "name": "TestModule"              // Uppercase not allowed
}
{
  "name": "test-module-"            // Ends with hyphen
}
{
  "name": "test--module"            // Consecutive hyphens
}
```

✅ **Valid**:
```json
{
  "name": "test-module"
}
{
  "name": "corporate-site"
}
{
  "name": "quiz-docs-v2"
}
{
  "name": "module123"
}
```

#### Error: "modules[N].source.repository: Value does not match any of the allowed schemas"

**Cause**: Repository URL is not a valid GitHub URL or the literal string "local".

**Valid formats**:
1. HTTPS GitHub URL: `https://github.com/user/repo`
2. SSH GitHub URL: `git@github.com:user/repo`
3. Local source: `"local"`

**Examples**:

❌ **Invalid**:
```json
{
  "repository": "https://gitlab.com/user/repo"    // Not GitHub
}
{
  "repository": "github.com/user/repo"            // Missing protocol
}
{
  "repository": "https://github.com/user"         // Missing repo name
}
{
  "repository": "./local/path"                    // Use "local", not path
}
```

✅ **Valid**:
```json
{
  "repository": "https://github.com/info-tech-io/quiz"
}
{
  "repository": "git@github.com:info-tech-io/quiz.git"
}
{
  "repository": "local"
}
```

#### Error: "modules[N].destination: String does not match required pattern"

**Cause**: Destination path doesn't start with `/` or contains invalid characters.

**Valid pattern**: `^/[a-zA-Z0-9/_-]*$`

**Rules**:
- Must start with `/`
- Can contain: letters, numbers, `/`, `_`, `-`
- Can end with or without `/`

**Examples**:

❌ **Invalid**:
```json
{
  "destination": "no-slash"         // Missing leading slash
}
{
  "destination": "/path/to/module!"  // Invalid character (!)
}
{
  "destination": "/path with spaces" // Spaces not allowed
}
```

✅ **Valid**:
```json
{
  "destination": "/"
}
{
  "destination": "/quiz"
}
{
  "destination": "/quiz/"
}
{
  "destination": "/docs/hugo-templates"
}
{
  "destination": "/products/web-terminal/"
}
```

#### Error: "modules[N].css_path_prefix: String does not match required pattern"

**Cause**: CSS path prefix has incorrect format.

**Valid pattern**: `^(/[a-zA-Z0-9/_-]*)?$`

**Rules**:
- Can be empty string: `""`
- If not empty, must start with `/`
- Can contain: letters, numbers, `/`, `_`, `-`
- Cannot end with `/`

**Examples**:

❌ **Invalid**:
```json
{
  "css_path_prefix": "no-slash"     // Missing leading slash
}
{
  "css_path_prefix": "/path/"       // Trailing slash
}
```

✅ **Valid**:
```json
{
  "css_path_prefix": ""             // Empty string (common)
}
{
  "css_path_prefix": "/"
}
{
  "css_path_prefix": "/quiz"
}
{
  "css_path_prefix": "/docs/templates"
}
```

### Build Settings Errors

#### Error: "federation.build_settings.max_parallel_builds: Expected integer between 1 and 10"

**Cause**: Value is out of range or not an integer.

**Examples**:

❌ **Invalid**:
```json
{
  "max_parallel_builds": 0          // Below minimum
}
{
  "max_parallel_builds": 15         // Above maximum
}
{
  "max_parallel_builds": "5"        // String instead of number
}
{
  "max_parallel_builds": 5.5        // Not an integer
}
```

✅ **Valid**:
```json
{
  "max_parallel_builds": 5
}
{
  "max_parallel_builds": 1
}
{
  "max_parallel_builds": 10
}
```

#### Error: "modules[N].build_options.build_timeout: Expected integer between 30 and 3600"

**Cause**: Timeout value is out of range.

**Range**: 30-3600 seconds (30 seconds to 1 hour)

**Examples**:

❌ **Invalid**:
```json
{
  "build_timeout": 10               // Below minimum (30s)
}
{
  "build_timeout": 7200             // Above maximum (3600s)
}
```

✅ **Valid**:
```json
{
  "build_timeout": 300              // 5 minutes
}
{
  "build_timeout": 600              // 10 minutes
}
{
  "build_timeout": 1800             // 30 minutes
}
```

#### Error: "modules[N].build_options.priority: Expected integer between 0 and 100"

**Cause**: Priority value is out of range.

**Range**: 0-100 (higher builds first)

**Examples**:

❌ **Invalid**:
```json
{
  "priority": -10                   // Negative
}
{
  "priority": 150                   // Above maximum
}
```

✅ **Valid**:
```json
{
  "priority": 0                     // Lowest priority
}
{
  "priority": 50                    // Default
}
{
  "priority": 100                   // Highest priority
}
```

### Array Errors

#### Error: "modules: Array must contain at least 1 items"

**Cause**: Empty modules array.

**Examples**:

❌ **Invalid**:
```json
{
  "modules": []                     // Empty array
}
```

✅ **Valid**:
```json
{
  "modules": [
    {
      "name": "test-module",
      ...
    }
  ]
}
```

#### Error: "modules: Array must contain at most 50 items"

**Cause**: Too many modules in one federation.

**Limit**: Maximum 50 modules per federation

**Solution**: Split into multiple federations or optimize module structure.

### Missing Required Fields

#### Error: "federation: Missing required property 'name'"

**Cause**: Required field is not present.

**Required federation fields**:
- `name`
- `baseURL`
- `strategy`

**Example**:

❌ **Invalid**:
```json
{
  "federation": {
    "baseURL": "https://example.com",
    "strategy": "download-merge-deploy"
    // Missing "name"
  }
}
```

✅ **Valid**:
```json
{
  "federation": {
    "name": "My Federation",
    "baseURL": "https://example.com",
    "strategy": "download-merge-deploy"
  }
}
```

#### Error: "modules[N]: Missing required property 'source'"

**Required module fields**:
- `name`
- `source` (with `repository`, `path`, `branch`)
- `destination`
- `module_json`

**Example**:

❌ **Invalid**:
```json
{
  "modules": [{
    "name": "test-module",
    "destination": "/",
    "module_json": "module.json"
    // Missing "source"
  }]
}
```

✅ **Valid**:
```json
{
  "modules": [{
    "name": "test-module",
    "source": {
      "repository": "local",
      "path": "docs",
      "branch": "main"
    },
    "destination": "/",
    "module_json": "module.json"
  }]
}
```

## Advanced Debugging

### Enable Detailed Error Messages

The validation output already includes detailed messages, but you can inspect the raw JSON to debug:

```bash
# Pretty-print your JSON
cat modules.json | python3 -m json.tool

# Check for syntax errors
node -e "console.log(JSON.stringify(require('./modules.json'), null, 2))"
```

### Validate Against Schema Manually

```bash
# Install ajv-cli
npm install -g ajv-cli ajv-formats

# Validate manually
ajv validate -s schemas/modules.schema.json -d modules.json --strict=false
```

### Test Individual Modules

Create a minimal test configuration with just one module to isolate the issue:

```json
{
  "federation": {
    "name": "Test Federation",
    "baseURL": "http://localhost:1313",
    "strategy": "download-merge-deploy"
  },
  "modules": [
    {
      "name": "test-module",
      "source": {
        "repository": "local",
        "path": "docs",
        "branch": "main"
      },
      "destination": "/",
      "module_json": "module.json"
    }
  ]
}
```

Then add your problematic module configuration one field at a time.

## Getting Help

1. **Check schema reference**: `schemas/modules.schema.json` contains all validation rules
2. **Review examples**: `docs/content/examples/` contains working configurations
3. **Run test suite**: `./tests/test-schema-validation.sh` shows validation examples
4. **Check documentation**: [Federated Builds Guide](../user-guides/federated-builds.md)

## Prevention Tips

1. **Use IDE integration**: Add `$schema` reference for autocomplete
2. **Validate early**: Run `--validate-only` before committing
3. **Use examples as templates**: Copy from working configurations
4. **Test incrementally**: Add modules one at a time
5. **Keep backups**: Commit working configurations before changes

## Schema Reference

For the complete schema definition with all rules, patterns, and constraints, see:
- **Schema file**: `schemas/modules.schema.json`
- **Schema README**: `schemas/README.md`
