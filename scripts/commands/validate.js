const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');
const Ajv = require('ajv');

/**
 * Validate command implementation
 * @param {string} target - Target to validate
 * @param {Object} options - Command options
 */
async function validateCommand(target, options) {
  console.log(chalk.blue('🔍 Hugo Template Factory - Validation'));
  console.log(chalk.gray('━'.repeat(50)));

  try {
    const results = {
      valid: true,
      errors: [],
      warnings: []
    };

    if (options.type === 'all' || options.type === 'config') {
      await validateConfigurations(target, results, options);
    }

    if (options.type === 'all' || options.type === 'template') {
      await validateTemplates(target, results, options);
    }

    if (options.type === 'all' || options.type === 'component') {
      await validateComponents(target, results, options);
    }

    // Output results
    if (results.valid) {
      console.log(chalk.green('✅ Validation passed'));
    } else {
      console.log(chalk.red('❌ Validation failed'));
      results.errors.forEach(error => {
        console.log(chalk.red(`   Error: ${error}`));
      });
    }

    if (results.warnings.length > 0) {
      console.log(chalk.yellow('\n⚠️  Warnings:'));
      results.warnings.forEach(warning => {
        console.log(chalk.yellow(`   ${warning}`));
      });
    }

    if (!results.valid) {
      process.exit(1);
    }

  } catch (error) {
    console.error(chalk.red('❌ Validation error:'));
    console.error(chalk.red(`   ${error.message}`));
    process.exit(1);
  }
}

/**
 * Validate configuration files
 */
async function validateConfigurations(target, results, options) {
  console.log(chalk.blue('📋 Validating configurations...'));

  // Check collection.json
  const collectionPath = path.join(__dirname, '../../collection.json');
  if (await fs.pathExists(collectionPath)) {
    try {
      const collection = await fs.readJson(collectionPath);
      console.log(chalk.green('   ✓ collection.json is valid'));
    } catch (error) {
      results.valid = false;
      results.errors.push(`collection.json: ${error.message}`);
    }
  } else {
    results.warnings.push('collection.json not found');
  }

  // Check package.json
  const packagePath = path.join(__dirname, '../../package.json');
  if (await fs.pathExists(packagePath)) {
    try {
      const pkg = await fs.readJson(packagePath);
      if (!pkg.name || !pkg.version) {
        results.valid = false;
        results.errors.push('package.json: missing required fields');
      } else {
        console.log(chalk.green('   ✓ package.json is valid'));
      }
    } catch (error) {
      results.valid = false;
      results.errors.push(`package.json: ${error.message}`);
    }
  }
}

/**
 * Validate templates
 */
async function validateTemplates(target, results, options) {
  console.log(chalk.blue('📁 Validating templates...'));

  const templatesDir = path.join(__dirname, '../../templates');
  if (!await fs.pathExists(templatesDir)) {
    results.warnings.push('templates directory not found');
    return;
  }

  const templates = await fs.readdir(templatesDir);
  for (const template of templates) {
    const templatePath = path.join(templatesDir, template);
    const stat = await fs.stat(templatePath);

    if (stat.isDirectory()) {
      await validateTemplate(template, templatePath, results, options);
    }
  }
}

/**
 * Validate individual template
 */
async function validateTemplate(name, templatePath, results, options) {
  // Check if template.json exists
  const configPath = path.join(templatePath, 'template.json');
  if (await fs.pathExists(configPath)) {
    try {
      const config = await fs.readJson(configPath);

      // Validate against schema
      const schemaPath = path.join(__dirname, '../../schemas/template.json');
      if (await fs.pathExists(schemaPath)) {
        const schema = await fs.readJson(schemaPath);
        const ajv = new Ajv({ allErrors: true });
        const validate = ajv.compile(schema);

        if (!validate(config)) {
          results.valid = false;
          validate.errors.forEach(error => {
            results.errors.push(`Template ${name}: ${error.instancePath} ${error.message}`);
          });
        } else {
          console.log(chalk.green(`   ✓ Template ${name} is valid`));
        }
      }
    } catch (error) {
      results.valid = false;
      results.errors.push(`Template ${name}: ${error.message}`);
    }
  } else {
    results.warnings.push(`Template ${name}: no template.json found`);
  }
}

/**
 * Validate components
 */
async function validateComponents(target, results, options) {
  console.log(chalk.blue('🧩 Validating components...'));

  const componentsDir = path.join(__dirname, '../../components');
  if (!await fs.pathExists(componentsDir)) {
    results.warnings.push('components directory not found');
    return;
  }

  const components = await fs.readdir(componentsDir);
  for (const component of components) {
    const componentPath = path.join(componentsDir, component);
    const stat = await fs.stat(componentPath);

    if (stat.isDirectory()) {
      await validateComponent(component, componentPath, results, options);
    }
  }
}

/**
 * Validate individual component
 */
async function validateComponent(name, componentPath, results, options) {
  const configPath = path.join(componentPath, 'component.json');
  if (await fs.pathExists(configPath)) {
    try {
      const config = await fs.readJson(configPath);

      // Validate against schema
      const schemaPath = path.join(__dirname, '../../schemas/component.json');
      if (await fs.pathExists(schemaPath)) {
        const schema = await fs.readJson(schemaPath);
        const ajv = new Ajv({ allErrors: true });
        const validate = ajv.compile(schema);

        if (!validate(config)) {
          results.valid = false;
          validate.errors.forEach(error => {
            results.errors.push(`Component ${name}: ${error.instancePath} ${error.message}`);
          });
        } else {
          console.log(chalk.green(`   ✓ Component ${name} is valid`));
        }
      }
    } catch (error) {
      results.valid = false;
      results.errors.push(`Component ${name}: ${error.message}`);
    }
  } else {
    results.warnings.push(`Component ${name}: no component.json found`);
  }
}

module.exports = validateCommand;