"""
Explainability.jl - F4 Evidence Path Analysis and Explainability

Implements k-shortest paths and evidence selection for transaction flow explanation:
- Multi-criteria k-shortest paths (hops, time, value weight)
- Top evidence selection based on flow contribution
- Path ranking by relevance and significance
- Real path analysis without mocks following golden rules
"""

using DataStructures

# Evidence path structures
struct EvidencePath
    path_id::String
    source::String
    destination::String
    hops::Int
    total_value::Float64
    segments::Vector{TxEdge}
    path_score::Float64          # Relevance score [0,1]
    taint_involvement::Float64   # Taint level along path [0,1]
    metadata::Dict{String,Any}   # Path-specific information
end

struct PathSegment
    from::String
    to::String
    slot::Union{Nothing,Int}
    program::String
    value::Float64
    token::String                # Token type or "SOL"
    hop::Int                    # Position in path
    edge_data::TxEdge           # Original edge reference
end

struct ExplainabilityConfig
    max_paths_per_pair::Int      # Maximum k for k-shortest paths
    max_hops::Int               # Maximum path length to consider
    min_path_value::Float64     # Minimum total value for path relevance
    weight_hops::Float64        # Weight for hop count in scoring
    weight_value::Float64       # Weight for value in scoring
    weight_time::Float64        # Weight for temporal proximity in scoring
    enable_taint_weighting::Bool # Boost paths with taint involvement
end

const DEFAULT_EXPLAINABILITY_CONFIG = ExplainabilityConfig(5, 6, 1.0, 0.3, 0.4, 0.3, true)

"""
    dijkstra_k_shortest_paths(graph::TxGraph, source::String, target::String, k::Int, config::ExplainabilityConfig)

Find k-shortest paths between source and target using modified Dijkstra with path tracking.
Multi-criteria: minimize (hops + value_weight + time_weight).
"""
function dijkstra_k_shortest_paths(graph::TxGraph, source::String, target::String, k::Int, config::ExplainabilityConfig)
    if source == target || !haskey(graph.adjacency_out, source)
        return EvidencePath[]
    end

    # Priority queue: (cost, current_node, path_edges, total_value)
    pq = PriorityQueue{Tuple{Float64, String, Vector{TxEdge}, Float64}, Float64}()

    # Track k-best paths found to target
    target_paths = EvidencePath[]

    # Initialize with source
    enqueue!(pq, (0.0, source, TxEdge[], 0.0), 0.0)

    # Track visited states to avoid infinite loops: (node, path_length)
    visited_states = Set{Tuple{String, Int}}()

    path_id = 1

    while !isempty(pq) && length(target_paths) < k
        (current_cost, current_node, path_edges, total_value) = dequeue!(pq)
        current_hops = length(path_edges)

        # Skip if we've reached max hops
        if current_hops >= config.max_hops
            continue
        end

        # Check if we've visited this state before
        state = (current_node, current_hops)
        if state in visited_states
            continue
        end
        push!(visited_states, state)

        # If we reached target, save path
        if current_node == target && current_hops > 0
            if total_value >= config.min_path_value
                # Calculate path score based on multiple criteria
                hops_score = 1.0 - (current_hops / config.max_hops)
                value_score = min(1.0, total_value / 100.0)  # Normalize to reasonable range
                time_score = calculate_temporal_score(path_edges)

                path_score = (config.weight_hops * hops_score +
                             config.weight_value * value_score +
                             config.weight_time * time_score)

                # Create evidence path
                evidence_path = EvidencePath(
                    "path_$(path_id)",
                    source,
                    target,
                    current_hops,
                    total_value,
                    copy(path_edges),
                    path_score,
                    0.0,  # Will be calculated later if taint data available
                    Dict{String,Any}(
                        "algorithm" => "dijkstra_k_shortest",
                        "cost" => current_cost,
                        "criteria_scores" => Dict(
                            "hops" => hops_score,
                            "value" => value_score,
                            "temporal" => time_score
                        )
                    )
                )

                push!(target_paths, evidence_path)
                path_id += 1
            end
            continue
        end

        # Explore neighbors
        if haskey(graph.adjacency_out, current_node)
            for edge in graph.adjacency_out[current_node]
                next_node = edge.to

                # Skip if this would create a cycle
                if any(e.to == next_node for e in path_edges)
                    continue
                end

                # Calculate edge cost (multi-criteria)
                hop_cost = 1.0 * config.weight_hops
                value_cost = (1.0 / max(edge.value, 0.1)) * config.weight_value  # Prefer higher values
                time_cost = calculate_time_cost(edge, path_edges) * config.weight_time

                edge_cost = hop_cost + value_cost + time_cost
                new_cost = current_cost + edge_cost
                new_total_value = total_value + edge.value
                new_path = vcat(path_edges, [edge])

                # Add to queue for exploration
                enqueue!(pq, (new_cost, next_node, new_path, new_total_value), new_cost)
            end
        end
    end

    # Sort paths by score (descending)
    sort!(target_paths, by = p -> p.path_score, rev = true)

    return target_paths[1:min(k, length(target_paths))]
end

"""
    calculate_temporal_score(path_edges::Vector{TxEdge})

Calculate temporal consistency score for a path.
"""
function calculate_temporal_score(path_edges::Vector{TxEdge})
    if length(path_edges) <= 1
        return 1.0
    end

    # Check temporal ordering and proximity
    valid_times = filter(e -> e.block_time !== nothing, path_edges)
    if length(valid_times) <= 1
        return 0.5  # Neutral score for missing time data
    end

    # Calculate temporal consistency (monotonic ordering)
    time_violations = 0
    max_time_gap = 0

    for i in 2:length(valid_times)
        if valid_times[i].block_time < valid_times[i-1].block_time
            time_violations += 1
        else
            time_gap = valid_times[i].block_time - valid_times[i-1].block_time
            max_time_gap = max(max_time_gap, time_gap)
        end
    end

    # Score based on temporal consistency and proximity
    consistency_score = 1.0 - (time_violations / length(valid_times))
    proximity_score = max(0.0, 1.0 - (max_time_gap / 86400))  # Penalize gaps > 1 day

    return (consistency_score + proximity_score) / 2.0
end

"""
    calculate_time_cost(edge::TxEdge, existing_path::Vector{TxEdge})

Calculate time-based cost for adding an edge to existing path.
"""
function calculate_time_cost(edge::TxEdge, existing_path::Vector{TxEdge})
    if isempty(existing_path) || edge.block_time === nothing
        return 0.0
    end

    last_edge = existing_path[end]
    if last_edge.block_time === nothing
        return 0.0
    end

    # Prefer edges that maintain temporal order
    if edge.block_time >= last_edge.block_time
        time_gap = edge.block_time - last_edge.block_time
        return min(1.0, time_gap / 3600.0)  # Normalize by hours
    else
        return 2.0  # High cost for temporal violations
    end
end

"""
    find_evidence_paths(graph::TxGraph, target_address::String, taint_results::Dict{String,TaintResult}, config::ExplainabilityConfig=DEFAULT_EXPLAINABILITY_CONFIG)

Find significant evidence paths involving the target address.
"""
function find_evidence_paths(graph::TxGraph, target_address::String, taint_results::Dict{String,TaintResult}, config::ExplainabilityConfig=DEFAULT_EXPLAINABILITY_CONFIG)
    evidence_paths = EvidencePath[]

    # Find high-value addresses to trace paths from/to
    high_value_addresses = Set{String}()

    # Add addresses with high transaction values
    for edge in graph.edges
        if edge.value >= config.min_path_value * 5  # 5x threshold for starting points
            push!(high_value_addresses, edge.from)
            push!(high_value_addresses, edge.to)
        end
    end

    # Add tainted addresses as important endpoints
    for (address, taint_result) in taint_results
        if taint_result.taint_share >= 0.1  # Significant taint
            push!(high_value_addresses, address)
        end
    end

    # Remove target address from sources to avoid trivial paths
    delete!(high_value_addresses, target_address)

    # Find paths TO target from important sources
    for source_address in high_value_addresses
        if source_address != target_address
            paths = dijkstra_k_shortest_paths(graph, source_address, target_address, config.max_paths_per_pair, config)
            for path in paths
                # Enhance with taint information if available
                if config.enable_taint_weighting
                    path.taint_involvement = calculate_path_taint_involvement(path, taint_results)
                    # Boost score for tainted paths
                    path.path_score *= (1.0 + path.taint_involvement * 0.5)
                end
                push!(evidence_paths, path)
            end
        end
    end

    # Find paths FROM target to important destinations
    for dest_address in high_value_addresses
        if dest_address != target_address
            paths = dijkstra_k_shortest_paths(graph, target_address, dest_address, config.max_paths_per_pair, config)
            for path in paths
                if config.enable_taint_weighting
                    path.taint_involvement = calculate_path_taint_involvement(path, taint_results)
                    path.path_score *= (1.0 + path.taint_involvement * 0.5)
                end
                push!(evidence_paths, path)
            end
        end
    end

    # Sort by relevance score and take top paths
    sort!(evidence_paths, by = p -> p.path_score, rev = true)

    return evidence_paths[1:min(20, length(evidence_paths))]  # Top 20 most relevant paths
end

"""
    calculate_path_taint_involvement(path::EvidencePath, taint_results::Dict{String,TaintResult})

Calculate how much taint is involved in a path.
"""
function calculate_path_taint_involvement(path::EvidencePath, taint_results::Dict{String,TaintResult})
    if isempty(taint_results)
        return 0.0
    end

    total_taint = 0.0
    address_count = 0

    # Check source and destination
    for address in [path.source, path.destination]
        if haskey(taint_results, address)
            total_taint += taint_results[address].taint_share
            address_count += 1
        end
    end

    # Check intermediate addresses in path
    for edge in path.segments
        for address in [edge.from, edge.to]
            if haskey(taint_results, address)
                total_taint += taint_results[address].taint_share
                address_count += 1
            end
        end
    end

    return address_count > 0 ? min(1.0, total_taint / address_count) : 0.0
end

"""
    convert_to_path_segments(path::EvidencePath)

Convert evidence path to detailed segment format for JSON export.
"""
function convert_to_path_segments(path::EvidencePath)
    segments = PathSegment[]

    for (i, edge) in enumerate(path.segments)
        segment = PathSegment(
            edge.from,
            edge.to,
            edge.slot,
            edge.program,
            edge.value,
            "SOL",  # Default to SOL, could be enhanced to detect token types
            i,
            edge
        )
        push!(segments, segment)
    end

    return segments
end

"""
    analyze_evidence_paths(graph::TxGraph, target_address::String, taint_results::Dict{String,TaintResult})

Perform complete evidence path analysis for explainability.
"""
function analyze_evidence_paths(graph::TxGraph, target_address::String, taint_results::Dict{String,TaintResult})
    # Find evidence paths
    evidence_paths = find_evidence_paths(graph, target_address, taint_results)

    # Calculate aggregate metrics
    total_paths = length(evidence_paths)
    high_score_paths = length(filter(p -> p.path_score >= 0.7, evidence_paths))
    tainted_paths = length(filter(p -> p.taint_involvement > 0, evidence_paths))

    avg_hops = total_paths > 0 ? sum(p.hops for p in evidence_paths) / total_paths : 0.0
    avg_value = total_paths > 0 ? sum(p.total_value for p in evidence_paths) / total_paths : 0.0

    # Select top evidence paths for detailed export
    top_evidence = evidence_paths[1:min(10, length(evidence_paths))]

    return Dict{String, Any}(
        "enabled" => true,
        "total_paths_found" => total_paths,
        "high_relevance_paths" => high_score_paths,
        "tainted_paths" => tainted_paths,
        "path_metrics" => Dict(
            "avg_hops" => avg_hops,
            "avg_value" => avg_value,
            "max_hops" => isempty(evidence_paths) ? 0 : maximum(p.hops for p in evidence_paths),
            "total_value_traced" => sum(p.total_value for p in evidence_paths)
        ),
        "evidence_paths" => [
            Dict(
                "path_id" => path.path_id,
                "source" => path.source,
                "destination" => path.destination,
                "hops" => path.hops,
                "total_value" => path.total_value,
                "path_score" => path.path_score,
                "taint_involvement" => path.taint_involvement,
                "segments" => [
                    Dict(
                        "from" => segment.from,
                        "to" => segment.to,
                        "slot" => segment.slot,
                        "program" => segment.program,
                        "value" => segment.value,
                        "token" => segment.token,
                        "hop" => segment.hop
                    ) for segment in convert_to_path_segments(path)
                ]
            ) for path in top_evidence
        ]
    )
end

"""
    validate_evidence_paths(evidence_paths::Vector{EvidencePath})

Validate evidence path results for quality and consistency.
"""
function validate_evidence_paths(evidence_paths::Vector{EvidencePath})
    validation = Dict{String, Any}(
        "is_valid" => true,
        "issues" => String[],
        "stats" => Dict{String, Any}()
    )

    # Check for invalid path scores
    invalid_score_paths = filter(path -> path.path_score < 0 || path.path_score > 2.0, evidence_paths)  # Allow boost above 1.0
    if !isempty(invalid_score_paths)
        validation["is_valid"] = false
        push!(validation["issues"], "Found $(length(invalid_score_paths)) paths with invalid scores")
    end

    # Check for paths with negative values
    negative_value_paths = filter(path -> path.total_value < 0, evidence_paths)
    if !isempty(negative_value_paths)
        validation["is_valid"] = false
        push!(validation["issues"], "Found $(length(negative_value_paths)) paths with negative values")
    end

    # Check for path consistency (segments should connect)
    inconsistent_paths = filter(path -> !validate_path_consistency(path), evidence_paths)
    if !isempty(inconsistent_paths)
        validation["is_valid"] = false
        push!(validation["issues"], "Found $(length(inconsistent_paths)) paths with disconnected segments")
    end

    # Add quality stats
    validation["stats"]["total_paths"] = length(evidence_paths)
    validation["stats"]["avg_score"] = isempty(evidence_paths) ? 0.0 :
        sum(path.path_score for path in evidence_paths) / length(evidence_paths)
    validation["stats"]["avg_hops"] = isempty(evidence_paths) ? 0.0 :
        sum(path.hops for path in evidence_paths) / length(evidence_paths)

    return validation
end

"""
    validate_path_consistency(path::EvidencePath)

Check if path segments are properly connected.
"""
function validate_path_consistency(path::EvidencePath)
    if isempty(path.segments)
        return false
    end

    # First segment should start from source
    if path.segments[1].from != path.source
        return false
    end

    # Last segment should end at destination
    if path.segments[end].to != path.destination
        return false
    end

    # Check segment connectivity
    for i in 2:length(path.segments)
        if path.segments[i-1].to != path.segments[i].from
            return false
        end
    end

    return true
end

# Export functions for use in analysis pipeline
export EvidencePath, PathSegment, ExplainabilityConfig, DEFAULT_EXPLAINABILITY_CONFIG
export dijkstra_k_shortest_paths, find_evidence_paths, analyze_evidence_paths
export validate_evidence_paths, convert_to_path_segments
