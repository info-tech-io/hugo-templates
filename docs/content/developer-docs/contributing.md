# Contributing Guide

## Overview

Welcome to the Hugo Template Factory Framework! We appreciate your interest in contributing to this project. This guide provides everything you need to know to contribute effectively.

## Quick Start for Contributors

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/yourusername/hugo-templates.git
cd hugo-templates

# Add upstream remote
git remote add upstream https://github.com/info-tech-io/hugo-templates.git
```

### 2. Set Up Development Environment

```bash
# Initialize submodules and install dependencies
git submodule update --init --recursive
npm ci

# Verify setup
./scripts/diagnostic.js --all
```

### 3. Understanding Our Workflow

We use **Epic Issues + Child Issues + Feature Branches Strategy**:

- **Epic Issues**: Large features tracked as Epics (e.g., "Build System v2.0")
- **Child Issues**: Individual features within Epics
- **Feature Branches**: Development branches for each Child Issue
- **Epic Integration**: All features merge to Epic branch before main

## Development Workflow

### Understanding Issue Structure

#### Epic Issues
Large features that span multiple components:
```
Epic: Build System v2.0 (#2)
├── Child Issue #3: Error Handling System
├── Child Issue #4: Test Coverage Framework
├── Child Issue #5: GitHub Actions Optimization
├── Child Issue #6: Documentation Updates
└── Child Issue #7: Performance Monitoring
```

#### Child Issues
Specific, actionable features within an Epic:
- Clear scope and requirements
- Can be completed in 1-2 weeks
- Have defined acceptance criteria
- Include testing requirements

### Branch Strategy

```bash
# Branch structure
main                    # Production-ready code
├── epic/feature-name   # Epic branch (e.g., epic/build-system-v2.0)
│   ├── feature/child-issue-name  # Feature branch for Child Issue
│   └── feature/another-child     # Another feature branch
└── hotfix/urgent-fix   # Emergency fixes
```

### Working on a Child Issue

#### 1. Create Feature Branch

```bash
# Switch to epic branch
git checkout epic/build-system-v2.0
git pull upstream epic/build-system-v2.0

# Create feature branch
git checkout -b feature/your-child-issue-name

# Example for Child Issue #6
git checkout -b feature/documentation-updates
```

#### 2. Development Process

```bash
# Make your changes
# Follow coding standards (see below)

# Test your changes
npm run test
./scripts/validate.js --all

# Commit with clear messages
git add .
git commit -m "feat: implement documentation updates

- Create comprehensive build system guide
- Add troubleshooting documentation
- Update README with new structure
- Add interactive flowcharts

Resolves #6"
```

#### 3. Create Pull Request

```bash
# Push feature branch
git push origin feature/documentation-updates

# Create PR to epic branch (NOT main)
# Title: "Child Issue #6: Documentation Updates"
# Target: epic/build-system-v2.0
```

#### 4. Code Review and Integration

- PR gets reviewed by maintainers
- Make requested changes
- Once approved, PR is merged to epic branch
- Epic maintainer updates progress tracking

#### 5. Epic Integration

When Epic is complete:
- Epic branch gets merged to main
- All Child Issues are closed
- Epic Issue is closed
- Progress documentation is updated

## Coding Standards

### Directory Structure

```
hugo-templates/
├── .github/
│   ├── actions/           # Reusable GitHub Actions
│   └── workflows/         # CI/CD pipelines
├── templates/             # Site templates
├── themes/               # Hugo themes (git submodules)
├── components/           # Modular components
├── scripts/              # Build and utility scripts
├── tests/                # Test files
│   ├── bash/            # BATS tests for bash scripts
│   └── node/            # Node.js tests
└── docs/                 # Documentation
    ├── user-guides/      # User documentation
    ├── developer-docs/   # Developer guides
    ├── troubleshooting/  # Problem resolution
    └── tutorials/        # Step-by-step guides
```

### Bash Script Standards

#### File Header
```bash
#!/bin/bash
# Description: Brief description of script purpose
# Usage: script.sh [options]
# Author: Hugo Template Factory Team
# License: Apache License 2.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

#### Error Handling
```bash
# Use consistent error handling
error_exit() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Example usage
[ -f "$CONFIG_FILE" ] || error_exit "Configuration file not found: $CONFIG_FILE"
```

#### Logging
```bash
# Use logger.js for consistent logging
source "$(dirname "$0")/logger.js"

log_info "Starting build process"
log_warn "Using default template"
log_error "Build failed"
```

### Node.js Standards

#### File Structure
```javascript
#!/usr/bin/env node
/**
 * Script Name
 * Description: Brief description
 * Author: Hugo Template Factory Team
 * License: Apache License 2.0
 */

'use strict';

const fs = require('fs');
const path = require('path');
```

#### Error Handling
```javascript
// Use consistent error handling
function handleError(message, error) {
    console.error(`[ERROR] ${message}`);
    if (error) console.error(error);
    process.exit(1);
}

// Example usage
try {
    const content = fs.readFileSync(configPath, 'utf8');
} catch (error) {
    handleError('Failed to read configuration file', error);
}
```

### Documentation Standards

#### Markdown Structure
```markdown
# Title

## Overview
Brief description of what this document covers.

## Prerequisites
What users need before following this guide.

## Main Content
Organized sections with clear headings.

### Code Examples
```bash
# Always include working examples
./scripts/build.sh --template=default
```

## Related Documentation
Links to related guides.
```

#### Code Comments
```bash
# Clear, concise comments explaining why, not what
validate_template() {
    # Check template exists before proceeding with build
    # This prevents cryptic Hugo errors later in the process
    if [[ ! -d "templates/$template" ]]; then
        error_exit "Template '$template' not found"
    fi
}
```

## Testing Requirements

### Test Coverage

All contributions must include appropriate tests:

#### Bash Scripts (BATS Tests)

```bash
# tests/bash/test_build.bats

@test "build script validates template parameter" {
    run ./scripts/build.sh --template=nonexistent
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Template 'nonexistent' not found" ]]
}

@test "build script creates output directory" {
    run ./scripts/build.sh --template=minimal --output=test-output
    [ "$status" -eq 0 ]
    [ -d "test-output" ]
    [ -f "test-output/index.html" ]
}
```

#### Node.js Scripts (Jest Tests)

```javascript
// tests/node/validate.test.js

const { validateTemplate } = require('../../scripts/validate');

describe('validateTemplate', () => {
    test('should validate existing template', () => {
        expect(() => validateTemplate('minimal')).not.toThrow();
    });

    test('should throw error for non-existent template', () => {
        expect(() => validateTemplate('nonexistent')).toThrow('Template not found');
    });
});
```

### Running Tests

```bash
# Run all tests
npm run test

# Run bash tests only
./scripts/test-bash.sh

# Run Node.js tests only
npm run test:node

# Run tests for specific component
./scripts/test-bash.sh --suite build
```

## Component Development

### Creating New Components

#### 1. Component Structure

```
components/your-component/
├── README.md              # Component documentation
├── component.yml          # Component configuration
├── src/                   # Source files
│   ├── js/               # JavaScript files
│   ├── css/              # Stylesheets
│   └── templates/        # Hugo templates
├── static/               # Static assets
├── tests/                # Component tests
└── examples/             # Usage examples
```

#### 2. Component Configuration

```yaml
# components/your-component/component.yml
name: your-component
version: "1.0.0"
description: "Brief description of what this component does"
author: "Your Name"
license: "Apache-2.0"

dependencies:
  hugo: ">=0.148.0"
  node: ">=18.0.0"

config:
  theme: "default"
  enabled: true
  options:
    option1: "default_value"
    option2: false

integration:
  css_files:
    - "css/your-component.css"
  js_files:
    - "js/your-component.js"
  hugo_partials:
    - "partials/your-component.html"
```

#### 3. Component Documentation

```markdown
# Your Component

## Overview
Description of what the component does.

## Installation
How to enable and configure the component.

## Configuration
```yaml
components:
  - name: your-component
    config:
      option1: "value"
```

## Usage Examples
Practical examples of using the component.

## API Reference
Detailed API documentation.
```

### Testing Components

```bash
# Test component integration
./scripts/build.sh --template=default --components=your-component

# Validate component configuration
./scripts/validate.js --components=your-component

# Run component-specific tests
npm run test:component your-component
```

## Theme Development

### Theme Structure

```
themes/your-theme/
├── theme.toml            # Theme metadata
├── layouts/              # Hugo layouts
│   ├── _default/        # Default layouts
│   ├── partials/        # Partial templates
│   └── shortcodes/      # Hugo shortcodes
├── static/              # Static assets
│   ├── css/            # Stylesheets
│   ├── js/             # JavaScript
│   └── images/         # Images
├── data/               # Data files
└── README.md           # Theme documentation
```

### Theme Configuration

```toml
# themes/your-theme/theme.toml
name = "Your Theme Name"
license = "Apache-2.0"
licenselink = "https://github.com/info-tech-io/hugo-templates/blob/main/LICENSE"
description = "Brief theme description"
homepage = "https://github.com/info-tech-io/hugo-templates"
tags = ["responsive", "minimal", "blog"]
features = ["blog", "gallery", "contact-form"]
min_version = "0.148.0"

[author]
  name = "Hugo Template Factory Team"
  homepage = "https://github.com/info-tech-io"
```

## Documentation Contributions

### Documentation Types

1. **User Guides**: For end users building sites
2. **Developer Docs**: For contributors and advanced users
3. **Tutorials**: Step-by-step learning materials
4. **Troubleshooting**: Problem resolution guides
5. **API Reference**: Technical specifications

### Documentation Standards

#### Writing Style
- **Clear and concise**: Use simple language
- **Action-oriented**: Start with verbs (Create, Install, Configure)
- **Example-heavy**: Include working code examples
- **Progressive**: Build from simple to complex

#### Structure Template
```markdown
# Title

## Overview
What this document covers and who it's for.

## Prerequisites
What users need to know or have installed.

## Step-by-Step Instructions
Clear, numbered steps with examples.

## Common Issues
Troubleshooting section.

## Related Documentation
Links to related guides.
```

### Documentation Testing

```bash
# Test all documentation links
./scripts/validate-docs.sh

# Test code examples in documentation
./scripts/test-docs-examples.sh

# Check documentation formatting
markdownlint docs/**/*.md
```

## Performance Considerations

### Build System Performance

- **Benchmark changes**: Measure impact on build times
- **Profile memory usage**: Ensure memory efficiency
- **Test with large sites**: Validate performance at scale

```bash
# Performance testing
time ./scripts/build.sh --template=enterprise
./scripts/performance-test.sh
```

### Component Performance

- **Lazy loading**: Implement when appropriate
- **Minification**: Ensure CSS/JS is optimized
- **Caching**: Use effective caching strategies

## Security Guidelines

### Code Security

- **Input validation**: Validate all user inputs
- **Path traversal**: Prevent directory traversal attacks
- **Secrets**: Never commit secrets or tokens

```bash
# Security validation
./scripts/security-check.sh
npm audit
```

### Documentation Security

- **No secrets**: Never include real credentials in docs
- **Safe examples**: Use placeholder values
- **Security notes**: Highlight security considerations

## Release Process

### Version Management

We follow [Semantic Versioning](https://semver.org/):
- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features, backward compatible
- **Patch** (0.0.1): Bug fixes, backward compatible

### Release Workflow

1. **Epic Completion**: All Child Issues completed
2. **Integration Testing**: Comprehensive testing on epic branch
3. **Documentation Review**: Ensure docs are updated
4. **Version Bump**: Update version numbers
5. **Merge to Main**: Epic branch merged to main
6. **Tag Release**: Create git tag and GitHub release
7. **Announce**: Update community about new release

## Getting Help

### For Contributors

1. **Read the docs**: Check existing documentation first
2. **Search issues**: Look for similar problems/questions
3. **Ask in discussions**: Use GitHub Discussions for questions
4. **Join community**: Connect with other contributors

### For Maintainers

1. **Code reviews**: Provide constructive feedback
2. **Issue triage**: Label and prioritize issues
3. **Epic coordination**: Manage Epic progress
4. **Community support**: Help contributors succeed

## Code of Conduct

We are committed to providing a welcoming and inclusive environment:

- **Be respectful**: Treat everyone with respect and kindness
- **Be inclusive**: Welcome people of all backgrounds
- **Be constructive**: Provide helpful feedback
- **Be patient**: Remember everyone is learning

### Reporting Issues

If you experience harassment or uncomfortable behavior:
1. Contact maintainers privately
2. Report via GitHub if comfortable
3. We will address issues promptly and fairly

## Recognition

### Contributors

We recognize contributions in several ways:
- **Contributors list**: README and documentation
- **Release notes**: Highlight major contributions
- **GitHub insights**: Contribution graphs and statistics
- **Community features**: Showcase interesting uses

### Types of Contributions

All contributions are valued:
- **Code**: New features, bug fixes, optimizations
- **Documentation**: Guides, tutorials, examples
- **Testing**: Bug reports, test cases, QA
- **Design**: UI/UX improvements, themes
- **Community**: Discussions, support, outreach

## Next Steps

### For New Contributors

1. **Start small**: Pick a "good first issue"
2. **Ask questions**: Don't hesitate to ask for help
3. **Learn the codebase**: Explore existing code
4. **Join discussions**: Participate in community

### For Experienced Contributors

1. **Mentor others**: Help new contributors
2. **Lead initiatives**: Propose new features
3. **Improve process**: Suggest workflow improvements
4. **Review code**: Help with code reviews

## Related Documentation

- [Development Setup](./development-setup.md)
- [Architecture Overview](./architecture.md)
- [Testing Guide](./testing.md)
- [Release Process](./release-process.md)

---

Thank you for contributing to the Hugo Template Factory Framework! Your contributions help make this project better for everyone. 🚀