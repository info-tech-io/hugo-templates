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

# Production build with optimization
./scripts/build.sh --template=enterprise --environment=production --minify --base-url=https://example.com
```

## 🎯 Why Hugo Template Factory?

Hugo Template Factory solves the **scaffolding gap** in Hugo ecosystem by providing:

- **🎯 Parametrized Generation**: Angular Schematics-like functionality for Hugo
- **🧩 Component Modularity**: Reusable components without Go Modules complexity
- **🎓 Educational Focus**: Built-in Quiz Engine and learning-oriented features
- **🔧 Script-Based Simplicity**: Accessible to non-Go developers with Bash/Node.js
- **⚡ Performance Optimized**: Smart caching and optimized CI/CD workflows
- **🛡️ Enterprise Ready**: Error handling, monitoring, and production features

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
│   ├── build.sh          # Main build script with error handling
│   ├── validate.js       # Configuration validation
│   └── diagnostic.js     # System diagnostics & troubleshooting
└── docs/                 # Comprehensive documentation
    ├── user-guides/      # User documentation
    ├── developer-docs/   # Developer guides
    ├── troubleshooting/  # Problem resolution guides
    └── api-reference/    # API documentation
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
- **[Getting Started](docs/tutorials/getting-started.md)** - Step-by-step tutorial
- **[Template Usage](docs/user-guides/templates.md)** - Working with templates
- **[Deployment Guide](docs/user-guides/deployment.md)** - Production deployment

### 🛠️ Developer Documentation
- **[Component Development](docs/developer-docs/components.md)** - Creating custom components
- **[GitHub Actions Guide](docs/developer-docs/github-actions.md)** - CI/CD workflows and optimization
- **[API Reference](docs/api-reference/)** - Complete API documentation
- **[Contributing Guide](docs/developer-docs/contributing.md)** - Contribution guidelines

### 🚨 Troubleshooting
- **[Common Issues](docs/troubleshooting/common-issues.md)** - Problem resolution guide
- **[Error Reference](docs/troubleshooting/error-reference.md)** - Error codes and solutions
- **[Performance Guide](docs/troubleshooting/performance.md)** - Optimization techniques

### 📖 Tutorials
- **[First Site Tutorial](docs/tutorials/first-site.md)** - Create your first site
- **[Educational Platform](docs/tutorials/educational-platform.md)** - Build a learning platform
- **[Corporate Website](docs/tutorials/corporate-website.md)** - Business website setup
- **[Academic Site](docs/tutorials/academic-site.md)** - Research publication site

## 🎯 Development Status

**Current Version**: `0.2.0-beta.1` - **Build System v2.0**

### ✅ Completed Features (Epic Status: 60%)
- **✅ Error Handling System** - Comprehensive error handling and diagnostics
- **✅ Test Coverage Framework** - BATS testing with 95%+ coverage
- **✅ GitHub Actions Optimization** - 50%+ performance improvement in CI/CD

### 🚧 In Development
- **🚧 Documentation Updates** - Comprehensive guides and troubleshooting
- **📋 Performance Monitoring** - Advanced monitoring and alerting

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