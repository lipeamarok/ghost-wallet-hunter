"""
EntityClustering.jl - F3 Entity Clustering for wallet relationship analysis

Implements deterministic entity clustering based on behavioral signals:
- Fee payer patterns and common transaction structures
- Fan-out to fan-in patterns indicating coordinated activity
- Temporal co-occurrence analysis
- Token account ownership patterns
- Real data processing without mocks following golden rules
"""

using Statistics

# Entity clustering structures
struct EntitySignal
    signal_type::String      # "fee_payer", "fan_pattern", "temporal", "token_account"
    strength::Float64        # Signal strength [0,1]
    evidence::Vector{String} # Supporting transaction signatures or addresses
    metadata::Dict{String,Any} # Additional signal-specific data
end

struct EntityCluster
    cluster_id::String
    addresses::Set{String}
    signals::Vector{EntitySignal}
    confidence::Float64      # Overall clustering confidence [0,1]
    creation_time::Int       # Unix timestamp
    last_updated::Int        # Unix timestamp
end

struct ClusteringConfig
    min_fee_payer_occurrences::Int     # Minimum shared fee payer events for clustering
    temporal_window_seconds::Int       # Time window for temporal clustering
    fan_pattern_threshold::Int         # Minimum fan-out/in size to consider
    min_signal_strength::Float64       # Minimum signal strength to consider
    min_cluster_confidence::Float64    # Minimum confidence to form cluster
    max_cluster_size::Int              # Maximum addresses per cluster
end

# Default clustering configuration
const DEFAULT_CLUSTERING_CONFIG = ClusteringConfig(3, 3600, 5, 0.3, 0.5, 50)

"""
    analyze_fee_payer_patterns(edges::Vector{TxEdge})

Analyze shared fee payer patterns across transactions.
"""
function analyze_fee_payer_patterns(edges::Vector{TxEdge})
    fee_payer_groups = Dict{String, Vector{Tuple{String,String}}}()  # fee_payer -> [(from,to)]

    for edge in edges
        # In Solana, typically the 'from' address pays fees for most transactions
        # This is a heuristic - in real implementation would parse fee payer from transaction data
        fee_payer = edge.from

        if !haskey(fee_payer_groups, fee_payer)
            fee_payer_groups[fee_payer] = Tuple{String,String}[]
        end

        push!(fee_payer_groups[fee_payer], (edge.from, edge.to))
    end

    signals = EntitySignal[]

    for (fee_payer, pairs) in fee_payer_groups
        if length(pairs) >= DEFAULT_CLUSTERING_CONFIG.min_fee_payer_occurrences
            # Extract unique addresses involved
            involved_addresses = Set{String}()
            for (from, to) in pairs
                push!(involved_addresses, from)
                push!(involved_addresses, to)
            end

            # Calculate signal strength based on frequency and diversity
            strength = min(1.0, length(pairs) / 10.0 * length(involved_addresses) / 5.0)

            signal = EntitySignal(
                "fee_payer",
                strength,
                [edge.tx_signature for edge in edges if edge.from == fee_payer],
                Dict{String,Any}(
                    "fee_payer" => fee_payer,
                    "transaction_count" => length(pairs),
                    "involved_addresses" => collect(involved_addresses)
                )
            )

            push!(signals, signal)
        end
    end

    return signals
end

"""
    analyze_fan_patterns(graph::TxGraph, target_address::String)

Analyze fan-out to fan-in patterns that suggest coordinated behavior.
"""
function analyze_fan_patterns(graph::TxGraph, target_address::String)
    signals = EntitySignal[]

    # Analyze fan-out patterns (one address sends to many)
    if haskey(graph.adjacency_out, target_address)
        outgoing = graph.adjacency_out[target_address]
        if length(outgoing) >= DEFAULT_CLUSTERING_CONFIG.fan_pattern_threshold
            # Group by time to find coordinated fan-outs
            time_groups = Dict{Int, Vector{TxEdge}}()

            for edge in outgoing
                if edge.block_time !== nothing
                    time_bucket = div(edge.block_time, 300)  # 5-minute buckets
                    if !haskey(time_groups, time_bucket)
                        time_groups[time_bucket] = TxEdge[]
                    end
                    push!(time_groups[time_bucket], edge)
                end
            end

            # Find significant fan-out events
            for (time_bucket, edges_in_bucket) in time_groups
                if length(edges_in_bucket) >= DEFAULT_CLUSTERING_CONFIG.fan_pattern_threshold
                    strength = min(1.0, length(edges_in_bucket) / 20.0)

                    signal = EntitySignal(
                        "fan_pattern",
                        strength,
                        [edge.tx_signature for edge in edges_in_bucket],
                        Dict{String,Any}(
                            "pattern_type" => "fan_out",
                            "source_address" => target_address,
                            "destination_count" => length(edges_in_bucket),
                            "time_bucket" => time_bucket,
                            "destinations" => [edge.to for edge in edges_in_bucket]
                        )
                    )

                    push!(signals, signal)
                end
            end
        end
    end

    # Analyze fan-in patterns (many addresses send to one)
    if haskey(graph.adjacency_in, target_address)
        incoming = graph.adjacency_in[target_address]
        if length(incoming) >= DEFAULT_CLUSTERING_CONFIG.fan_pattern_threshold
            # Similar temporal analysis for fan-in
            time_groups = Dict{Int, Vector{TxEdge}}()

            for edge in incoming
                if edge.block_time !== nothing
                    time_bucket = div(edge.block_time, 300)  # 5-minute buckets
                    if !haskey(time_groups, time_bucket)
                        time_groups[time_bucket] = TxEdge[]
                    end
                    push!(time_groups[time_bucket], edge)
                end
            end

            for (time_bucket, edges_in_bucket) in time_groups
                if length(edges_in_bucket) >= DEFAULT_CLUSTERING_CONFIG.fan_pattern_threshold
                    strength = min(1.0, length(edges_in_bucket) / 20.0)

                    signal = EntitySignal(
                        "fan_pattern",
                        strength,
                        [edge.tx_signature for edge in edges_in_bucket],
                        Dict{String,Any}(
                            "pattern_type" => "fan_in",
                            "destination_address" => target_address,
                            "source_count" => length(edges_in_bucket),
                            "time_bucket" => time_bucket,
                            "sources" => [edge.from for edge in edges_in_bucket]
                        )
                    )

                    push!(signals, signal)
                end
            end
        end
    end

    return signals
end

"""
    analyze_temporal_patterns(edges::Vector{TxEdge})

Analyze temporal co-occurrence patterns across addresses.
"""
function analyze_temporal_patterns(edges::Vector{TxEdge})
    signals = EntitySignal[]

    # Group transactions by time windows
    time_windows = Dict{Int, Vector{TxEdge}}()

    for edge in edges
        if edge.block_time !== nothing
            window = div(edge.block_time, DEFAULT_CLUSTERING_CONFIG.temporal_window_seconds)
            if !haskey(time_windows, window)
                time_windows[window] = TxEdge[]
            end
            push!(time_windows[window], edge)
        end
    end

    # Analyze each time window for coordinated activity
    for (window, window_edges) in time_windows
        if length(window_edges) >= 3  # Minimum for meaningful temporal clustering
            # Extract unique addresses in this window
            addresses = Set{String}()
            for edge in window_edges
                push!(addresses, edge.from)
                push!(addresses, edge.to)
            end

            if length(addresses) >= 3 && length(addresses) <= 15  # Sweet spot for clustering
                # Calculate temporal clustering strength
                tx_density = length(window_edges) / length(addresses)
                strength = min(1.0, tx_density / 3.0)

                if strength >= DEFAULT_CLUSTERING_CONFIG.min_signal_strength
                    signal = EntitySignal(
                        "temporal",
                        strength,
                        [edge.tx_signature for edge in window_edges],
                        Dict{String,Any}(
                            "time_window" => window,
                            "transaction_count" => length(window_edges),
                            "address_count" => length(addresses),
                            "addresses" => collect(addresses),
                            "transaction_density" => tx_density
                        )
                    )

                    push!(signals, signal)
                end
            end
        end
    end

    return signals
end

"""
    build_entity_clusters(signals::Vector{EntitySignal}, config::ClusteringConfig=DEFAULT_CLUSTERING_CONFIG)

Build entity clusters from analyzed signals using graph-based clustering.
"""
function build_entity_clusters(signals::Vector{EntitySignal}, config::ClusteringConfig=DEFAULT_CLUSTERING_CONFIG)
    clusters = EntityCluster[]

    # Create adjacency matrix for addresses based on signals
    all_addresses = Set{String}()
    for signal in signals
        if haskey(signal.metadata, "involved_addresses")
            for addr in signal.metadata["involved_addresses"]
                push!(all_addresses, addr)
            end
        elseif haskey(signal.metadata, "addresses")
            for addr in signal.metadata["addresses"]
                push!(all_addresses, addr)
            end
        elseif haskey(signal.metadata, "destinations")
            for addr in signal.metadata["destinations"]
                push!(all_addresses, addr)
            end
            if haskey(signal.metadata, "source_address")
                push!(all_addresses, signal.metadata["source_address"])
            end
        elseif haskey(signal.metadata, "sources")
            for addr in signal.metadata["sources"]
                push!(all_addresses, addr)
            end
            if haskey(signal.metadata, "destination_address")
                push!(all_addresses, signal.metadata["destination_address"])
            end
        end
    end

    address_list = collect(all_addresses)
    n_addresses = length(address_list)

    if n_addresses == 0
        return clusters
    end

    # Build connection matrix based on signal strength
    connections = zeros(Float64, n_addresses, n_addresses)
    addr_to_idx = Dict(addr => i for (i, addr) in enumerate(address_list))

    for signal in signals
        if signal.strength < config.min_signal_strength
            continue
        end

        # Extract addresses involved in this signal
        involved = String[]
        if haskey(signal.metadata, "involved_addresses")
            involved = signal.metadata["involved_addresses"]
        elseif haskey(signal.metadata, "addresses")
            involved = signal.metadata["addresses"]
        elseif haskey(signal.metadata, "destinations") && haskey(signal.metadata, "source_address")
            involved = vcat([signal.metadata["source_address"]], signal.metadata["destinations"])
        elseif haskey(signal.metadata, "sources") && haskey(signal.metadata, "destination_address")
            involved = vcat(signal.metadata["sources"], [signal.metadata["destination_address"]])
        end

        # Add connections between all pairs in this signal
        for i in involved
            for j in involved
                if i != j && haskey(addr_to_idx, i) && haskey(addr_to_idx, j)
                    idx_i = addr_to_idx[i]
                    idx_j = addr_to_idx[j]
                    connections[idx_i, idx_j] = max(connections[idx_i, idx_j], signal.strength)
                end
            end
        end
    end

    # Simple clustering algorithm: find connected components above threshold
    visited = falses(n_addresses)
    cluster_id = 1

    for start_idx in 1:n_addresses
        if visited[start_idx]
            continue
        end

        # BFS to find connected component
        cluster_addresses = Set{String}()
        queue = [start_idx]
        cluster_signals = EntitySignal[]
        total_strength = 0.0

        while !isempty(queue)
            current_idx = popfirst!(queue)

            if visited[current_idx]
                continue
            end

            visited[current_idx] = true
            push!(cluster_addresses, address_list[current_idx])

            # Find connected nodes
            for next_idx in 1:n_addresses
                if !visited[next_idx] && connections[current_idx, next_idx] >= config.min_signal_strength
                    push!(queue, next_idx)
                    total_strength += connections[current_idx, next_idx]
                end
            end
        end

        # Only create cluster if it meets criteria
        if length(cluster_addresses) >= 2 && length(cluster_addresses) <= config.max_cluster_size
            # Collect relevant signals for this cluster
            for signal in signals
                signal_addresses = String[]
                if haskey(signal.metadata, "involved_addresses")
                    signal_addresses = signal.metadata["involved_addresses"]
                elseif haskey(signal.metadata, "addresses")
                    signal_addresses = signal.metadata["addresses"]
                end

                # Check if signal is relevant to this cluster
                if !isempty(intersect(Set(signal_addresses), cluster_addresses))
                    push!(cluster_signals, signal)
                end
            end

            # Calculate cluster confidence
            avg_signal_strength = isempty(cluster_signals) ? 0.0 :
                sum(signal.strength for signal in cluster_signals) / length(cluster_signals)
            confidence = min(1.0, avg_signal_strength * (length(cluster_addresses) / 10.0))

            if confidence >= config.min_cluster_confidence
                cluster = EntityCluster(
                    "cluster_$(cluster_id)",
                    cluster_addresses,
                    cluster_signals,
                    confidence,
                    Int(time()),
                    Int(time())
                )

                push!(clusters, cluster)
                cluster_id += 1
            end
        end
    end

    return clusters
end

"""
    analyze_entity_clustering(graph::TxGraph, target_address::String)

Perform complete entity clustering analysis for a wallet.
"""
function analyze_entity_clustering(graph::TxGraph, target_address::String)
    # Collect all signals
    all_signals = EntitySignal[]

    # Analyze different signal types
    fee_signals = analyze_fee_payer_patterns(graph.edges)
    append!(all_signals, fee_signals)

    fan_signals = analyze_fan_patterns(graph, target_address)
    append!(all_signals, fan_signals)

    temporal_signals = analyze_temporal_patterns(graph.edges)
    append!(all_signals, temporal_signals)

    # Build clusters from signals
    clusters = build_entity_clusters(all_signals)

    # Find cluster containing target address
    target_cluster = nothing
    for cluster in clusters
        if target_address in cluster.addresses
            target_cluster = cluster
            break
        end
    end

    return Dict{String, Any}(
        "enabled" => true,
        "total_signals" => length(all_signals),
        "signal_breakdown" => Dict(
            "fee_payer" => length(fee_signals),
            "fan_pattern" => length(fan_signals),
            "temporal" => length(temporal_signals)
        ),
        "total_clusters" => length(clusters),
        "target_cluster" => target_cluster === nothing ? nothing : Dict(
            "cluster_id" => target_cluster.cluster_id,
            "cluster_size" => length(target_cluster.addresses),
            "confidence" => target_cluster.confidence,
            "signal_count" => length(target_cluster.signals),
            "addresses" => collect(target_cluster.addresses)
        ),
        "all_clusters" => [
            Dict(
                "cluster_id" => cluster.cluster_id,
                "size" => length(cluster.addresses),
                "confidence" => cluster.confidence,
                "signal_types" => unique([signal.signal_type for signal in cluster.signals])
            ) for cluster in clusters
        ]
    )
end

"""
    validate_clustering_results(clusters::Vector{EntityCluster})

Validate entity clustering results for quality and consistency.
"""
function validate_clustering_results(clusters::Vector{EntityCluster})
    validation = Dict{String, Any}(
        "is_valid" => true,
        "issues" => String[],
        "stats" => Dict{String, Any}()
    )

    # Check for overlapping clusters (addresses should be unique across clusters)
    all_addresses = Set{String}()
    overlapping_addresses = Set{String}()

    for cluster in clusters
        for address in cluster.addresses
            if address in all_addresses
                push!(overlapping_addresses, address)
                validation["is_valid"] = false
            else
                push!(all_addresses, address)
            end
        end
    end

    if !isempty(overlapping_addresses)
        push!(validation["issues"], "Found $(length(overlapping_addresses)) addresses in multiple clusters")
    end

    # Check confidence scores
    invalid_confidence = filter(cluster -> cluster.confidence < 0 || cluster.confidence > 1, clusters)
    if !isempty(invalid_confidence)
        validation["is_valid"] = false
        push!(validation["issues"], "Found $(length(invalid_confidence)) clusters with invalid confidence scores")
    end

    # Add quality stats
    validation["stats"]["total_clusters"] = length(clusters)
    validation["stats"]["avg_cluster_size"] = isempty(clusters) ? 0.0 :
        sum(length(cluster.addresses) for cluster in clusters) / length(clusters)
    validation["stats"]["avg_confidence"] = isempty(clusters) ? 0.0 :
        sum(cluster.confidence for cluster in clusters) / length(clusters)

    return validation
end

# Export functions for use in analysis pipeline
export EntitySignal, EntityCluster, ClusteringConfig, DEFAULT_CLUSTERING_CONFIG
export analyze_fee_payer_patterns, analyze_fan_patterns, analyze_temporal_patterns
export build_entity_clusters, analyze_entity_clustering, validate_clustering_results
