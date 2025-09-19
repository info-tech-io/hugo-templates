#!/usr/bin/env node

/**
 * Hugo Template Factory Framework - Generate Utility
 * Generates new templates, components, and configuration files
 */

const fs = require('fs-extra');
const path = require('path');
const yaml = require('yaml');
const chalk = require('chalk');
const inquirer = require('inquirer');

/**
 * Generate a new template
 * @param {string} templateName - Name of the new template
 * @param {Object} options - Generation options
 */
async function generateTemplate(templateName, options = {}) {
    const projectRoot = options.projectRoot || path.join(__dirname, '..');
    const templatesDir = path.join(projectRoot, 'templates');
    const templatePath = path.join(templatesDir, templateName);

    console.log(chalk.blue(`🏗️  Generating template: ${templateName}`));
    console.log(chalk.gray('━'.repeat(50)));

    // Check if template already exists
    if (fs.existsSync(templatePath)) {
        if (!options.force) {
            console.log(chalk.red(`❌ Template '${templateName}' already exists`));
            console.log(chalk.gray(`   Use --force to overwrite`));
            return false;
        } else {
            console.log(chalk.yellow(`⚠️  Overwriting existing template: ${templateName}`));
        }
    }

    // Create template directory
    await fs.ensureDir(templatePath);

    // Generate base template configuration
    const templateConfig = await generateTemplateConfig(templateName, options);

    // Create components.yml
    const componentsYmlPath = path.join(templatePath, 'components.yml');
    await fs.writeFile(componentsYmlPath, yaml.stringify(templateConfig, null, 2));
    console.log(chalk.green(`✅ Created: components.yml`));

    // Create hugo.toml
    const hugoConfig = generateHugoConfig(templateName, options);
    const hugoConfigPath = path.join(templatePath, 'hugo.toml');
    await fs.writeFile(hugoConfigPath, hugoConfig);
    console.log(chalk.green(`✅ Created: hugo.toml`));

    // Create template.json (metadata)
    const templateMetadata = generateTemplateMetadata(templateName, options);
    const templateJsonPath = path.join(templatePath, 'template.json');
    await fs.writeFile(templateJsonPath, JSON.stringify(templateMetadata, null, 2));
    console.log(chalk.green(`✅ Created: template.json`));

    // Create directory structure
    const directories = ['content', 'static', 'archetypes'];
    for (const dir of directories) {
        const dirPath = path.join(templatePath, dir);
        await fs.ensureDir(dirPath);

        // Create basic files
        if (dir === 'content') {
            await generateContentStructure(dirPath, options);
        } else if (dir === 'archetypes') {
            await generateArchetypes(dirPath, options);
        }

        console.log(chalk.green(`✅ Created directory: ${dir}/`));
    }

    // Copy files from base template if specified
    if (options.basedOn) {
        await copyFromBaseTemplate(templatePath, options.basedOn, projectRoot);
    }

    console.log('');
    console.log(chalk.green(`🎉 Template '${templateName}' generated successfully!`));
    console.log(chalk.blue(`   Location: ${templatePath}`));
    console.log(chalk.gray(`   Next steps:`));
    console.log(chalk.gray(`   1. Edit components.yml to configure components`));
    console.log(chalk.gray(`   2. Add content to content/ directory`));
    console.log(chalk.gray(`   3. Customize hugo.toml configuration`));

    return true;
}

/**
 * Generate a new component configuration
 * @param {string} componentName - Name of the component
 * @param {Object} options - Generation options
 */
async function generateComponent(componentName, options = {}) {
    console.log(chalk.blue(`📦 Generating component: ${componentName}`));
    console.log(chalk.gray('━'.repeat(50)));

    const component = {
        version: options.version || "^1.0.0",
        status: options.status || "experimental",
        description: options.description || `${componentName} component`,
        repository: options.repository || null,
        submodule_path: options.submodule ? `components/${componentName}` : null,
        static_files: options.staticFiles || [],
        layouts: options.layouts || [],
        configuration: options.configuration || {}
    };

    // Remove null values
    Object.keys(component).forEach(key => {
        if (component[key] === null || (Array.isArray(component[key]) && component[key].length === 0)) {
            delete component[key];
        }
    });

    if (options.format === 'yaml') {
        console.log(yaml.stringify({ [componentName]: component }, null, 2));
    } else {
        console.log(JSON.stringify({ [componentName]: component }, null, 2));
    }

    return component;
}

/**
 * Generate template configuration
 * @param {string} templateName - Template name
 * @param {Object} options - Options
 */
async function generateTemplateConfig(templateName, options) {
    const config = {
        template: {
            name: templateName,
            version: "1.0.0",
            description: options.description || `${templateName} template for Hugo Template Factory`,
            author: options.author || "info-tech-io",
            license: "MIT"
        },
        components: {},
        hugo: {
            minVersion: "0.110.0",
            extended: false
        },
        build: {
            writeStats: true,
            noJSConfigInAssets: false,
            useResourceCacheWhen: "fallback"
        }
    };

    // Add default components based on template type
    if (options.includeTheme !== false) {
        config.components['compose-theme'] = {
            version: "^4.0.0",
            status: "stable",
            description: "Clean and modern Hugo theme",
            repository: "https://github.com/onweru/compose.git",
            submodule_path: "themes/compose",
            configuration: {
                theme: "compose"
            }
        };
    }

    // Add components based on template type
    switch (options.type) {
        case 'educational':
            config.components['quiz-engine'] = {
                version: "^1.0.0",
                status: "stable",
                description: "Interactive quiz system for educational content",
                repository: "https://github.com/info-tech-io/quiz.git",
                submodule_path: "components/quiz-engine",
                static_files: ["quiz/", "js/quiz.js", "css/quiz.css"]
            };
            break;

        case 'academic':
            config.components['citations'] = {
                version: "^0.1.0",
                status: "planned",
                description: "Academic citation system",
                static_files: ["js/citations.js", "css/citations.css"],
                layouts: ["shortcodes/cite.html", "partials/citations/"]
            };
            break;

        case 'enterprise':
            config.components['analytics'] = {
                version: "^0.1.0",
                status: "planned",
                description: "Analytics tracking component",
                static_files: ["js/analytics.js"],
                layouts: ["partials/analytics.html"]
            };
            config.components['auth'] = {
                version: "^0.1.0",
                status: "planned",
                description: "Authentication system component",
                static_files: ["js/auth.js", "css/auth.css"],
                layouts: ["shortcodes/login.html", "partials/auth/"]
            };
            break;
    }

    return config;
}

/**
 * Generate Hugo configuration
 * @param {string} templateName - Template name
 * @param {Object} options - Options
 */
function generateHugoConfig(templateName, options) {
    const baseURL = options.baseURL || 'http://localhost:1313';
    const theme = options.theme || 'compose';
    const title = options.title || `${templateName.charAt(0).toUpperCase() + templateName.slice(1)} Site`;

    return `# Hugo Template Factory Framework - ${templateName} Template Configuration

baseURL = '${baseURL}'
languageCode = 'en-us'
title = '${title}'
theme = '${theme}'

# Pagination
paginate = 10
paginatePath = "page"

# Menu configuration
[menu]
  [[menu.main]]
    name = "Home"
    url = "/"
    weight = 1

  [[menu.main]]
    name = "About"
    url = "/about/"
    weight = 2

# Theme parameters
[params]
  description = "Site built with Hugo Template Factory Framework"
  author = "${options.author || 'Site Author'}"

  # Logo and favicon
  logo = "logo.png"
  favicon = "favicon.ico"

  # Social links
  [params.social]
    github = "${options.github || ''}"
    twitter = "${options.twitter || ''}"

# Markup configuration
[markup]
  [markup.goldmark]
    [markup.goldmark.renderer]
      unsafe = true
  [markup.highlight]
    style = "github"
    lineNos = true

# Output formats
[outputs]
  home = ["HTML", "RSS", "JSON"]
  page = ["HTML"]
  section = ["HTML", "RSS"]

# Privacy configuration
[privacy]
  [privacy.googleAnalytics]
    disable = true
  [privacy.twitter]
    disable = true
  [privacy.youtube]
    disable = true
`;
}

/**
 * Generate template metadata
 * @param {string} templateName - Template name
 * @param {Object} options - Options
 */
function generateTemplateMetadata(templateName, options) {
    return {
        "$schema": "https://schemas.hugo-templates.org/template.json",
        "name": templateName,
        "version": "1.0.0",
        "description": options.description || `${templateName} template for Hugo Template Factory`,
        "author": options.author || "info-tech-io",
        "license": "MIT",
        "homepage": options.homepage || "",
        "repository": options.repository || "",
        "tags": options.tags || [templateName],
        "categories": options.categories || ["general"],
        "requirements": {
            "hugo": ">=0.110.0",
            "node": ">=16.0.0"
        },
        "features": options.features || [
            "Hugo Template Factory Framework",
            "Responsive design",
            "Modern CSS",
            "Fast build times"
        ],
        "demo": options.demo || "",
        "screenshots": options.screenshots || [],
        "created": new Date().toISOString(),
        "updated": new Date().toISOString()
    };
}

/**
 * Generate content structure
 * @param {string} contentPath - Path to content directory
 * @param {Object} options - Options
 */
async function generateContentStructure(contentPath, options) {
    // Create _index.md for the home page
    const indexContent = `---
title: "Welcome"
description: "Welcome to your new Hugo site"
date: ${new Date().toISOString()}
draft: false
---

# Welcome to Your New Site

This site was generated using the Hugo Template Factory Framework.

## Getting Started

1. Add your content to the \`content/\` directory
2. Customize the theme in your \`hugo.toml\` file
3. Build your site with Hugo

## Features

- Fast static site generation
- Modern responsive design
- Easy content management
- Extensible component system

Enjoy building your site!
`;

    await fs.writeFile(path.join(contentPath, '_index.md'), indexContent);

    // Create about page
    const aboutContent = `---
title: "About"
description: "About this site"
date: ${new Date().toISOString()}
draft: false
---

# About

This is the about page for your Hugo site.

Add information about yourself, your organization, or your project here.
`;

    await fs.writeFile(path.join(contentPath, 'about.md'), aboutContent);

    // Create posts directory if needed
    if (options.includeBlog !== false) {
        const postsDir = path.join(contentPath, 'posts');
        await fs.ensureDir(postsDir);

        const firstPost = `---
title: "First Post"
description: "Your first blog post"
date: ${new Date().toISOString()}
draft: true
tags: ["hello", "first-post"]
categories: ["blog"]
---

# Welcome to Your First Post

This is your first blog post. Edit this file to add your own content.

## Markdown Support

You can use all standard Markdown features:

- **Bold text**
- *Italic text*
- [Links](https://gohugo.io)
- \`Inline code\`

\`\`\`javascript
// Code blocks
console.log("Hello, world!");
\`\`\`

## Images

Add images to your \`static/\` directory and reference them like this:

![Example](/images/example.jpg)

Happy blogging!
`;

        await fs.writeFile(path.join(postsDir, 'first-post.md'), firstPost);
    }
}

/**
 * Generate archetypes
 * @param {string} archetypesPath - Path to archetypes directory
 * @param {Object} options - Options
 */
async function generateArchetypes(archetypesPath, options) {
    // Default archetype
    const defaultArchetype = `---
title: "{{ replace .Name "-" " " | title }}"
description: ""
date: {{ .Date }}
draft: true
tags: []
categories: []
---

`;

    await fs.writeFile(path.join(archetypesPath, 'default.md'), defaultArchetype);

    // Post archetype if blog is enabled
    if (options.includeBlog !== false) {
        const postArchetype = `---
title: "{{ replace .Name "-" " " | title }}"
description: ""
date: {{ .Date }}
draft: true
tags: []
categories: ["blog"]
author: ""
---

`;

        await fs.writeFile(path.join(archetypesPath, 'posts.md'), postArchetype);
    }
}

/**
 * Copy files from base template
 * @param {string} targetPath - Target template path
 * @param {string} baseName - Base template name
 * @param {string} projectRoot - Project root
 */
async function copyFromBaseTemplate(targetPath, baseName, projectRoot) {
    const basePath = path.join(projectRoot, 'templates', baseName);

    if (!fs.existsSync(basePath)) {
        console.log(chalk.yellow(`⚠️  Base template '${baseName}' not found, skipping copy`));
        return;
    }

    console.log(chalk.blue(`📋 Copying files from base template: ${baseName}`));

    // Copy content and static directories
    const dirsToCopy = ['content', 'static'];

    for (const dir of dirsToCopy) {
        const sourceDir = path.join(basePath, dir);
        const targetDir = path.join(targetPath, dir);

        if (fs.existsSync(sourceDir)) {
            await fs.copy(sourceDir, targetDir, { overwrite: false });
            console.log(chalk.green(`✅ Copied: ${dir}/ from ${baseName}`));
        }
    }
}

/**
 * Interactive template generation
 */
async function interactiveGenerate() {
    console.log(chalk.blue('🎯 Interactive Template Generator'));
    console.log(chalk.gray('━'.repeat(50)));

    const answers = await inquirer.prompt([
        {
            type: 'input',
            name: 'templateName',
            message: 'Template name:',
            validate: (input) => {
                if (!input) return 'Template name is required';
                if (!/^[a-z0-9-]+$/.test(input)) return 'Template name must be lowercase letters, numbers, and hyphens only';
                return true;
            }
        },
        {
            type: 'input',
            name: 'description',
            message: 'Template description:',
            default: (answers) => `${answers.templateName} template for Hugo Template Factory`
        },
        {
            type: 'list',
            name: 'type',
            message: 'Template type:',
            choices: [
                { name: 'General purpose', value: 'general' },
                { name: 'Educational (includes Quiz Engine)', value: 'educational' },
                { name: 'Academic (includes citations)', value: 'academic' },
                { name: 'Enterprise (includes analytics)', value: 'enterprise' },
                { name: 'Minimal (basic features only)', value: 'minimal' }
            ]
        },
        {
            type: 'input',
            name: 'author',
            message: 'Author:',
            default: 'info-tech-io'
        },
        {
            type: 'confirm',
            name: 'includeBlog',
            message: 'Include blog functionality?',
            default: true
        },
        {
            type: 'list',
            name: 'basedOn',
            message: 'Base on existing template?',
            choices: [
                { name: 'None (create from scratch)', value: null },
                { name: 'default', value: 'default' },
                { name: 'minimal', value: 'minimal' }
            ]
        }
    ]);

    return generateTemplate(answers.templateName, answers);
}

// Command-line interface
if (require.main === module) {
    const args = process.argv.slice(2);

    if (args.length === 0 || args[0] === '--help') {
        console.log(`
Usage: node generate.js <command> [options]

Commands:
    template <name>     Generate a new template
    component <name>    Generate component configuration
    interactive         Interactive template generator

Template Options:
    --description <text>    Template description
    --type <type>          Template type (general, educational, academic, enterprise, minimal)
    --author <name>        Author name
    --based-on <template>  Base on existing template
    --force                Overwrite existing template

Component Options:
    --version <version>    Component version
    --status <status>      Component status (stable, experimental, planned)
    --description <text>   Component description
    --format <format>      Output format (json, yaml)

Examples:
    node generate.js template my-blog --type educational
    node generate.js component analytics --status stable
    node generate.js interactive
`);
        process.exit(0);
    }

    const command = args[0];
    const name = args[1];

    const options = {};

    // Parse options
    for (let i = 2; i < args.length; i += 2) {
        const key = args[i];
        const value = args[i + 1];

        if (key === '--description') options.description = value;
        else if (key === '--type') options.type = value;
        else if (key === '--author') options.author = value;
        else if (key === '--based-on') options.basedOn = value;
        else if (key === '--force') { options.force = true; i--; }
        else if (key === '--version') options.version = value;
        else if (key === '--status') options.status = value;
        else if (key === '--format') options.format = value;
    }

    async function runCommand() {
        try {
            switch (command) {
                case 'template':
                    if (!name) {
                        console.log(chalk.red('❌ Template name is required'));
                        process.exit(1);
                    }
                    await generateTemplate(name, options);
                    break;

                case 'component':
                    if (!name) {
                        console.log(chalk.red('❌ Component name is required'));
                        process.exit(1);
                    }
                    await generateComponent(name, options);
                    break;

                case 'interactive':
                    await interactiveGenerate();
                    break;

                default:
                    console.log(chalk.red(`❌ Unknown command: ${command}`));
                    process.exit(1);
            }
        } catch (error) {
            console.error(chalk.red('❌ Generate command failed:'), error.message);
            process.exit(1);
        }
    }

    runCommand();
}

module.exports = {
    generateTemplate,
    generateComponent,
    interactiveGenerate
};