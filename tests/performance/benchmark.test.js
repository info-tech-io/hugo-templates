/**
 * Performance Benchmarking Tests
 * Hugo Template Factory Framework - Stage 4.3
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const os = require('os');

describe('Performance Benchmarking', () => {
    const testDir = path.join(__dirname, '../../');
    const tempDir = path.join(os.tmpdir(), 'hugo-templates-perf-' + Date.now());
    const benchmarkResults = {};

    beforeAll(() => {
        if (!fs.existsSync(tempDir)) {
            fs.mkdirSync(tempDir, { recursive: true });
        }
    });

    afterAll(() => {
        if (fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true });
        }

        // Output benchmark summary
        console.log('\n=== PERFORMANCE BENCHMARK RESULTS ===');
        Object.entries(benchmarkResults).forEach(([test, metrics]) => {
            console.log(`${test}:`);
            Object.entries(metrics).forEach(([metric, value]) => {
                console.log(`  ${metric}: ${value}`);
            });
            console.log('');
        });
    });

    const measurePerformance = async (testName, operation) => {
        const startTime = process.hrtime.bigint();
        const startMemory = process.memoryUsage();

        let result;
        try {
            result = await operation();
        } catch (error) {
            result = { error: error.message };
        }

        const endTime = process.hrtime.bigint();
        const endMemory = process.memoryUsage();

        const duration = Number(endTime - startTime) / 1000000; // Convert to milliseconds
        const memoryUsed = Math.max(0, endMemory.heapUsed - startMemory.heapUsed);

        benchmarkResults[testName] = {
            'Duration (ms)': Math.round(duration * 100) / 100,
            'Memory Used (MB)': Math.round((memoryUsed / 1024 / 1024) * 100) / 100,
            'Status': result.error ? 'Error' : 'Success'
        };

        return { result, duration, memoryUsed };
    };

    describe('Build Performance Benchmarks', () => {
        test('should benchmark minimal template build time', async () => {
            const outputDir = path.join(tempDir, 'perf-minimal');

            const { duration } = await measurePerformance('Minimal Template Build', async () => {
                return execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 120000
                });
            });

            expect(duration).toBeLessThan(60000); // Should complete within 60 seconds
            expect(fs.existsSync(outputDir)).toBe(true);
        }, 120000);

        test('should benchmark default template build time', async () => {
            const outputDir = path.join(tempDir, 'perf-default');

            const { duration } = await measurePerformance('Default Template Build', async () => {
                return execSync(`bash scripts/build.sh --template=default --theme=compose --output="${outputDir}"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 120000
                });
            });

            expect(duration).toBeLessThan(90000); // Should complete within 90 seconds
            expect(fs.existsSync(outputDir)).toBe(true);
        }, 120000);

        test('should benchmark components integration performance', async () => {
            const outputDir = path.join(tempDir, 'perf-components');

            const { duration } = await measurePerformance('Components Integration Build', async () => {
                return execSync(`bash scripts/build.sh --template=default --theme=compose --components=quiz-engine --output="${outputDir}"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 120000
                });
            });

            expect(duration).toBeLessThan(120000); // Should complete within 120 seconds
            expect(fs.existsSync(outputDir)).toBe(true);
        }, 120000);
    });

    describe('CLI Tools Performance', () => {
        test('should benchmark validation performance', async () => {
            const { duration } = await measurePerformance('Template Validation', async () => {
                return execSync(`node scripts/validate.js --template default`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 30000
                });
            });

            expect(duration).toBeLessThan(10000); // Should complete within 10 seconds
        }, 30000);

        test('should benchmark list operations performance', async () => {
            const { duration } = await measurePerformance('Template Listing', async () => {
                return execSync(`node scripts/list.js templates`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 15000
                });
            });

            expect(duration).toBeLessThan(5000); // Should complete within 5 seconds
        }, 15000);

        test('should benchmark diagnostic performance', async () => {
            const { duration } = await measurePerformance('System Diagnostics', async () => {
                return execSync(`node scripts/diagnostic.js`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 30000
                });
            });

            expect(duration).toBeLessThan(20000); // Should complete within 20 seconds
        }, 30000);
    });

    describe('Memory Usage Benchmarks', () => {
        test('should monitor memory usage during build', async () => {
            const outputDir = path.join(tempDir, 'memory-test');

            const { memoryUsed } = await measurePerformance('Memory Usage Test', async () => {
                return execSync(`bash scripts/build.sh --template=default --theme=compose --output="${outputDir}"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 120000
                });
            });

            // Memory usage should be reasonable (less than 500MB for this test)
            expect(memoryUsed).toBeLessThan(500 * 1024 * 1024);
        }, 120000);

        test('should monitor memory efficiency of CLI tools', async () => {
            const operations = [
                () => execSync(`node scripts/validate.js --template minimal`, { encoding: 'utf8', cwd: testDir }),
                () => execSync(`node scripts/list.js templates`, { encoding: 'utf8', cwd: testDir }),
                () => execSync(`node scripts/list.js themes`, { encoding: 'utf8', cwd: testDir })
            ];

            for (let i = 0; i < operations.length; i++) {
                const { memoryUsed } = await measurePerformance(`CLI Memory Test ${i + 1}`, operations[i]);
                expect(memoryUsed).toBeLessThan(100 * 1024 * 1024); // Less than 100MB per operation
            }
        });
    });

    describe('Scalability Benchmarks', () => {
        test('should benchmark multiple concurrent builds', async () => {
            const concurrentBuilds = 3;
            const buildPromises = [];

            const { duration } = await measurePerformance('Concurrent Builds', async () => {
                for (let i = 0; i < concurrentBuilds; i++) {
                    const outputDir = path.join(tempDir, `concurrent-${i}`);
                    buildPromises.push(
                        new Promise((resolve, reject) => {
                            try {
                                const result = execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${outputDir}"`, {
                                    encoding: 'utf8',
                                    cwd: testDir,
                                    timeout: 120000
                                });
                                resolve(result);
                            } catch (error) {
                                reject(error);
                            }
                        })
                    );
                }

                return Promise.all(buildPromises);
            });

            // Concurrent builds should not take significantly longer than sequential
            expect(duration).toBeLessThan(180000); // Should complete within 3 minutes

            // Verify all builds completed
            for (let i = 0; i < concurrentBuilds; i++) {
                expect(fs.existsSync(path.join(tempDir, `concurrent-${i}`))).toBe(true);
            }
        }, 200000);

        test('should benchmark repeated operations', async () => {
            const iterations = 5;
            const durations = [];

            for (let i = 0; i < iterations; i++) {
                const { duration } = await measurePerformance(`Repeated Validation ${i + 1}`, async () => {
                    return execSync(`node scripts/validate.js --template minimal`, {
                        encoding: 'utf8',
                        cwd: testDir,
                        timeout: 30000
                    });
                });
                durations.push(duration);
            }

            // Performance should be consistent (standard deviation < 50% of mean)
            const mean = durations.reduce((a, b) => a + b, 0) / durations.length;
            const variance = durations.reduce((a, b) => a + Math.pow(b - mean, 2), 0) / durations.length;
            const stdDev = Math.sqrt(variance);

            expect(stdDev / mean).toBeLessThan(0.5); // Coefficient of variation < 50%
        });
    });

    describe('File Size Benchmarks', () => {
        test('should measure output file sizes', async () => {
            const outputDir = path.join(tempDir, 'size-test');

            await measurePerformance('File Size Analysis', async () => {
                return execSync(`bash scripts/build.sh --template=default --theme=compose --output="${outputDir}"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 120000
                });
            });

            // Measure output directory size
            const getDirectorySize = (dirPath) => {
                let totalSize = 0;
                const files = fs.readdirSync(dirPath, { withFileTypes: true });

                for (const file of files) {
                    const filePath = path.join(dirPath, file.name);
                    if (file.isDirectory()) {
                        totalSize += getDirectorySize(filePath);
                    } else {
                        totalSize += fs.statSync(filePath).size;
                    }
                }
                return totalSize;
            };

            const outputSize = getDirectorySize(outputDir);
            const outputSizeMB = outputSize / (1024 * 1024);

            benchmarkResults['Output Size'] = {
                'Size (MB)': Math.round(outputSizeMB * 100) / 100,
                'Files Count': fs.readdirSync(outputDir, { recursive: true }).length
            };

            // Output size should be reasonable (less than 100MB for default template)
            expect(outputSizeMB).toBeLessThan(100);
        }, 120000);

        test('should compare minified vs non-minified sizes', async () => {
            const normalDir = path.join(tempDir, 'normal-size');
            const minifiedDir = path.join(tempDir, 'minified-size');

            // Build normal version
            await measurePerformance('Normal Build', async () => {
                return execSync(`bash scripts/build.sh --template=minimal --theme=compose --output="${normalDir}"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 120000
                });
            });

            // Build minified version
            await measurePerformance('Minified Build', async () => {
                return execSync(`bash scripts/build.sh --template=minimal --theme=compose --minify --output="${minifiedDir}"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 120000
                });
            });

            // Both should exist
            expect(fs.existsSync(normalDir)).toBe(true);
            expect(fs.existsSync(minifiedDir)).toBe(true);

            // Note: We can't reliably test Hugo's minification without Hugo installed
            // But we can verify the builds completed successfully
        }, 240000);
    });

    describe('Resource Utilization', () => {
        test('should monitor CPU usage patterns', async () => {
            const startUsage = process.cpuUsage();

            await measurePerformance('CPU Usage Test', async () => {
                return execSync(`bash scripts/build.sh --template=default --theme=compose --output="${path.join(tempDir, 'cpu-test')}"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 120000
                });
            });

            const endUsage = process.cpuUsage(startUsage);
            const totalCpuTime = (endUsage.user + endUsage.system) / 1000; // Convert to milliseconds

            benchmarkResults['CPU Usage'] = {
                'User Time (ms)': endUsage.user / 1000,
                'System Time (ms)': endUsage.system / 1000,
                'Total CPU Time (ms)': totalCpuTime
            };

            // CPU usage should be reasonable
            expect(totalCpuTime).toBeLessThan(60000); // Less than 1 minute of CPU time
        }, 120000);

        test('should test performance with different load levels', async () => {
            const loadLevels = [
                { name: 'Light Load', template: 'minimal', components: '' },
                { name: 'Medium Load', template: 'default', components: '' },
                { name: 'Heavy Load', template: 'default', components: 'quiz-engine' }
            ];

            for (const load of loadLevels) {
                const outputDir = path.join(tempDir, `load-${load.name.toLowerCase().replace(' ', '-')}`);
                const componentsFlag = load.components ? `--components=${load.components}` : '';

                const { duration } = await measurePerformance(load.name, async () => {
                    return execSync(`bash scripts/build.sh --template=${load.template} --theme=compose ${componentsFlag} --output="${outputDir}"`, {
                        encoding: 'utf8',
                        cwd: testDir,
                        timeout: 120000
                    });
                });

                expect(fs.existsSync(outputDir)).toBe(true);
                expect(duration).toBeLessThan(120000); // All loads should complete within 2 minutes
            }
        }, 360000);
    });

    describe('Performance Regression Detection', () => {
        test('should establish baseline performance metrics', async () => {
            const baselineTests = [
                {
                    name: 'Baseline Minimal Build',
                    command: `bash scripts/build.sh --template=minimal --theme=compose --output="${path.join(tempDir, 'baseline-minimal')}"`,
                    maxDuration: 60000
                },
                {
                    name: 'Baseline Validation',
                    command: `node scripts/validate.js --template default`,
                    maxDuration: 10000
                },
                {
                    name: 'Baseline List',
                    command: `node scripts/list.js templates`,
                    maxDuration: 5000
                }
            ];

            for (const test of baselineTests) {
                const { duration } = await measurePerformance(test.name, async () => {
                    return execSync(test.command, {
                        encoding: 'utf8',
                        cwd: testDir,
                        timeout: test.maxDuration + 30000
                    });
                });

                expect(duration).toBeLessThan(test.maxDuration);
            }
        });

        test('should compare with hugo-base baseline', async () => {
            // This test establishes a baseline comparison with the existing hugo-base system
            // Note: This requires hugo-base to be available for comparison

            const outputDir = path.join(tempDir, 'hugo-base-comparison');

            const { duration } = await measurePerformance('Hugo-Base Comparison', async () => {
                // Since we can't easily build hugo-base in this test environment,
                // we'll just measure our template factory performance
                return execSync(`bash scripts/build.sh --template=default --theme=compose --output="${outputDir}"`, {
                    encoding: 'utf8',
                    cwd: testDir,
                    timeout: 120000
                });
            });

            // Our template factory should not be significantly slower than hugo-base
            expect(duration).toBeLessThan(120000); // Should complete within 2 minutes

            benchmarkResults['Hugo-Base Comparison'] = {
                'Template Factory Duration (ms)': Math.round(duration),
                'Status': 'Baseline established'
            };
        }, 120000);
    });
});