#!/bin/bash
set -euo pipefail

#
# Hugo Template Factory Framework - Performance Monitoring System v1.0
# Real-time performance analysis and benchmarking for build optimizations
#
# This script provides comprehensive performance monitoring including build times,
# resource usage, cache efficiency, and optimization recommendations.
#

# Script directory and dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define logging functions if not already available
if ! command -v log_debug &> /dev/null; then
    log_debug() { [[ "${DEBUG:-false}" == "true" ]] && echo "🔍 $*" >&2; }
fi
if ! command -v log_info &> /dev/null; then
    log_info() { echo "ℹ️  $*"; }
fi
if ! command -v log_error &> /dev/null; then
    log_error() { echo "❌ $*" >&2; }
fi
if ! command -v log_warning &> /dev/null; then
    log_warning() { echo "⚠️  $*" >&2; }
fi

# Performance monitoring constants
readonly PERF_VERSION="1.0"
readonly PERF_LOG_DIR="${HUGO_TEMPLATE_PERF_DIR:-$HOME/.hugo-template-perf}"
readonly PERF_HISTORY_FILE="$PERF_LOG_DIR/performance_history.json"
readonly PERF_CURRENT_FILE="$PERF_LOG_DIR/current_session.json"

# Performance thresholds (configurable via environment)
PERF_BUILD_TIME_THRESHOLD=${HUGO_TEMPLATE_PERF_BUILD_THRESHOLD:-300}  # 5 minutes
PERF_MEMORY_THRESHOLD=${HUGO_TEMPLATE_PERF_MEMORY_THRESHOLD:-2048}    # 2GB in MB
PERF_CACHE_HIT_TARGET=${HUGO_TEMPLATE_PERF_CACHE_TARGET:-80}          # 80% cache hit rate

# Global performance tracking variables
declare -A current_session=(
    ["session_id"]=""
    ["start_time"]=""
    ["template"]=""
    ["theme"]=""
    ["components"]=""
    ["environment"]=""
    ["cache_enabled"]=""
    ["parallel_enabled"]=""
    ["build_time"]=""
    ["cache_hit"]=""
    ["memory_peak"]=""
    ["file_count"]=""
    ["size_bytes"]=""
)

#
# Performance Monitoring Infrastructure
#

# Initialize performance monitoring system
init_performance_monitoring() {
    log_debug "Initializing performance monitoring system v${PERF_VERSION}"

    # Create performance directories
    mkdir -p "$PERF_LOG_DIR"

    # Generate unique session ID
    current_session["session_id"]="perf_$(date +%s)_$$"
    current_session["start_time"]=$(date +%s)

    log_debug "Performance session started: ${current_session["session_id"]}"
}

# Start performance measurement for a build
start_build_measurement() {
    local template="$1"
    local theme="$2"
    local components="$3"
    local environment="$4"
    local cache_enabled="$5"
    local parallel_enabled="$6"

    current_session["template"]="$template"
    current_session["theme"]="$theme"
    current_session["components"]="$components"
    current_session["environment"]="$environment"
    current_session["cache_enabled"]="$cache_enabled"
    current_session["parallel_enabled"]="$parallel_enabled"
    current_session["build_start_time"]=$(date +%s.%N)

    log_debug "Build measurement started for template: $template"
}

# End performance measurement and calculate metrics
end_build_measurement() {
    local cache_hit="$1"
    local output_dir="$2"

    local build_end_time=$(date +%s.%N)
    local build_start_time=${current_session["build_start_time"]}

    # Calculate build time in milliseconds
    if command -v bc >/dev/null 2>&1; then
        current_session["build_time"]=$(echo "scale=0; ($build_end_time - $build_start_time) * 1000" | bc)
    else
        current_session["build_time"]=$(awk "BEGIN { printf \"%.0f\", ($build_end_time - $build_start_time) * 1000 }")
    fi

    current_session["cache_hit"]="$cache_hit"

    # Measure output metrics
    if [[ -d "$output_dir" ]]; then
        current_session["file_count"]=$(find "$output_dir" -type f | wc -l)
        current_session["size_bytes"]=$(du -sb "$output_dir" 2>/dev/null | cut -f1 || echo "0")
    fi

    # Get memory usage (if available)
    if command -v free >/dev/null 2>&1; then
        local memory_used=$(free -m | awk 'NR==2{printf "%.0f", $3}')
        current_session["memory_peak"]="$memory_used"
    fi

    log_debug "Build measurement completed: ${current_session["build_time"]}ms"
}

# Save current session performance data
save_performance_data() {
    local session_json
    session_json=$(cat <<EOF
{
    "version": "$PERF_VERSION",
    "session_id": "${current_session["session_id"]}",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "timestamp_unix": $(date +%s),
    "template": "${current_session["template"]}",
    "theme": "${current_session["theme"]}",
    "components": "${current_session["components"]}",
    "environment": "${current_session["environment"]}",
    "cache_enabled": ${current_session["cache_enabled"]},
    "parallel_enabled": ${current_session["parallel_enabled"]},
    "build_time_ms": ${current_session["build_time"]:-0},
    "cache_hit": ${current_session["cache_hit"]:-false},
    "memory_peak_mb": ${current_session["memory_peak"]:-0},
    "file_count": ${current_session["file_count"]:-0},
    "size_bytes": ${current_session["size_bytes"]:-0}
}
EOF
    )

    # Save current session
    echo "$session_json" > "$PERF_CURRENT_FILE"

    # Append to history
    if [[ -f "$PERF_HISTORY_FILE" ]]; then
        # Read existing history and append new record
        local temp_file="$PERF_HISTORY_FILE.tmp"
        jq ". += [$session_json]" "$PERF_HISTORY_FILE" > "$temp_file" && mv "$temp_file" "$PERF_HISTORY_FILE"
    else
        # Create new history file
        echo "[$session_json]" > "$PERF_HISTORY_FILE"
    fi

    log_debug "Performance data saved to $PERF_HISTORY_FILE"
}

#
# Performance Analysis Functions
#

# Analyze current build performance
analyze_current_build() {
    local build_time_ms=${current_session["build_time"]:-0}
    local cache_hit=${current_session["cache_hit"]:-false}
    local memory_peak=${current_session["memory_peak"]:-0}
    local template=${current_session["template"]}

    echo "🚀 Build Performance Analysis"
    echo "════════════════════════════"

    # Build time analysis
    local build_time_seconds
    if command -v bc >/dev/null 2>&1; then
        build_time_seconds=$(echo "scale=2; $build_time_ms / 1000" | bc)
    else
        build_time_seconds=$(awk "BEGIN { printf \"%.2f\", $build_time_ms / 1000 }")
    fi

    echo "📊 Build Time: ${build_time_seconds}s (${build_time_ms}ms)"

    # Performance assessment
    if [[ $build_time_ms -lt 30000 ]]; then
        echo "   Status: ✅ Excellent (< 30s)"
    elif [[ $build_time_ms -lt 120000 ]]; then
        echo "   Status: 🟡 Good (< 2min)"
    elif [[ $build_time_ms -lt 300000 ]]; then
        echo "   Status: 🟠 Acceptable (< 5min)"
    else
        echo "   Status: 🔴 Slow (> 5min)"
    fi

    # Cache analysis
    echo "💾 Cache Performance:"
    if [[ "$cache_hit" == "true" ]]; then
        echo "   Status: ✅ Cache Hit (restored from cache)"
        echo "   Performance: Maximum (no Hugo build required)"
    else
        echo "   Status: ⚡ Cache Miss (built from source)"
        echo "   Recommendation: Future builds of same config will be cached"
    fi

    # Memory analysis
    if [[ $memory_peak -gt 0 ]]; then
        echo "💻 Memory Usage: ${memory_peak}MB"
        if [[ $memory_peak -lt 512 ]]; then
            echo "   Status: ✅ Low memory usage"
        elif [[ $memory_peak -lt 1024 ]]; then
            echo "   Status: 🟡 Moderate memory usage"
        elif [[ $memory_peak -lt 2048 ]]; then
            echo "   Status: 🟠 High memory usage"
        else
            echo "   Status: 🔴 Very high memory usage"
        fi
    fi

    # File output analysis
    local file_count=${current_session["file_count"]:-0}
    local size_bytes=${current_session["size_bytes"]:-0}

    if [[ $file_count -gt 0 ]]; then
        local size_mb
        if command -v bc >/dev/null 2>&1; then
            size_mb=$(echo "scale=1; $size_bytes / 1024 / 1024" | bc)
        else
            size_mb=$(awk "BEGIN { printf \"%.1f\", $size_bytes / 1024 / 1024 }")
        fi

        echo "📁 Output: $file_count files (${size_mb}MB)"
    fi

    echo ""
}

# Generate optimization recommendations
generate_recommendations() {
    local build_time_ms=${current_session["build_time"]:-0}
    local cache_hit=${current_session["cache_hit"]:-false}
    local memory_peak=${current_session["memory_peak"]:-0}
    local template=${current_session["template"]}
    local cache_enabled=${current_session["cache_enabled"]:-false}
    local parallel_enabled=${current_session["parallel_enabled"]:-false}

    echo "💡 Performance Recommendations"
    echo "══════════════════════════════"

    local recommendations=()

    # Build time recommendations
    if [[ $build_time_ms -gt 120000 && "$cache_hit" != "true" ]]; then
        if [[ "$template" == "enterprise" || "$template" == "academic" ]]; then
            recommendations+=("Consider using 'minimal' or 'default' template for development builds")
        fi

        if [[ "$cache_enabled" != "true" ]]; then
            recommendations+=("Enable caching with --cache to speed up repeated builds")
        fi

        if [[ "$parallel_enabled" != "true" ]]; then
            recommendations+=("Enable parallel processing (default) for faster file operations")
        fi
    fi

    # Memory recommendations
    if [[ $memory_peak -gt 1536 ]]; then
        recommendations+=("Consider splitting large content into smaller sections")
        recommendations+=("Use 'minimal' template for memory-constrained environments")
    fi

    # Cache recommendations
    if [[ "$cache_enabled" == "false" ]]; then
        recommendations+=("Enable intelligent caching to improve build performance")
    fi

    # Environment-specific recommendations
    if [[ "${current_session["environment"]}" == "development" && $build_time_ms -gt 60000 ]]; then
        recommendations+=("Use --no-minify for faster development builds")
        recommendations+=("Consider --template=minimal for rapid development iteration")
    fi

    # Print recommendations
    if [[ ${#recommendations[@]} -eq 0 ]]; then
        echo "✅ No optimization recommendations - build performance is optimal!"
    else
        local i=1
        for rec in "${recommendations[@]}"; do
            echo "$i. $rec"
            ((i++))
        done
    fi

    echo ""
}

# Show performance history
show_performance_history() {
    local limit="${1:-10}"

    if [[ ! -f "$PERF_HISTORY_FILE" ]]; then
        log_info "No performance history available"
        return 0
    fi

    echo "📈 Performance History (last $limit builds)"
    echo "═══════════════════════════════════════════"

    # Use jq to format and limit history
    if command -v jq >/dev/null 2>&1; then
        jq -r ".[-$limit:] | reverse | .[] |
            \"[\(.timestamp[0:19])] \(.template)/\(.theme) - \(.build_time_ms)ms\" +
            (if .cache_hit then \" (cached)\" else \"\" end)" "$PERF_HISTORY_FILE"
    else
        # Fallback without jq
        tail -"$limit" "$PERF_HISTORY_FILE" | while read -r line; do
            echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4 || echo "N/A"
        done
    fi

    echo ""
}

# Calculate performance statistics
calculate_performance_stats() {
    if [[ ! -f "$PERF_HISTORY_FILE" ]]; then
        log_info "No performance history available for statistics"
        return 0
    fi

    echo "📊 Performance Statistics"
    echo "════════════════════════"

    if command -v jq >/dev/null 2>&1; then
        local total_builds
        total_builds=$(jq 'length' "$PERF_HISTORY_FILE")

        local avg_build_time
        avg_build_time=$(jq '[.[] | .build_time_ms] | add / length | floor' "$PERF_HISTORY_FILE")

        local cache_hits
        cache_hits=$(jq '[.[] | select(.cache_hit == true)] | length' "$PERF_HISTORY_FILE")

        local cache_hit_rate
        if [[ $total_builds -gt 0 ]]; then
            cache_hit_rate=$(( cache_hits * 100 / total_builds ))
        else
            cache_hit_rate=0
        fi

        echo "Total Builds: $total_builds"
        echo "Average Build Time: ${avg_build_time}ms"
        echo "Cache Hit Rate: ${cache_hit_rate}% ($cache_hits/$total_builds)"

        # Template performance breakdown
        echo ""
        echo "Template Performance:"
        jq -r 'group_by(.template) | .[] | "\(.[0].template): \(length) builds, avg \((map(.build_time_ms) | add / length | floor))ms"' "$PERF_HISTORY_FILE"
    else
        log_info "Install 'jq' for detailed performance statistics"
    fi

    echo ""
}

# Clear performance history
clear_performance_history() {
    if [[ -f "$PERF_HISTORY_FILE" ]]; then
        rm -f "$PERF_HISTORY_FILE"
        log_info "Performance history cleared"
    fi

    if [[ -f "$PERF_CURRENT_FILE" ]]; then
        rm -f "$PERF_CURRENT_FILE"
    fi
}

# Main performance command interface
main() {
    case "${1:-}" in
        "init")
            init_performance_monitoring
            ;;
        "start")
            start_build_measurement "$2" "$3" "$4" "$5" "$6" "$7"
            ;;
        "end")
            end_build_measurement "$2" "$3"
            save_performance_data
            ;;
        "analyze")
            analyze_current_build
            generate_recommendations
            ;;
        "history")
            show_performance_history "${2:-10}"
            ;;
        "stats")
            calculate_performance_stats
            ;;
        "clear")
            clear_performance_history
            ;;
        "help"|*)
            echo "Hugo Template Factory - Performance Monitoring System v$PERF_VERSION"
            echo "Usage: $0 {init|start|end|analyze|history|stats|clear|help}"
            echo "  init                           Initialize performance monitoring"
            echo "  start <template> <theme> <components> <env> <cache> <parallel>"
            echo "                                 Start build measurement"
            echo "  end <cache_hit> <output_dir>   End measurement and save data"
            echo "  analyze                        Analyze current build performance"
            echo "  history [limit]                Show performance history"
            echo "  stats                          Calculate performance statistics"
            echo "  clear                          Clear performance history"
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi