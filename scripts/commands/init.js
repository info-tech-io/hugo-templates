const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');
const inquirer = require('inquirer');

/**
 * Init command implementation
 * @param {string} name - Project name
 * @param {Object} options - Command options
 */
async function initCommand(name, options) {
  console.log(chalk.blue('🚀 Hugo Template Factory - Initialize Project'));
  console.log(chalk.gray('━'.repeat(50)));

  try {
    let projectName = name;
    let template = options.template;
    let theme = options.theme;
    let components = options.components || [];

    // Interactive prompts if not provided
    if (!options.noInteractive) {
      const answers = await inquirer.prompt([
        {
          type: 'input',
          name: 'projectName',
          message: 'Project name:',
          default: projectName || 'my-hugo-site',
          when: !projectName
        },
        {
          type: 'list',
          name: 'template',
          message: 'Choose a template:',
          choices: [
            { name: 'Default - Full-featured template', value: 'default' },
            { name: 'Minimal - Lightweight for fast builds', value: 'minimal' },
            { name: 'Academic - With citations and references', value: 'academic' },
            { name: 'Enterprise - Corporate with analytics', value: 'enterprise' }
          ],
          default: template || 'default',
          when: !template
        },
        {
          type: 'list',
          name: 'theme',
          message: 'Choose a theme:',
          choices: [
            { name: 'Compose - Clean and modern', value: 'compose' },
            { name: 'Academic - Academic styling', value: 'academic' },
            { name: 'Corporate - Corporate design', value: 'corporate' }
          ],
          default: theme || 'compose',
          when: !theme
        },
        {
          type: 'checkbox',
          name: 'components',
          message: 'Select components to include:',
          choices: [
            { name: 'Quiz Engine - Interactive quizzes', value: 'quiz-engine' },
            { name: 'Analytics - Tracking and analytics', value: 'analytics', disabled: '(planned)' },
            { name: 'Auth - Authentication system', value: 'auth', disabled: '(planned)' },
            { name: 'Citations - Citation system', value: 'citations', disabled: '(planned)' }
          ],
          default: components,
          when: components.length === 0
        }
      ]);

      projectName = answers.projectName || projectName;
      template = answers.template || template;
      theme = answers.theme || theme;
      components = answers.components || components;
    }

    // Set defaults if still not provided
    projectName = projectName || 'my-hugo-site';
    template = template || 'default';
    theme = theme || 'compose';

    console.log(chalk.yellow('\\n📋 Project Configuration:'));
    console.log(chalk.white(`   Name: ${projectName}`));
    console.log(chalk.white(`   Template: ${template}`));
    console.log(chalk.white(`   Theme: ${theme}`));
    console.log(chalk.white(`   Components: ${components.length ? components.join(', ') : 'none'}`));

    // Check if project directory already exists
    const projectPath = path.resolve(projectName);
    if (await fs.pathExists(projectPath)) {
      const { overwrite } = await inquirer.prompt([
        {
          type: 'confirm',
          name: 'overwrite',
          message: `Directory ${projectName} already exists. Overwrite?`,
          default: false
        }
      ]);

      if (!overwrite) {
        console.log(chalk.yellow('Initialization cancelled'));
        return;
      }

      await fs.remove(projectPath);
    }

    console.log(chalk.blue('\\n🏗️  Initializing project...'));

    // Create project directory
    await fs.ensureDir(projectPath);

    // For now, just create a placeholder structure
    await fs.writeJson(path.join(projectPath, 'hugo-templates.json'), {
      template,
      theme,
      components,
      generated: new Date().toISOString(),
      version: require('../../package.json').version
    }, { spaces: 2 });

    await fs.writeFile(path.join(projectPath, 'README.md'),
      `# ${projectName}\\n\\nGenerated with Hugo Template Factory Framework\\n\\nTemplate: ${template}\\nTheme: ${theme}\\nComponents: ${components.join(', ') || 'none'}\\n`
    );

    console.log(chalk.green('✅ Project initialized successfully!'));
    console.log(chalk.yellow('\\n📝 Next steps:'));
    console.log(chalk.white(`   cd ${projectName}`));
    console.log(chalk.white('   hugo-templates build'));
    console.log(chalk.gray('\\n   Note: Full build functionality will be available in Stage 2'));

  } catch (error) {
    console.error(chalk.red('❌ Initialization failed:'));
    console.error(chalk.red(`   ${error.message}`));
    process.exit(1);
  }
}

module.exports = initCommand;