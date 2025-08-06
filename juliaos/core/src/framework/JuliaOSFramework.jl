# julia/src/framework/JuliaOSFramework.jl
module JuliaOSFramework

using Logging
using Pkg

export initialize, initialize_detective_system, create_detective_agent, start_investigation
export get_system_health, get_performance_metrics

# Dependency verification
const REQUIRED_PACKAGES = [
    "DataStructures",
    "StructTypes",
    "JSON3",
    "TOML",
    "Dates",
    "UUIDs"
]

"""
Verify and install required dependencies
"""
function verify_dependencies()
    @info "🔍 Checking JuliaOS dependencies..."

    missing_packages = String[]

    for pkg in REQUIRED_PACKAGES
        try
            Base.require(Main, Symbol(pkg))
        catch
            push!(missing_packages, pkg)
        end
    end

    if !isempty(missing_packages)
        @warn "Missing packages: $(join(missing_packages, ", "))"
        @info "Installing missing packages..."

        for pkg in missing_packages
            try
                Pkg.add(pkg)
                @info "✅ Installed: $pkg"
            catch e
                @error "❌ Failed to install $pkg: $e"
                return false
            end
        end
    end

    @info "✅ All dependencies verified"
    return true
end

# Verify dependencies before loading modules
if !verify_dependencies()
    @error "Failed to verify dependencies. JuliaOSFramework initialization aborted."
    error("Dependency verification failed")
end

# Import required packages
using DataStructures
using StructTypes
using JSON3
using TOML
using Dates
using UUIDs

# --- Include Core Agent Modules (CORRECTED ORDER) ---
# Paths are relative to this file (src/framework/) going to src/agents/
try
    # Load in correct dependency order
    include("../../config/config.jl")        # First - load config from config/config.jl
    include("../agents/AgentCore.jl")        # Second - depends on Config
    include("../agents/CommonTypes.jl")      # Third - depends on AgentCore
    include("../agents/AgentMetrics.jl")     # Fourth - depends on AgentCore
    include("../agents/Persistence.jl")     # Fifth - depends on AgentCore, AgentMetrics
    include("../agents/LLMIntegration.jl")   # Sixth - depends on AgentCore, Config
    include("../agents/Triggers.jl")         # Seventh - depends on AgentCore
    include("../agents/DetectiveAgents.jl")  # Eighth - INTEGRATION: Individual detective agents (replaces Agents.jl)
    include("../agents/PlanAndExecute.jl")   # Ninth - depends on LLMIntegration, AgentCore
    include("../agents/AgentMonitor.jl")     # Tenth - depends on AgentMetrics, AgentCore
    include("../agents/Agent_Management.jl") # Eleventh - depends on all above
    include("../agents/utils.jl")           # Last - utility functions (after all modules loaded)

    # Make Agent modules available in correct order
    using .Config
    using .AgentCore
    using .CommonTypes
    using .Persistence
    using .AgentMetrics
    using .Triggers
    using .LLMIntegration
    using .PlanAndExecute
    using .AgentMonitor
    using .DetectiveAgents  # INTEGRATION: New detective agents system

    @info "🤖 JuliaOSFramework: Agent modules loaded successfully"

catch e
    @error "💥 JuliaOSFramework: Critical error loading Agent modules" exception=(e, catch_backtrace())
    rethrow(e)
end

# --- Detective System Functions ---

"""
Initialize the Detective System
"""
function initialize_detective_system()
    try
        @info "🕵️ Initializing Detective Agent System..."

        # Load detective configuration
        config_result = Config.load_detective_config()
        if isnothing(config_result)
            @warn "Failed to load detective configuration, using defaults"
        end

        # Initialize metrics system
        AgentMetrics.initialize_detective_metrics()

        # Create all detective agents
        agents = create_all_detective_agents()

        @info "✅ Detective system initialized with $(length(agents)) agents"
        return Dict(
            "status" => "success",
            "agents_created" => length(agents),
            "message" => "Detective system ready"
        )

    catch e
        @error "❌ Failed to initialize detective system: $e"
        return Dict(
            "status" => "error",
            "error" => string(e),
            "message" => "Detective system initialization failed"
        )
    end
end

"""
Create a detective agent of specified type using the new DetectiveAgents system
"""
function create_detective_agent(detective_type::String)
    try
        @info "🕵️ Creating detective agent: $detective_type"

        # Use the new DetectiveAgents system for agent creation
        agent = DetectiveAgents.create_detective_by_type(detective_type)

        if !isnothing(agent)
            @info "✅ Detective agent '$detective_type' created successfully"
            return agent
        else
            @warn "⚠️ Failed to create detective agent '$detective_type'"
            return nothing
        end

    catch e
        @error "❌ Failed to create detective agent '$detective_type': $e"
        return nothing
    end
end

"""
Create all detective agents using the new DetectiveAgents system
"""
function create_all_detective_agents()
    # Updated to match the refactored detective agents
    detective_types = ["poirot", "marple", "spade", "marlowee", "dupin", "shadow", "raven"]
    agents = Dict{String, Any}()

    @info "🕵️ Creating all detective agents..."

    for detective_type in detective_types
        agent = create_detective_agent(detective_type)
        if !isnothing(agent)
            agents[detective_type] = agent
            @info "✅ Created detective: $detective_type"
        else
            @warn "⚠️ Failed to create detective: $detective_type"
        end
    end

    @info "📊 Detective squad ready: $(length(agents))/$(length(detective_types)) agents created"
    return agents
end

"""
Start a detective investigation using the new DetectiveAgents system
"""
function start_investigation(detective_type::String, wallet_address::String, params::Dict{String, Any} = Dict())
    try
        @info "🔍 Starting investigation: $detective_type -> $wallet_address"

        # Use the new DetectiveAgents investigation system
        investigation_id = get(params, "investigation_id", string(UUIDs.uuid4()))

        # Perform investigation using DetectiveAgents module
        result = DetectiveAgents.investigate_with_agent(detective_type, wallet_address, params)

        if !isnothing(result) && haskey(result, "status") && result["status"] != "error"
            # Record metrics
            try
                AgentMetrics.record_investigation_metric(detective_type, wallet_address, time())
            catch e
                @warn "Failed to record metrics: $e"
            end

            @info "✅ Investigation completed: $detective_type"
            return result
        else
            @warn "⚠️ Investigation returned with issues: $detective_type"
            return result
        end

    catch e
        @error "❌ Investigation failed: $e"
        return Dict(
            "status" => "error",
            "error" => string(e),
            "message" => "Investigation failed"
        )
    end
end

"""
Get system health status
"""
function get_system_health()
    try
        health = AgentMonitor.get_detective_system_health()
        return health
    catch e
        @error "Failed to get system health: $e"
        return Dict(
            "status" => "UNKNOWN",
            "error" => string(e),
            "timestamp" => now()
        )
    end
end

"""
Get performance metrics
"""
function get_performance_metrics()
    try
        metrics = AgentMetrics.get_detective_performance_metrics()
        return metrics
    catch e
        @error "Failed to get performance metrics: $e"
        return Dict(
            "error" => string(e),
            "timestamp" => now()
        )
    end
end

# --- Include Core Swarm Modules ---
try
    include("../swarm/SwarmBase.jl")
    include("../swarm/Swarms.jl")

    # Make Swarm modules available
    using .SwarmBase
    using .Swarms
    @info "🐝 JuliaOSFramework: Swarm modules loaded successfully"
catch e
    @error "🐝 JuliaOSFramework: Error loading Swarm modules" exception=(e, catch_backtrace())
    # Swarm modules not available - continuing without them
    @warn "Swarm functionality disabled"
end

"""
    initialize(; storage_path::String)

Initialize the JuliaOS Framework backend components.
This function will call initialization routines for all included modules.
"""
function initialize(; storage_path::String="default_storage_path_from_framework")
    @info "🚀 Initializing JuliaOSFramework..."

    try
        # Initialize detective system
        detective_init = initialize_detective_system()

        if detective_init["status"] == "success"
            @info "✅ JuliaOSFramework initialized successfully"
            @info "📊 System ready with $(detective_init["agents_created"]) detective agents"
            return true
        else
            @warn "⚠️ JuliaOSFramework initialization completed with warnings"
            return false
        end

    catch e
        @error "💥 JuliaOSFramework initialization failed: $e"
        return false
    end
end

end # module JuliaOSFramework
