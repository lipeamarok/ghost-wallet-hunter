"""
GraphMetrics.jl - Graph statistics export (F1_graph_stats)

Exports comprehensive graph metrics from real transaction data.
NO MOCKS - all statistics derived from actual parsed transactions.
"""

# Dependencies are loaded by the parent Analysis module; no local includes/usings needed

"""
Generate comprehensive graph statistics for export.
All metrics calculated from real transaction graph data.
"""
function generate_graph_stats(graph::TxGraph, center_wallet::String)::GraphStats
    # Basic graph metrics
    node_count = length(graph.nodes)
    edge_count = length(graph.edges)
    density = calculate_graph_density(graph)

    # Calculate max hops from center wallet
    reachable_nodes = find_nodes_within_hops(graph, center_wallet, 10)  # Max 10 hops
    max_hops = isempty(reachable_nodes) ? 0 : maximum(values(reachable_nodes))

    # Fan-in analysis for all nodes
    fan_in_stats = Dict{String,Any}()
    for node in graph.nodes
        fan_in_stats[node] = calculate_fan_in(graph, node)
    end

    # Fan-out analysis for all nodes
    fan_out_stats = Dict{String,Any}()
    for node in graph.nodes
        fan_out_stats[node] = calculate_fan_out(graph, node)
    end

    # Net flow analysis for all nodes
    net_flow_stats = Dict{String,Any}()
    for node in graph.nodes
        net_flow_stats[node] = calculate_net_flow(graph, node)
    end

    return GraphStats(
        node_count,
        edge_count,
        max_hops,
        density,
        fan_in_stats,
        fan_out_stats,
        net_flow_stats
    )
end

"""
Export graph statistics to JSON-compatible format.
Real data export for investigation reports.
"""
function export_graph_stats_json(stats::GraphStats, center_wallet::String)::Dict{String,Any}
    # Calculate aggregate statistics
    all_net_flows = [flow["net_flow"] for flow in values(stats.net_flow_stats)]
    all_fan_ins = [fan["count"] for fan in values(stats.fan_in_stats)]
    all_fan_outs = [fan["count"] for fan in values(stats.fan_out_stats)]

    # Find top nodes by different metrics
    top_fan_in = sort(collect(stats.fan_in_stats), by=x->x[2]["total_value"], rev=true)[1:min(5, length(stats.fan_in_stats))]
    top_fan_out = sort(collect(stats.fan_out_stats), by=x->x[2]["total_value"], rev=true)[1:min(5, length(stats.fan_out_stats))]
    top_net_flow = sort(collect(stats.net_flow_stats), by=x->x[2]["net_flow"], rev=true)[1:min(5, length(stats.net_flow_stats))]

    return Dict{String,Any}(
        "graph_overview" => Dict(
            "nodes" => stats.nodes,
            "edges" => stats.edges,
            "max_hops" => stats.max_hops,
            "density" => stats.density,
            "center_wallet" => center_wallet
        ),
        "aggregate_metrics" => Dict(
            "total_net_flow" => sum(all_net_flows),
            "avg_fan_in" => isempty(all_fan_ins) ? 0.0 : sum(all_fan_ins) / length(all_fan_ins),
            "avg_fan_out" => isempty(all_fan_outs) ? 0.0 : sum(all_fan_outs) / length(all_fan_outs),
            "max_net_flow" => isempty(all_net_flows) ? 0.0 : maximum(all_net_flows),
            "min_net_flow" => isempty(all_net_flows) ? 0.0 : minimum(all_net_flows)
        ),
        "top_nodes" => Dict(
            "highest_fan_in" => [Dict("address"=>addr, "metrics"=>metrics) for (addr, metrics) in top_fan_in],
            "highest_fan_out" => [Dict("address"=>addr, "metrics"=>metrics) for (addr, metrics) in top_fan_out],
            "highest_net_flow" => [Dict("address"=>addr, "metrics"=>metrics) for (addr, metrics) in top_net_flow]
        ),
        "center_wallet_metrics" => Dict(
            "fan_in" => get(stats.fan_in_stats, center_wallet, Dict()),
            "fan_out" => get(stats.fan_out_stats, center_wallet, Dict()),
            "net_flow" => get(stats.net_flow_stats, center_wallet, Dict())
        )
    )
end

"""
Calculate graph connectivity patterns.
Real analysis of transaction flow patterns.
"""
function analyze_connectivity_patterns(graph::TxGraph, center_wallet::String)::Dict{String,Any}
    patterns = Dict{String,Any}()

    # Hub detection (nodes with high fan-in or fan-out)
    hubs = String[]
    for node in graph.nodes
        fan_in = calculate_fan_in(graph, node)
        fan_out = calculate_fan_out(graph, node)

        if fan_in["count"] > 10 || fan_out["count"] > 10 || fan_in["total_value"] > 100.0 || fan_out["total_value"] > 100.0
            push!(hubs, node)
        end
    end
    patterns["hubs"] = hubs

    # Isolated nodes (no connections)
    isolated = String[]
    for node in graph.nodes
        if !haskey(graph.adjacency_in, node) && !haskey(graph.adjacency_out, node)
            push!(isolated, node)
        end
    end
    patterns["isolated_nodes"] = isolated

    # Sink nodes (only incoming)
    sinks = String[]
    for node in graph.nodes
        has_incoming = haskey(graph.adjacency_in, node) && !isempty(graph.adjacency_in[node])
        has_outgoing = haskey(graph.adjacency_out, node) && !isempty(graph.adjacency_out[node])

        if has_incoming && !has_outgoing
            push!(sinks, node)
        end
    end
    patterns["sink_nodes"] = sinks

    # Source nodes (only outgoing)
    sources = String[]
    for node in graph.nodes
        has_incoming = haskey(graph.adjacency_in, node) && !isempty(graph.adjacency_in[node])
        has_outgoing = haskey(graph.adjacency_out, node) && !isempty(graph.adjacency_out[node])

        if !has_incoming && has_outgoing
            push!(sources, node)
        end
    end
    patterns["source_nodes"] = sources

    return patterns
end

"""
Generate performance metrics for graph operations.
Real performance analysis - no simulated data.
"""
function calculate_performance_metrics(graph::TxGraph)::Dict{String,Any}
    start_time = time()

    # Test graph traversal performance
    sample_nodes = collect(graph.nodes)[1:min(5, length(graph.nodes))]
    traversal_times = Float64[]

    for node in sample_nodes
        node_start = time()
        find_nodes_within_hops(graph, node, 3)
        push!(traversal_times, time() - node_start)
    end

    total_time = time() - start_time

    return Dict{String,Any}(
        "total_analysis_time" => total_time,
        "avg_traversal_time" => isempty(traversal_times) ? 0.0 : sum(traversal_times) / length(traversal_times),
        "nodes_per_second" => total_time > 0 ? length(graph.nodes) / total_time : 0.0,
        "edges_per_second" => total_time > 0 ? length(graph.edges) / total_time : 0.0
    )
end

export generate_graph_stats, export_graph_stats_json, analyze_connectivity_patterns, calculate_performance_metrics
