const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');
const Ajv = require('ajv');
const { execSync } = require('child_process');

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

    // Start build process
    console.log(chalk.blue('\n🚀 Starting build process...'));
    await executeBuild(options);

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

/**
 * Execute the build process
 * @param {Object} options - Build options
 */
async function executeBuild(options) {
  const yaml = require('yaml');

  const templatePath = path.join(__dirname, '../../templates', options.template);
  const outputPath = path.resolve(options.output);

  console.log(chalk.yellow('📋 Step 1: Preparing build environment...'));

  // Ensure output directory exists
  await fs.ensureDir(outputPath);

  console.log(chalk.yellow('📋 Step 2: Loading template configuration...'));

  // Load components.yml configuration
  const componentsYmlPath = path.join(templatePath, 'components.yml');
  let templateConfig = {};

  if (await fs.pathExists(componentsYmlPath)) {
    const componentsContent = await fs.readFile(componentsYmlPath, 'utf8');
    templateConfig = yaml.parse(componentsContent);

    if (options.verbose) {
      console.log(chalk.gray(`   Loaded configuration for template: ${templateConfig.template?.name || options.template}`));
      console.log(chalk.gray(`   Available components: ${Object.keys(templateConfig.components || {}).join(', ')}`));
    }
  }

  console.log(chalk.yellow('📋 Step 3: Copying template files...'));

  // Copy template files to output directory
  await fs.copy(templatePath, outputPath, {
    filter: (src, dest) => {
      // Skip .git directories and other unwanted files
      const relativePath = path.relative(templatePath, src);
      return !relativePath.includes('.git') &&
             !relativePath.includes('node_modules') &&
             path.basename(src) !== '.DS_Store';
    }
  });

  console.log(chalk.yellow('📋 Step 4: Processing components...'));

  // Process components based on options
  await processComponents(templateConfig, options, outputPath);

  console.log(chalk.yellow('📋 Step 5: Updating Hugo configuration...'));

  // Update Hugo configuration
  await updateHugoConfig(options, outputPath, templateConfig);

  console.log(chalk.yellow('📋 Step 6: Running Hugo build...'));

  // Run Hugo build
  await runHugoBuild(options, outputPath);

  console.log(chalk.green('\n🎉 Build completed successfully!'));
  console.log(chalk.blue(`   Output directory: ${outputPath}`));

  // Show build summary
  await showBuildSummary(outputPath, options);
}

/**
 * Process components based on configuration
 * @param {Object} templateConfig - Template configuration
 * @param {Object} options - Build options
 * @param {string} outputPath - Output directory
 */
async function processComponents(templateConfig, options, outputPath) {
  const components = templateConfig.components || {};
  const requestedComponents = options.components || [];

  for (const [componentName, componentConfig] of Object.entries(components)) {
    // Skip planned components
    if (componentConfig.status === 'planned') {
      if (options.verbose) {
        console.log(chalk.gray(`   Skipping planned component: ${componentName}`));
      }
      continue;
    }

    // Include component if specifically requested or if it's a stable default
    const shouldInclude = requestedComponents.length === 0 ||
                         requestedComponents.includes(componentName) ||
                         componentConfig.status === 'stable';

    if (shouldInclude) {
      console.log(chalk.white(`   ✓ Including component: ${componentName}`));

      // Handle theme components
      if (componentConfig.submodule_path && componentConfig.submodule_path.startsWith('themes/')) {
        const themeName = path.basename(componentConfig.submodule_path);
        const sourcePath = path.join(__dirname, '../../', componentConfig.submodule_path);
        const destPath = path.join(outputPath, 'themes', themeName);

        if (await fs.pathExists(sourcePath)) {
          await fs.copy(sourcePath, destPath);
          if (options.verbose) {
            console.log(chalk.gray(`     Copied theme: ${themeName}`));
          }
        }
      }

      // Handle regular components
      if (componentConfig.submodule_path && componentConfig.submodule_path.startsWith('components/')) {
        const sourcePath = path.join(__dirname, '../../', componentConfig.submodule_path);

        // Process static files if they exist
        if (componentConfig.static_files) {
          for (const staticFile of componentConfig.static_files) {
            const sourceFilePath = path.join(sourcePath, staticFile);
            const destPath = path.join(outputPath, 'static', staticFile);

            if (await fs.pathExists(sourceFilePath)) {
              await fs.copy(sourceFilePath, destPath);
              if (options.verbose) {
                console.log(chalk.gray(`     Copied: ${staticFile}`));
              }
            }
          }
        }
      }
    } else {
      console.log(chalk.gray(`   ⊝ Excluding component: ${componentName}`));
    }
  }
}

/**
 * Update Hugo configuration
 * @param {Object} options - Build options
 * @param {string} outputPath - Output directory
 * @param {Object} templateConfig - Template configuration
 */
async function updateHugoConfig(options, outputPath, templateConfig) {
  const hugoConfigPath = path.join(outputPath, 'hugo.toml');

  if (await fs.pathExists(hugoConfigPath)) {
    let configContent = await fs.readFile(hugoConfigPath, 'utf8');

    // Update theme if specified
    if (options.theme && options.theme !== 'compose') {
      configContent = configContent.replace(
        /theme\s*=\s*['"].*?['"]/,
        `theme = '${options.theme}'`
      );
    }

    // Update base URL if specified
    if (options.baseUrl) {
      configContent = configContent.replace(
        /baseURL\s*=\s*['"].*?['"]/,
        `baseURL = '${options.baseUrl}'`
      );
    }

    // Update environment-specific settings
    if (options.environment === 'production') {
      configContent += `\n\n# Production environment settings\nenvironmentOutput = "production"\n`;
    }

    await fs.writeFile(hugoConfigPath, configContent);

    if (options.verbose) {
      console.log(chalk.gray(`   Updated Hugo configuration`));
    }
  }
}

/**
 * Run Hugo build process
 * @param {Object} options - Build options
 * @param {string} outputPath - Output directory
 */
async function runHugoBuild(options, outputPath) {
  try {
    // Change to output directory for Hugo build
    process.chdir(outputPath);

    // Build Hugo command
    let hugoCmd = 'hugo';

    // Add Hugo flags based on options
    if (options.minify) hugoCmd += ' --minify';
    if (options.draft) hugoCmd += ' --draft';
    if (options.future) hugoCmd += ' --future';
    if (options.baseUrl) hugoCmd += ` --baseURL "${options.baseUrl}"`;
    if (options.environment) hugoCmd += ` --environment ${options.environment}`;
    if (options.logLevel) hugoCmd += ` --logLevel ${options.logLevel}`;

    // Set destination to public subdirectory
    hugoCmd += ' --destination public';

    if (options.verbose) {
      console.log(chalk.gray(`   Running: ${hugoCmd}`));
    }

    // Execute Hugo build
    const output = execSync(hugoCmd, {
      encoding: 'utf8',
      stdio: options.verbose ? 'inherit' : 'pipe'
    });

    if (!options.verbose && output) {
      console.log(chalk.gray(`   Hugo build output: ${output.split('\n')[0]}`));
    }

  } catch (error) {
    throw new Error(`Hugo build failed: ${error.message}`);
  }
}

/**
 * Show build summary
 * @param {string} outputPath - Output directory
 * @param {Object} options - Build options
 */
async function showBuildSummary(outputPath, options) {
  const publicPath = path.join(outputPath, 'public');

  if (await fs.pathExists(publicPath)) {
    try {

      // Get build statistics
      const sizeOutput = execSync(`du -sh "${publicPath}"`, { encoding: 'utf8' });
      const totalSize = sizeOutput.split('\t')[0];

      const fileCount = execSync(`find "${publicPath}" -type f | wc -l`, { encoding: 'utf8' }).trim();

      console.log(chalk.blue('\n📊 Build Summary:'));
      console.log(chalk.white(`   Template: ${options.template}`));
      console.log(chalk.white(`   Theme: ${options.theme}`));
      console.log(chalk.white(`   Total size: ${totalSize}`));
      console.log(chalk.white(`   Files generated: ${fileCount}`));
      console.log(chalk.white(`   Output location: ${publicPath}`));

      if (options.verbose) {
        console.log(chalk.gray('\n🔍 Detailed file structure:'));
        const treeOutput = execSync(`find "${publicPath}" -type f | head -10`, { encoding: 'utf8' });
        treeOutput.split('\n').forEach(file => {
          if (file.trim()) {
            console.log(chalk.gray(`   ${path.relative(publicPath, file)}`));
          }
        });
        if (parseInt(fileCount) > 10) {
          console.log(chalk.gray(`   ... and ${parseInt(fileCount) - 10} more files`));
        }
      }

    } catch (error) {
      console.log(chalk.yellow('\n📊 Build completed (statistics unavailable)'));
    }
  }
}

module.exports = buildCommand;