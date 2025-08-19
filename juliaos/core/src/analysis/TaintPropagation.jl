"""
TaintPropagation.jl - F2 Taint Tracking with BFS propagation and decay

Implements deterministic taint tracking algorithm:
- Seeds from incident data with taint=1.0
- Proportional inheritance based on transaction values
- Exponential decay α^hop_distance
- Dust threshold to ignore negligible fractions
- Real transaction graph traversal without mocks
"""

# Types are available via parent include ordering

# Taint tracking structures
struct TaintSeed
    address::String
    incident_id::String
    initial_taint::Float64
    source::String          # Source of taint (e.g., "exploit_db", "manual")
end

struct TaintResult
    address::String
    taint_share::Float64
    hop_distance::Int
    incident_id::String
    propagation_path::Vector{String}  # Path from seed to this address
    total_flow_from_seed::Float64
end

struct TaintConfig
    decay_factor::Float64     # α for α^hop decay (default 0.8)
    dust_threshold::Float64   # Minimum taint to track (default 0.001)
    max_hops::Int            # Maximum propagation distance (default 6)
    min_value_threshold::Float64  # Minimum SOL value to propagate (default 0.01)
end

# Default configuration
const DEFAULT_TAINT_CONFIG = TaintConfig(0.8, 0.001, 6, 0.01)

"""
    propagate_taint(graph::TxGraph, seeds::Vector{TaintSeed}, config::TaintConfig=DEFAULT_TAINT_CONFIG)

Propagate taint through transaction graph using BFS with decay.
Returns Dict{String, TaintResult} mapping addresses to their taint results.
"""
function propagate_taint(graph::TxGraph, seeds::Vector{TaintSeed}, config::TaintConfig=DEFAULT_TAINT_CONFIG)
    # Initialize taint tracking
    taint_results = Dict{String, TaintResult}()
    queue = Tuple{String, Int, Float64, String, Vector{String}, Float64}[]  # (address, hops, taint, incident_id, path, total_flow)

    # Initialize with seeds
    for seed in seeds
        if seed.address in graph.nodes
            push!(queue, (seed.address, 0, seed.initial_taint, seed.incident_id, [seed.address], 0.0))
            taint_results[seed.address] = TaintResult(
                seed.address,
                seed.initial_taint,
                0,
                seed.incident_id,
                [seed.address],
                0.0
            )
        end
    end

    # BFS propagation with decay
    visited = Set{String}()

    while !isempty(queue)
        current_address, hops, current_taint, incident_id, path, total_flow = popfirst!(queue)

        # Skip if already visited or beyond max hops
        if current_address in visited || hops >= config.max_hops
            continue
        end

        push!(visited, current_address)

        # Get outgoing edges from current address
        if haskey(graph.adjacency_out, current_address)
            outgoing_edges = graph.adjacency_out[current_address]

            # Calculate total outgoing value for proportional distribution
            total_outgoing = sum(edge.value for edge in outgoing_edges if edge.value >= config.min_value_threshold)

            if total_outgoing > 0
                for edge in outgoing_edges
                    # Skip small transactions
                    if edge.value < config.min_value_threshold
                        continue
                    end

                    # Calculate proportional taint
                    proportion = edge.value / total_outgoing
                    new_taint = current_taint * proportion * (config.decay_factor ^ (hops + 1))

                    # Skip if taint below dust threshold
                    if new_taint < config.dust_threshold
                        continue
                    end

                    next_address = edge.to
                    new_path = vcat(path, [next_address])
                    new_total_flow = total_flow + edge.value

                    # Update taint result if this is better than existing
                    if !haskey(taint_results, next_address) ||
                       taint_results[next_address].taint_share < new_taint

                        taint_results[next_address] = TaintResult(
                            next_address,
                            new_taint,
                            hops + 1,
                            incident_id,
                            new_path,
                            new_total_flow
                        )

                        # Add to queue for further propagation
                        push!(queue, (next_address, hops + 1, new_taint, incident_id, new_path, new_total_flow))
                    end
                end
            end
        end
    end

    return taint_results
end

"""
    calculate_taint_metrics(taint_results::Dict{String, TaintResult})

Calculate aggregate metrics from taint propagation results.
"""
function calculate_taint_metrics(taint_results::Dict{String, TaintResult})
    if isempty(taint_results)
        return Dict{String, Any}(
            "total_tainted_addresses" => 0,
            "max_taint_share" => 0.0,
            "avg_taint_share" => 0.0,
            "max_hop_distance" => 0,
            "avg_hop_distance" => 0.0,
            "total_flow_through_taint" => 0.0
        )
    end

    taint_shares = [result.taint_share for result in values(taint_results)]
    hop_distances = [result.hop_distance for result in values(taint_results)]
    total_flows = [result.total_flow_from_seed for result in values(taint_results)]

    return Dict{String, Any}(
        "total_tainted_addresses" => length(taint_results),
        "max_taint_share" => maximum(taint_shares),
        "avg_taint_share" => sum(taint_shares) / length(taint_shares),
        "max_hop_distance" => maximum(hop_distances),
        "avg_hop_distance" => sum(hop_distances) / length(hop_distances),
        "total_flow_through_taint" => sum(total_flows),
        "incident_coverage" => length(unique(result.incident_id for result in values(taint_results)))
    )
end

"""
    get_taint_for_address(taint_results::Dict{String, TaintResult}, address::String)

Get taint information for a specific address, returns nothing if not tainted.
"""
function get_taint_for_address(taint_results::Dict{String, TaintResult}, address::String)
    return get(taint_results, address, nothing)
end

"""
    filter_high_taint_addresses(taint_results::Dict{String, TaintResult}, min_taint::Float64=0.1)

Filter addresses with taint above threshold for risk analysis.
"""
function filter_high_taint_addresses(taint_results::Dict{String, TaintResult}, min_taint::Float64=0.1)
    return filter(pair -> pair.second.taint_share >= min_taint, taint_results)
end

"""
    validate_taint_results(taint_results::Dict{String, TaintResult})

Validate taint propagation results for consistency and quality.
"""
function validate_taint_results(taint_results::Dict{String, TaintResult})
    validation = Dict{String, Any}(
        "is_valid" => true,
        "issues" => String[],
        "stats" => Dict{String, Any}()
    )

    # Check for invalid taint values
    invalid_taint = filter(pair -> pair.second.taint_share < 0 || pair.second.taint_share > 1, taint_results)
    if !isempty(invalid_taint)
        validation["is_valid"] = false
        push!(validation["issues"], "Found $(length(invalid_taint)) addresses with invalid taint values")
    end

    # Check for negative hop distances
    negative_hops = filter(pair -> pair.second.hop_distance < 0, taint_results)
    if !isempty(negative_hops)
        validation["is_valid"] = false
        push!(validation["issues"], "Found $(length(negative_hops)) addresses with negative hop distances")
    end

    # Add quality stats
    validation["stats"]["total_results"] = length(taint_results)
    validation["stats"]["avg_taint"] = isempty(taint_results) ? 0.0 :
        sum(result.taint_share for result in values(taint_results)) / length(taint_results)

    return validation
end

# Export functions for use in analysis pipeline
export TaintSeed, TaintResult, TaintConfig, DEFAULT_TAINT_CONFIG
export propagate_taint, calculate_taint_metrics, get_taint_for_address
export filter_high_taint_addresses, validate_taint_results
