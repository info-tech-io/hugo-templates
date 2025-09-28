#!/bin/bash
set -euo pipefail

#
# Hugo Template Factory Framework - Intelligent Caching System v1.0
# Multi-level caching infrastructure with content-based invalidation
#
# This script provides comprehensive caching for components, templates,
# build artifacts, and dependencies to dramatically improve build performance.
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

# Cache system constants
readonly CACHE_VERSION="1.0"
readonly CACHE_ROOT="${HUGO_TEMPLATE_CACHE_DIR:-$HOME/.hugo-template-cache}"
readonly CACHE_L1_DIR="${CACHE_ROOT}/l1"      # In-session cache
readonly CACHE_L2_DIR="${CACHE_ROOT}/l2"      # Persistent local cache
readonly CACHE_L3_DIR="${CACHE_ROOT}/l3"      # Shared team cache
readonly CACHE_META_DIR="${CACHE_ROOT}/meta"  # Cache metadata
readonly CACHE_STATS_FILE="${CACHE_ROOT}/stats.json"

# Cache configuration
CACHE_ENABLED=${HUGO_TEMPLATE_CACHE_ENABLED:-true}
CACHE_MAX_SIZE=${HUGO_TEMPLATE_CACHE_MAX_SIZE:-"1G"}
CACHE_TTL_HOURS=${HUGO_TEMPLATE_CACHE_TTL:-24}
CACHE_CLEANUP_THRESHOLD=${HUGO_TEMPLATE_CACHE_CLEANUP_THRESHOLD:-0.85}

# Performance tracking
declare -A cache_stats=(
    ["hits"]=0
    ["misses"]=0
    ["builds"]=0
    ["size_bytes"]=0
    ["cleanup_runs"]=0
)

#
# Cache Infrastructure Functions
#

# Initialize cache system
init_cache_system() {
    if [[ "$CACHE_ENABLED" != "true" ]]; then
        log_debug "Cache system disabled"
        return 0
    fi

    log_debug "Initializing cache system v${CACHE_VERSION}"

    # Create cache directories
    mkdir -p "$CACHE_L1_DIR" "$CACHE_L2_DIR" "$CACHE_L3_DIR" "$CACHE_META_DIR"

    # Initialize cache stats if not exists
    if [[ ! -f "$CACHE_STATS_FILE" ]]; then
        echo '{"version":"'$CACHE_VERSION'","stats":{"hits":0,"misses":0,"builds":0,"size_bytes":0,"cleanup_runs":0}}' > "$CACHE_STATS_FILE"
    fi

    # Load existing stats
    load_cache_stats

    # Check cache health
    validate_cache_integrity

    # Cleanup if needed
    check_cache_size_limits

    log_info "Cache system initialized successfully"
}

# Load cache statistics
load_cache_stats() {
    if [[ -f "$CACHE_STATS_FILE" ]]; then
        local stats
        stats=$(cat "$CACHE_STATS_FILE" 2>/dev/null || echo '{}')

        cache_stats["hits"]=$(echo "$stats" | jq -r '.stats.hits // 0' 2>/dev/null || echo "0")
        cache_stats["misses"]=$(echo "$stats" | jq -r '.stats.misses // 0' 2>/dev/null || echo "0")
        cache_stats["builds"]=$(echo "$stats" | jq -r '.stats.builds // 0' 2>/dev/null || echo "0")
        cache_stats["size_bytes"]=$(echo "$stats" | jq -r '.stats.size_bytes // 0' 2>/dev/null || echo "0")
        cache_stats["cleanup_runs"]=$(echo "$stats" | jq -r '.stats.cleanup_runs // 0' 2>/dev/null || echo "0")
    fi
}

# Save cache statistics
save_cache_stats() {
    local stats_json
    stats_json=$(cat <<EOF
{
    "version": "$CACHE_VERSION",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "stats": {
        "hits": ${cache_stats["hits"]},
        "misses": ${cache_stats["misses"]},
        "builds": ${cache_stats["builds"]},
        "size_bytes": ${cache_stats["size_bytes"]},
        "cleanup_runs": ${cache_stats["cleanup_runs"]}
    }
}
EOF
    )
    echo "$stats_json" > "$CACHE_STATS_FILE"
}

#
# Content-Based Cache Key Generation
#

# Generate cache key for template
generate_template_cache_key() {
    local template_path="$1"
    local components="$2"
    local config_hash="$3"

    local template_hash
    template_hash=$(find "$template_path" -type f \( -name "*.md" -o -name "*.toml" -o -name "*.yml" -o -name "*.yaml" \) -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1)

    local components_hash
    components_hash=$(echo "$components" | sha256sum | cut -d' ' -f1)

    local combined_hash="${template_hash}_${components_hash}_${config_hash}"
    echo "template_$(echo "$combined_hash" | sha256sum | cut -d' ' -f1)"
}

# Generate cache key for component
generate_component_cache_key() {
    local component_name="$1"
    local component_path="$2"
    local version="$3"

    local content_hash
    if [[ -d "$component_path" ]]; then
        content_hash=$(find "$component_path" -type f -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1)
    else
        content_hash=$(echo "$version" | sha256sum | cut -d' ' -f1)
    fi

    echo "component_${component_name}_${content_hash}"
}

# Generate cache key for build artifacts
generate_build_cache_key() {
    local template_key="$1"
    local hugo_version="$2"
    local environment="$3"
    local minify="$4"

    local build_params="${hugo_version}_${environment}_${minify}"
    local build_hash=$(echo "$build_params" | sha256sum | cut -d' ' -f1)

    echo "build_${template_key}_${build_hash}"
}

#
# Cache Operations
#

# Check if cache entry exists and is valid
cache_exists() {
    local cache_key="$1"
    local cache_level="${2:-l2}"  # Default to L2 cache

    local cache_dir
    case "$cache_level" in
        "l1") cache_dir="$CACHE_L1_DIR" ;;
        "l2") cache_dir="$CACHE_L2_DIR" ;;
        "l3") cache_dir="$CACHE_L3_DIR" ;;
        *) log_error "Invalid cache level: $cache_level"; return 1 ;;
    esac

    local cache_path="${cache_dir}/${cache_key}"
    local meta_path="${CACHE_META_DIR}/${cache_key}.meta"

    # Check if cache entry exists
    if [[ ! -f "$cache_path" || ! -f "$meta_path" ]]; then
        return 1
    fi

    # Check TTL
    local created_timestamp
    created_timestamp=$(jq -r '.created' "$meta_path" 2>/dev/null || echo "0")
    local current_timestamp=$(date +%s)
    local age_hours=$(( (current_timestamp - created_timestamp) / 3600 ))

    if [[ $age_hours -gt $CACHE_TTL_HOURS ]]; then
        log_debug "Cache entry expired: $cache_key (age: ${age_hours}h)"
        return 1
    fi

    return 0
}

# Store entry in cache
cache_store() {
    local cache_key="$1"
    local source_path="$2"
    local cache_level="${3:-l2}"
    local metadata="$4"

    if [[ "$CACHE_ENABLED" != "true" ]]; then
        return 0
    fi

    # Load current stats
    load_cache_stats

    local cache_dir
    case "$cache_level" in
        "l1") cache_dir="$CACHE_L1_DIR" ;;
        "l2") cache_dir="$CACHE_L2_DIR" ;;
        "l3") cache_dir="$CACHE_L3_DIR" ;;
        *) log_error "Invalid cache level: $cache_level"; return 1 ;;
    esac

    local cache_path="${cache_dir}/${cache_key}"
    local meta_path="${CACHE_META_DIR}/${cache_key}.meta"

    # Create cache entry
    if [[ -d "$source_path" ]]; then
        tar -czf "$cache_path" -C "$(dirname "$source_path")" "$(basename "$source_path")"
    else
        cp "$source_path" "$cache_path"
    fi

    # Create metadata
    local meta_json
    meta_json=$(cat <<EOF
{
    "version": "$CACHE_VERSION",
    "key": "$cache_key",
    "level": "$cache_level",
    "created": $(date +%s),
    "created_iso": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "source_path": "$source_path",
    "cache_path": "$cache_path",
    "size_bytes": $(stat -f%z "$cache_path" 2>/dev/null || stat -c%s "$cache_path" 2>/dev/null || echo "0"),
    "metadata": $metadata
}
EOF
    )
    echo "$meta_json" > "$meta_path"

    # Update cache size and build count
    cache_stats["builds"]=$((cache_stats["builds"] + 1))
    update_cache_size_stats

    log_debug "Cache stored: $cache_key in $cache_level"
}

# Retrieve entry from cache
cache_retrieve() {
    local cache_key="$1"
    local target_path="$2"
    local cache_level="${3:-l2}"

    # Load current stats
    load_cache_stats

    if ! cache_exists "$cache_key" "$cache_level"; then
        cache_stats["misses"]=$((cache_stats["misses"] + 1))
        save_cache_stats
        log_debug "Cache miss: $cache_key"
        return 1
    fi

    local cache_dir
    case "$cache_level" in
        "l1") cache_dir="$CACHE_L1_DIR" ;;
        "l2") cache_dir="$CACHE_L2_DIR" ;;
        "l3") cache_dir="$CACHE_L3_DIR" ;;
        *) log_error "Invalid cache level: $cache_level"; return 1 ;;
    esac

    local cache_path="${cache_dir}/${cache_key}"

    # Extract cache entry
    if file "$cache_path" | grep -q "gzip compressed"; then
        # Tar archive
        mkdir -p "$(dirname "$target_path")"
        tar -xzf "$cache_path" -C "$(dirname "$target_path")"
    else
        # Regular file
        cp "$cache_path" "$target_path"
    fi

    cache_stats["hits"]=$((cache_stats["hits"] + 1))
    save_cache_stats
    log_debug "Cache hit: $cache_key"
    return 0
}

#
# Cache Maintenance
#

# Update cache size statistics
update_cache_size_stats() {
    local total_size=0

    for cache_dir in "$CACHE_L1_DIR" "$CACHE_L2_DIR" "$CACHE_L3_DIR"; do
        if [[ -d "$cache_dir" ]]; then
            local dir_size
            dir_size=$(du -sb "$cache_dir" 2>/dev/null | cut -f1 || echo "0")
            total_size=$((total_size + dir_size))
        fi
    done

    cache_stats["size_bytes"]=$total_size
}

# Check cache size limits and cleanup if needed
check_cache_size_limits() {
    update_cache_size_stats

    local max_size_bytes
    max_size_bytes=$(convert_size_to_bytes "$CACHE_MAX_SIZE")
    local current_size_bytes=${cache_stats["size_bytes"]}
    local usage_ratio
    if command -v bc >/dev/null 2>&1; then
        usage_ratio=$(echo "scale=2; $current_size_bytes / $max_size_bytes" | bc -l 2>/dev/null || echo "0")
    else
        # Fallback calculation using awk
        usage_ratio=$(awk "BEGIN { printf \"%.2f\", $current_size_bytes / $max_size_bytes }" 2>/dev/null || echo "0")
    fi

    # Check if cleanup needed using awk for portability
    local cleanup_needed
    cleanup_needed=$(awk "BEGIN { print ($usage_ratio > $CACHE_CLEANUP_THRESHOLD) ? 1 : 0 }" 2>/dev/null || echo "0")

    if [[ "$cleanup_needed" == "1" ]]; then
        log_info "Cache size limit exceeded (${usage_ratio}), starting cleanup..."
        cleanup_cache
    fi
}

# Convert size string to bytes
convert_size_to_bytes() {
    local size_str="$1"
    local size_num="${size_str%[KMGT]*}"
    local size_unit="${size_str: -1}"

    case "$size_unit" in
        "K"|"k") echo $((size_num * 1024)) ;;
        "M"|"m") echo $((size_num * 1024 * 1024)) ;;
        "G"|"g") echo $((size_num * 1024 * 1024 * 1024)) ;;
        "T"|"t") echo $((size_num * 1024 * 1024 * 1024 * 1024)) ;;
        *) echo "$size_num" ;;
    esac
}

# Cleanup old cache entries
cleanup_cache() {
    log_info "Starting cache cleanup..."

    local cleaned_count=0
    local current_time=$(date +%s)

    # Cleanup expired entries
    for meta_file in "$CACHE_META_DIR"/*.meta; do
        if [[ ! -f "$meta_file" ]]; then
            continue
        fi

        local created_timestamp
        created_timestamp=$(jq -r '.created' "$meta_file" 2>/dev/null || echo "0")
        local age_hours=$(( (current_time - created_timestamp) / 3600 ))

        if [[ $age_hours -gt $CACHE_TTL_HOURS ]]; then
            local cache_key
            cache_key=$(jq -r '.key' "$meta_file" 2>/dev/null || basename "$meta_file" .meta)

            # Remove from all cache levels
            for cache_dir in "$CACHE_L1_DIR" "$CACHE_L2_DIR" "$CACHE_L3_DIR"; do
                local cache_file="${cache_dir}/${cache_key}"
                if [[ -f "$cache_file" ]]; then
                    rm -f "$cache_file"
                fi
            done

            rm -f "$meta_file"
            cleaned_count=$((cleaned_count + 1))
        fi
    done

    cache_stats["cleanup_runs"]=$((cache_stats["cleanup_runs"] + 1))
    update_cache_size_stats

    log_info "Cache cleanup completed. Removed $cleaned_count expired entries"
}

# Validate cache integrity
validate_cache_integrity() {
    local invalid_count=0

    for meta_file in "$CACHE_META_DIR"/*.meta; do
        if [[ ! -f "$meta_file" ]]; then
            continue
        fi

        local cache_path
        cache_path=$(jq -r '.cache_path' "$meta_file" 2>/dev/null || echo "")

        if [[ -n "$cache_path" && ! -f "$cache_path" ]]; then
            # Orphaned metadata
            rm -f "$meta_file"
            invalid_count=$((invalid_count + 1))
        fi
    done

    if [[ $invalid_count -gt 0 ]]; then
        log_debug "Cleaned up $invalid_count orphaned cache metadata entries"
    fi
}

# Clear all cache
clear_cache() {
    log_info "Clearing all cache data..."

    rm -rf "$CACHE_L1_DIR"/* "$CACHE_L2_DIR"/* "$CACHE_L3_DIR"/* "$CACHE_META_DIR"/*

    # Reset stats
    cache_stats["hits"]=0
    cache_stats["misses"]=0
    cache_stats["builds"]=0
    cache_stats["size_bytes"]=0
    cache_stats["cleanup_runs"]=0

    save_cache_stats
    log_info "Cache cleared successfully"
}

#
# Cache Reporting
#

# Show cache statistics
show_cache_stats() {
    update_cache_size_stats
    save_cache_stats

    local hit_rate=0
    local total_requests=$((cache_stats["hits"] + cache_stats["misses"]))
    if [[ $total_requests -gt 0 ]]; then
        if command -v bc >/dev/null 2>&1; then
            hit_rate=$(echo "scale=1; ${cache_stats["hits"]} * 100 / $total_requests" | bc -l)
        else
            hit_rate=$(awk "BEGIN { printf \"%.1f\", ${cache_stats["hits"]} * 100 / $total_requests }")
        fi
    fi

    local cache_size_mb
    if command -v bc >/dev/null 2>&1; then
        cache_size_mb=$(echo "scale=1; ${cache_stats["size_bytes"]} / 1024 / 1024" | bc -l)
    else
        cache_size_mb=$(awk "BEGIN { printf \"%.1f\", ${cache_stats["size_bytes"]} / 1024 / 1024 }")
    fi

    echo "Cache Statistics:"
    echo "  Version: $CACHE_VERSION"
    echo "  Status: $([ "$CACHE_ENABLED" = "true" ] && echo "Enabled" || echo "Disabled")"
    echo "  Hit Rate: ${hit_rate}% (${cache_stats["hits"]} hits, ${cache_stats["misses"]} misses)"
    echo "  Total Builds: ${cache_stats["builds"]}"
    echo "  Cache Size: ${cache_size_mb} MB"
    echo "  Cleanup Runs: ${cache_stats["cleanup_runs"]}"
    echo "  Cache Root: $CACHE_ROOT"
}

# Main cache command interface
main() {
    case "${1:-}" in
        "init")
            init_cache_system
            ;;
        "store")
            cache_store "$2" "$3" "${4:-l2}" "${5:-{}}"
            ;;
        "retrieve")
            cache_retrieve "$2" "$3" "${4:-l2}"
            ;;
        "exists")
            cache_exists "$2" "${3:-l2}"
            ;;
        "cleanup")
            cleanup_cache
            ;;
        "clear")
            clear_cache
            ;;
        "stats")
            show_cache_stats
            ;;
        "help"|*)
            echo "Hugo Template Factory - Cache System v$CACHE_VERSION"
            echo "Usage: $0 {init|store|retrieve|exists|cleanup|clear|stats|help}"
            echo "  init                     Initialize cache system"
            echo "  store <key> <source>     Store file/directory in cache"
            echo "  retrieve <key> <target>  Retrieve from cache"
            echo "  exists <key>             Check if cache entry exists"
            echo "  cleanup                  Remove expired cache entries"
            echo "  clear                    Clear all cache data"
            echo "  stats                    Show cache statistics"
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi