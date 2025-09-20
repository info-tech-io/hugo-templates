/**
 * Unit Tests for CLI Components
 * Hugo Template Factory Framework - Stage 4.1
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

describe('CLI Components', () => {
    const testDir = path.join(__dirname, '../../');
    const scriptsDir = path.join(testDir, 'scripts');

    beforeAll(() => {
        // Ensure we're in the right directory
        expect(fs.existsSync(scriptsDir)).toBe(true);
    });

    describe('build.sh script', () => {
        const buildScript = path.join(scriptsDir, 'build.sh');

        test('should exist and be executable', () => {
            expect(fs.existsSync(buildScript)).toBe(true);
            const stats = fs.statSync(buildScript);
            expect(stats.mode & parseInt('111', 8)).toBeTruthy(); // Check executable bits
        });

        test('should show help when called with --help', () => {
            const output = execSync(`${buildScript} --help`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 10000
            });
            expect(output).toContain('Usage:');
            expect(output).toContain('--template');
            expect(output).toContain('--theme');
        });

        test('should validate parameters correctly', () => {
            // Test with invalid template
            expect(() => {
                execSync(`${buildScript} --template=invalid-template --validate-only`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 10000
                });
            }).toThrow();
        });

        test('should accept valid template combinations', () => {
            // Test minimal template validation
            const output = execSync(`${buildScript} --template=minimal --validate-only --verbose`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 10000
            });
            expect(output).toContain('SUCCESS') || expect(output).toContain('✓');
        });
    });

    describe('factory.js Node.js wrapper', () => {
        const factoryScript = path.join(scriptsDir, 'factory.js');

        test('should exist and be executable', () => {
            expect(fs.existsSync(factoryScript)).toBe(true);
        });

        test('should show version information', () => {
            const output = execSync(`node ${factoryScript} --version`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 5000
            });
            expect(output).toMatch(/\d+\.\d+\.\d+/); // Version pattern
        });

        test('should handle help flag correctly', () => {
            const output = execSync(`node ${factoryScript} --help`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 5000
            });
            expect(output).toContain('Usage:');
            expect(output).toContain('Options:');
        });
    });

    describe('validate.js utility', () => {
        const validateScript = path.join(scriptsDir, 'validate.js');

        test('should exist and be executable', () => {
            expect(fs.existsSync(validateScript)).toBe(true);
        });

        test('should validate existing templates', () => {
            const output = execSync(`node ${validateScript} --template default`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 10000
            });
            expect(output).toContain('SUCCESS') || expect(output).toContain('✓');
        });

        test('should detect invalid template structure', () => {
            // This should fail gracefully for non-existent templates
            expect(() => {
                execSync(`node ${validateScript} --template non-existent-template`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 5000,
                    stdio: 'pipe'
                });
            }).toThrow();
        });
    });

    describe('list.js utility', () => {
        const listScript = path.join(scriptsDir, 'list.js');

        test('should exist and be executable', () => {
            expect(fs.existsSync(listScript)).toBe(true);
        });

        test('should list available templates', () => {
            const output = execSync(`node ${listScript} templates`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 5000
            });
            expect(output).toContain('default') || expect(output).toContain('minimal');
        });

        test('should list available themes', () => {
            const output = execSync(`node ${listScript} themes`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 5000
            });
            expect(output).toContain('compose');
        });

        test('should support JSON output format', () => {
            const output = execSync(`node ${listScript} templates --format json`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 5000
            });
            expect(() => JSON.parse(output)).not.toThrow();
        });
    });

    describe('generate.js utility', () => {
        const generateScript = path.join(scriptsDir, 'generate.js');

        test('should exist and be executable', () => {
            expect(fs.existsSync(generateScript)).toBe(true);
        });

        test('should show help for template generation', () => {
            const output = execSync(`node ${generateScript} --help`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 5000
            });
            expect(output).toContain('Usage:');
            expect(output).toContain('template');
        });
    });

    describe('diagnostic.js system', () => {
        const diagnosticScript = path.join(scriptsDir, 'diagnostic.js');

        test('should exist and be executable', () => {
            expect(fs.existsSync(diagnosticScript)).toBe(true);
        });

        test('should run system diagnostics', () => {
            const output = execSync(`node ${diagnosticScript}`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 15000
            });
            expect(output).toContain('System Diagnostics');
        });

        test('should check required dependencies', () => {
            const output = execSync(`node ${diagnosticScript} --verbose`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 15000
            });
            expect(output).toContain('Node.js') || expect(output).toContain('dependencies');
        });
    });
});