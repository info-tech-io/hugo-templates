#!/usr/bin/env node

/**
 * Hugo Template Factory Framework - Centralized Logging System
 * Provides consistent logging, progress tracking, and debugging capabilities
 */

const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');
const util = require('util');

/**
 * Log levels
 */
const LOG_LEVELS = {
    DEBUG: 0,
    INFO: 1,
    WARN: 2,
    ERROR: 3,
    QUIET: 4
};

/**
 * Logger class
 */
class Logger {
    constructor(options = {}) {
        this.level = LOG_LEVELS[options.level] || LOG_LEVELS.INFO;
        this.prefix = options.prefix || '';
        this.colors = options.colors !== false;
        this.timestamp = options.timestamp || false;
        this.logFile = options.logFile || null;
        this.context = options.context || {};

        // Initialize log file if specified
        if (this.logFile) {
            this.initLogFile();
        }
    }

    /**
     * Initialize log file
     */
    initLogFile() {
        try {
            const logDir = path.dirname(this.logFile);
            fs.ensureDirSync(logDir);

            // Write session header
            const header = `\n=== Hugo Template Factory Log Session ===\n` +
                          `Date: ${new Date().toISOString()}\n` +
                          `Level: ${Object.keys(LOG_LEVELS)[this.level]}\n` +
                          `Context: ${JSON.stringify(this.context)}\n` +
                          `${'='.repeat(50)}\n\n`;

            fs.appendFileSync(this.logFile, header);
        } catch (error) {
            console.error('Failed to initialize log file:', error.message);
        }
    }

    /**
     * Write to log file
     * @param {string} level - Log level
     * @param {string} message - Message to log
     * @param {Object} data - Additional data
     */
    writeToFile(level, message, data = {}) {
        if (!this.logFile) return;

        try {
            const timestamp = new Date().toISOString();
            const contextStr = Object.keys(this.context).length > 0 ?
                ` [${JSON.stringify(this.context)}]` : '';

            let logEntry = `[${timestamp}] ${level.toUpperCase()}${contextStr}: ${message}`;

            if (Object.keys(data).length > 0) {
                logEntry += `\n  Data: ${JSON.stringify(data, null, 2)}`;
            }

            logEntry += '\n';

            fs.appendFileSync(this.logFile, logEntry);
        } catch (error) {
            // Silently fail to avoid logging loops
        }
    }

    /**
     * Format message with timestamp and prefix
     * @param {string} message - Message to format
     */
    formatMessage(message) {
        let formatted = '';

        if (this.timestamp) {
            const now = new Date();
            const time = now.toTimeString().split(' ')[0];
            formatted += chalk.gray(`[${time}] `);
        }

        if (this.prefix) {
            formatted += chalk.gray(`[${this.prefix}] `);
        }

        formatted += message;
        return formatted;
    }

    /**
     * Debug level logging
     * @param {string} message - Debug message
     * @param {...any} args - Additional arguments
     */
    debug(message, ...args) {
        if (this.level > LOG_LEVELS.DEBUG) return;

        const formatted = this.formatMessage(
            this.colors ? chalk.gray(`🔍 ${message}`) : `🔍 ${message}`
        );

        console.log(formatted, ...args);
        this.writeToFile('debug', message, { args });
    }

    /**
     * Info level logging
     * @param {string} message - Info message
     * @param {...any} args - Additional arguments
     */
    info(message, ...args) {
        if (this.level > LOG_LEVELS.INFO) return;

        const formatted = this.formatMessage(
            this.colors ? chalk.blue(`ℹ️  ${message}`) : `ℹ️  ${message}`
        );

        console.log(formatted, ...args);
        this.writeToFile('info', message, { args });
    }

    /**
     * Success level logging
     * @param {string} message - Success message
     * @param {...any} args - Additional arguments
     */
    success(message, ...args) {
        if (this.level > LOG_LEVELS.INFO) return;

        const formatted = this.formatMessage(
            this.colors ? chalk.green(`✅ ${message}`) : `✅ ${message}`
        );

        console.log(formatted, ...args);
        this.writeToFile('success', message, { args });
    }

    /**
     * Warning level logging
     * @param {string} message - Warning message
     * @param {...any} args - Additional arguments
     */
    warn(message, ...args) {
        if (this.level > LOG_LEVELS.WARN) return;

        const formatted = this.formatMessage(
            this.colors ? chalk.yellow(`⚠️  ${message}`) : `⚠️  ${message}`
        );

        console.log(formatted, ...args);
        this.writeToFile('warn', message, { args });
    }

    /**
     * Error level logging
     * @param {string} message - Error message
     * @param {...any} args - Additional arguments
     */
    error(message, ...args) {
        if (this.level > LOG_LEVELS.ERROR) return;

        const formatted = this.formatMessage(
            this.colors ? chalk.red(`❌ ${message}`) : `❌ ${message}`
        );

        console.error(formatted, ...args);
        this.writeToFile('error', message, { args });
    }

    /**
     * Always print regardless of log level
     * @param {string} message - Message to print
     * @param {...any} args - Additional arguments
     */
    print(message, ...args) {
        const formatted = this.formatMessage(message);
        console.log(formatted, ...args);
        this.writeToFile('print', message, { args });
    }

    /**
     * Create a child logger with additional context
     * @param {Object} context - Additional context
     * @returns {Logger} Child logger
     */
    child(context) {
        return new Logger({
            level: Object.keys(LOG_LEVELS)[this.level],
            prefix: this.prefix,
            colors: this.colors,
            timestamp: this.timestamp,
            logFile: this.logFile,
            context: { ...this.context, ...context }
        });
    }

    /**
     * Set log level
     * @param {string} level - Log level name
     */
    setLevel(level) {
        const upperLevel = level.toUpperCase();
        if (LOG_LEVELS.hasOwnProperty(upperLevel)) {
            this.level = LOG_LEVELS[upperLevel];
        } else {
            this.warn(`Invalid log level: ${level}`);
        }
    }

    /**
     * Get current log level name
     * @returns {string} Log level name
     */
    getLevel() {
        return Object.keys(LOG_LEVELS)[this.level];
    }
}

/**
 * Progress tracker class
 */
class ProgressTracker {
    constructor(total, options = {}) {
        this.total = total;
        this.current = 0;
        this.label = options.label || 'Progress';
        this.width = options.width || 40;
        this.logger = options.logger || new Logger();
        this.startTime = Date.now();
        this.showEta = options.showEta !== false;
        this.showPercent = options.showPercent !== false;
        this.showCount = options.showCount !== false;
    }

    /**
     * Update progress
     * @param {number} increment - Amount to increment (default: 1)
     * @param {string} message - Optional status message
     */
    update(increment = 1, message = '') {
        this.current = Math.min(this.current + increment, this.total);
        this.render(message);
    }

    /**
     * Set progress to specific value
     * @param {number} value - Progress value
     * @param {string} message - Optional status message
     */
    set(value, message = '') {
        this.current = Math.min(Math.max(value, 0), this.total);
        this.render(message);
    }

    /**
     * Render progress bar
     * @param {string} message - Optional status message
     */
    render(message = '') {
        const percent = this.total > 0 ? (this.current / this.total) : 0;
        const filled = Math.floor(percent * this.width);
        const empty = this.width - filled;

        let bar = chalk.green('█'.repeat(filled)) + chalk.gray('░'.repeat(empty));
        let info = [];

        if (this.showPercent) {
            info.push(`${(percent * 100).toFixed(1)}%`);
        }

        if (this.showCount) {
            info.push(`${this.current}/${this.total}`);
        }

        if (this.showEta && this.current > 0) {
            const elapsed = Date.now() - this.startTime;
            const rate = this.current / elapsed;
            const remaining = (this.total - this.current) / rate;

            if (remaining > 0 && remaining < Infinity) {
                const eta = new Date(Date.now() + remaining);
                info.push(`ETA: ${eta.toTimeString().split(' ')[0]}`);
            }
        }

        const infoStr = info.length > 0 ? ` (${info.join(', ')})` : '';
        const statusMsg = message ? ` - ${message}` : '';

        // Clear line and rewrite
        process.stdout.write(`\r${this.label}: [${bar}]${infoStr}${statusMsg}`);

        // New line when complete
        if (this.current >= this.total) {
            process.stdout.write('\n');
        }
    }

    /**
     * Complete the progress
     * @param {string} message - Completion message
     */
    complete(message = 'Complete') {
        this.set(this.total, message);
    }
}

/**
 * Performance monitor class
 */
class PerformanceMonitor {
    constructor(logger) {
        this.logger = logger || new Logger();
        this.timers = new Map();
        this.counters = new Map();
        this.memory = [];
    }

    /**
     * Start a timer
     * @param {string} name - Timer name
     */
    startTimer(name) {
        this.timers.set(name, {
            start: process.hrtime.bigint(),
            end: null
        });
        this.logger.debug(`Started timer: ${name}`);
    }

    /**
     * End a timer
     * @param {string} name - Timer name
     * @returns {number} Duration in milliseconds
     */
    endTimer(name) {
        const timer = this.timers.get(name);
        if (!timer) {
            this.logger.warn(`Timer '${name}' not found`);
            return 0;
        }

        timer.end = process.hrtime.bigint();
        const duration = Number(timer.end - timer.start) / 1000000; // Convert to ms

        this.logger.debug(`Timer '${name}' completed: ${duration.toFixed(2)}ms`);
        return duration;
    }

    /**
     * Increment a counter
     * @param {string} name - Counter name
     * @param {number} increment - Amount to increment (default: 1)
     */
    incrementCounter(name, increment = 1) {
        const current = this.counters.get(name) || 0;
        this.counters.set(name, current + increment);
    }

    /**
     * Get counter value
     * @param {string} name - Counter name
     * @returns {number} Counter value
     */
    getCounter(name) {
        return this.counters.get(name) || 0;
    }

    /**
     * Record memory usage
     * @param {string} label - Memory snapshot label
     */
    recordMemory(label) {
        const usage = process.memoryUsage();
        this.memory.push({
            label,
            timestamp: Date.now(),
            ...usage
        });

        this.logger.debug(`Memory snapshot '${label}': ${(usage.heapUsed / 1024 / 1024).toFixed(2)}MB`);
    }

    /**
     * Get performance summary
     * @returns {Object} Performance summary
     */
    getSummary() {
        const summary = {
            timers: {},
            counters: Object.fromEntries(this.counters),
            memory: this.memory
        };

        // Calculate timer durations
        for (const [name, timer] of this.timers) {
            if (timer.end) {
                summary.timers[name] = Number(timer.end - timer.start) / 1000000;
            }
        }

        return summary;
    }

    /**
     * Print performance report
     */
    printReport() {
        const summary = this.getSummary();

        this.logger.print(chalk.blue('\n📊 Performance Report'));
        this.logger.print(chalk.gray('━'.repeat(50)));

        // Timers
        if (Object.keys(summary.timers).length > 0) {
            this.logger.print(chalk.yellow('\n⏱️  Timers:'));
            for (const [name, duration] of Object.entries(summary.timers)) {
                this.logger.print(`   ${name}: ${duration.toFixed(2)}ms`);
            }
        }

        // Counters
        if (Object.keys(summary.counters).length > 0) {
            this.logger.print(chalk.yellow('\n🔢 Counters:'));
            for (const [name, count] of Object.entries(summary.counters)) {
                this.logger.print(`   ${name}: ${count}`);
            }
        }

        // Memory
        if (summary.memory.length > 0) {
            this.logger.print(chalk.yellow('\n💾 Memory Usage:'));
            summary.memory.forEach(snapshot => {
                const heapMB = (snapshot.heapUsed / 1024 / 1024).toFixed(2);
                this.logger.print(`   ${snapshot.label}: ${heapMB}MB`);
            });
        }
    }
}

/**
 * Create default logger instance
 */
function createLogger(options = {}) {
    // Get log level from environment or options
    const envLevel = process.env.HUGO_LOG_LEVEL;
    const level = options.level || envLevel || 'INFO';

    // Get log file from environment or options
    const envLogFile = process.env.HUGO_LOG_FILE;
    const logFile = options.logFile || envLogFile || null;

    return new Logger({
        level,
        logFile,
        colors: options.colors !== false && process.stdout.isTTY,
        timestamp: options.timestamp || false,
        prefix: options.prefix || '',
        context: options.context || {}
    });
}

/**
 * Create progress tracker
 * @param {number} total - Total items
 * @param {Object} options - Options
 * @returns {ProgressTracker} Progress tracker instance
 */
function createProgress(total, options = {}) {
    return new ProgressTracker(total, options);
}

/**
 * Create performance monitor
 * @param {Logger} logger - Logger instance
 * @returns {PerformanceMonitor} Performance monitor instance
 */
function createPerformanceMonitor(logger) {
    return new PerformanceMonitor(logger);
}

// Default logger instance
const defaultLogger = createLogger();

module.exports = {
    Logger,
    ProgressTracker,
    PerformanceMonitor,
    LOG_LEVELS,
    createLogger,
    createProgress,
    createPerformanceMonitor,
    logger: defaultLogger
};