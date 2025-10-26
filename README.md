# Hugo Template Factory Framework

> The first parametrized scaffolding tool for Hugo - bringing Angular Schematics-like functionality to static site generation

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/info-tech-io/hugo-templates.git
cd hugo-templates

# Initialize submodules and install dependencies
git submodule update --init --recursive
npm ci

# Create a site with default template and compose theme
./scripts/build.sh --template=default --theme=compose --output=my-site

# Create a minimal site for faster builds
./scripts/build.sh --template=minimal --theme=minimal --output=quick-site

# Add Quiz Engine component for educational content
./scripts/build.sh --template=default --theme=compose --components=quiz-engine --output=education-site

# Production build with optimization and performance monitoring
./scripts/build.sh --template=enterprise --environment=production --minify --base-url=https://example.com --performance-track --performance-report

# Development build with performance tracking
./scripts/build.sh --template=minimal --performance-track --cache-stats

# Federated builds: Orchestrate multiple Hugo sites from different repositories
./scripts/federated-build.sh --config=examples/modules-simple.json --output=federated-site

# Production InfoTech.io 5-module federation
./scripts/federated-build.sh --config=examples/modules-infotech.json --output=production --minify

# Dry-run to test federation configuration
./scripts/federated-build.sh --config=modules.json --dry-run
```

## 🎯 Why Hugo Template Factory?

Hugo Template Factory solves the **scaffolding gap** in Hugo ecosystem by providing:

- **🎯 Parametrized Generation**: Angular Schematics-like functionality for Hugo
- **🧩 Component Modularity**: Reusable components without Go Modules complexity
- **🎓 Educational Focus**: Built-in Quiz Engine and learning-oriented features
- **🔧 Script-Based Simplicity**: Accessible to non-Go developers with Bash/Node.js
- **⚡ Performance Optimized**: Smart caching and optimized CI/CD workflows
- **🛡️ Enterprise Ready**: Error handling, monitoring, and production features

### How We Compare

| Approach | Example | Flexibility | Learning Curve | Our Advantage |
|----------|---------|-------------|----------------|---------------|
| **Hugo CLI** | `hugo new site` | ⭐ Too basic | ⭐⭐⭐⭐⭐ Very easy | We provide ready-to-use templates |
| **Hugo Modules** | `hugo mod get` | ⭐⭐⭐⭐⭐ Maximum | ⭐ Expert only | We abstract complexity while keeping power |
| **Starter Templates** | Hugoplate, Doks | ⭐⭐ Monolithic | ⭐⭐⭐⭐ Easy | We offer modular components vs all-or-nothing |
| **Universal Tools** | Cookiecutter, Yeoman | ⭐⭐⭐ Generic | ⭐⭐⭐ Moderate | We're Hugo-native with theme integration |
| **Platform Builders** | Hugo Blox Builder | ⭐⭐⭐ Ecosystem-locked | ⭐⭐⭐ Moderate | We stay open and Hugo-compatible |
| **🚀 Hugo Template Factory** | **Our solution** | **⭐⭐⭐⭐⭐ Maximum** | **⭐⭐⭐⭐ Easy** | **Best of all worlds** |

**The Sweet Spot**: We bridge the gap between "too simple" and "too complex" by offering the configurability of Hugo Modules with the simplicity of starter templates.

## 🌐 Federated Build System

**NEW: Layer 2 Federation** - Orchestrate multiple Hugo sites from different repositories into a unified GitHub Pages deployment.

### What is Federation?

The federated build system allows you to:
- **Merge content from multiple repositories** - Each team maintains their own Hugo site independently
- **Deploy as unified site** - Single GitHub Pages deployment from distributed sources
- **Maintain module independence** - Teams develop, test, and version their content separately
- **Centralized orchestration** - One configuration controls the entire federation

**Perfect for**: Multi-team documentation, multi-repository projects, content aggregation from distributed sources.

### Why Use Federation?

**Multi-Team Collaboration**
- Each team has their own repository and workflow
- Independent development and testing
- No merge conflicts between teams
- Centralized deployment without centralized development

**Distributed Content Management**
- Main documentation in one repo
- API reference in another
- Blog posts, tutorials, FAQs each in separate repos
- Merge all into single site for users

**Flexible Source Options**
- Build from Git repositories (clone and build)
- Download pre-built sites from GitHub Releases (fastest)
- Use local module paths for development
- Mix and match strategies per module

### Key Capabilities

**Three Merge Strategies**:
1. **download-merge-deploy** - Download pre-built modules from GitHub Releases (fastest, CI/CD-friendly)
2. **merge-and-build** - Clone and build all modules from source (full control)
3. **preserve-base-site** - Merge modules into existing base site (incremental enhancement)

**Intelligent Merge System**:
- Automatic CSS path detection and rewriting
- Content deduplication
- Conflict resolution with priority-based merging
- YAML front matter preservation

**Enterprise-Grade**:
- JSON Schema validation for configurations
- 140 comprehensive tests (100% passing)
- Detailed error reporting
- Dry-run mode for testing

### Federation vs Single-Site

| Feature | Single-Site (Layer 1) | Federation (Layer 2) |
|---------|----------------------|----------------------|
| **Repositories** | Single repository | Multiple repositories |
| **Teams** | One team | Multiple independent teams |
| **Build Command** | `build.sh` | `federated-build.sh` |
| **Use Case** | Simple projects | Multi-team collaboration |
| **Setup Complexity** | ⭐ Simple | ⭐⭐⭐ Moderate |
| **Scalability** | Limited | ⭐⭐⭐⭐⭐ Excellent |
| **Independence** | Tight coupling | ⭐⭐⭐⭐⭐ Full independence |

### Real-World Use Cases

**Use Case 1: InfoTech.io Multi-Team Documentation**
```
Scenario: 5 teams, each with their own repository
- Team 1: Main documentation (base site)
- Team 2: API reference
- Team 3: Tutorials
- Team 4: Blog posts
- Team 5: FAQ and troubleshooting

Solution: Federated build merges all 5 modules into single site
Result: Unified documentation portal with independent team workflows
```

**Use Case 2: Multi-Repository Product Documentation**
```
Scenario: Product with multiple components
- Core product docs in main repo
- Plugin documentation in plugin repos
- Community content in separate repo

Solution: Federation pulls from all repos automatically
Result: Complete documentation from distributed sources
```

**Use Case 3: Content from Multiple Sources**
```
Scenario: Static site with diverse content origins
- Editorial content from Git
- Product data from external API (pre-processed to Hugo)
- User-generated content from database (exported to Hugo)

Solution: Pre-process each source to Hugo modules, then federate
Result: Unified static site from multiple data sources
```

### Quick Start: Federation

**Step 1**: Create federation configuration (`modules.json`):
```json
{
  "baseSite": {
    "name": "main-docs",
    "source": { "type": "local", "path": "./base-site" }
  },
  "modules": [
    {
      "name": "api-reference",
      "source": {
        "type": "github",
        "repo": "your-org/api-docs",
        "tag": "v1.0.0"
      },
      "priority": 1
    }
  ],
  "strategy": "download-merge-deploy"
}
```

**Step 2**: Run federated build:
```bash
./scripts/federated-build.sh --config=modules.json --output=public
```

**Step 3**: Deploy to GitHub Pages (automated in CI/CD)

### Federation Documentation

**User Guides**:
- [Federated Builds Guide](docs/content/user-guides/federated-builds.md) - Complete configuration reference
- [Compatibility Guide](docs/content/user-guides/federation-compatibility.md) - When to use federation

**Tutorials**:
- [Simple 2-Module Tutorial](docs/content/tutorials/federation-simple-tutorial.md) - Get started in 15 minutes
- [Advanced 5-Module Tutorial](docs/content/tutorials/federation-advanced-tutorial.md) - Production InfoTech.io scenario
- [Migration Checklist](docs/content/tutorials/federation-migration-checklist.md) - Migrate from single-site

**Developer Documentation**:
- [Federation Architecture](docs/content/developer-docs/federation-architecture.md) - Technical design and Layer 1/2 separation
- [API Reference](docs/content/developer-docs/federation-api-reference.md) - Complete function documentation
- [Testing Guide](docs/content/developer-docs/testing/federation-testing.md) - 140 tests with 100% coverage

**Examples**:
- [Simple Example](docs/content/examples/modules-simple.json) - 2-module federation
- [Advanced Example](docs/content/examples/modules-advanced.json) - Complex configuration
- [InfoTech.io Example](docs/content/examples/modules-infotech.json) - Production 5-module setup

## 🏗️ Architecture

```
hugo-templates/
├── .github/
│   ├── actions/           # Reusable GitHub Actions
│   │   └── setup-build-env/   # Optimized build environment setup
│   └── workflows/         # CI/CD pipelines with smart caching
├── templates/             # Parametrized site templates
│   ├── default/          # Full-featured template
│   ├── minimal/          # Lightweight for fast builds
│   ├── academic/         # Academic publications & research
│   ├── enterprise/       # Corporate features & analytics
│   └── educational/      # Learning-focused template
├── themes/               # Hugo themes (git submodules)
│   ├── compose/          # Feature-rich responsive theme
│   └── minimal/          # Clean, fast-loading theme
├── components/           # Modular, reusable components
│   ├── quiz-engine/      # Interactive educational quizzes
│   ├── analytics/        # Web analytics integration
│   └── auth/             # Authentication & access control
├── scripts/              # Build automation & tooling
│   ├── build.sh          # Layer 1: Single-site builds
│   ├── federated-build.sh    # Layer 2: Multi-module federation ⭐ NEW
│   ├── validate.js       # Configuration validation
│   └── diagnostic.js     # System diagnostics & troubleshooting
├── schemas/              # Configuration schemas ⭐ NEW
│   └── modules.schema.json   # Federation configuration schema
└── docs/                 # Comprehensive documentation
    ├── content/
    │   ├── user-guides/
    │   │   ├── federated-builds.md          # Federation guide ⭐
    │   │   └── federation-compatibility.md  # Compatibility guide ⭐
    │   ├── tutorials/
    │   │   ├── federation-simple-tutorial.md      # 2-module tutorial ⭐
    │   │   ├── federation-advanced-tutorial.md    # 5-module tutorial ⭐
    │   │   └── federation-migration-checklist.md  # Migration guide ⭐
    │   ├── developer-docs/
    │   │   ├── federation-architecture.md   # Technical design ⭐
    │   │   ├── federation-api-reference.md  # API documentation ⭐
    │   │   └── testing/
    │   │       └── federation-testing.md    # Testing guide (140 tests)
    │   └── examples/
    │       ├── modules-simple.json         # 2-module example
    │       ├── modules-advanced.json       # Complex configuration
    │       └── modules-infotech.json       # Production 5-module setup
    ├── user-guides/      # User documentation
    ├── developer-docs/   # Developer guides
    ├── troubleshooting/  # Problem resolution guides
    └── api-reference/    # API documentation

⭐ = Federation-related (Layer 2)
```

## 📦 Templates

| Template | Description | Use Case | Features |
|----------|-------------|----------|----------|
| **default** | Full-featured template | General-purpose sites | All components, flexible layout |
| **minimal** | Lightweight template | Fast builds, simple sites | Essential features only |
| **academic** | Academic template | Research, publications | Citations, references, papers |
| **enterprise** | Corporate template | Business websites | Analytics, auth, professional layout |
| **educational** | Learning-focused | Educational platforms | Quiz engine, progress tracking |

## 🧩 Components

| Component | Status | Description | Features |
|-----------|---------|-------------|----------|
| **quiz-engine** | ✅ **Ready** | Interactive quiz system | Progress tracking, multiple question types, analytics |
| **analytics** | 🚧 **Beta** | Web analytics tracking | Google Analytics, privacy-compliant, event tracking |
| **auth** | 🚧 **Beta** | Authentication system | User management, access control, SSO |
| **citations** | 📋 **Planned** | Academic citations | BibTeX, CSL, automatic formatting |
| **search** | 📋 **Planned** | Site search functionality | Full-text search, instant results |
| **comments** | 📋 **Planned** | Comment system | Moderation, notifications, integrations |

## 🔧 System Requirements

- **Hugo Extended** ≥ 0.148.0
- **Node.js** ≥ 18.0.0
- **Git** for theme management
- **Bash** shell (Linux/macOS) or **Git Bash** (Windows)

## 📚 Documentation

### 👥 User Guides
- **[Build System Guide](docs/user-guides/build-system.md)** - Complete build system documentation
- **[Federated Builds Guide](docs/content/user-guides/federated-builds.md)** ⭐ - Multi-module federation reference
- **[Federation Compatibility](docs/content/user-guides/federation-compatibility.md)** ⭐ - When to use federation
- **[Getting Started](docs/tutorials/getting-started.md)** - Step-by-step tutorial
- **[Template Usage](docs/user-guides/templates.md)** - Working with templates
- **[Deployment Guide](docs/user-guides/deployment.md)** - Production deployment

### 🛠️ Developer Documentation
- **[Testing Documentation](docs/content/developer-docs/testing/)** - Comprehensive testing guide with 140 tests
  - [Test Inventory](docs/content/developer-docs/testing/test-inventory.md) - Complete test catalog (Layer 1 + Layer 2)
  - [Testing Guidelines](docs/content/developer-docs/testing/guidelines.md) - Standards and best practices
  - [Coverage Matrix](docs/content/developer-docs/testing/coverage-matrix.md) - Function coverage analysis
  - [Federation Testing](docs/content/developer-docs/testing/federation-testing.md) ⭐ - Federation test suite (140 tests, 100%)
- **[Federation Architecture](docs/content/developer-docs/federation-architecture.md)** ⭐ - Layer 1/2 design and technical details
- **[Federation API Reference](docs/content/developer-docs/federation-api-reference.md)** ⭐ - Complete function documentation (28 functions)
- **[Alternatives Analysis](docs/developer-docs/alternatives.md)** - How we compare to other Hugo tools
- **[Component Development](docs/developer-docs/components.md)** - Creating custom components
- **[GitHub Actions Guide](docs/developer-docs/github-actions.md)** - CI/CD workflows and optimization
- **[API Reference](docs/api-reference/)** - Complete API documentation
- **[Contributing Guide](docs/developer-docs/contributing.md)** - Contribution guidelines (includes federation workflow)

### 🚨 Troubleshooting
- **[Common Issues](docs/troubleshooting/common-issues.md)** - Problem resolution guide
- **[Error Reference](docs/troubleshooting/error-reference.md)** - Error codes and solutions
- **[Performance Guide](docs/troubleshooting/performance.md)** - Optimization techniques

### 📖 Tutorials
- **[Use Cases & User Stories](docs/tutorials/use-cases.md)** - Real-world usage scenarios and examples
- **[Simple 2-Module Federation](docs/content/tutorials/federation-simple-tutorial.md)** ⭐ - Get started with federation (15 min)
- **[Advanced 5-Module Federation](docs/content/tutorials/federation-advanced-tutorial.md)** ⭐ - Production InfoTech.io scenario (45 min)
- **[Federation Migration Checklist](docs/content/tutorials/federation-migration-checklist.md)** ⭐ - Migrate from single-site
- **[First Site Tutorial](docs/tutorials/first-site.md)** - Create your first site
- **[Getting Started Guide](docs/tutorials/getting-started.md)** - Comprehensive getting started tutorial
- **[Educational Platform](docs/tutorials/educational-platform.md)** - Build a learning platform
- **[Corporate Website](docs/tutorials/corporate-website.md)** - Business website setup
- **[Academic Site](docs/tutorials/academic-site.md)** - Research publication site

## 🎯 Development Status

**Current Version**: `0.2.0` - **Build System v2.0**

### ✅ Completed Features (Epic Status: 100% - COMPLETE)
- **✅ Error Handling System** - Comprehensive error handling and diagnostics
- **✅ Test Coverage Framework** - BATS testing with 95%+ coverage
- **✅ GitHub Actions Optimization** - 50%+ performance improvement in CI/CD
- **✅ Documentation Updates** - Comprehensive guides and troubleshooting
- **✅ Performance Optimization** - 4-phase performance framework with intelligent caching, parallel processing, monitoring, and analytics

### 🚀 New Performance Features
- **Multi-Level Caching (L1/L2/L3)** - Intelligent caching for maximum build speed
- **Parallel Processing** - Optimized parallel operations with job throttling
- **Performance Monitoring** - Real-time tracking, historical analysis, and optimization recommendations
- **Advanced CLI Options** - `--performance-track`, `--performance-report`, `--performance-history`, `--cache-stats`

This framework is under active development as part of the **info-tech-io** educational platform ecosystem.

## 🤝 Contributing

We welcome contributions! This project aims to become the definitive scaffolding framework for the Hugo ecosystem.

### Quick Contribution Guide
1. **Fork** the repository
2. **Create** a feature branch from `epic/build-system-v2.0`
3. **Follow** our [Contributing Guidelines](docs/developer-docs/contributing.md)
4. **Submit** a Pull Request

### Development Workflow
- **Epic Issues**: Large features tracked as Epics
- **Child Issues**: Individual features within Epics
- **Feature Branches**: Development branches for each Child Issue
- **Epic Integration**: All features merge to Epic branch before main

## 🎉 Success Stories

> *"Hugo Template Factory reduced our site setup time from hours to minutes while maintaining full customization capabilities."* - Educational Platform Team

> *"The component system allowed us to create standardized, reusable building blocks across multiple projects."* - Enterprise Development Team

## 📄 License

**Apache License 2.0** - see [LICENSE](LICENSE) file for details.

This project is licensed under Apache 2.0 in accordance with info-tech-io organization licensing policy.

## 🔗 Links

- **[Hugo Framework](https://gohugo.io/)** - Static site generator
- **[info-tech-io Organization](https://github.com/info-tech-io)** - Open source projects
- **[INFOTEKA Platform](https://infotecha.ru)** - Educational platform
- **[Project Issues](https://github.com/info-tech-io/hugo-templates/issues)** - Bug reports and feature requests
- **[Discussions](https://github.com/info-tech-io/hugo-templates/discussions)** - Community discussions

---

<div align="center">

**Built with ❤️ by the info-tech-io team**

[⭐ Star this project](https://github.com/info-tech-io/hugo-templates) • [🐛 Report Bug](https://github.com/info-tech-io/hugo-templates/issues) • [💡 Request Feature](https://github.com/info-tech-io/hugo-templates/issues/new?template=feature_request.md)

</div>