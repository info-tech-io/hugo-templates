const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');
const Ajv = require('ajv');

/**
 * Build command implementation
 * @param {Object} options - Command options
 */
async function buildCommand(options) {
  console.log(chalk.blue('🏗️  Hugo Template Factory Build'));
  console.log(chalk.gray('━'.repeat(50)));

  try {
    // Validate options against schema
    await validateBuildOptions(options);

    // Show build configuration
    console.log(chalk.yellow('📋 Build Configuration:'));
    console.log(chalk.white(`   Template: ${options.template}`));
    console.log(chalk.white(`   Theme: ${options.theme}`));
    console.log(chalk.white(`   Components: ${options.components ? options.components.join(', ') : 'none'}`));
    console.log(chalk.white(`   Output: ${options.output}`));
    console.log(chalk.white(`   Environment: ${options.environment}`));

    if (options.verbose) {
      console.log(chalk.gray('\n🔍 Verbose mode enabled'));
      console.log(chalk.gray(`   Minify: ${options.minify || false}`));
      console.log(chalk.gray(`   Draft: ${options.draft || false}`));
      console.log(chalk.gray(`   Future: ${options.future || false}`));
      console.log(chalk.gray(`   Base URL: ${options.baseUrl || 'not set'}`));
      console.log(chalk.gray(`   Log Level: ${options.logLevel}`));
    }

    // Check template exists
    const templatePath = path.join(__dirname, '../../templates', options.template);
    if (!await fs.pathExists(templatePath)) {
      throw new Error(`Template '${options.template}' not found`);
    }

    console.log(chalk.green('\n✅ Build configuration validated'));
    console.log(chalk.yellow('🚧 Build process not yet implemented (Stage 2)'));
    console.log(chalk.blue('   This will be completed in the next stage of development'));

  } catch (error) {
    console.error(chalk.red('\n❌ Build failed:'));
    console.error(chalk.red(`   ${error.message}`));
    process.exit(1);
  }
}

/**
 * Validate build options against JSON Schema
 * @param {Object} options - Options to validate
 */
async function validateBuildOptions(options) {
  try {
    const schemaPath = path.join(__dirname, '../../schemas/build.json');
    const schema = await fs.readJson(schemaPath);

    const ajv = new Ajv({ allErrors: true });
    const validate = ajv.compile(schema);

    const valid = validate(options);
    if (!valid) {
      const errors = validate.errors.map(err =>
        `${err.instancePath}: ${err.message}`
      ).join(', ');
      throw new Error(`Validation failed: ${errors}`);
    }
  } catch (error) {
    if (error.code === 'ENOENT') {
      console.warn(chalk.yellow('⚠️  Schema file not found, skipping validation'));
    } else {
      throw error;
    }
  }
}

module.exports = buildCommand;