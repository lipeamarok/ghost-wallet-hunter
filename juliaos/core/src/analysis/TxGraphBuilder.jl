"""
TxGraphBuilder.jl - Real transaction graph builder (F1_graph_builder)

Builds transaction graphs from parsed edges with efficient indexing.
NO MOCKS - processes real transaction data into graph structures.
"""

# TxTypes are included by the parent Analysis module; no local includes/usings needed

"""
Build a transaction graph from parsed edges.
Creates efficient adjacency lists for fast graph traversal.
"""
function build_graph(edges::Vector{TxEdge})::TxGraph
    graph = TxGraph()

    # Add all edges and build node set
    for edge in edges
        push!(graph.edges, edge)
        push!(graph.nodes, edge.from)
        push!(graph.nodes, edge.to)

        # Build outgoing adjacency list
        if !haskey(graph.adjacency_out, edge.from)
            graph.adjacency_out[edge.from] = TxEdge[]
        end
        push!(graph.adjacency_out[edge.from], edge)

        # Build incoming adjacency list
        if !haskey(graph.adjacency_in, edge.to)
            graph.adjacency_in[edge.to] = TxEdge[]
        end
        push!(graph.adjacency_in[edge.to], edge)
    end

    return graph
end

"""
Calculate fan-in statistics for a node.
Returns real metrics based on actual transaction data.
"""
function calculate_fan_in(graph::TxGraph, node::String)::Dict{String,Any}
    if !haskey(graph.adjacency_in, node)
        return Dict(
            "count" => 0,
            "total_value" => 0.0,
            "unique_sources" => 0,
            "avg_value" => 0.0,
            "max_value" => 0.0
        )
    end

    incoming_edges = graph.adjacency_in[node]
    values = [e.value for e in incoming_edges if e.value > 0]
    sources = Set([e.from for e in incoming_edges])

    return Dict(
        "count" => length(incoming_edges),
        "total_value" => sum(values),
        "unique_sources" => length(sources),
        "avg_value" => isempty(values) ? 0.0 : sum(values) / length(values),
        "max_value" => isempty(values) ? 0.0 : maximum(values)
    )
end

"""
Calculate fan-out statistics for a node.
Returns real metrics based on actual transaction data.
"""
function calculate_fan_out(graph::TxGraph, node::String)::Dict{String,Any}
    if !haskey(graph.adjacency_out, node)
        return Dict(
            "count" => 0,
            "total_value" => 0.0,
            "unique_destinations" => 0,
            "avg_value" => 0.0,
            "max_value" => 0.0
        )
    end

    outgoing_edges = graph.adjacency_out[node]
    values = [e.value for e in outgoing_edges if e.value > 0]
    destinations = Set([e.to for e in outgoing_edges])

    return Dict(
        "count" => length(outgoing_edges),
        "total_value" => sum(values),
        "unique_destinations" => length(destinations),
        "avg_value" => isempty(values) ? 0.0 : sum(values) / length(values),
        "max_value" => isempty(values) ? 0.0 : maximum(values)
    )
end

"""
Calculate net flow for a node (inflow - outflow).
Real calculation based on actual transaction values.
"""
function calculate_net_flow(graph::TxGraph, node::String)::Dict{String,Any}
    fan_in = calculate_fan_in(graph, node)
    fan_out = calculate_fan_out(graph, node)

    inflow = fan_in["total_value"]
    outflow = fan_out["total_value"]
    net_flow = inflow - outflow

    return Dict(
        "inflow" => inflow,
        "outflow" => outflow,
        "net_flow" => net_flow,
        "flow_ratio" => outflow > 0 ? inflow / outflow : (inflow > 0 ? Inf : 1.0),
        "transaction_count" => fan_in["count"] + fan_out["count"]
    )
end

"""
Find nodes within N hops from a source node.
Real graph traversal for connectivity analysis.
"""
function find_nodes_within_hops(graph::TxGraph, source::String, max_hops::Int)::Dict{String,Int}
    if !(source in graph.nodes)
        return Dict{String,Int}()
    end

    visited = Dict{String,Int}()
    queue = [(source, 0)]

    while !isempty(queue)
        current, hops = popfirst!(queue)

        if hops > max_hops || haskey(visited, current)
            continue
        end

        visited[current] = hops

        # Add neighbors from outgoing edges
        if haskey(graph.adjacency_out, current)
            for edge in graph.adjacency_out[current]
                if !haskey(visited, edge.to) && hops + 1 <= max_hops
                    push!(queue, (edge.to, hops + 1))
                end
            end
        end

        # Add neighbors from incoming edges
        if haskey(graph.adjacency_in, current)
            for edge in graph.adjacency_in[current]
                if !haskey(visited, edge.from) && hops + 1 <= max_hops
                    push!(queue, (edge.from, hops + 1))
                end
            end
        end
    end

    return visited
end

"""
Calculate graph density (actual edges / possible edges).
Real metric for graph connectivity analysis.
"""
function calculate_graph_density(graph::TxGraph)::Float64
    n = length(graph.nodes)
    if n <= 1
        return 0.0
    end

    # For directed graph: max possible edges = n * (n-1)
    max_possible = n * (n - 1)
    actual_edges = length(graph.edges)

    return actual_edges / max_possible
end

"""
Validate graph structure integrity.
Ensures graph was built correctly from real data.
"""
function validate_graph(graph::TxGraph)::Dict{String,Any}
    # Check consistency between edges and adjacency lists
    adj_out_edges = sum(length(edges) for edges in values(graph.adjacency_out))
    adj_in_edges = sum(length(edges) for edges in values(graph.adjacency_in))

    return Dict(
        "valid" => adj_out_edges == length(graph.edges) && adj_in_edges == length(graph.edges),
        "node_count" => length(graph.nodes),
        "edge_count" => length(graph.edges),
        "adjacency_out_consistency" => adj_out_edges == length(graph.edges),
        "adjacency_in_consistency" => adj_in_edges == length(graph.edges),
        "density" => calculate_graph_density(graph)
    )
end

export build_graph, calculate_fan_in, calculate_fan_out, calculate_net_flow,
       find_nodes_within_hops, calculate_graph_density, validate_graph
