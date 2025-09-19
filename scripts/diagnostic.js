#!/usr/bin/env node

/**
 * Hugo Template Factory Framework - Diagnostic and Debug Utility
 * Provides system diagnostics, environment checks, and debugging tools
 */

const fs = require('fs-extra');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');
const chalk = require('chalk');
const { createLogger, createPerformanceMonitor } = require('./logger');

/**
 * System diagnostic class
 */
class SystemDiagnostic {
    constructor(options = {}) {
        this.logger = options.logger || createLogger({ level: 'INFO' });
        this.projectRoot = options.projectRoot || path.join(__dirname, '..');
        this.performance = createPerformanceMonitor(this.logger);
    }

    /**
     * Run complete system diagnostic
     */
    async runComplete() {
        this.logger.print(chalk.blue('🔍 Hugo Template Factory - System Diagnostic'));
        this.logger.print(chalk.gray('━'.repeat(60)));
        this.logger.print('');

        this.performance.startTimer('diagnostic');

        const results = {
            system: await this.checkSystem(),
            environment: await this.checkEnvironment(),
            dependencies: await this.checkDependencies(),
            project: await this.checkProject(),
            permissions: await this.checkPermissions(),
            performance: await this.checkPerformance()
        };

        this.performance.endTimer('diagnostic');

        this.printSummary(results);
        return results;
    }

    /**
     * Check system information
     */
    async checkSystem() {
        this.logger.info('Checking system information...');

        const system = {
            platform: os.platform(),
            arch: os.arch(),
            release: os.release(),
            hostname: os.hostname(),
            uptime: os.uptime(),
            memory: {
                total: os.totalmem(),
                free: os.freemem(),
                used: os.totalmem() - os.freemem()
            },
            cpus: os.cpus().length,
            tmpdir: os.tmpdir(),
            homedir: os.homedir()
        };

        this.logger.success(`System: ${system.platform} ${system.arch} (${system.release})`);
        this.logger.success(`Memory: ${(system.memory.used / 1024 / 1024 / 1024).toFixed(2)}GB used / ${(system.memory.total / 1024 / 1024 / 1024).toFixed(2)}GB total`);
        this.logger.success(`CPUs: ${system.cpus}`);

        return system;
    }

    /**
     * Check environment variables and configuration
     */
    async checkEnvironment() {
        this.logger.info('Checking environment configuration...');

        const env = {
            node_env: process.env.NODE_ENV || 'development',
            hugo_log_level: process.env.HUGO_LOG_LEVEL || 'not set',
            hugo_log_file: process.env.HUGO_LOG_FILE || 'not set',
            path: process.env.PATH ? process.env.PATH.split(':').length : 0,
            shell: process.env.SHELL || 'not set',
            editor: process.env.EDITOR || 'not set',
            lang: process.env.LANG || 'not set',
            pwd: process.cwd(),
            argv: process.argv
        };

        this.logger.success(`Node environment: ${env.node_env}`);
        this.logger.success(`Current directory: ${env.pwd}`);
        this.logger.success(`PATH entries: ${env.path}`);

        return env;
    }

    /**
     * Check required dependencies
     */
    async checkDependencies() {
        this.logger.info('Checking required dependencies...');

        const deps = {
            node: await this.checkCommand('node --version'),
            npm: await this.checkCommand('npm --version'),
            hugo: await this.checkCommand('hugo version'),
            git: await this.checkCommand('git --version'),
            bash: await this.checkCommand('bash --version | head -1'),
            yarn: await this.checkCommand('yarn --version', false), // Optional
        };

        // Check Node.js packages
        const packageJsonPath = path.join(this.projectRoot, 'package.json');
        if (fs.existsSync(packageJsonPath)) {
            try {
                const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
                deps.packageJson = {
                    name: packageJson.name,
                    version: packageJson.version,
                    dependencies: Object.keys(packageJson.dependencies || {}).length,
                    devDependencies: Object.keys(packageJson.devDependencies || {}).length
                };

                this.logger.success(`Package: ${deps.packageJson.name}@${deps.packageJson.version}`);
                this.logger.success(`Dependencies: ${deps.packageJson.dependencies} runtime, ${deps.packageJson.devDependencies} dev`);
            } catch (error) {
                this.logger.warn(`Failed to parse package.json: ${error.message}`);
            }
        }

        return deps;
    }

    /**
     * Check project structure and files
     */
    async checkProject() {
        this.logger.info('Checking project structure...');

        const project = {
            root: this.projectRoot,
            exists: fs.existsSync(this.projectRoot),
            structure: {},
            git: {}
        };

        if (!project.exists) {
            this.logger.error(`Project root not found: ${this.projectRoot}`);
            return project;
        }

        // Check main directories
        const expectedDirs = ['templates', 'themes', 'components', 'scripts', 'schemas', 'docs'];
        for (const dir of expectedDirs) {
            const dirPath = path.join(this.projectRoot, dir);
            project.structure[dir] = {
                exists: fs.existsSync(dirPath),
                isDirectory: fs.existsSync(dirPath) && fs.lstatSync(dirPath).isDirectory(),
                itemCount: 0
            };

            if (project.structure[dir].exists && project.structure[dir].isDirectory) {
                try {
                    project.structure[dir].itemCount = fs.readdirSync(dirPath).length;
                    this.logger.success(`Directory ${dir}/: ${project.structure[dir].itemCount} items`);
                } catch (error) {
                    this.logger.warn(`Cannot read directory ${dir}/: ${error.message}`);
                }
            } else {
                this.logger.warn(`Missing or invalid directory: ${dir}/`);
            }
        }

        // Check important files
        const expectedFiles = ['package.json', 'collection.json', '.gitignore', 'README.md'];
        for (const file of expectedFiles) {
            const filePath = path.join(this.projectRoot, file);
            const exists = fs.existsSync(filePath);
            project.structure[file] = { exists };

            if (exists) {
                try {
                    const stats = fs.statSync(filePath);
                    project.structure[file].size = stats.size;
                    project.structure[file].modified = stats.mtime;
                    this.logger.success(`File ${file}: ${stats.size} bytes`);
                } catch (error) {
                    this.logger.warn(`Cannot read file ${file}: ${error.message}`);
                }
            } else {
                this.logger.warn(`Missing file: ${file}`);
            }
        }

        // Check Git status
        try {
            const gitStatus = execSync('git status --porcelain', {
                cwd: this.projectRoot,
                encoding: 'utf8',
                stdio: 'pipe'
            });

            project.git = {
                isRepository: true,
                hasChanges: gitStatus.length > 0,
                changedFiles: gitStatus.split('\n').filter(line => line.trim()).length
            };

            if (project.git.hasChanges) {
                this.logger.warn(`Git: ${project.git.changedFiles} files with changes`);
            } else {
                this.logger.success('Git: Working directory clean');
            }
        } catch (error) {
            project.git.isRepository = false;
            this.logger.warn('Git: Not a git repository or git not available');
        }

        return project;
    }

    /**
     * Check file permissions
     */
    async checkPermissions() {
        this.logger.info('Checking file permissions...');

        const permissions = {
            scripts: {},
            directories: {}
        };

        // Check script permissions
        const scriptsDir = path.join(this.projectRoot, 'scripts');
        if (fs.existsSync(scriptsDir)) {
            const scripts = ['build.sh', 'factory.js', 'validate.js', 'list.js', 'generate.js'];

            for (const script of scripts) {
                const scriptPath = path.join(scriptsDir, script);
                if (fs.existsSync(scriptPath)) {
                    try {
                        fs.accessSync(scriptPath, fs.constants.X_OK);
                        permissions.scripts[script] = { executable: true };
                        this.logger.success(`Script ${script}: executable`);
                    } catch (error) {
                        permissions.scripts[script] = { executable: false, error: error.message };
                        this.logger.warn(`Script ${script}: not executable`);
                    }
                } else {
                    permissions.scripts[script] = { exists: false };
                    this.logger.warn(`Script ${script}: not found`);
                }
            }
        }

        // Check directory permissions
        const dirs = ['templates', 'themes', 'components'];
        for (const dir of dirs) {
            const dirPath = path.join(this.projectRoot, dir);
            if (fs.existsSync(dirPath)) {
                try {
                    fs.accessSync(dirPath, fs.constants.R_OK | fs.constants.W_OK);
                    permissions.directories[dir] = { readable: true, writable: true };
                    this.logger.success(`Directory ${dir}/: read/write access`);
                } catch (error) {
                    permissions.directories[dir] = { readable: false, writable: false, error: error.message };
                    this.logger.warn(`Directory ${dir}/: access denied`);
                }
            }
        }

        return permissions;
    }

    /**
     * Check performance metrics
     */
    async checkPerformance() {
        this.logger.info('Running performance checks...');

        this.performance.recordMemory('start');

        const performance = {
            memory: process.memoryUsage(),
            timing: {},
            io: {}
        };

        // Test file I/O performance
        this.performance.startTimer('file_io');
        try {
            const testFile = path.join(this.projectRoot, '.diagnostic_test');
            const testData = 'x'.repeat(1024 * 100); // 100KB

            fs.writeFileSync(testFile, testData);
            const readData = fs.readFileSync(testFile, 'utf8');
            fs.unlinkSync(testFile);

            performance.io.write_read_100kb = this.performance.endTimer('file_io');
            performance.io.success = readData.length === testData.length;

            this.logger.success(`I/O Performance: ${performance.io.write_read_100kb.toFixed(2)}ms for 100KB`);
        } catch (error) {
            performance.io.error = error.message;
            this.logger.warn(`I/O Performance test failed: ${error.message}`);
        }

        // Test script execution performance
        this.performance.startTimer('script_exec');
        try {
            const scriptPath = path.join(this.projectRoot, 'scripts', 'list.js');
            if (fs.existsSync(scriptPath)) {
                execSync(`node "${scriptPath}" --help`, {
                    stdio: 'pipe',
                    timeout: 5000
                });
                performance.timing.script_help = this.performance.endTimer('script_exec');
                this.logger.success(`Script execution: ${performance.timing.script_help.toFixed(2)}ms`);
            }
        } catch (error) {
            performance.timing.script_error = error.message;
            this.logger.warn(`Script execution test failed: ${error.message}`);
        }

        this.performance.recordMemory('end');

        return performance;
    }

    /**
     * Check if a command is available
     * @param {string} command - Command to check
     * @param {boolean} required - Whether command is required
     */
    async checkCommand(command, required = true) {
        try {
            const output = execSync(command, {
                encoding: 'utf8',
                stdio: 'pipe',
                timeout: 5000
            });

            const version = output.split('\n')[0].trim();

            if (required) {
                this.logger.success(`✓ ${command.split(' ')[0]}: ${version}`);
            } else {
                this.logger.info(`✓ ${command.split(' ')[0]}: ${version}`);
            }

            return { available: true, version, output };
        } catch (error) {
            if (required) {
                this.logger.error(`✗ ${command.split(' ')[0]}: not available`);
            } else {
                this.logger.info(`- ${command.split(' ')[0]}: not available (optional)`);
            }

            return { available: false, error: error.message };
        }
    }

    /**
     * Print diagnostic summary
     * @param {Object} results - Diagnostic results
     */
    printSummary(results) {
        this.logger.print('');
        this.logger.print(chalk.blue('📋 Diagnostic Summary'));
        this.logger.print(chalk.gray('━'.repeat(40)));

        let issues = 0;
        let warnings = 0;

        // System issues
        if (!results.dependencies.node?.available) {
            this.logger.error('CRITICAL: Node.js not found');
            issues++;
        }

        if (!results.dependencies.hugo?.available) {
            this.logger.error('CRITICAL: Hugo not found');
            issues++;
        }

        if (!results.project.exists) {
            this.logger.error('CRITICAL: Project directory not found');
            issues++;
        }

        // Warnings
        if (!results.dependencies.git?.available) {
            this.logger.warn('WARNING: Git not available');
            warnings++;
        }

        if (results.project.git?.hasChanges) {
            this.logger.warn('WARNING: Uncommitted changes in git repository');
            warnings++;
        }

        // Performance issues
        if (results.performance.memory.heapUsed > 500 * 1024 * 1024) { // 500MB
            this.logger.warn('WARNING: High memory usage');
            warnings++;
        }

        // Summary
        this.logger.print('');
        if (issues === 0 && warnings === 0) {
            this.logger.success('🎉 All checks passed - System is ready!');
        } else if (issues === 0) {
            this.logger.warn(`⚠️  ${warnings} warnings found - System is mostly ready`);
        } else {
            this.logger.error(`💥 ${issues} critical issues and ${warnings} warnings found`);
        }

        // Performance summary
        this.performance.printReport();
    }
}

// Command-line interface
if (require.main === module) {
    const args = process.argv.slice(2);

    const options = {
        verbose: args.includes('--verbose') || args.includes('-v'),
        logFile: null
    };

    // Parse log file option
    const logFileIndex = args.findIndex(arg => arg === '--log-file');
    if (logFileIndex !== -1 && logFileIndex + 1 < args.length) {
        options.logFile = args[logFileIndex + 1];
    }

    if (args.includes('--help')) {
        console.log(`
Usage: node diagnostic.js [OPTIONS]

Options:
    --verbose, -v       Enable verbose output
    --log-file <path>   Write detailed log to file
    --help              Show this help

Examples:
    node diagnostic.js                    # Run basic diagnostic
    node diagnostic.js --verbose          # Run with verbose output
    node diagnostic.js --log-file diag.log  # Save detailed log
`);
        process.exit(0);
    }

    async function runDiagnostic() {
        const logger = createLogger({
            level: options.verbose ? 'DEBUG' : 'INFO',
            logFile: options.logFile,
            timestamp: true
        });

        const diagnostic = new SystemDiagnostic({ logger });

        try {
            const results = await diagnostic.runComplete();

            // Exit with appropriate code
            const hasErrors = !results.dependencies.node?.available ||
                             !results.dependencies.hugo?.available ||
                             !results.project.exists;

            process.exit(hasErrors ? 1 : 0);
        } catch (error) {
            logger.error('Diagnostic failed:', error.message);
            process.exit(1);
        }
    }

    runDiagnostic();
}

module.exports = { SystemDiagnostic };