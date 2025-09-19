#!/usr/bin/env node

/**
 * Hugo Template Factory Framework - Advanced Validation System
 * Enhanced JSON Schema validation for templates, components, and build configurations
 */

const fs = require('fs-extra');
const path = require('path');
const Ajv = require('ajv');
const yaml = require('yaml');
const chalk = require('chalk');

// Initialize AJV with options
const ajv = new Ajv({
    allErrors: true,
    verbose: true,
    strict: false,
    validateFormats: false
});

/**
 * Validation result structure
 */
class ValidationResult {
    constructor() {
        this.valid = true;
        this.errors = [];
        this.warnings = [];
        this.info = [];
    }

    addError(message, details = {}) {
        this.valid = false;
        this.errors.push({ message, details, type: 'error' });
    }

    addWarning(message, details = {}) {
        this.warnings.push({ message, details, type: 'warning' });
    }

    addInfo(message, details = {}) {
        this.info.push({ message, details, type: 'info' });
    }

    hasIssues() {
        return this.errors.length > 0 || this.warnings.length > 0;
    }
}

/**
 * Load and compile JSON schema
 * @param {string} schemaName - Name of the schema file
 * @returns {Function|null} Compiled schema validator
 */
function loadSchema(schemaName) {
    try {
        const schemaPath = path.join(__dirname, '..', 'schemas', `${schemaName}.json`);

        if (!fs.existsSync(schemaPath)) {
            console.warn(chalk.yellow(`⚠️  Schema file not found: ${schemaPath}`));
            return null;
        }

        const schemaContent = fs.readFileSync(schemaPath, 'utf8');
        const schema = JSON.parse(schemaContent);

        return ajv.compile(schema);
    } catch (error) {
        console.error(chalk.red(`❌ Failed to load schema '${schemaName}': ${error.message}`));
        return null;
    }
}

/**
 * Validate components.yml file
 * @param {string} filePath - Path to components.yml
 * @param {ValidationResult} result - Validation result object
 */
async function validateComponentsYml(filePath, result) {
    try {
        if (!fs.existsSync(filePath)) {
            result.addWarning(`Components file not found: ${filePath}`);
            return;
        }

        const content = fs.readFileSync(filePath, 'utf8');
        let config;

        try {
            config = yaml.parse(content);
        } catch (yamlError) {
            result.addError(`Invalid YAML syntax in ${filePath}`, { error: yamlError.message });
            return;
        }

        // Validate against component schema
        const componentValidator = loadSchema('component');
        if (componentValidator) {
            const isValid = componentValidator(config);
            if (!isValid) {
                componentValidator.errors.forEach(error => {
                    result.addError(`Schema validation error in ${filePath}`, {
                        path: error.instancePath,
                        message: error.message,
                        data: error.data
                    });
                });
            } else {
                result.addInfo(`Components configuration schema is valid: ${filePath}`);
            }
        }

        // Validate template metadata
        if (config.template) {
            if (!config.template.name) {
                result.addError('Template name is required in components.yml');
            }
            if (!config.template.version) {
                result.addWarning('Template version is recommended in components.yml');
            }
            if (!config.template.description) {
                result.addWarning('Template description is recommended in components.yml');
            }
        } else {
            result.addWarning('Template metadata section is missing in components.yml');
        }

        // Validate components
        if (config.components) {
            for (const [componentName, componentConfig] of Object.entries(config.components)) {
                validateComponent(componentName, componentConfig, result, filePath);
            }
        } else {
            result.addWarning('No components defined in components.yml');
        }

        // Validate Hugo configuration
        if (config.hugo) {
            validateHugoConfig(config.hugo, result, filePath);
        }

    } catch (error) {
        result.addError(`Failed to validate components file: ${filePath}`, { error: error.message });
    }
}

/**
 * Validate individual component configuration
 * @param {string} name - Component name
 * @param {Object} config - Component configuration
 * @param {ValidationResult} result - Validation result object
 * @param {string} filePath - Source file path for context
 */
function validateComponent(name, config, result, filePath) {
    // Required fields
    if (!config.status) {
        result.addError(`Component '${name}' missing required 'status' field`);
    } else if (!['stable', 'experimental', 'planned', 'deprecated'].includes(config.status)) {
        result.addWarning(`Component '${name}' has unknown status: ${config.status}`);
    }

    if (!config.version) {
        result.addWarning(`Component '${name}' missing version information`);
    }

    if (!config.description) {
        result.addWarning(`Component '${name}' missing description`);
    }

    // Validate submodule path if present
    if (config.submodule_path) {
        const submodulePath = path.join(path.dirname(path.dirname(filePath)), config.submodule_path);
        if (!fs.existsSync(submodulePath)) {
            result.addWarning(`Component '${name}' submodule path does not exist: ${config.submodule_path}`);
        } else {
            result.addInfo(`Component '${name}' submodule path verified: ${config.submodule_path}`);
        }
    }

    // Validate static files if present
    if (config.static_files) {
        if (!Array.isArray(config.static_files)) {
            result.addError(`Component '${name}' static_files must be an array`);
        } else {
            config.static_files.forEach(file => {
                if (config.submodule_path) {
                    const fullPath = path.join(path.dirname(path.dirname(filePath)), config.submodule_path, file);
                    if (!fs.existsSync(fullPath)) {
                        result.addWarning(`Component '${name}' static file not found: ${file} (in ${config.submodule_path})`);
                    }
                }
            });
        }
    }

    // Status-specific validation
    if (config.status === 'planned') {
        if (config.submodule_path) {
            result.addWarning(`Component '${name}' is marked as planned but has submodule_path defined`);
        }
    } else if (config.status === 'stable') {
        if (!config.submodule_path && !config.files) {
            result.addWarning(`Component '${name}' is marked as stable but has no submodule_path or files defined`);
        }
    }
}

/**
 * Validate Hugo configuration section
 * @param {Object} hugoConfig - Hugo configuration object
 * @param {ValidationResult} result - Validation result object
 * @param {string} filePath - Source file path for context
 */
function validateHugoConfig(hugoConfig, result, filePath) {
    if (hugoConfig.minVersion) {
        // Basic version format validation
        const versionPattern = /^\d+\.\d+\.\d+$/;
        if (!versionPattern.test(hugoConfig.minVersion)) {
            result.addWarning(`Hugo minVersion should follow semantic versioning: ${hugoConfig.minVersion}`);
        }
    }

    if (hugoConfig.modules) {
        if (!Array.isArray(hugoConfig.modules)) {
            result.addError('Hugo modules configuration must be an array');
        } else {
            hugoConfig.modules.forEach((module, index) => {
                if (typeof module === 'object' && !module.path) {
                    result.addError(`Hugo module at index ${index} missing required 'path' field`);
                }
            });
        }
    }
}

/**
 * Validate template directory structure
 * @param {string} templatePath - Path to template directory
 * @param {ValidationResult} result - Validation result object
 */
async function validateTemplateStructure(templatePath, result) {
    const templateName = path.basename(templatePath);

    if (!fs.existsSync(templatePath)) {
        result.addError(`Template directory not found: ${templatePath}`);
        return;
    }

    const requiredFiles = ['hugo.toml', 'components.yml'];
    const recommendedDirs = ['content', 'static', 'archetypes'];

    // Check required files
    for (const file of requiredFiles) {
        const filePath = path.join(templatePath, file);
        if (!fs.existsSync(filePath)) {
            if (file === 'components.yml') {
                result.addWarning(`Template '${templateName}' missing ${file} (recommended)`);
            } else {
                result.addError(`Template '${templateName}' missing required file: ${file}`);
            }
        } else {
            result.addInfo(`Template '${templateName}' has required file: ${file}`);
        }
    }

    // Check recommended directories
    for (const dir of recommendedDirs) {
        const dirPath = path.join(templatePath, dir);
        if (!fs.existsSync(dirPath)) {
            result.addWarning(`Template '${templateName}' missing recommended directory: ${dir}`);
        } else if (!fs.lstatSync(dirPath).isDirectory()) {
            result.addError(`Template '${templateName}' has ${dir} as file, expected directory`);
        } else {
            result.addInfo(`Template '${templateName}' has recommended directory: ${dir}`);
        }
    }

    // Validate Hugo configuration
    const hugoConfigPath = path.join(templatePath, 'hugo.toml');
    if (fs.existsSync(hugoConfigPath)) {
        try {
            const hugoContent = fs.readFileSync(hugoConfigPath, 'utf8');
            // Basic TOML syntax check - just try to parse it manually for basic validation
            if (!hugoContent.includes('title') && !hugoContent.includes('baseURL')) {
                result.addWarning(`Template '${templateName}' hugo.toml seems incomplete (no title or baseURL)`);
            }
        } catch (error) {
            result.addError(`Template '${templateName}' has invalid hugo.toml`, { error: error.message });
        }
    }

    // Validate components.yml if present
    const componentsPath = path.join(templatePath, 'components.yml');
    if (fs.existsSync(componentsPath)) {
        await validateComponentsYml(componentsPath, result);
    }
}

/**
 * Validate build parameters combination
 * @param {Object} buildParams - Build parameters
 * @param {ValidationResult} result - Validation result object
 */
function validateBuildParameters(buildParams, result) {
    const { template, theme, components, output, environment } = buildParams;

    // Validate template
    if (!template) {
        result.addError('Template parameter is required');
    }

    // Validate theme
    if (!theme) {
        result.addWarning('Theme parameter not specified, using default');
    }

    // Validate output directory
    if (output) {
        if (output === '.' || output === './') {
            result.addError('Output directory cannot be current directory');
        }

        if (fs.existsSync(output)) {
            try {
                const stats = fs.lstatSync(output);
                if (stats.isFile()) {
                    result.addError(`Output path exists as file, expected directory: ${output}`);
                }
            } catch (error) {
                result.addWarning(`Cannot access output directory: ${output}`);
            }
        }
    }

    // Validate environment
    if (environment && !['development', 'production', 'staging'].includes(environment)) {
        result.addWarning(`Unknown environment: ${environment}. Common values: development, production, staging`);
    }

    // Validate components if specified
    if (components) {
        if (typeof components === 'string') {
            const componentList = components.split(',').map(c => c.trim());
            componentList.forEach(component => {
                if (!component) {
                    result.addWarning('Empty component name in components list');
                }
            });
        }
    }
}

/**
 * Main validation function
 * @param {Object} options - Validation options
 */
async function validate(options = {}) {
    const result = new ValidationResult();

    console.log(chalk.blue('🔍 Hugo Template Factory - Advanced Validation'));
    console.log(chalk.gray('━'.repeat(60)));
    console.log('');

    try {
        const projectRoot = options.projectRoot || path.join(__dirname, '..');

        // Validate project structure
        if (options.validateProject !== false) {
            console.log(chalk.yellow('📋 Validating project structure...'));

            const templatesDir = path.join(projectRoot, 'templates');
            if (fs.existsSync(templatesDir)) {
                const templates = fs.readdirSync(templatesDir).filter(item => {
                    return fs.lstatSync(path.join(templatesDir, item)).isDirectory();
                });

                for (const template of templates) {
                    const templatePath = path.join(templatesDir, template);
                    await validateTemplateStructure(templatePath, result);
                }

                result.addInfo(`Found ${templates.length} templates: ${templates.join(', ')}`);
            } else {
                result.addError(`Templates directory not found: ${templatesDir}`);
            }
        }

        // Validate specific template if requested
        if (options.template) {
            console.log(chalk.yellow(`📋 Validating template: ${options.template}...`));
            const templatePath = path.join(projectRoot, 'templates', options.template);
            await validateTemplateStructure(templatePath, result);
        }

        // Validate build parameters if provided
        if (options.buildParams) {
            console.log(chalk.yellow('📋 Validating build parameters...'));
            validateBuildParameters(options.buildParams, result);
        }

        // Validate specific components.yml file if provided
        if (options.componentsFile) {
            console.log(chalk.yellow(`📋 Validating components file: ${options.componentsFile}...`));
            await validateComponentsYml(options.componentsFile, result);
        }

    } catch (error) {
        result.addError('Validation process failed', { error: error.message });
    }

    // Output results
    console.log('');
    console.log(chalk.blue('📊 Validation Results:'));
    console.log('━'.repeat(40));

    // Show info messages
    if (result.info.length > 0) {
        console.log(chalk.green(`\n✅ Information (${result.info.length}):`));
        result.info.forEach(item => {
            console.log(chalk.green(`   ℹ️  ${item.message}`));
        });
    }

    // Show warnings
    if (result.warnings.length > 0) {
        console.log(chalk.yellow(`\n⚠️  Warnings (${result.warnings.length}):`));
        result.warnings.forEach(item => {
            console.log(chalk.yellow(`   ⚠️  ${item.message}`));
            if (item.details && Object.keys(item.details).length > 0) {
                console.log(chalk.gray(`      Details: ${JSON.stringify(item.details, null, 2)}`));
            }
        });
    }

    // Show errors
    if (result.errors.length > 0) {
        console.log(chalk.red(`\n❌ Errors (${result.errors.length}):`));
        result.errors.forEach(item => {
            console.log(chalk.red(`   ❌ ${item.message}`));
            if (item.details && Object.keys(item.details).length > 0) {
                console.log(chalk.gray(`      Details: ${JSON.stringify(item.details, null, 2)}`));
            }
        });
    }

    // Final result
    console.log('');
    if (result.valid) {
        console.log(chalk.green('🎉 Overall validation: PASSED'));
        if (result.warnings.length > 0) {
            console.log(chalk.yellow(`   Note: ${result.warnings.length} warnings found (non-critical)`));
        }
    } else {
        console.log(chalk.red('💥 Overall validation: FAILED'));
        console.log(chalk.red(`   Found ${result.errors.length} errors that must be fixed`));
    }

    return result;
}

// Command-line interface
if (require.main === module) {
    const args = process.argv.slice(2);

    const options = {
        template: null,
        componentsFile: null,
        validateProject: true,
        buildParams: null
    };

    // Parse command line arguments
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (arg === '--template' && i + 1 < args.length) {
            options.template = args[i + 1];
            i++;
        } else if (arg === '--components-file' && i + 1 < args.length) {
            options.componentsFile = args[i + 1];
            i++;
        } else if (arg === '--no-project') {
            options.validateProject = false;
        } else if (arg === '--help') {
            console.log(`
Usage: node validate.js [OPTIONS]

Options:
    --template <name>           Validate specific template
    --components-file <path>    Validate specific components.yml file
    --no-project                Skip project structure validation
    --help                      Show this help

Examples:
    node validate.js                              # Validate entire project
    node validate.js --template default          # Validate default template
    node validate.js --components-file path.yml  # Validate specific components file
    node validate.js --no-project --template minimal  # Validate only minimal template
`);
            process.exit(0);
        }
    }

    validate(options).then(result => {
        process.exit(result.valid ? 0 : 1);
    }).catch(error => {
        console.error(chalk.red('❌ Validation failed:'), error.message);
        process.exit(1);
    });
}

module.exports = { validate, ValidationResult };