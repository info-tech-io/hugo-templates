---
title: "Contributing"
description: "How to contribute to Hugo Templates Framework development"
weight: 50
---

# Contributing to Hugo Templates Framework

We welcome contributions from developers who want to help improve Hugo Templates Framework! Whether you're fixing bugs, adding new templates, improving documentation, or helping other users, your contributions make the project better for everyone.

## Quick Start for Contributors

### 1. Development Environment Setup

```bash
# Clone the repository
git clone https://github.com/info-tech-io/hugo-templates.git
cd hugo-templates

# Install dependencies
npm install

# Verify your setup
./scripts/build.sh --template documentation --validate-only
```

### 2. Make Your First Contribution

1. **Find something to work on** - Check our [GitHub Issues](https://github.com/info-tech-io/hugo-templates/issues)
2. **Comment on the issue** - Let others know you're working on it
3. **Fork and create a branch** - `git checkout -b feature/your-feature`
4. **Make your changes** - Follow our development guidelines
5. **Test thoroughly** - Ensure everything works
6. **Submit a pull request** - Clear description of your changes

## Ways to Contribute

### 🐛 Bug Reports
Found a bug? Please [create an issue](https://github.com/info-tech-io/hugo-templates/issues/new/choose) with:
- Clear reproduction steps
- Expected vs actual behavior
- Build environment details (Hugo version, OS, etc.)
- Minimal example configuration

### 💡 Feature Requests
Have an idea for improvement? We'd love to hear it!
- Check existing issues first to avoid duplicates
- Describe the use case clearly
- Explain how it would benefit other users
- Consider implementation complexity

### 📝 Documentation
Help improve our documentation:
- Fix typos and unclear explanations
- Add examples and tutorials
- Improve API documentation
- Create video tutorials or blog posts

### 🏗️ Template Development
Contribute new templates or improve existing ones:
- Create new templates for specific use cases
- Improve existing template functionality
- Add new components and integrations
- Optimize template performance

### 🎨 Theme Development
Help expand our theme collection:
- Create new Hugo themes
- Improve existing theme compatibility
- Add responsive design enhancements
- Optimize theme performance

## Development Guidelines

### Project Structure

Understanding the project structure helps you contribute effectively:

```
hugo-templates/
├── templates/              # Template definitions
│   ├── educational/       # Educational template
│   ├── corporate/         # Corporate template
│   └── documentation/     # Documentation template
├── themes/                # Hugo themes
│   ├── compose/           # Default theme
│   ├── minimal/           # Minimal theme
│   └── dark/              # Dark theme
├── components/            # Reusable components
│   ├── quiz-engine/       # Quiz Engine integration
│   ├── analytics/         # Analytics integration
│   └── search/            # Search functionality
├── schemas/               # JSON schemas for validation
├── scripts/               # Build and utility scripts
├── docs/                  # Documentation source
└── __tests__/             # Test suites
```

### Code Style and Standards

We maintain consistent code quality through automated tools:

```bash
# Format code
npm run format

# Lint code
npm run lint

# Fix auto-fixable issues
npm run lint:fix
```

**Key principles:**
- Use meaningful names for files, functions, and variables
- Add comments for complex logic
- Follow existing patterns in the codebase
- Keep templates modular and reusable
- Test all changes thoroughly

### Template Development

When creating or modifying templates:

#### 1. Template Structure
```
templates/your-template/
├── hugo.toml.template     # Required: Hugo config template
├── module.json           # Required: Template metadata
├── layouts/              # Required: Hugo layouts
│   ├── _default/
│   ├── partials/
│   └── index.html
├── content/              # Optional: Example content
├── static/               # Optional: Static assets
├── data/                 # Optional: Data files
└── README.md             # Required: Template documentation
```

#### 2. Template Metadata (module.json)
```json
{
  "name": "your-template",
  "description": "Template description",
  "version": "1.0.0",
  "author": "Your Name",
  "license": "MIT",
  "hugo": {
    "minVersion": "0.110.0"
  },
  "dependencies": {
    "themes": ["compose"],
    "components": []
  },
  "config": {
    "schema": "schemas/your-template.json"
  }
}
```

#### 3. Configuration Schema
Create a JSON schema in `schemas/` for template validation:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "enableFeature": {
      "type": "boolean",
      "default": true,
      "description": "Enable specific feature"
    }
  }
}
```

### Component Development

Components are reusable modules that can be included in any template:

#### Component Structure
```
components/your-component/
├── component.json        # Component metadata
├── layouts/             # Layout additions
├── static/              # Static assets
├── data/                # Data files
└── README.md            # Component documentation
```

#### Component Integration
Components integrate with templates through:
- **Layout additions** - Partial templates and shortcodes
- **Static assets** - CSS, JavaScript, images
- **Data files** - Configuration and content data
- **Hugo configuration** - Additional Hugo settings

### Testing Requirements

All contributions must include appropriate tests.

📚 **See our comprehensive [Testing Documentation](../developer-docs/testing/)** for:
- **[Test Inventory](../developer-docs/testing/test-inventory/)** - Complete catalog of all 35+ tests
- **[Testing Guidelines](../developer-docs/testing/guidelines/)** - Detailed standards with DO/DON'T examples
- **[Coverage Matrix](../developer-docs/testing/coverage-matrix/)** - Function coverage analysis and gap identification

**Quick Start**:
```bash
# Run all unit tests
./scripts/test-bash.sh --suite unit

# Run with verbose output
./scripts/test-bash.sh --suite unit --verbose

# Run specific test file
./scripts/test-bash.sh --suite unit --file tests/bash/unit/build-functions.bats
```

**Testing Guidelines Summary:**
- All contributions must include appropriate tests
- Follow [Testing Guidelines](../developer-docs/testing/guidelines/) for patterns and best practices
- Check [Test Inventory](../developer-docs/testing/test-inventory/) to avoid duplicating existing coverage
- Use [Coverage Matrix](../developer-docs/testing/coverage-matrix/) to identify testing priorities

### Documentation Standards

When adding features or making changes:

1. **Update relevant documentation** - Keep docs in sync with code
2. **Add JSDoc comments** - Document all public functions
3. **Include usage examples** - Show how to use new features
4. **Update changelog** - Record user-facing changes

### Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]

[optional footer]
```

**Examples:**
```
feat(templates): add blog template for corporate sites
fix(build): resolve component integration issue
docs(api): update configuration reference
test(templates): add integration tests for educational template
```

**Types:**
- `feat` - New features
- `fix` - Bug fixes
- `docs` - Documentation changes
- `test` - Adding or updating tests
- `refactor` - Code changes that neither fix bugs nor add features
- `perf` - Performance improvements
- `chore` - Maintenance tasks

## Pull Request Process

### Before Submitting

1. **Sync with main branch**
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-feature-branch
   git rebase main
   ```

2. **Run full test suite**
   ```bash
   npm run test:full
   npm run build:test
   ```

3. **Update documentation** if needed

4. **Add changelog entry** for user-facing changes

### PR Description Template

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Build tests pass for all templates

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Changelog updated (if applicable)
- [ ] Tests added/updated as needed
```

### Review Process

1. **Automated checks** must pass (tests, linting, build validation)
2. **Code review** by maintainers
3. **Testing** in multiple environments
4. **Documentation review** for user-facing changes
5. **Approval** and merge

## Specific Contribution Areas

### Template Contributions

**Educational Templates:**
- Course-specific layouts (programming, design, etc.)
- Assessment and grading features
- Learning path visualizations
- Student progress tracking

**Corporate Templates:**
- Industry-specific layouts (tech, healthcare, finance)
- E-commerce integrations
- Advanced SEO features
- Multi-language business sites

**Documentation Templates:**
- API documentation generators
- Interactive documentation features
- Version management systems
- Advanced search capabilities

### Component Contributions

**High Priority Components:**
- Authentication systems
- E-commerce integrations
- Advanced analytics
- Social media integrations
- Comment systems
- Newsletter subscriptions

**Theme Contributions:**
- Accessibility-focused themes
- Industry-specific themes
- Mobile-first themes
- Print-optimized themes

### Infrastructure Contributions

- Build system improvements
- CI/CD pipeline enhancements
- Testing infrastructure
- Performance optimizations
- Security improvements

## Getting Help

### Questions and Support
- **GitHub Discussions** - General questions and community chat
- **Discord** - Real-time chat with maintainers and contributors
- **Email** - Contact maintainers directly at hugo-templates@info-tech.io

### Finding Work
- **Good First Issues** - Issues labeled `good-first-issue`
- **Help Wanted** - Issues labeled `help-wanted`
- **Feature Requests** - Community-requested features
- **Documentation** - Always needs improvement

### Stuck or Need Guidance?
- Check existing [GitHub Issues](https://github.com/info-tech-io/hugo-templates/issues)
- Look at [closed PRs](https://github.com/info-tech-io/hugo-templates/pulls?q=is%3Apr+is%3Aclosed) for similar work
- Ask in [GitHub Discussions](https://github.com/info-tech-io/hugo-templates/discussions)
- Join our [Discord community](https://discord.gg/infotechht)

## Recognition

We recognize contributors in several ways:

- **Contributors page** on our documentation site
- **Release notes** mention for significant contributions
- **Swag program** for regular contributors (stickers, t-shirts)
- **Maintainer opportunities** for long-term contributors
- **Speaking opportunities** at conferences and meetups

## Code of Conduct

We are committed to providing a welcoming and inclusive experience for all contributors. Please read our [Code of Conduct](https://github.com/info-tech-io/hugo-templates/blob/main/CODE_OF_CONDUCT.md) before participating.

### Our Standards

- **Be respectful** and inclusive in all interactions
- **Provide constructive feedback** in code reviews
- **Help newcomers** get started and learn
- **Be patient** with questions and different skill levels
- **Celebrate successes** and learn from mistakes together

## Release Process

Understanding our release process helps you plan contributions:

### Version Numbering
We use [Semantic Versioning](https://semver.org/):
- **Major** (1.0.0) - Breaking changes
- **Minor** (1.1.0) - New features, backwards compatible
- **Patch** (1.1.1) - Bug fixes, backwards compatible

### Release Schedule
- **Major releases** - Annual, with advance notice
- **Minor releases** - Monthly, with new features
- **Patch releases** - As needed, for bug fixes

### Feature Planning
- Features are planned in quarterly roadmaps
- Community input welcome through GitHub Discussions
- Major features go through RFC (Request for Comments) process

---

Thank you for contributing to Hugo Templates Framework! Every contribution, no matter how small, helps make the project better for developers worldwide. 🎉

**Ready to get started?** Check out our [good first issues](https://github.com/info-tech-io/hugo-templates/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) and jump in!