"""
F5 Influence Analysis Module - Contrafactual Impact Assessment

Implements influence analysis to determine how much individual nodes/clusters
affect the overall network flow and taint propagation. Uses counterfactual
analysis to rank addresses by their importance to fund flows.

No mocks - real algorithm implementation following ghost wallet hunter golden rules.
"""

using LinearAlgebra
using Statistics

"""
Influence metric for a single address
"""
struct AddressInfluence
    address::String
    baseline_flow::Float64      # Flow in original network
    counterfactual_flow::Float64 # Flow when address is removed
    influence_score::Float64    # Difference normalized
    taint_influence::Float64    # Impact on taint propagation
    centrality_score::Float64   # Network centrality measure
    criticality_level::String   # HIGH/MEDIUM/LOW classification
end

"""
Network influence analysis result
"""
struct InfluenceAnalysis
    total_addresses::Int
    addresses_analyzed::Int
    top_influencers::Vector{AddressInfluence}
    influence_distribution::Dict{String, Float64}  # level -> count percentage
    network_fragility::Float64  # How dependent network is on key nodes
    computation_metrics::Dict{String, Any}
end

"""
Calculate betweenness centrality for an address in the transaction graph
"""
function calculate_betweenness_centrality(address::String, tx_graph::TxGraph)::Float64
    # Get all unique addresses
    all_addresses = Set{String}()
    for (from_addr, edges) in tx_graph.adjacency_list
        push!(all_addresses, from_addr)
        for edge in edges
            push!(all_addresses, edge.to_address)
        end
    end

    addresses_list = collect(all_addresses)
    n = length(addresses_list)

    if n <= 2
        return 0.0
    end

    # Calculate shortest paths from all addresses
    betweenness = 0.0
    path_count = 0

    for source in addresses_list
        if source == address
            continue
        end

        # Simple BFS to find shortest paths from source
        distances = Dict{String, Int}()
        paths_through = Dict{String, Int}()
        queue = Vector{String}()

        distances[source] = 0
        paths_through[source] = 1
        push!(queue, source)

        while !isempty(queue)
            current = popfirst!(queue)
            current_dist = distances[current]

            # Get neighbors
            neighbors = String[]
            if haskey(tx_graph.adjacency_list, current)
                for edge in tx_graph.adjacency_list[current]
                    push!(neighbors, edge.to_address)
                end
            end

            for neighbor in neighbors
                if !haskey(distances, neighbor)
                    distances[neighbor] = current_dist + 1
                    paths_through[neighbor] = paths_through[current]
                    push!(queue, neighbor)
                elseif distances[neighbor] == current_dist + 1
                    paths_through[neighbor] += paths_through[current]
                end
            end
        end

        # Count paths that go through our target address
        for target in addresses_list
            if target != source && target != address
                if haskey(distances, target) && haskey(distances, address)
                    if distances[address] + 1 == distances[target] &&
                       haskey(paths_through, address) && haskey(paths_through, target)
                        # Path from source to target goes through address
                        total_paths = get(paths_through, target, 0)
                        paths_via_address = get(paths_through, address, 0)

                        if total_paths > 0
                            betweenness += paths_via_address / total_paths
                            path_count += 1
                        end
                    end
                end
            end
        end
    end

    # Normalize by maximum possible betweenness
    max_betweenness = (n - 1) * (n - 2) / 2
    return max_betweenness > 0 ? betweenness / max_betweenness : 0.0
end

"""
Simulate network with address removed for counterfactual analysis
"""
function simulate_network_without_address(tx_graph::TxGraph, removed_address::String)::TxGraph
    # Create new graph without the specified address
    new_adjacency = Dict{String, Vector{TxEdge}}()
    new_edges = Vector{TxEdge}()

    for (from_addr, edges) in tx_graph.adjacency_list
        if from_addr == removed_address
            continue  # Skip edges from removed address
        end

        filtered_edges = Vector{TxEdge}()
        for edge in edges
            if edge.to_address != removed_address
                push!(filtered_edges, edge)
                push!(new_edges, edge)
            end
        end

        if !isempty(filtered_edges)
            new_adjacency[from_addr] = filtered_edges
        end
    end

    return TxGraph(new_adjacency, new_edges)
end

"""
Calculate total flow value in a transaction graph
"""
function calculate_total_flow(tx_graph::TxGraph)::Float64
    total = 0.0
    for edge in tx_graph.edges
        total += edge.value_sol
    end
    return total
end

"""
Calculate maximum taint score in network
"""
function calculate_max_taint(taint_results::Dict{String, Any})::Float64
    address_scores = get(taint_results, "address_scores", Dict{String, Float64}())
    return isempty(address_scores) ? 0.0 : maximum(values(address_scores))
end

"""
Analyze influence of a specific address
"""
function analyze_address_influence(address::String, tx_graph::TxGraph, taint_results::Dict{String, Any})::AddressInfluence
    # Calculate baseline metrics
    baseline_flow = calculate_total_flow(tx_graph)
    baseline_taint = calculate_max_taint(taint_results)

    # Calculate centrality
    centrality = calculate_betweenness_centrality(address, tx_graph)

    # Simulate network without this address
    modified_graph = simulate_network_without_address(tx_graph, address)
    counterfactual_flow = calculate_total_flow(modified_graph)

    # Calculate influence metrics
    flow_difference = baseline_flow - counterfactual_flow
    influence_score = baseline_flow > 0 ? flow_difference / baseline_flow : 0.0

    # Estimate taint influence (simplified - based on centrality and direct taint)
    address_taint = get(get(taint_results, "address_scores", Dict{String, Float64}()), address, 0.0)
    taint_influence = centrality * address_taint

    # Classify criticality
    criticality = if influence_score > 0.1 || centrality > 0.3
        "HIGH"
    elseif influence_score > 0.05 || centrality > 0.1
        "MEDIUM"
    else
        "LOW"
    end

    return AddressInfluence(
        address,
        baseline_flow,
        counterfactual_flow,
        influence_score,
        taint_influence,
        centrality,
        criticality
    )
end

"""
Main influence analysis function
"""
function analyze_network_influence(tx_graph::TxGraph, taint_results::Dict{String, Any}, target_address::String; max_addresses::Int = 20, max_computation_time_s::Float64 = 45.0)::Dict{String, Any}
    start_time = time()

    try
        # Get all unique addresses from graph
        all_addresses = Set{String}()
        for (from_addr, edges) in tx_graph.adjacency_list
            push!(all_addresses, from_addr)
            for edge in edges
                push!(all_addresses, edge.to_address)
            end
        end

        addresses_list = collect(all_addresses)
        total_addresses = length(addresses_list)

        if total_addresses == 0
            return Dict{String, Any}(
                "total_addresses" => 0,
                "addresses_analyzed" => 0,
                "top_influencers" => [],
                "influence_distribution" => Dict{String, Float64}(),
                "network_fragility" => 0.0,
                "computation_time_s" => time() - start_time,
                "error" => "No addresses found in graph"
            )
        end

        # Prioritize addresses for analysis
        # 1. Target address (always include)
        # 2. Addresses with high taint scores
        # 3. Addresses with high transaction volume

        address_scores = get(taint_results, "address_scores", Dict{String, Float64}())
        prioritized_addresses = String[]

        # Always include target address first
        if target_address in addresses_list
            push!(prioritized_addresses, target_address)
        end

        # Sort other addresses by taint score + volume
        other_addresses = [addr for addr in addresses_list if addr != target_address]

        # Calculate volume per address
        address_volumes = Dict{String, Float64}()
        for (from_addr, edges) in tx_graph.adjacency_list
            vol = sum(edge.value_sol for edge in edges)
            address_volumes[from_addr] = get(address_volumes, from_addr, 0.0) + vol
        end
        for edge in tx_graph.edges
            to_addr = edge.to_address
            address_volumes[to_addr] = get(address_volumes, to_addr, 0.0) + edge.value_sol
        end

        # Score addresses by taint + volume
        scored_addresses = Tuple{String, Float64}[]
        for addr in other_addresses
            taint_score = get(address_scores, addr, 0.0)
            volume_score = get(address_volumes, addr, 0.0)
            # Normalize volume (simple percentile approach)
            volume_norm = isempty(address_volumes) ? 0.0 : volume_score / maximum(values(address_volumes))
            combined_score = taint_score * 0.7 + volume_norm * 0.3
            push!(scored_addresses, (addr, combined_score))
        end

        # Sort by combined score and take top addresses
        sort!(scored_addresses, by=x->x[2], rev=true)
        num_to_analyze = min(max_addresses - 1, length(scored_addresses))  # -1 for target address

        for i in 1:num_to_analyze
            push!(prioritized_addresses, scored_addresses[i][1])
        end

        # Analyze influence for selected addresses
        influences = Vector{AddressInfluence}()
        addresses_analyzed = 0

        for addr in prioritized_addresses
            # Check time limit
            if time() - start_time > max_computation_time_s
                break
            end

            try
                influence = analyze_address_influence(addr, tx_graph, taint_results)
                push!(influences, influence)
                addresses_analyzed += 1
            catch e
                # Skip problematic addresses but continue analysis
                continue
            end
        end

        # Sort by influence score
        sort!(influences, by=x->x.influence_score, rev=true)

        # Calculate influence distribution
        distribution = Dict{String, Float64}(
            "HIGH" => 0.0,
            "MEDIUM" => 0.0,
            "LOW" => 0.0
        )

        for influence in influences
            distribution[influence.criticality_level] += 1.0
        end

        # Normalize to percentages
        if addresses_analyzed > 0
            for key in keys(distribution)
                distribution[key] = distribution[key] / addresses_analyzed * 100.0
            end
        end

        # Calculate network fragility (dependency on top nodes)
        fragility = 0.0
        if !isempty(influences)
            top_influences = [inf.influence_score for inf in influences[1:min(3, length(influences))]]
            fragility = mean(top_influences)
        end

        return Dict{String, Any}(
            "total_addresses" => total_addresses,
            "addresses_analyzed" => addresses_analyzed,
            "top_influencers" => [
                Dict{String, Any}(
                    "address" => inf.address,
                    "influence_score" => inf.influence_score,
                    "taint_influence" => inf.taint_influence,
                    "centrality_score" => inf.centrality_score,
                    "criticality_level" => inf.criticality_level,
                    "baseline_flow" => inf.baseline_flow,
                    "counterfactual_flow" => inf.counterfactual_flow
                ) for inf in influences
            ],
            "influence_distribution" => distribution,
            "network_fragility" => fragility,
            "computation_time_s" => time() - start_time,
            "analysis_quality" => addresses_analyzed / min(max_addresses, total_addresses),
            "prioritization_used" => addresses_analyzed < total_addresses
        )

    catch e
        return Dict{String, Any}(
            "total_addresses" => 0,
            "addresses_analyzed" => 0,
            "top_influencers" => [],
            "influence_distribution" => Dict{String, Float64}(),
            "network_fragility" => 0.0,
            "computation_time_s" => time() - start_time,
            "error" => "Influence analysis failed: $(string(e))"
        )
    end
end
