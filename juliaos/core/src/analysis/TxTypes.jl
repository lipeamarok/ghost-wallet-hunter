"""
TxTypes.jl - Core transaction graph data structures for F1 phase

Defines the fundamental types for transaction graph analysis without mocks.
Real structures based on actual Solana transaction format.
"""

# Core graph structures for transaction analysis
struct TxEdge
    from::String           # Source address
    to::String            # Destination address
    value::Float64        # SOL amount transferred
    slot::Union{Nothing,Int}        # Block slot
    block_time::Union{Nothing,Int}  # Block timestamp
    program::String       # Program that facilitated transfer
    tx_signature::String  # Transaction signature
    direction::String     # "in", "out", "neutral"
end

struct TxGraph
    nodes::Set{String}                    # All unique addresses
    edges::Vector{TxEdge}                 # All transaction edges
    adjacency_out::Dict{String,Vector{TxEdge}}  # Outgoing edges per node
    adjacency_in::Dict{String,Vector{TxEdge}}   # Incoming edges per node

    function TxGraph()
        new(Set{String}(), TxEdge[], Dict{String,Vector{TxEdge}}(), Dict{String,Vector{TxEdge}}())
    end
end

struct GraphStats
    nodes::Int
    edges::Int
    max_hops::Int
    density::Float64
    fan_in_stats::Dict{String,Any}   # fan-in analysis per node
    fan_out_stats::Dict{String,Any}  # fan-out analysis per node
    net_flow_stats::Dict{String,Any} # net flow per node
end

struct PathEvidence
    path_id::String
    hops::Int
    total_value::Float64
    segments::Vector{TxEdge}
end

# Export all types for use in other modules
export TxEdge, TxGraph, GraphStats, PathEvidence
