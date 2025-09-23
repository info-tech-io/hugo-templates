---
title: "Build Scripts"
description: "Complete reference for Hugo Templates Framework build system"
weight: 31
---

# Build Scripts Reference

Hugo Templates Framework provides a powerful command-line build system through the `scripts/build.sh` script. This script is the primary interface for generating Hugo sites using templates, themes, and components.

## Basic Usage

```bash
./scripts/build.sh [OPTIONS]
```

## Command-Line Options

### Required Parameters

#### `--template` or `-t`
**Type:** `string`
**Required:** Yes
**Description:** Specifies which template to use for site generation

**Available values:**
- `educational` - For courses and learning content
- `corporate` - For business and organization websites
- `documentation` - For technical documentation sites

**Example:**
```bash
./scripts/build.sh --template documentation
```

#### `--output` or `-o`
**Type:** `string`
**Required:** No (defaults to `./site`)
**Description:** Output directory where the generated site will be created

**Example:**
```bash
./scripts/build.sh --template corporate --output my-company-site
```

### Content and Configuration

#### `--content`
**Type:** `string`
**Description:** Path to content directory containing Markdown files

**Example:**
```bash
./scripts/build.sh \
  --template documentation \
  --content docs/content \
  --output docs-site
```

#### `--config`
**Type:** `string`
**Description:** Path to custom configuration file (overrides template defaults)

**Example:**
```bash
./scripts/build.sh \
  --template corporate \
  --config custom-config.toml \
  --output custom-site
```

### Theming and Styling

#### `--theme`
**Type:** `string`
**Default:** `compose`
**Description:** Hugo theme to apply to the site

**Available themes:**
- `compose` - Modern, clean design (default)
- `minimal` - Lightweight and fast
- `dark` - Dark mode optimized

**Example:**
```bash
./scripts/build.sh \
  --template corporate \
  --theme minimal \
  --output minimal-site
```

#### `--components` or `-c`
**Type:** `string` (comma-separated)
**Description:** Components to include in the site

**Available components:**
- `quiz-engine` - Interactive testing system
- `analytics` - Google Analytics integration
- `search` - Site-wide search functionality
- `contact-form` - Contact form integration

**Example:**
```bash
./scripts/build.sh \
  --template corporate \
  --components analytics,search,contact-form \
  --output enhanced-site
```

### Build Configuration

#### `--base-url`
**Type:** `string`
**Description:** Base URL for the site (used for absolute links and SEO)

**Example:**
```bash
./scripts/build.sh \
  --template documentation \
  --base-url "https://docs.myproject.com" \
  --output docs-site
```

#### `--environment` or `-e`
**Type:** `string`
**Default:** `development`
**Description:** Hugo environment for the build

**Available values:**
- `development` - Development environment with debug features
- `production` - Production environment with optimizations

**Example:**
```bash
./scripts/build.sh \
  --template corporate \
  --environment production \
  --base-url "https://company.com" \
  --output production-site
```

#### `--minify`
**Type:** `boolean`
**Description:** Enable Hugo minification for CSS, JS, and HTML

**Example:**
```bash
./scripts/build.sh \
  --template corporate \
  --minify \
  --environment production \
  --output optimized-site
```

#### `--draft`
**Type:** `boolean`
**Description:** Include draft content in the build

**Example:**
```bash
./scripts/build.sh \
  --template documentation \
  --draft \
  --output preview-site
```

#### `--future`
**Type:** `boolean`
**Description:** Include content with future publication dates

**Example:**
```bash
./scripts/build.sh \
  --template corporate \
  --future \
  --output preview-site
```

### Development and Debugging

#### `--verbose` or `-v`
**Type:** `boolean`
**Description:** Enable verbose output for debugging

**Example:**
```bash
./scripts/build.sh \
  --template documentation \
  --verbose \
  --output debug-site
```

#### `--quiet` or `-q`
**Type:** `boolean`
**Description:** Suppress non-error output

**Example:**
```bash
./scripts/build.sh \
  --template corporate \
  --quiet \
  --output silent-build
```

#### `--validate-only`
**Type:** `boolean`
**Description:** Only validate configuration without building

**Example:**
```bash
./scripts/build.sh \
  --template documentation \
  --content docs/content \
  --validate-only
```

#### `--log-level`
**Type:** `string`
**Default:** `info`
**Description:** Set logging verbosity level

**Available values:**
- `debug` - Detailed debugging information
- `info` - General information (default)
- `warn` - Warnings only
- `error` - Errors only

**Example:**
```bash
./scripts/build.sh \
  --template corporate \
  --log-level debug \
  --output debug-site
```

## Complete Examples

### Basic Documentation Site
```bash
./scripts/build.sh \
  --template documentation \
  --content docs/content \
  --base-url "https://docs.example.com" \
  --output docs-site
```

### Production Corporate Site
```bash
./scripts/build.sh \
  --template corporate \
  --theme compose \
  --components analytics,search,contact-form \
  --environment production \
  --minify \
  --base-url "https://company.com" \
  --output company-production
```

### Educational Platform with Quiz Engine
```bash
./scripts/build.sh \
  --template educational \
  --components quiz-engine,analytics \
  --content course-content \
  --base-url "https://learn.example.com" \
  --output learning-platform
```

### Development Build with Debugging
```bash
./scripts/build.sh \
  --template documentation \
  --content docs/content \
  --draft \
  --future \
  --verbose \
  --log-level debug \
  --output dev-docs
```

## Build Process Flow

The build script follows this process:

1. **Parameter Validation** - Validates all input parameters
2. **Template Selection** - Copies the specified template files
3. **Content Processing** - Processes content from the specified directory
4. **Theme Application** - Applies the selected theme
5. **Component Integration** - Includes requested components
6. **Configuration Generation** - Creates Hugo configuration files
7. **Hugo Build** - Runs Hugo to generate the static site
8. **Optimization** - Applies minification if requested

## Configuration Inheritance

The build system uses a hierarchical configuration approach:

1. **Template defaults** - Base configuration from template
2. **Component configs** - Additional configuration from components
3. **Custom config** - Overrides from `--config` parameter
4. **Command-line params** - Final overrides from CLI arguments

## Error Handling

The build script provides detailed error messages for common issues:

- **Invalid template names** - Shows available templates
- **Missing content directories** - Suggests correct paths
- **Configuration conflicts** - Explains incompatible options
- **Hugo build errors** - Displays Hugo error messages with context

## Performance Tips

### Faster Builds
- Use `--quiet` to reduce output overhead
- Avoid `--verbose` unless debugging
- Use local content paths (avoid network sources)

### Optimized Production Builds
- Always use `--environment production`
- Enable `--minify` for smaller files
- Set appropriate `--base-url` for SEO

### Development Workflow
- Use `--draft` and `--future` for previewing content
- Enable `--verbose` for troubleshooting
- Use `--validate-only` to check configurations quickly

## Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Build Documentation
  run: |
    ./scripts/build.sh \
      --template documentation \
      --content docs/content \
      --environment production \
      --minify \
      --base-url ${{ env.DOCS_URL }} \
      --output build/docs
```

### GitLab CI Example
```yaml
build-docs:
  script:
    - ./scripts/build.sh
        --template documentation
        --content docs/content
        --environment production
        --base-url "${CI_PAGES_URL}"
        --output public
```

## Troubleshooting

### Common Issues

**"Template not found" error:**
```bash
# Check available templates
ls templates/
# Use exact template name
./scripts/build.sh --template documentation
```

**"Content directory not found" error:**
```bash
# Verify content path exists
ls -la docs/content/
# Use correct relative or absolute path
./scripts/build.sh --content docs/content
```

**Hugo build fails:**
```bash
# Use verbose mode to see Hugo errors
./scripts/build.sh --verbose --template documentation
# Check Hugo configuration
hugo config --source output-directory
```

### Getting Help

- Use `--help` flag to see all options
- Check `--validate-only` for configuration issues
- Enable `--verbose` for detailed debugging
- Review Hugo error messages carefully

---

**Next:** Learn about [Configuration](/hugo/user-guide/configuration/) to understand module.json files and advanced customization options.