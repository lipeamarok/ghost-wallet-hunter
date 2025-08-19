# JuliaOS.jl - Main module required by Project.toml as the main module

module JuliaOS

using Logging
using HTTP
using JSON3
using Dates
using UUIDs
using Random

# Export main functionality
export start_server, get_health, investigate_wallet

# Include essential components
# 1) Legacy app Config (key-path access) needed by many agent modules
include("../config/config.jl")
using .Config

# 2) New typed Configuration (env-driven)
include("config/Configuration.jl")
using .Configuration

include("agents/CommonTypes.jl")
using .CommonTypes

# Ensure core Agent modules are loaded before optional A2A/Swarms
include("agents/AgentCore.jl")
using .AgentCore
include("agents/AgentMetrics.jl")
using .AgentMetrics

include("agents/DetectiveAgents.jl")
using .DetectiveAgents

# NEW: Public blacklist checker (real sources)
include("security/BlacklistChecker.jl")
using .BlacklistChecker

# NEW: Metrics collection module (lightweight production implementation)
include("monitoring/Metrics.jl")
using .Metrics
include("providers/ProviderPool.jl")
using .ProviderPool

# MCP core stub (Phase 2 minimal implementation)
include("mcp/MCPCore.jl")
using .MCPCore

include("api/MainServer.jl")
using .MainServer

# A2A integrated singleton (optional)
const A2A_SERVER = Ref{Any}(nothing)
const A2A_AVAILABLE = Ref(false)
try
    # Default A2A to disabled unless explicitly enabled via ENV
    if lowercase(get(ENV, "A2A_ENABLED", "false")) in ("1","true","yes","on")
        # Avoid re-including if already defined
        if !isdefined(@__MODULE__, :A2AProtocol)
            include("a2a/A2AProtocol.jl")
        end
        @eval using .A2AProtocol
        A2A_AVAILABLE[] = true
        @info "A2A module loaded"
    else
        @info "A2A disabled via ENV"
    end
catch e
    @warn "A2A module failed to load; continuing without A2A" error=e
    A2A_AVAILABLE[] = false
end

"""
    start_server(host="0.0.0.0", port=10000)

Start the Ghost Wallet Hunter JuliaOS server
"""
function start_server(host="0.0.0.0", port=10000)
    @info "🔥 Starting Ghost Wallet Hunter JuliaOS Server"
    @info "📡 Server: http://$host:$port"
    @info "🔧 Using configuration: $(Configuration.get_environment())"

    # Optional deterministic mode for stabilizing stochastic tests
    if lowercase(get(ENV, "JULIAOS_DETERMINISTIC", "true")) in ("1","true","yes","on")
        seed = try parse(Int, get(ENV, "JULIAOS_SEED", "12345")) catch; 12345 end
        Random.seed!(seed)
        @info "Deterministic RNG seed applied" seed=seed
    end

    # Initialize blacklist service (non-blocking freshness later handled internally)
    try
        @info "🛡️ Initializing public blacklist sources..."
        BlacklistChecker.initialize_blacklist()
    catch e
        @warn "Blacklist initialization failed" error=e
    end

    # Initialize Solana provider pool (real endpoints, warmup)
    try
        ProviderPool.init_solana_pool()
    catch e
        @warn "Solana provider pool init failed" error=e
    end

    # Initialize A2A (integrated) if enabled and available
    try
        if A2A_AVAILABLE[]
            a2a_enabled = lowercase(get(ENV, "A2A_ENABLED", "false")) in ("1","true","yes","on")
            a2a_integrated = lowercase(get(ENV, "A2A_INTEGRATED", "true")) in ("1","true","yes","on")
            if a2a_enabled && a2a_integrated && (A2A_SERVER[] === nothing)
                port_a2a = try parse(Int, get(ENV, "A2A_PORT", "9100")) catch; 9100 end
                @info "🔗 Starting A2A Protocol (integrated) on port $port_a2a"
                server = A2AProtocol.A2AProtocolServer(port_a2a)
                A2AProtocol.start_server!(server)
                A2A_SERVER[] = server
            else
                @info "A2A disabled or already started"
            end
        else
            @info "A2A module not available; skipping"
        end
    catch e
        @warn "A2A initialization error: $e"
    end

    # Initialize detective squad
    @info "🕵️ Initializing detective squad..."
    squad = DetectiveAgents.create_detective_squad()
    @info "✅ Detective squad ready: $(length(squad)) detectives"

    # Start the main server
    MainServer.start_server(default_host=host, default_port=port)
end

"""
    get_health()

Get system health status
"""
function get_health()
    env = Configuration.get_environment()

    return Dict(
        "status" => "healthy",
        "service" => "ghost-wallet-hunter-juliaos",
        "version" => "2.0.0",
        "environment" => env,
        "timestamp" => now(),
        "detectives_available" => DetectiveAgents.count_active_detectives()
    )
end

"""
    investigate_wallet(wallet_address::String, detective_type::String="comprehensive")

Start wallet investigation using specified detective type
"""
function investigate_wallet(wallet_address::String, detective_type::String="comprehensive")
    @info "🔍 Starting investigation: $detective_type -> $wallet_address"

    # Get detective squad
    squad = DetectiveAgents.create_detective_squad()

    # Start investigation
    result = DetectiveAgents.investigate(squad, wallet_address, detective_type)

    @info "✅ Investigation completed for $wallet_address"
    return result
end

end # module JuliaOS
