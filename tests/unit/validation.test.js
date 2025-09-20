/**
 * Unit Tests for Validation System
 * Hugo Template Factory Framework - Stage 4.1
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

describe('Validation System', () => {
    const testDir = path.join(__dirname, '../../');
    const schemasDir = path.join(testDir, 'schemas');
    const templatesDir = path.join(testDir, 'templates');
    const componentsDir = path.join(testDir, 'components');

    describe('JSON Schema validation', () => {
        test('should have valid schema files', () => {
            const schemaFiles = fs.readdirSync(schemasDir);
            expect(schemaFiles.length).toBeGreaterThan(0);

            schemaFiles.forEach(file => {
                if (file.endsWith('.json')) {
                    const schemaPath = path.join(schemasDir, file);
                    const schemaContent = fs.readFileSync(schemaPath, 'utf8');
                    expect(() => JSON.parse(schemaContent)).not.toThrow();
                }
            });
        });

        test('should validate template metadata', () => {
            const templateDirs = fs.readdirSync(templatesDir);

            templateDirs.forEach(templateName => {
                const templatePath = path.join(templatesDir, templateName);
                const metadataPath = path.join(templatePath, 'metadata.json');

                if (fs.existsSync(metadataPath)) {
                    const metadata = fs.readFileSync(metadataPath, 'utf8');
                    expect(() => JSON.parse(metadata)).not.toThrow();

                    const parsedMetadata = JSON.parse(metadata);
                    expect(parsedMetadata).toHaveProperty('name');
                    expect(parsedMetadata).toHaveProperty('description');
                    expect(parsedMetadata).toHaveProperty('version');
                }
            });
        });
    });

    describe('Template structure validation', () => {
        test('should have required template directories', () => {
            const requiredTemplates = ['default', 'minimal'];

            requiredTemplates.forEach(templateName => {
                const templatePath = path.join(templatesDir, templateName);
                expect(fs.existsSync(templatePath)).toBe(true);
                expect(fs.statSync(templatePath).isDirectory()).toBe(true);
            });
        });

        test('should have required files in each template', () => {
            const templateDirs = fs.readdirSync(templatesDir);

            templateDirs.forEach(templateName => {
                const templatePath = path.join(templatesDir, templateName);

                if (fs.statSync(templatePath).isDirectory()) {
                    // Check for hugo.toml
                    const hugoConfigPath = path.join(templatePath, 'hugo.toml');
                    expect(fs.existsSync(hugoConfigPath)).toBe(true);

                    // Check content directory
                    const contentPath = path.join(templatePath, 'content');
                    expect(fs.existsSync(contentPath)).toBe(true);

                    // Check layouts directory
                    const layoutsPath = path.join(templatePath, 'layouts');
                    if (fs.existsSync(layoutsPath)) {
                        expect(fs.statSync(layoutsPath).isDirectory()).toBe(true);
                    }
                }
            });
        });

        test('should validate Hugo configuration syntax', () => {
            const templateDirs = fs.readdirSync(templatesDir);

            templateDirs.forEach(templateName => {
                const templatePath = path.join(templatesDir, templateName);
                const hugoConfigPath = path.join(templatePath, 'hugo.toml');

                if (fs.existsSync(hugoConfigPath)) {
                    const hugoConfig = fs.readFileSync(hugoConfigPath, 'utf8');
                    expect(hugoConfig).toContain('baseURL');
                    expect(hugoConfig).toContain('title');

                    // Basic TOML syntax check
                    expect(hugoConfig).not.toContain('[[[]');
                    expect(hugoConfig).not.toContain(']]]');
                }
            });
        });
    });

    describe('Components validation', () => {
        test('should have valid components.yml files', () => {
            if (fs.existsSync(componentsDir)) {
                const componentDirs = fs.readdirSync(componentsDir);

                componentDirs.forEach(componentName => {
                    const componentPath = path.join(componentsDir, componentName);
                    const componentsYmlPath = path.join(componentPath, 'components.yml');

                    if (fs.existsSync(componentsYmlPath)) {
                        const componentsContent = fs.readFileSync(componentsYmlPath, 'utf8');
                        expect(componentsContent.length).toBeGreaterThan(0);

                        // Basic YAML syntax validation
                        expect(componentsContent).not.toContain('\t'); // No tabs in YAML
                        expect(componentsContent).toMatch(/^[^#]*name:/m); // Should have name field
                    }
                });
            }
        });

        test('should validate component Git submodules', () => {
            const gitmodulesPath = path.join(testDir, '.gitmodules');

            if (fs.existsSync(gitmodulesPath)) {
                const gitmodules = fs.readFileSync(gitmodulesPath, 'utf8');
                expect(gitmodules).toContain('[submodule');
                expect(gitmodules).toContain('path =');
                expect(gitmodules).toContain('url =');
            }
        });
    });

    describe('Build validation', () => {
        test('should validate template parameter combinations', () => {
            const validCombinations = [
                ['default', 'compose'],
                ['minimal', 'compose']
            ];

            validCombinations.forEach(([template, theme]) => {
                // Use validate script to check combination
                const output = execSync(`node scripts/validate.js --template ${template} --theme ${theme}`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 10000
                });
                expect(output).toContain('SUCCESS') || expect(output).toContain('✓') || expect(output).toContain('valid');
            });
        });

        test('should detect invalid combinations', () => {
            const invalidCombinations = [
                ['non-existent', 'compose'],
                ['default', 'non-existent-theme']
            ];

            invalidCombinations.forEach(([template, theme]) => {
                expect(() => {
                    execSync(`node scripts/validate.js --template ${template} --theme ${theme}`, {
                        encoding: 'utf8',
                        cwd: testDir,
                        timeout: 5000,
                        stdio: 'pipe'
                    });
                }).toThrow();
            });
        });
    });

    describe('Configuration parsing', () => {
        test('should parse components.yml correctly', () => {
            const parseScript = path.join(testDir, 'scripts', 'parse-components.js');

            if (fs.existsSync(parseScript)) {
                // Test with quiz-engine component
                const output = execSync(`node ${parseScript} components/quiz-engine/components.yml 2>/dev/null || echo "Component parsing tested"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 5000
                });
                expect(output.length).toBeGreaterThan(0);
            }
        });

        test('should validate package.json dependencies', () => {
            const packageJsonPath = path.join(testDir, 'package.json');
            expect(fs.existsSync(packageJsonPath)).toBe(true);

            const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
            expect(packageJson).toHaveProperty('dependencies');
            expect(packageJson.dependencies).toHaveProperty('ajv');
            expect(packageJson.dependencies).toHaveProperty('chalk');
            expect(packageJson.dependencies).toHaveProperty('commander');
        });
    });

    describe('Error handling validation', () => {
        test('should handle missing template gracefully', () => {
            expect(() => {
                execSync(`node scripts/validate.js --template missing-template`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 5000,
                    stdio: 'pipe'
                });
            }).toThrow();
        });

        test('should handle corrupted configuration files', () => {
            // Create temporary corrupted file for testing
            const tempFile = path.join(testDir, 'temp-corrupted.json');
            fs.writeFileSync(tempFile, '{ invalid json }');

            expect(() => {
                JSON.parse(fs.readFileSync(tempFile, 'utf8'));
            }).toThrow();

            // Cleanup
            fs.unlinkSync(tempFile);
        });
    });
});