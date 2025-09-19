#!/usr/bin/env node

/**
 * Hugo Template Factory Framework - List Utility
 * Lists available templates, themes, and components with detailed information
 */

const fs = require('fs-extra');
const path = require('path');
const yaml = require('yaml');
const chalk = require('chalk');

/**
 * List available templates
 * @param {Object} options - List options
 */
async function listTemplates(options = {}) {
    const projectRoot = options.projectRoot || path.join(__dirname, '..');
    const templatesDir = path.join(projectRoot, 'templates');

    if (!fs.existsSync(templatesDir)) {
        console.log(chalk.red('❌ Templates directory not found'));
        return [];
    }

    const templates = fs.readdirSync(templatesDir)
        .filter(item => fs.lstatSync(path.join(templatesDir, item)).isDirectory())
        .sort();

    if (options.format === 'json') {
        const templateData = [];
        for (const template of templates) {
            const templatePath = path.join(templatesDir, template);
            const info = await getTemplateInfo(templatePath);
            templateData.push(info);
        }
        console.log(JSON.stringify(templateData, null, 2));
        return templateData;
    }

    console.log(chalk.blue('📋 Available Templates:'));
    console.log(chalk.gray('━'.repeat(50)));

    if (templates.length === 0) {
        console.log(chalk.yellow('   No templates found'));
        return [];
    }

    for (const template of templates) {
        const templatePath = path.join(templatesDir, template);
        const info = await getTemplateInfo(templatePath);

        // Template name with status indicator
        const statusIcon = getStatusIcon(info.status);
        console.log(chalk.white(`\n${statusIcon} ${chalk.bold(template)}`));

        // Description
        if (info.description) {
            console.log(chalk.gray(`   ${info.description}`));
        }

        // Version and author
        const metadata = [];
        if (info.version) metadata.push(`v${info.version}`);
        if (info.author) metadata.push(`by ${info.author}`);
        if (metadata.length > 0) {
            console.log(chalk.gray(`   ${metadata.join(' • ')}`));
        }

        // Components count
        if (info.componentsCount > 0) {
            console.log(chalk.cyan(`   📦 ${info.componentsCount} components`));
        }

        // Features
        if (info.features && info.features.length > 0) {
            console.log(chalk.green(`   ✨ Features: ${info.features.slice(0, 2).join(', ')}`));
            if (info.features.length > 2) {
                console.log(chalk.green(`      + ${info.features.length - 2} more...`));
            }
        }

        // Status details
        if (info.status === 'empty') {
            console.log(chalk.yellow('   ⚠️  Template is empty (placeholder only)'));
        } else if (info.status === 'incomplete') {
            console.log(chalk.yellow('   ⚠️  Template is incomplete (missing required files)'));
        }
    }

    console.log(`\n${chalk.blue('📊 Total:')} ${templates.length} templates found`);
    return templates;
}

/**
 * List available themes
 * @param {Object} options - List options
 */
async function listThemes(options = {}) {
    const projectRoot = options.projectRoot || path.join(__dirname, '..');
    const themesDir = path.join(projectRoot, 'themes');

    if (!fs.existsSync(themesDir)) {
        console.log(chalk.red('❌ Themes directory not found'));
        return [];
    }

    const themes = fs.readdirSync(themesDir)
        .filter(item => fs.lstatSync(path.join(themesDir, item)).isDirectory())
        .sort();

    if (options.format === 'json') {
        const themeData = [];
        for (const theme of themes) {
            const themePath = path.join(themesDir, theme);
            const info = await getThemeInfo(themePath);
            themeData.push(info);
        }
        console.log(JSON.stringify(themeData, null, 2));
        return themeData;
    }

    console.log(chalk.blue('🎨 Available Themes:'));
    console.log(chalk.gray('━'.repeat(50)));

    if (themes.length === 0) {
        console.log(chalk.yellow('   No themes found'));
        return [];
    }

    for (const theme of themes) {
        const themePath = path.join(themesDir, theme);
        const info = await getThemeInfo(themePath);

        console.log(chalk.white(`\n🎨 ${chalk.bold(theme)}`));

        if (info.description) {
            console.log(chalk.gray(`   ${info.description}`));
        }

        if (info.version) {
            console.log(chalk.gray(`   Version: ${info.version}`));
        }

        if (info.homepage) {
            console.log(chalk.blue(`   🔗 ${info.homepage}`));
        }

        if (info.features && info.features.length > 0) {
            console.log(chalk.green(`   ✨ ${info.features.join(', ')}`));
        }

        if (info.status === 'submodule' && !info.initialized) {
            console.log(chalk.yellow('   ⚠️  Git submodule not initialized'));
        }
    }

    console.log(`\n${chalk.blue('📊 Total:')} ${themes.length} themes found`);
    return themes;
}

/**
 * List available components
 * @param {Object} options - List options
 */
async function listComponents(options = {}) {
    const projectRoot = options.projectRoot || path.join(__dirname, '..');
    const componentsDir = path.join(projectRoot, 'components');
    const templatesDir = path.join(projectRoot, 'templates');

    // Collect components from templates
    const allComponents = new Map();

    // Scan components directory
    if (fs.existsSync(componentsDir)) {
        const components = fs.readdirSync(componentsDir)
            .filter(item => fs.lstatSync(path.join(componentsDir, item)).isDirectory());

        for (const component of components) {
            allComponents.set(component, {
                name: component,
                type: 'standalone',
                path: path.join(componentsDir, component),
                usedIn: []
            });
        }
    }

    // Scan templates for component definitions
    if (fs.existsSync(templatesDir)) {
        const templates = fs.readdirSync(templatesDir)
            .filter(item => fs.lstatSync(path.join(templatesDir, item)).isDirectory());

        for (const template of templates) {
            const componentsYml = path.join(templatesDir, template, 'components.yml');
            if (fs.existsSync(componentsYml)) {
                try {
                    const content = fs.readFileSync(componentsYml, 'utf8');
                    const config = yaml.parse(content);

                    if (config.components) {
                        for (const [componentName, componentConfig] of Object.entries(config.components)) {
                            if (!allComponents.has(componentName)) {
                                allComponents.set(componentName, {
                                    name: componentName,
                                    type: 'template-defined',
                                    config: componentConfig,
                                    usedIn: []
                                });
                            }
                            allComponents.get(componentName).usedIn.push(template);
                        }
                    }
                } catch (error) {
                    // Skip invalid YAML files
                }
            }
        }
    }

    const components = Array.from(allComponents.values()).sort((a, b) => a.name.localeCompare(b.name));

    if (options.format === 'json') {
        console.log(JSON.stringify(components, null, 2));
        return components;
    }

    console.log(chalk.blue('📦 Available Components:'));
    console.log(chalk.gray('━'.repeat(50)));

    if (components.length === 0) {
        console.log(chalk.yellow('   No components found'));
        return [];
    }

    for (const component of components) {
        const config = component.config || {};
        const statusIcon = getStatusIcon(config.status || 'unknown');

        console.log(chalk.white(`\n${statusIcon} ${chalk.bold(component.name)}`));

        if (config.description) {
            console.log(chalk.gray(`   ${config.description}`));
        }

        // Version and status
        const metadata = [];
        if (config.version) metadata.push(`v${config.version}`);
        if (config.status) metadata.push(config.status);
        if (metadata.length > 0) {
            console.log(chalk.gray(`   ${metadata.join(' • ')}`));
        }

        // Type
        if (component.type === 'standalone') {
            console.log(chalk.cyan(`   📁 Standalone component`));
        } else {
            console.log(chalk.cyan(`   📋 Template-defined component`));
        }

        // Used in templates
        if (component.usedIn.length > 0) {
            console.log(chalk.green(`   🔗 Used in: ${component.usedIn.join(', ')}`));
        }

        // Repository
        if (config.repository) {
            console.log(chalk.blue(`   🔗 ${config.repository}`));
        }

        // Files
        if (config.static_files && config.static_files.length > 0) {
            console.log(chalk.purple(`   📄 Files: ${config.static_files.slice(0, 3).join(', ')}`));
            if (config.static_files.length > 3) {
                console.log(chalk.purple(`      + ${config.static_files.length - 3} more...`));
            }
        }
    }

    console.log(`\n${chalk.blue('📊 Total:')} ${components.length} components found`);
    return components;
}

/**
 * Get template information
 * @param {string} templatePath - Path to template directory
 */
async function getTemplateInfo(templatePath) {
    const name = path.basename(templatePath);
    const info = {
        name,
        status: 'unknown',
        version: null,
        description: null,
        author: null,
        features: [],
        componentsCount: 0
    };

    // Check for required files
    const hasHugoConfig = fs.existsSync(path.join(templatePath, 'hugo.toml'));
    const hasComponents = fs.existsSync(path.join(templatePath, 'components.yml'));
    const hasContent = fs.existsSync(path.join(templatePath, 'content'));

    // Determine status
    if (!hasHugoConfig && !hasComponents && !hasContent) {
        info.status = 'empty';
    } else if (!hasHugoConfig) {
        info.status = 'incomplete';
    } else {
        info.status = 'ready';
    }

    // Read components.yml if exists
    const componentsYml = path.join(templatePath, 'components.yml');
    if (fs.existsSync(componentsYml)) {
        try {
            const content = fs.readFileSync(componentsYml, 'utf8');
            const config = yaml.parse(content);

            if (config.template) {
                info.version = config.template.version;
                info.description = config.template.description;
                info.author = config.template.author;
                info.features = config.template.features || [];
            }

            if (config.components) {
                info.componentsCount = Object.keys(config.components).length;
            }
        } catch (error) {
            // Ignore YAML parsing errors
        }
    }

    return info;
}

/**
 * Get theme information
 * @param {string} themePath - Path to theme directory
 */
async function getThemeInfo(themePath) {
    const name = path.basename(themePath);
    const info = {
        name,
        version: null,
        description: null,
        homepage: null,
        features: [],
        status: 'local',
        initialized: true
    };

    // Check if it's a git submodule
    if (fs.existsSync(path.join(themePath, '.git'))) {
        info.status = 'submodule';
        info.initialized = fs.readdirSync(themePath).length > 1; // More than just .git
    }

    // Try to read theme.toml or config.toml
    const possibleConfigs = ['theme.toml', 'config.toml', 'hugo.toml'];
    for (const configFile of possibleConfigs) {
        const configPath = path.join(themePath, configFile);
        if (fs.existsSync(configPath)) {
            try {
                const content = fs.readFileSync(configPath, 'utf8');
                // Basic TOML parsing for common fields
                const nameMatch = content.match(/name\s*=\s*["']([^"']+)["']/);
                const descMatch = content.match(/description\s*=\s*["']([^"']+)["']/);
                const homepageMatch = content.match(/homepage\s*=\s*["']([^"']+)["']/);

                if (nameMatch) info.name = nameMatch[1];
                if (descMatch) info.description = descMatch[1];
                if (homepageMatch) info.homepage = homepageMatch[1];
                break;
            } catch (error) {
                // Ignore parsing errors
            }
        }
    }

    return info;
}

/**
 * Get status icon for component/template status
 * @param {string} status - Status string
 */
function getStatusIcon(status) {
    const icons = {
        'stable': '✅',
        'ready': '✅',
        'experimental': '🧪',
        'planned': '📋',
        'deprecated': '❌',
        'empty': '📂',
        'incomplete': '⚠️',
        'unknown': '❓'
    };
    return icons[status] || '❓';
}

/**
 * Generate autocompletion suggestions
 * @param {string} type - Type of completion (templates, themes, components)
 * @param {Object} options - Options
 */
async function generateCompletions(type, options = {}) {
    let items = [];

    switch (type) {
        case 'templates':
            items = await listTemplates({ ...options, format: 'names' });
            break;
        case 'themes':
            items = await listThemes({ ...options, format: 'names' });
            break;
        case 'components':
            const components = await listComponents({ ...options, format: 'names' });
            items = components.map(c => c.name);
            break;
    }

    if (options.format === 'bash') {
        console.log(items.join(' '));
    } else if (options.format === 'zsh') {
        items.forEach(item => console.log(`${item}:${item}`));
    } else {
        items.forEach(item => console.log(item));
    }

    return items;
}

// Command-line interface
if (require.main === module) {
    const args = process.argv.slice(2);

    const options = {
        format: 'pretty',
        projectRoot: null
    };

    let command = 'all';

    // Parse arguments
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (arg === '--format' && i + 1 < args.length) {
            options.format = args[i + 1];
            i++;
        } else if (arg === '--project-root' && i + 1 < args.length) {
            options.projectRoot = args[i + 1];
            i++;
        } else if (arg === '--help') {
            console.log(`
Usage: node list.js [COMMAND] [OPTIONS]

Commands:
    templates    List available templates
    themes       List available themes
    components   List available components
    all          List all items (default)

Options:
    --format <type>      Output format (pretty, json, names)
    --project-root <path> Project root directory
    --help               Show this help

Examples:
    node list.js                    # List all items
    node list.js templates          # List only templates
    node list.js --format json      # Output as JSON
    node list.js templates --format names  # Just template names
`);
            process.exit(0);
        } else if (!arg.startsWith('--')) {
            command = arg;
        }
    }

    async function runCommand() {
        try {
            switch (command) {
                case 'templates':
                    await listTemplates(options);
                    break;
                case 'themes':
                    await listThemes(options);
                    break;
                case 'components':
                    await listComponents(options);
                    break;
                case 'all':
                default:
                    await listTemplates(options);
                    console.log('');
                    await listThemes(options);
                    console.log('');
                    await listComponents(options);
                    break;
            }
        } catch (error) {
            console.error(chalk.red('❌ List command failed:'), error.message);
            process.exit(1);
        }
    }

    runCommand();
}

module.exports = {
    listTemplates,
    listThemes,
    listComponents,
    generateCompletions
};