---
title: "Configuration"
description: "Complete reference for module.json configuration in Hugo Templates Framework"
weight: 32
---

# Configuration Reference

Hugo Templates Framework uses `module.json` files to configure site generation. These files control template behavior, component integration, and Hugo settings. This reference covers all available configuration options.

## Basic Structure

Every `module.json` file follows this basic structure:

```json
{
  "template": "template-name",
  "config": {
    "template-specific": "options"
  },
  "hugo": {
    "baseURL": "https://example.com",
    "title": "Site Title"
  },
  "theme": "theme-name",
  "components": ["component-list"],
  "build": {
    "environment": "production",
    "minify": true
  }
}
```

## Root-Level Properties

### template
**Type:** `string`
**Required:** Yes
**Description:** Specifies which template to use

**Valid values:**
- `"educational"` - For learning platforms and courses
- `"corporate"` - For business and organization websites
- `"documentation"` - For technical documentation sites

**Example:**
```json
{
  "template": "documentation"
}
```

### config
**Type:** `object`
**Description:** Template-specific configuration options

Each template accepts different configuration options. See [Template-Specific Configuration](#template-specific-configuration) below.

### hugo
**Type:** `object`
**Description:** Hugo configuration that will be merged into `hugo.toml`

**Common properties:**
```json
{
  "hugo": {
    "baseURL": "https://docs.example.com",
    "title": "My Documentation",
    "languageCode": "en-us",
    "defaultContentLanguage": "en",
    "enableRobotsTXT": true,
    "enableGitInfo": true
  }
}
```

### theme
**Type:** `string`
**Default:** `"compose"`
**Description:** Hugo theme to apply

**Available themes:**
- `"compose"` - Modern, clean design
- `"minimal"` - Lightweight and fast
- `"dark"` - Dark mode optimized

**Example:**
```json
{
  "theme": "minimal"
}
```

### components
**Type:** `array[string]`
**Description:** List of components to include

**Available components:**
- `"quiz-engine"` - Interactive testing system
- `"analytics"` - Google Analytics integration
- `"search"` - Site-wide search functionality
- `"contact-form"` - Contact form integration
- `"syntax-highlighting"` - Code syntax highlighting

**Example:**
```json
{
  "components": ["search", "analytics", "syntax-highlighting"]
}
```

### build
**Type:** `object`
**Description:** Build-specific configuration

**Properties:**
```json
{
  "build": {
    "environment": "production",
    "minify": true,
    "draft": false,
    "future": false
  }
}
```

## Template-Specific Configuration

### Educational Template

```json
{
  "template": "educational",
  "config": {
    "enableQuizEngine": true,
    "showProgress": true,
    "allowComments": false,
    "trackingEnabled": true,
    "courseStructure": {
      "modules": true,
      "lessons": true,
      "assessments": true
    },
    "navigation": {
      "showPrevNext": true,
      "showModuleOverview": true
    },
    "i18n": {
      "defaultLanguage": "en",
      "supportedLanguages": ["en", "ru"]
    }
  }
}
```

#### Educational Configuration Options

**enableQuizEngine** (`boolean`, default: `true`)
- Enables Quiz Engine integration for interactive tests

**showProgress** (`boolean`, default: `true`)
- Shows learning progress indicators

**allowComments** (`boolean`, default: `false`)
- Enables commenting system for lessons

**trackingEnabled** (`boolean`, default: `true`)
- Enables learning analytics and progress tracking

**courseStructure** (`object`)
- Controls course organization features

**navigation** (`object`)
- Configures navigation elements

**i18n** (`object`)
- Internationalization settings

### Corporate Template

```json
{
  "template": "corporate",
  "config": {
    "enableBlog": true,
    "enableSearch": true,
    "showSocial": true,
    "contactForm": true,
    "seo": {
      "enableStructuredData": true,
      "enableOpenGraph": true,
      "enableTwitterCards": true
    },
    "homepage": {
      "showHero": true,
      "showProducts": true,
      "showTestimonials": true
    },
    "social": {
      "twitter": "@company",
      "linkedin": "company-name",
      "github": "company-org"
    }
  }
}
```

#### Corporate Configuration Options

**enableBlog** (`boolean`, default: `true`)
- Enables blog functionality

**enableSearch** (`boolean`, default: `true`)
- Enables site-wide search

**showSocial** (`boolean`, default: `true`)
- Shows social media links

**contactForm** (`boolean`, default: `true`)
- Enables contact form

**seo** (`object`)
- SEO optimization settings

**homepage** (`object`)
- Homepage section configuration

**social** (`object`)
- Social media account information

### Documentation Template

```json
{
  "template": "documentation",
  "config": {
    "enableSearch": true,
    "syntaxHighlighting": true,
    "showEditLinks": true,
    "enableComments": false,
    "navigation": {
      "showTOC": true,
      "maxTOCDepth": 3,
      "showBreadcrumbs": true
    },
    "code": {
      "lineNumbers": true,
      "copyButton": true,
      "theme": "github"
    },
    "versioning": {
      "enabled": false,
      "currentVersion": "1.0"
    }
  }
}
```

#### Documentation Configuration Options

**enableSearch** (`boolean`, default: `true`)
- Enables documentation search

**syntaxHighlighting** (`boolean`, default: `true`)
- Enables code syntax highlighting

**showEditLinks** (`boolean`, default: `true`)
- Shows "Edit this page" links

**enableComments** (`boolean`, default: `false`)
- Enables commenting on documentation pages

**navigation** (`object`)
- Navigation and table of contents settings

**code** (`object`)
- Code block appearance and functionality

**versioning** (`object`)
- Documentation versioning configuration

## Component Configuration

Components can be configured through the `components` section:

```json
{
  "components": ["analytics", "search", "quiz-engine"],
  "componentConfig": {
    "analytics": {
      "googleAnalyticsID": "GA-XXXXXXXXX",
      "trackOutboundLinks": true
    },
    "search": {
      "engine": "fuse",
      "includeContent": true,
      "threshold": 0.3
    },
    "quiz-engine": {
      "theme": "default",
      "showExplanations": "all",
      "allowRetries": true
    }
  }
}
```

### Analytics Component
```json
{
  "componentConfig": {
    "analytics": {
      "googleAnalyticsID": "GA-XXXXXXXXX",
      "trackOutboundLinks": true,
      "anonymizeIP": true,
      "respectDoNotTrack": true
    }
  }
}
```

### Search Component
```json
{
  "componentConfig": {
    "search": {
      "engine": "fuse",
      "includeContent": true,
      "threshold": 0.3,
      "maxResults": 10,
      "placeholder": "Search documentation..."
    }
  }
}
```

### Quiz Engine Component
```json
{
  "componentConfig": {
    "quiz-engine": {
      "theme": "default",
      "showExplanations": "all",
      "allowRetries": true,
      "timeLimit": null,
      "randomizeAnswers": false
    }
  }
}
```

## Hugo Configuration Integration

The `hugo` section gets merged into the generated `hugo.toml` file:

```json
{
  "hugo": {
    "baseURL": "https://example.com",
    "title": "My Site",
    "languageCode": "en-us",
    "defaultContentLanguage": "en",
    "enableRobotsTXT": true,
    "enableGitInfo": true,
    "params": {
      "description": "Site description",
      "author": "Author Name",
      "logo": "/images/logo.png"
    },
    "menu": {
      "main": [
        {
          "name": "Home",
          "url": "/",
          "weight": 10
        },
        {
          "name": "About",
          "url": "/about/",
          "weight": 20
        }
      ]
    }
  }
}
```

## Environment-Specific Configuration

You can provide different configurations for different environments:

```json
{
  "template": "corporate",
  "environments": {
    "development": {
      "hugo": {
        "baseURL": "http://localhost:1313"
      },
      "build": {
        "minify": false,
        "draft": true
      }
    },
    "production": {
      "hugo": {
        "baseURL": "https://company.com"
      },
      "build": {
        "minify": true,
        "draft": false
      },
      "components": ["analytics"]
    }
  }
}
```

## Configuration Validation

Hugo Templates Framework validates configurations using JSON Schema. Common validation errors:

### Invalid Template Name
```json
{
  "template": "invalid-template"  // ❌ Not a valid template
}
```
**Fix:** Use `"educational"`, `"corporate"`, or `"documentation"`

### Missing Required Properties
```json
{
  "config": {}  // ❌ Missing template property
}
```
**Fix:** Always include `"template"` property

### Invalid Component Names
```json
{
  "components": ["invalid-component"]  // ❌ Component doesn't exist
}
```
**Fix:** Use valid component names from the documentation

## Complete Examples

### Educational Platform
```json
{
  "template": "educational",
  "config": {
    "enableQuizEngine": true,
    "showProgress": true,
    "courseStructure": {
      "modules": true,
      "lessons": true,
      "assessments": true
    }
  },
  "hugo": {
    "baseURL": "https://learn.example.com",
    "title": "Learning Platform",
    "params": {
      "description": "Interactive learning platform"
    }
  },
  "theme": "compose",
  "components": ["quiz-engine", "analytics"],
  "componentConfig": {
    "analytics": {
      "googleAnalyticsID": "GA-XXXXXXXXX"
    }
  }
}
```

### Corporate Website
```json
{
  "template": "corporate",
  "config": {
    "enableBlog": true,
    "enableSearch": true,
    "seo": {
      "enableStructuredData": true,
      "enableOpenGraph": true
    },
    "social": {
      "twitter": "@company",
      "linkedin": "company-name"
    }
  },
  "hugo": {
    "baseURL": "https://company.com",
    "title": "Company Name",
    "params": {
      "description": "Leading provider of solutions"
    }
  },
  "components": ["search", "analytics", "contact-form"],
  "build": {
    "environment": "production",
    "minify": true
  }
}
```

### Documentation Site
```json
{
  "template": "documentation",
  "config": {
    "enableSearch": true,
    "syntaxHighlighting": true,
    "showEditLinks": true,
    "navigation": {
      "showTOC": true,
      "maxTOCDepth": 3
    }
  },
  "hugo": {
    "baseURL": "https://docs.example.com",
    "title": "Documentation",
    "params": {
      "edit_page": true,
      "repo_url": "https://github.com/user/repo"
    }
  },
  "components": ["search", "syntax-highlighting"],
  "theme": "compose"
}
```

## Migration Guide

### From Legacy Configuration
If you have existing configurations, migrate them step by step:

1. **Update template names** - Ensure template names match current options
2. **Move Hugo config** - Move Hugo settings to `hugo` section
3. **Update component names** - Check component names against current list
4. **Add required fields** - Ensure all required properties are present

### Version Compatibility
- **v1.0+** - All configurations in this reference
- **v0.x** - Legacy format, migration required

---

**Next:** Learn about [Themes](/hugo/user-guide/themes/) to understand styling and customization options.