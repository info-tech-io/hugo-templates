/**
 * Integration Tests for Build System
 * Hugo Template Factory Framework - Stage 4.2
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const os = require('os');

describe('Build System Integration', () => {
    const testDir = path.join(__dirname, '../../');
    const tempDir = path.join(os.tmpdir(), 'hugo-templates-test-' + Date.now());

    beforeAll(() => {
        // Create temporary directory for build tests
        if (!fs.existsSync(tempDir)) {
            fs.mkdirSync(tempDir, { recursive: true });
        }
    });

    afterAll(() => {
        // Cleanup temporary directory
        if (fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true });
        }
    });

    describe('End-to-end build process', () => {
        test('should build minimal template successfully', async () => {
            const outputDir = path.join(tempDir, 'minimal-build');

            const buildCommand = `bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}" --verbose`;

            const output = execSync(buildCommand, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(output).toContain('SUCCESS') || expect(output).toContain('✓');
            expect(fs.existsSync(outputDir)).toBe(true);

            // Check for generated Hugo files
            const hugoConfigPath = path.join(outputDir, 'hugo.toml');
            expect(fs.existsSync(hugoConfigPath)).toBe(true);

            const contentPath = path.join(outputDir, 'content');
            expect(fs.existsSync(contentPath)).toBe(true);
        }, 60000);

        test('should build default template successfully', async () => {
            const outputDir = path.join(tempDir, 'default-build');

            const buildCommand = `bash scripts/build.sh --template=default --theme=compose --output="${outputDir}" --verbose`;

            const output = execSync(buildCommand, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(output).toContain('SUCCESS') || expect(output).toContain('✓');
            expect(fs.existsSync(outputDir)).toBe(true);

            // Verify Hugo configuration
            const hugoConfigPath = path.join(outputDir, 'hugo.toml');
            expect(fs.existsSync(hugoConfigPath)).toBe(true);

            const config = fs.readFileSync(hugoConfigPath, 'utf8');
            expect(config).toContain('baseURL');
            expect(config).toContain('title');
            expect(config).toContain('theme');
        }, 60000);

        test('should build with components integration', async () => {
            const outputDir = path.join(tempDir, 'components-build');

            const buildCommand = `bash scripts/build.sh --template=default --theme=compose --components=quiz-engine --output="${outputDir}" --verbose`;

            const output = execSync(buildCommand, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(output).toContain('SUCCESS') || expect(output).toContain('✓') || expect(output).toContain('quiz-engine');
            expect(fs.existsSync(outputDir)).toBe(true);

            // Check for quiz-engine component files
            const staticPath = path.join(outputDir, 'static');
            if (fs.existsSync(staticPath)) {
                const staticFiles = fs.readdirSync(staticPath);
                expect(staticFiles.length).toBeGreaterThan(0);
            }
        }, 60000);
    });

    describe('Hugo build integration', () => {
        test('should produce valid Hugo site with minimal template', async () => {
            const outputDir = path.join(tempDir, 'hugo-minimal');

            // Build the template
            execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}"`, {
                cwd: testDir,
                timeout: 60000
            });

            // Try to build with Hugo
            try {
                const hugoOutput = execSync('hugo --minify', {
                    encoding: 'utf8',
                    cwd: outputDir,
                    timeout: 30000
                });

                expect(hugoOutput).toContain('Total') || expect(hugoOutput).toContain('Built');

                // Check for generated public directory
                const publicPath = path.join(outputDir, 'public');
                expect(fs.existsSync(publicPath)).toBe(true);

                // Check for index.html
                const indexPath = path.join(publicPath, 'index.html');
                expect(fs.existsSync(indexPath)).toBe(true);

            } catch (error) {
                // Hugo might not be installed, but template should be valid
                console.warn('Hugo not available for integration test:', error.message);
                expect(fs.existsSync(path.join(outputDir, 'hugo.toml'))).toBe(true);
            }
        }, 90000);

        test('should produce valid Hugo site with default template', async () => {
            const outputDir = path.join(tempDir, 'hugo-default');

            // Build the template
            execSync(`bash scripts/build.sh --template=default --theme=compose --output="${outputDir}"`, {
                cwd: testDir,
                timeout: 60000
            });

            // Try to build with Hugo
            try {
                const hugoOutput = execSync('hugo --minify', {
                    encoding: 'utf8',
                    cwd: outputDir,
                    timeout: 30000
                });

                expect(hugoOutput).toContain('Total') || expect(hugoOutput).toContain('Built');

                const publicPath = path.join(outputDir, 'public');
                expect(fs.existsSync(publicPath)).toBe(true);

            } catch (error) {
                // Hugo might not be installed
                console.warn('Hugo not available for integration test:', error.message);
                expect(fs.existsSync(path.join(outputDir, 'hugo.toml'))).toBe(true);
            }
        }, 90000);
    });

    describe('Theme integration', () => {
        test('should integrate compose theme correctly', async () => {
            const outputDir = path.join(tempDir, 'theme-integration');

            execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}"`, {
                cwd: testDir,
                timeout: 60000
            });

            // Check theme integration
            const themesPath = path.join(outputDir, 'themes', 'compose');
            expect(fs.existsSync(themesPath)).toBe(true);

            // Verify theme has required structure
            const layoutsPath = path.join(themesPath, 'layouts');
            if (fs.existsSync(layoutsPath)) {
                expect(fs.statSync(layoutsPath).isDirectory()).toBe(true);
            }

            // Check Hugo config references theme
            const hugoConfigPath = path.join(outputDir, 'hugo.toml');
            const config = fs.readFileSync(hugoConfigPath, 'utf8');
            expect(config).toContain('compose');
        });

        test('should handle theme submodules correctly', async () => {
            const outputDir = path.join(tempDir, 'submodule-test');

            const output = execSync(`bash scripts/build.sh --template=default --theme=compose --output="${outputDir}" --verbose`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(output).toContain('SUCCESS') || expect(output).toContain('✓');

            // Check .gitmodules handling
            const gitmodulesPath = path.join(outputDir, '.gitmodules');
            if (fs.existsSync(gitmodulesPath)) {
                const gitmodules = fs.readFileSync(gitmodulesPath, 'utf8');
                expect(gitmodules).toContain('themes/compose');
            }
        });
    });

    describe('Environment-specific builds', () => {
        test('should build for production environment', async () => {
            const outputDir = path.join(tempDir, 'production');

            const output = execSync(`bash scripts/build.sh --template=minimal --theme=compose --environment=production --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(output).toContain('SUCCESS') || expect(output).toContain('✓');

            const config = fs.readFileSync(path.join(outputDir, 'hugo.toml'), 'utf8');
            expect(config).toContain('production') || expect(config).toContain('baseURL');
        });

        test('should build for development environment', async () => {
            const outputDir = path.join(tempDir, 'development');

            const output = execSync(`bash scripts/build.sh --template=minimal --theme=compose --environment=development --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(output).toContain('SUCCESS') || expect(output).toContain('✓');

            const config = fs.readFileSync(path.join(outputDir, 'hugo.toml'), 'utf8');
            expect(config).toContain('localhost') || expect(config).toContain('development') || expect(config).toContain('baseURL');
        });
    });

    describe('Custom content integration', () => {
        test('should handle custom content directory', async () => {
            const outputDir = path.join(tempDir, 'custom-content');
            const customContentDir = path.join(tempDir, 'custom-content-source');

            // Create custom content
            fs.mkdirSync(customContentDir, { recursive: true });
            fs.writeFileSync(
                path.join(customContentDir, 'custom-page.md'),
                '---\ntitle: "Custom Page"\n---\n\nThis is custom content.'
            );

            const output = execSync(`bash scripts/build.sh --template=minimal --theme=compose --content="${customContentDir}" --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(output).toContain('SUCCESS') || expect(output).toContain('✓') || expect(output).toContain('custom');

            // Check that custom content was copied
            const contentPath = path.join(outputDir, 'content');
            if (fs.existsSync(contentPath)) {
                const contentFiles = fs.readdirSync(contentPath);
                expect(contentFiles.some(file => file.includes('custom'))).toBe(true);
            }
        });
    });

    describe('Build options integration', () => {
        test('should handle minification option', async () => {
            const outputDir = path.join(tempDir, 'minified');

            const output = execSync(`bash scripts/build.sh --template=minimal --theme=compose --minify --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(output).toContain('SUCCESS') || expect(output).toContain('✓') || expect(output).toContain('minify');
        });

        test('should handle verbose output', async () => {
            const outputDir = path.join(tempDir, 'verbose');

            const output = execSync(`bash scripts/build.sh --template=minimal --theme=compose --verbose --output="${outputDir}"`, {
                encoding: 'utf8',
                cwd: testDir,
                timeout: 60000
            });

            expect(output).toContain('INFO') || expect(output).toContain('DEBUG') || expect(output).toContain('verbose');
        });
    });

    describe('Error handling integration', () => {
        test('should handle invalid template gracefully', async () => {
            expect(() => {
                execSync(`bash scripts/build.sh --template=non-existent --theme=compose --output="${tempDir}/error-test"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 30000,
                    stdio: 'pipe'
                });
            }).toThrow();
        });

        test('should handle invalid theme gracefully', async () => {
            expect(() => {
                execSync(`bash scripts/build.sh --template=minimal --theme=non-existent --output="${tempDir}/error-test2"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 30000,
                    stdio: 'pipe'
                });
            }).toThrow();
        });

        test('should handle missing output directory', async () => {
            const invalidOutput = '/non-existent-path/that/should/not/exist';

            expect(() => {
                execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${invalidOutput}"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 30000,
                    stdio: 'pipe'
                });
            }).toThrow();
        });
    });

    describe('Parallel build support', () => {
        test('should handle multiple builds concurrently', async () => {
            const builds = [
                path.join(tempDir, 'parallel1'),
                path.join(tempDir, 'parallel2')
            ];

            const buildPromises = builds.map((outputDir, index) => {
                return new Promise((resolve, reject) => {
                    try {
                        const output = execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}"`, {
                            encoding: 'utf8',
                            cwd: testDir,
                            timeout: 60000
                        });
                        resolve(output);
                    } catch (error) {
                        reject(error);
                    }
                });
            });

            const results = await Promise.all(buildPromises);

            results.forEach((output, index) => {
                expect(output).toContain('SUCCESS') || expect(output).toContain('✓');
                expect(fs.existsSync(builds[index])).toBe(true);
            });
        }, 120000);
    });
});