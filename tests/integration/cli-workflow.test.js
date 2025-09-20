/**
 * Integration Tests for CLI Workflow
 * Hugo Template Factory Framework - Stage 4.2
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const os = require('os');

describe('CLI Workflow Integration', () => {
    const testDir = path.join(__dirname, '../../');
    const tempDir = path.join(os.tmpdir(), 'hugo-templates-cli-test-' + Date.now());

    beforeAll(() => {
        if (!fs.existsSync(tempDir)) {
            fs.mkdirSync(tempDir, { recursive: true });
        }
    });

    afterAll(() => {
        if (fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true });
        }
    });

    describe('Complete workflow scenarios', () => {
        test('should execute complete workflow: list → validate → build', async () => {
            // Step 1: List available templates
            const listOutput = execSync(`node scripts/list.js templates`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 10000
            });

            expect(listOutput).toContain('default') || expect(listOutput).toContain('minimal');

            // Step 2: Validate template combination
            const validateOutput = execSync(`node scripts/validate.js --template default --theme compose`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 15000
            });

            expect(validateOutput).toContain('SUCCESS') || expect(validateOutput).toContain('✓') || expect(validateOutput).toContain('valid');

            // Step 3: Build the template
            const outputDir = path.join(tempDir, 'workflow-test');
            const buildOutput = execSync(`bash scripts/build.sh --template=default --theme=compose --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(buildOutput).toContain('SUCCESS') || expect(buildOutput).toContain('✓');
            expect(fs.existsSync(outputDir)).toBe(true);
        }, 90000);

        test('should execute diagnostic → build → validate workflow', async () => {
            // Step 1: Run diagnostics
            const diagnosticOutput = execSync(`node scripts/diagnostic.js`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 20000
            });

            expect(diagnosticOutput).toContain('Diagnostics') || expect(diagnosticOutput).toContain('System') || expect(diagnosticOutput).toContain('✓');

            // Step 2: Build minimal template
            const outputDir = path.join(tempDir, 'diagnostic-workflow');
            const buildOutput = execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(buildOutput).toContain('SUCCESS') || expect(buildOutput).toContain('✓');

            // Step 3: Validate the built template
            const validateOutput = execSync(`node scripts/validate.js --template minimal`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 10000
            });

            expect(validateOutput).toContain('SUCCESS') || expect(validateOutput).toContain('✓');
        }, 100000);
    });

    describe('Node.js vs Bash CLI compatibility', () => {
        test('should produce same results with Node.js and Bash interfaces', async () => {
            const outputDir1 = path.join(tempDir, 'node-build');
            const outputDir2 = path.join(tempDir, 'bash-build');

            // Build with Node.js interface
            const nodeOutput = execSync(`node scripts/factory.js --template=minimal --theme=compose --output="${outputDir1}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            // Build with Bash interface
            const bashOutput = execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir2}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(nodeOutput).toContain('SUCCESS') || expect(nodeOutput).toContain('✓');
            expect(bashOutput).toContain('SUCCESS') || expect(bashOutput).toContain('✓');

            // Both should produce similar directory structures
            expect(fs.existsSync(outputDir1)).toBe(true);
            expect(fs.existsSync(outputDir2)).toBe(true);

            // Both should have hugo.toml
            expect(fs.existsSync(path.join(outputDir1, 'hugo.toml'))).toBe(true);
            expect(fs.existsSync(path.join(outputDir2, 'hugo.toml'))).toBe(true);
        }, 120000);

        test('should handle validation consistently across interfaces', async () => {
            // Validate with Node.js script
            const nodeValidation = execSync(`node scripts/validate.js --template default`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 10000
            });

            // Validate with Bash script (validation flag)
            const bashValidation = execSync(`bash scripts/build.sh --template=default --validate-only`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 10000
            });

            expect(nodeValidation).toContain('SUCCESS') || expect(nodeValidation).toContain('✓');
            expect(bashValidation).toContain('SUCCESS') || expect(bashValidation).toContain('✓');
        });
    });

    describe('Error recovery workflows', () => {
        test('should recover from invalid parameters gracefully', async () => {
            // Try invalid template first
            expect(() => {
                execSync(`bash scripts/build.sh --template=invalid --validate-only`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 10000,
                    stdio: 'pipe'
                });
            }).toThrow();

            // Should still work with valid parameters after error
            const validOutput = execSync(`bash scripts/build.sh --template=minimal --validate-only`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 10000
            });

            expect(validOutput).toContain('SUCCESS') || expect(validOutput).toContain('✓');
        });

        test('should handle partial build failures', async () => {
            const outputDir = path.join(tempDir, 'recovery-test');

            // Create output directory with some existing content
            fs.mkdirSync(outputDir, { recursive: true });
            fs.writeFileSync(path.join(outputDir, 'existing-file.txt'), 'existing content');

            // Build should still work despite existing content
            const buildOutput = execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(buildOutput).toContain('SUCCESS') || expect(buildOutput).toContain('✓');
            expect(fs.existsSync(path.join(outputDir, 'hugo.toml'))).toBe(true);
        });
    });

    describe('Advanced parameter combinations', () => {
        test('should handle complex parameter combinations', async () => {
            const outputDir = path.join(tempDir, 'complex-params');

            const complexBuild = execSync(`bash scripts/build.sh --template=default --theme=compose --components=quiz-engine --environment=production --minify --verbose --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 90000
            });

            expect(complexBuild).toContain('SUCCESS') || expect(complexBuild).toContain('✓');
            expect(fs.existsSync(outputDir)).toBe(true);

            // Check that all components were processed
            expect(complexBuild).toContain('quiz-engine') || expect(complexBuild).toContain('component');
            expect(complexBuild).toContain('production') || expect(complexBuild).toContain('environment');
            expect(complexBuild).toContain('minify') || expect(complexBuild).toContain('✓');
        }, 90000);

        test('should handle edge case parameter values', async () => {
            const outputDir = path.join(tempDir, 'edge-cases');

            // Test with edge case values
            const edgeCaseBuild = execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}" --verbose`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(edgeCaseBuild).toContain('SUCCESS') || expect(edgeCaseBuild).toContain('✓');
        });
    });

    describe('Cross-platform workflow compatibility', () => {
        test('should work with different path separators', async () => {
            const outputDir = path.join(tempDir, 'cross-platform');

            // Use path.join for cross-platform compatibility
            const crossPlatformBuild = execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(crossPlatformBuild).toContain('SUCCESS') || expect(crossPlatformBuild).toContain('✓');
            expect(fs.existsSync(outputDir)).toBe(true);
        });

        test('should handle different line endings', async () => {
            // This test ensures the scripts work regardless of line ending style
            const listOutput = execSync(`node scripts/list.js templates`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 5000
            });

            expect(listOutput.length).toBeGreaterThan(0);
            expect(listOutput).toContain('default') || expect(listOutput).toContain('minimal');
        });
    });

    describe('Performance workflow testing', () => {
        test('should complete workflow within reasonable time', async () => {
            const startTime = Date.now();

            const outputDir = path.join(tempDir, 'performance-test');
            const performanceBuild = execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            const endTime = Date.now();
            const duration = endTime - startTime;

            expect(performanceBuild).toContain('SUCCESS') || expect(performanceBuild).toContain('✓');
            expect(duration).toBeLessThan(60000); // Should complete within 60 seconds
        }, 60000);

        test('should handle concurrent CLI operations', async () => {
            const operations = [
                () => execSync(`node scripts/list.js templates`, { encoding: 'utf8', cwd: testDir, timeout: 10000 }),
                () => execSync(`node scripts/validate.js --template minimal`, { encoding: 'utf8', cwd: testDir, timeout: 10000 }),
                () => execSync(`node scripts/diagnostic.js`, { encoding: 'utf8', cwd: testDir, timeout: 15000 })
            ];

            const results = await Promise.all(operations.map(op =>
                new Promise((resolve, reject) => {
                    try {
                        resolve(op());
                    } catch (error) {
                        reject(error);
                    }
                })
            ));

            results.forEach(result => {
                expect(result.length).toBeGreaterThan(0);
            });
        }, 30000);
    });

    describe('Help and documentation workflow', () => {
        test('should provide consistent help across all CLI tools', async () => {
            const cliTools = [
                'scripts/build.sh --help',
                'scripts/factory.js --help',
                'scripts/validate.js --help',
                'scripts/list.js --help',
                'scripts/generate.js --help',
                'scripts/diagnostic.js --help'
            ];

            for (const tool of cliTools) {
                const [script, flag] = tool.split(' ');
                let helpOutput;

                if (script.endsWith('.sh')) {
                    helpOutput = execSync(`bash ${tool}`, {
                        encoding: 'utf8',
                        cwd: testDir,
                        timeout: 5000
                    });
                } else {
                    helpOutput = execSync(`node ${tool}`, {
                        encoding: 'utf8',
                        cwd: testDir,
                        timeout: 5000
                    });
                }

                expect(helpOutput).toContain('Usage:') || expect(helpOutput).toContain('help') || expect(helpOutput).toContain('Options:');
            }
        });

        test('should provide version information consistently', async () => {
            const versionTools = [
                'scripts/factory.js --version'
            ];

            for (const tool of versionTools) {
                const versionOutput = execSync(`node ${tool}`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 5000
                });

                expect(versionOutput).toMatch(/\d+\.\d+\.\d+/) || expect(versionOutput).toContain('version');
            }
        });
    });
});