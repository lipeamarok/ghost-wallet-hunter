"""
TaintCache.jl - F2 Cache system for taint retroprocessing

Implements intelligent caching for taint analysis results:
- Cache keyed by slot ranges and incident set versions
- Retroprocessing when new incidents are added
- Efficient invalidation and recalculation
- Persistent storage for taint results without mocks
"""

using JSON3

# Cache structures
struct CacheKey
    slot_range_start::Int
    slot_range_end::Int
    incident_set_hash::String    # Hash of incident IDs and versions
    graph_hash::String          # Hash of transaction graph structure
end

struct CachedTaintResult
    cache_key::CacheKey
    taint_results::Dict{String, TaintResult}
    taint_metrics::Dict{String, Any}
    created_at::Int             # Unix timestamp
    last_accessed::Int          # Unix timestamp
    computation_time_ms::Int    # Time taken to compute
end

struct TaintCacheConfig
    max_cache_size::Int         # Maximum number of cached results
    cache_ttl_hours::Int        # Time to live in hours
    enable_persistence::Bool     # Save cache to disk
    cache_directory::String     # Directory for persistent cache
    auto_cleanup::Bool          # Automatically remove expired entries
end

# Global cache storage
const TAINT_CACHE = Dict{String, CachedTaintResult}()
const DEFAULT_CACHE_CONFIG = TaintCacheConfig(100, 24, true, "cache/taint", true)

"""
    generate_cache_key(slot_range::Tuple{Int,Int}, incidents::Vector{TaintSeed}, graph::TxGraph)

Generate a unique cache key based on parameters.
"""
function generate_cache_key(slot_range::Tuple{Int,Int}, incidents::Vector{TaintSeed}, graph::TxGraph)
    # Create incident set hash
    incident_data = sort([(seed.incident_id, seed.address, seed.initial_taint) for seed in incidents])
    incident_hash = string(hash(incident_data))

    # Create graph structure hash (based on edge count and key nodes)
    graph_data = (length(graph.edges), length(graph.nodes),
                  sort(collect(graph.nodes))[1:min(10, length(graph.nodes))])
    graph_hash = string(hash(graph_data))

    return CacheKey(slot_range[1], slot_range[2], incident_hash, graph_hash)
end

"""
    get_cache_key_string(key::CacheKey)

Convert cache key to string for dictionary indexing.
"""
function get_cache_key_string(key::CacheKey)
    return "$(key.slot_range_start)-$(key.slot_range_end)_$(key.incident_set_hash)_$(key.graph_hash)"
end

"""
    get_cached_taint(slot_range::Tuple{Int,Int}, incidents::Vector{TaintSeed}, graph::TxGraph, config::TaintCacheConfig=DEFAULT_CACHE_CONFIG)

Retrieve cached taint results if available and valid.
"""
function get_cached_taint(slot_range::Tuple{Int,Int}, incidents::Vector{TaintSeed}, graph::TxGraph, config::TaintCacheConfig=DEFAULT_CACHE_CONFIG)
    cache_key = generate_cache_key(slot_range, incidents, graph)
    key_string = get_cache_key_string(cache_key)

    if haskey(TAINT_CACHE, key_string)
        cached_result = TAINT_CACHE[key_string]

        # Check if cache is still valid (TTL)
        current_time = Int(time())
        if current_time - cached_result.created_at < config.cache_ttl_hours * 3600
            # Update last accessed time
            TAINT_CACHE[key_string] = CachedTaintResult(
                cached_result.cache_key,
                cached_result.taint_results,
                cached_result.taint_metrics,
                cached_result.created_at,
                current_time,
                cached_result.computation_time_ms
            )

            return cached_result
        else
            # Remove expired cache entry
            delete!(TAINT_CACHE, key_string)
        end
    end

    return nothing
end

"""
    cache_taint_results(slot_range::Tuple{Int,Int}, incidents::Vector{TaintSeed}, graph::TxGraph,
                       taint_results::Dict{String, TaintResult}, computation_time_ms::Int,
                       config::TaintCacheConfig=DEFAULT_CACHE_CONFIG)

Store taint results in cache.
"""
function cache_taint_results(slot_range::Tuple{Int,Int}, incidents::Vector{TaintSeed}, graph::TxGraph,
                            taint_results::Dict{String, TaintResult}, computation_time_ms::Int,
                            config::TaintCacheConfig=DEFAULT_CACHE_CONFIG)

    cache_key = generate_cache_key(slot_range, incidents, graph)
    key_string = get_cache_key_string(cache_key)
    current_time = Int(time())

    # Calculate metrics for caching
    taint_metrics = calculate_taint_metrics(taint_results)

    # Create cached result
    cached_result = CachedTaintResult(
        cache_key,
        taint_results,
        taint_metrics,
        current_time,
        current_time,
        computation_time_ms
    )

    # Store in memory cache
    TAINT_CACHE[key_string] = cached_result

    # Cleanup if cache is too large
    if config.auto_cleanup && length(TAINT_CACHE) > config.max_cache_size
        cleanup_cache(config)
    end

    # Persist to disk if enabled
    if config.enable_persistence
        persist_cache_entry(key_string, cached_result, config)
    end

    return cached_result
end

"""
    cleanup_cache(config::TaintCacheConfig)

Remove old and expired cache entries.
"""
function cleanup_cache(config::TaintCacheConfig)
    current_time = Int(time())
    expired_keys = String[]

    # Find expired entries
    for (key, cached_result) in TAINT_CACHE
        if current_time - cached_result.created_at >= config.cache_ttl_hours * 3600
            push!(expired_keys, key)
        end
    end

    # Remove expired entries
    for key in expired_keys
        delete!(TAINT_CACHE, key)
    end

    # If still too large, remove least recently accessed
    if length(TAINT_CACHE) > config.max_cache_size
        sorted_entries = sort(collect(TAINT_CACHE), by = x -> x.second.last_accessed)
        entries_to_remove = length(TAINT_CACHE) - config.max_cache_size

        for i in 1:entries_to_remove
            delete!(TAINT_CACHE, sorted_entries[i].first)
        end
    end
end

"""
    invalidate_cache_for_incidents(incident_ids::Vector{String})

Invalidate cache entries that contain specific incidents.
"""
function invalidate_cache_for_incidents(incident_ids::Vector{String})
    keys_to_remove = String[]

    for (key_string, cached_result) in TAINT_CACHE
        # Check if any incident in this cache entry matches the invalidated incidents
        cached_incidents = Set(result.incident_id for result in values(cached_result.taint_results))

        if !isempty(intersect(cached_incidents, Set(incident_ids)))
            push!(keys_to_remove, key_string)
        end
    end

    # Remove invalidated entries
    for key in keys_to_remove
        delete!(TAINT_CACHE, key)
    end

    return length(keys_to_remove)
end

"""
    persist_cache_entry(key_string::String, cached_result::CachedTaintResult, config::TaintCacheConfig)

Persist a cache entry to disk.
"""
function persist_cache_entry(key_string::String, cached_result::CachedTaintResult, config::TaintCacheConfig)
    try
        # Ensure cache directory exists
        if !isdir(config.cache_directory)
            mkpath(config.cache_directory)
        end

        # Convert to serializable format
        cache_data = Dict{String, Any}(
            "cache_key" => Dict{String, Any}(
                "slot_range_start" => cached_result.cache_key.slot_range_start,
                "slot_range_end" => cached_result.cache_key.slot_range_end,
                "incident_set_hash" => cached_result.cache_key.incident_set_hash,
                "graph_hash" => cached_result.cache_key.graph_hash
            ),
            "taint_results" => Dict{String, Any}(
                address => Dict{String, Any}(
                    "address" => result.address,
                    "taint_share" => result.taint_share,
                    "hop_distance" => result.hop_distance,
                    "incident_id" => result.incident_id,
                    "propagation_path" => result.propagation_path,
                    "total_flow_from_seed" => result.total_flow_from_seed
                ) for (address, result) in cached_result.taint_results
            ),
            "taint_metrics" => cached_result.taint_metrics,
            "created_at" => cached_result.created_at,
            "last_accessed" => cached_result.last_accessed,
            "computation_time_ms" => cached_result.computation_time_ms
        )

        # Write to file
        file_path = joinpath(config.cache_directory, "$(key_string).json")
        open(file_path, "w") do f
            JSON3.write(f, cache_data)
        end

    catch e
        @warn "Failed to persist cache entry: $(e)"
    end
end

"""
    load_cache_from_disk(config::TaintCacheConfig)

Load cached entries from disk on startup.
"""
function load_cache_from_disk(config::TaintCacheConfig)
    if !config.enable_persistence || !isdir(config.cache_directory)
        return 0
    end

    loaded_count = 0

    try
        for file in readdir(config.cache_directory)
            if endswith(file, ".json")
                try
                    file_path = joinpath(config.cache_directory, file)
                    cache_data = JSON3.read(read(file_path, String))

                    # Reconstruct cache entry
                    key_string = splitext(file)[1]

                    # Skip if already in memory cache
                    if haskey(TAINT_CACHE, key_string)
                        continue
                    end

                    # Check if cache is still valid
                    current_time = Int(time())
                    if current_time - cache_data["created_at"] >= config.cache_ttl_hours * 3600
                        rm(file_path, force=true)  # Remove expired file
                        continue
                    end

                    # Reconstruct taint results
                    taint_results = Dict{String, TaintResult}()
                    for (address, result_data) in cache_data["taint_results"]
                        taint_results[address] = TaintResult(
                            result_data["address"],
                            result_data["taint_share"],
                            result_data["hop_distance"],
                            result_data["incident_id"],
                            result_data["propagation_path"],
                            result_data["total_flow_from_seed"]
                        )
                    end

                    # Reconstruct cache key
                    key_data = cache_data["cache_key"]
                    cache_key = CacheKey(
                        key_data["slot_range_start"],
                        key_data["slot_range_end"],
                        key_data["incident_set_hash"],
                        key_data["graph_hash"]
                    )

                    # Create cached result
                    cached_result = CachedTaintResult(
                        cache_key,
                        taint_results,
                        cache_data["taint_metrics"],
                        cache_data["created_at"],
                        current_time,  # Update last accessed
                        cache_data["computation_time_ms"]
                    )

                    TAINT_CACHE[key_string] = cached_result
                    loaded_count += 1

                catch e
                    @warn "Failed to load cache file $(file): $(e)"
                end
            end
        end
    catch e
        @warn "Failed to load cache from disk: $(e)"
    end

    return loaded_count
end

"""
    get_cache_stats()

Get current cache statistics.
"""
function get_cache_stats()
    current_time = Int(time())

    return Dict{String, Any}(
        "total_entries" => length(TAINT_CACHE),
        "total_memory_usage_mb" => Base.summarysize(TAINT_CACHE) / (1024 * 1024),
        "oldest_entry_age_hours" => isempty(TAINT_CACHE) ? 0 :
            (current_time - minimum(entry.created_at for entry in values(TAINT_CACHE))) / 3600,
        "newest_entry_age_hours" => isempty(TAINT_CACHE) ? 0 :
            (current_time - maximum(entry.created_at for entry in values(TAINT_CACHE))) / 3600,
        "avg_computation_time_ms" => isempty(TAINT_CACHE) ? 0 :
            sum(entry.computation_time_ms for entry in values(TAINT_CACHE)) / length(TAINT_CACHE)
    )
end

# Export functions for use in analysis pipeline
export CacheKey, CachedTaintResult, TaintCacheConfig, DEFAULT_CACHE_CONFIG
export get_cached_taint, cache_taint_results, cleanup_cache
export invalidate_cache_for_incidents, load_cache_from_disk, get_cache_stats
