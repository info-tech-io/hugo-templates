# Hugo Template Factory Framework

> The first parametrized scaffolding tool for Hugo - bringing Angular Schematics-like functionality to static site generation

## 🚀 Quick Start

```bash
# Install globally
npm install -g hugo-templates

# Create a site with default template and compose theme
hugo-templates build --template=default --theme=compose

# Create a minimal site for faster builds
hugo-templates build --template=minimal --theme=compose

# Add Quiz Engine component
hugo-templates build --template=default --theme=compose --components=quiz-engine
```

## 🎯 Why Hugo Template Factory?

Hugo Template Factory solves the **scaffolding gap** in Hugo ecosystem by providing:

- **Parametrized generation** like Angular Schematics
- **Component modularity** without Go Modules complexity
- **Educational focus** with Quiz Engine integration
- **Script-based simplicity** accessible to non-Go developers

## 🏗️ Architecture

```
hugo-templates/
├── templates/          # Build templates
│   ├── default/       # Full-featured (≈ hugo-base)
│   ├── minimal/       # Lightweight for fast builds
│   ├── academic/      # Academic + references
│   └── enterprise/    # Corporate + analytics
├── themes/            # Hugo themes (git submodules)
├── components/        # Modular components
└── schemas/           # JSON Schema validation
```

## 📦 Templates

- **default**: Full-featured template with all components
- **minimal**: Lightweight template for fast builds
- **academic**: Academic template with citations and references
- **enterprise**: Corporate template with analytics

## 🧩 Components

- **quiz-engine**: Interactive quiz system for educational content
- **analytics**: Analytics tracking (planned)
- **auth**: Authentication system (planned)
- **citations**: Citation system for academic content (planned)

## 🔧 Development Status

**Current Version**: 0.1.0-alpha.1

This is an alpha release. The framework is under active development as part of the info-tech-io educational platform project.

## 📚 Documentation

- [Usage Guide](docs/USAGE.md)
- [Templates Reference](docs/TEMPLATES.md)
- [Components Guide](docs/COMPONENTS.md)
- [Contributing](docs/CONTRIBUTING.md)

## 🤝 Contributing

We welcome contributions! This project aims to become the first comprehensive scaffolding framework for Hugo ecosystem.

## 📄 License

MIT License - see LICENSE file for details.

## 🔗 Links

- [Hugo](https://gohugo.io/)
- [info-tech-io Organization](https://github.com/info-tech-io)
- [INFOTEKA Platform](https://infotecha.ru)