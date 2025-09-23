---
title: "Getting Started"
description: "Learn how to use Hugo Templates Framework to build professional Hugo sites quickly"
weight: 10
---

# Getting Started with Hugo Templates Framework

Hugo Templates Framework is designed to help developers rapidly create professional Hugo static sites using a factory-based approach. Instead of starting from scratch each time, you can use our pre-built templates, themes, and components to build sites efficiently.

## What is Hugo Templates Framework?

Hugo Templates Framework is a **parametrized scaffolding system** that:

- 🏗️ **Generates Hugo sites** based on predefined templates
- ⚙️ **Uses JSON configuration** to customize each site
- 🎨 **Applies themes and components** automatically
- 📋 **Validates configurations** to prevent errors
- 🚀 **Integrates with CI/CD** for automatic deployment

## Prerequisites

Before using Hugo Templates Framework, ensure you have:

- **Hugo Extended** version 0.110.0 or higher
- **Node.js** 16+ (for advanced features and validation)
- **Git** for version control
- Basic understanding of **Markdown** and **YAML**

### Installing Hugo

```bash
# macOS (using Homebrew)
brew install hugo

# Linux (using snap)
sudo snap install hugo

# Windows (using Chocolatey)
choco install hugo-extended

# Verify installation
hugo version
```

## Quick Start (5 Minutes)

### 1. Clone Hugo Templates Framework

```bash
git clone https://github.com/info-tech-io/hugo-templates.git
cd hugo-templates
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Generate Your First Site

```bash
# Create a documentation site
./scripts/build.sh \
  --template documentation \
  --content example-content \
  --base-url "http://localhost:1313" \
  --output my-docs-site

# Create a corporate site
./scripts/build.sh \
  --template corporate \
  --base-url "https://mycompany.com" \
  --output my-company-site
```

### 4. Preview Your Site

```bash
cd my-docs-site
hugo server

# Open http://localhost:1313 in your browser
```

## Understanding the Build Process

When you run a build command, Hugo Templates Framework:

1. **Validates** your parameters and configuration
2. **Copies** the selected template files
3. **Applies** the specified theme
4. **Includes** requested components
5. **Generates** the Hugo configuration
6. **Builds** the final static site

## Key Concepts

### Templates
Templates define the **structure and organization** of your site:
- `educational` - For courses and learning content
- `corporate` - For business and organization websites
- `documentation` - For technical documentation

### Themes
Themes control the **visual appearance**:
- `compose` - Modern, clean design (default)
- `minimal` - Lightweight and fast
- `dark` - Dark mode optimized

### Components
Components add **functionality**:
- `quiz-engine` - Interactive testing system
- `analytics` - Google Analytics integration
- `search` - Site-wide content search

### Configuration
Configuration is managed through:
- **Command-line parameters** for build settings
- **module.json files** for content-specific options
- **Hugo config files** for Hugo-specific settings

## Next Steps

Now that you understand the basics:

1. **[Explore Templates](/hugo/templates/)** - Learn about each template type
2. **[Configuration Guide](/hugo/user-guide/configuration/)** - Master the configuration system
3. **[Build Scripts](/hugo/user-guide/build-scripts/)** - Learn all build options
4. **[Examples](/hugo/examples/)** - See real-world implementations

## Common Use Cases

### Creating Documentation Sites
Perfect for API docs, user guides, and technical documentation:

```bash
./scripts/build.sh \
  --template documentation \
  --content docs/content \
  --base-url "https://docs.myproject.com" \
  --output docs-site
```

### Building Corporate Websites
Ideal for company sites, product showcases, and blogs:

```bash
./scripts/build.sh \
  --template corporate \
  --theme compose \
  --components analytics \
  --base-url "https://mycompany.com" \
  --output company-site
```

### Educational Platforms
Great for courses, tutorials, and learning materials:

```bash
./scripts/build.sh \
  --template educational \
  --components quiz-engine \
  --content course-content \
  --base-url "https://learn.mysite.com" \
  --output learning-site
```

## Getting Help

If you run into issues:

- 📖 **Check our [FAQ](/hugo/faq/)**
- 🐛 **Report bugs** on [GitHub Issues](https://github.com/info-tech-io/hugo-templates/issues)
- 💬 **Ask questions** in [GitHub Discussions](https://github.com/info-tech-io/hugo-templates/discussions)
- 📧 **Contact us** at hugo-templates@info-tech.io

---

**Ready to dive deeper?** Continue with our [Template Guide](/hugo/templates/) to learn about each template type in detail!