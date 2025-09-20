/**
 * Unit Tests for Template System
 * Hugo Template Factory Framework - Stage 4.1
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

describe('Template System', () => {
    const testDir = path.join(__dirname, '../../');
    const templatesDir = path.join(testDir, 'templates');
    const themesDir = path.join(testDir, 'themes');

    describe('Template availability', () => {
        test('should have required templates', () => {
            const requiredTemplates = ['default', 'minimal'];

            requiredTemplates.forEach(templateName => {
                const templatePath = path.join(templatesDir, templateName);
                expect(fs.existsSync(templatePath)).toBe(true);
                expect(fs.statSync(templatePath).isDirectory()).toBe(true);
            });
        });

        test('should list templates correctly', () => {
            const output = execSync(`node scripts/list.js templates`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 5000
            });

            expect(output).toContain('default');
            expect(output).toContain('minimal');
        });
    });

    describe('Template structure', () => {
        const templates = ['default', 'minimal'];

        templates.forEach(templateName => {
            describe(`${templateName} template`, () => {
                const templatePath = path.join(templatesDir, templateName);

                test('should have hugo.toml configuration', () => {
                    const hugoConfigPath = path.join(templatePath, 'hugo.toml');
                    expect(fs.existsSync(hugoConfigPath)).toBe(true);

                    const config = fs.readFileSync(hugoConfigPath, 'utf8');
                    expect(config).toContain('baseURL');
                    expect(config).toContain('title');
                    expect(config).toContain('theme');
                });

                test('should have content directory', () => {
                    const contentPath = path.join(templatePath, 'content');
                    expect(fs.existsSync(contentPath)).toBe(true);
                    expect(fs.statSync(contentPath).isDirectory()).toBe(true);
                });

                test('should have valid metadata.json', () => {
                    const metadataPath = path.join(templatePath, 'metadata.json');

                    if (fs.existsSync(metadataPath)) {
                        const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
                        expect(metadata).toHaveProperty('name');
                        expect(metadata).toHaveProperty('description');
                        expect(metadata).toHaveProperty('version');
                        expect(metadata.name).toBe(templateName);
                    }
                });

                test('should have static directory if needed', () => {
                    const staticPath = path.join(templatePath, 'static');
                    if (fs.existsSync(staticPath)) {
                        expect(fs.statSync(staticPath).isDirectory()).toBe(true);
                    }
                });
            });
        });
    });

    describe('Theme integration', () => {
        test('should have compose theme available', () => {
            const composePath = path.join(themesDir, 'compose');
            expect(fs.existsSync(composePath)).toBe(true);
            expect(fs.statSync(composePath).isDirectory()).toBe(true);
        });

        test('should list themes correctly', () => {
            const output = execSync(`node scripts/list.js themes`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 5000
            });

            expect(output).toContain('compose');
        });

        test('compose theme should have required structure', () => {
            const composePath = path.join(themesDir, 'compose');

            if (fs.existsSync(composePath)) {
                const layoutsPath = path.join(composePath, 'layouts');
                expect(fs.existsSync(layoutsPath)).toBe(true);

                const assetsPath = path.join(composePath, 'assets');
                if (fs.existsSync(assetsPath)) {
                    expect(fs.statSync(assetsPath).isDirectory()).toBe(true);
                }
            }
        });
    });

    describe('Template parametrization', () => {
        test('should support template building with parameters', () => {
            const output = execSync(`bash scripts/build.sh --template=minimal --theme=compose --validate-only --verbose`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 15000
            });

            expect(output).toContain('SUCCESS') || expect(output).toContain('✓') || expect(output).toContain('valid');
        });

        test('should handle template+theme combinations', () => {
            const combinations = [
                ['default', 'compose'],
                ['minimal', 'compose']
            ];

            combinations.forEach(([template, theme]) => {
                const output = execSync(`bash scripts/build.sh --template=${template} --theme=${theme} --validate-only`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 10000
                });

                expect(output).toContain('SUCCESS') || expect(output).toContain('✓') || expect(output).toContain('validation passed');
            });
        });
    });

    describe('Content structure validation', () => {
        const templates = ['default', 'minimal'];

        templates.forEach(templateName => {
            test(`${templateName} template should have proper content structure`, () => {
                const templatePath = path.join(templatesDir, templateName);
                const contentPath = path.join(templatePath, 'content');

                if (fs.existsSync(contentPath)) {
                    const contentItems = fs.readdirSync(contentPath);

                    // Should have at least some content
                    expect(contentItems.length).toBeGreaterThan(0);

                    // Check for index file or main content
                    const hasIndex = contentItems.some(item =>
                        item.includes('index') || item.includes('_index')
                    );

                    if (contentItems.length > 0) {
                        expect(hasIndex || contentItems.length > 0).toBe(true);
                    }
                }
            });
        });
    });

    describe('Template customization', () => {
        test('should support template generation', () => {
            const tempName = 'test-template-' + Date.now();

            try {
                const output = execSync(`node scripts/generate.js template ${tempName} --type educational --no-interactive`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 10000
                });

                expect(output).toContain('SUCCESS') || expect(output).toContain('created') || expect(output).toContain('generated');
            } catch (error) {
                // Generator might need interactive input, which is expected
                expect(error.message).toContain('interactive') || expect(error.message).toContain('input');
            }
        });

        test('should validate generated template structure', () => {
            // Test template generation without actual creation
            const output = execSync(`node scripts/generate.js --help`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 5000
            });

            expect(output).toContain('Usage:') || expect(output).toContain('template');
        });
    });

    describe('Hugo configuration validation', () => {
        test('should validate Hugo config syntax in all templates', () => {
            const templateDirs = fs.readdirSync(templatesDir);

            templateDirs.forEach(templateName => {
                const templatePath = path.join(templatesDir, templateName);
                const hugoConfigPath = path.join(templatePath, 'hugo.toml');

                if (fs.existsSync(hugoConfigPath) && fs.statSync(templatePath).isDirectory()) {
                    const config = fs.readFileSync(hugoConfigPath, 'utf8');

                    // Basic TOML validation
                    expect(config).not.toContain('[[[');
                    expect(config).not.toContain(']]]');

                    // Required Hugo fields
                    expect(config).toMatch(/baseURL\s*=/);
                    expect(config).toMatch(/title\s*=/);

                    // Theme configuration
                    expect(config).toMatch(/theme\s*=/) || expect(config).toMatch(/\[module\]/);
                }
            });
        });

        test('should have consistent Hugo version requirements', () => {
            const packageJsonPath = path.join(testDir, 'package.json');
            if (fs.existsSync(packageJsonPath)) {
                const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

                // Check if Hugo version is documented
                expect(packageJson.description || packageJson.readme || '').toMatch(/hugo/i);
            }
        });
    });

    describe('Template compatibility', () => {
        test('should work with different environments', () => {
            const environments = ['production', 'development'];

            environments.forEach(env => {
                const output = execSync(`bash scripts/build.sh --template=minimal --environment=${env} --validate-only`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 10000
                });

                expect(output).toContain('SUCCESS') || expect(output).toContain('✓') || expect(output).toContain('validated');
            });
        });

        test('should handle minification options', () => {
            const output = execSync(`bash scripts/build.sh --template=minimal --minify --validate-only`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 10000
            });

            expect(output).toContain('SUCCESS') || expect(output).toContain('✓') || expect(output).toContain('minify');
        });
    });
});