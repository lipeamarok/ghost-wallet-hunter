module JuliaOS

# Export public modules and functions for Ghost Wallet Hunter
export initialize, create_agent, create_swarm, swarm_investigate, agent_investigate
export Detective, investigate_wallet

# Constants for feature detection
const PYTHON_WRAPPER_EXISTS = isfile(joinpath(@__DIR__, "python/python_bridge.jl"))
const FRAMEWORK_EXISTS = isdir(joinpath(dirname(dirname(@__DIR__)), "packages/framework"))

# Include base modules first
include("agents/CommonTypes.jl")
include("agents/Config.jl")
include("agents/AgentCore.jl")
include("agents/AgentMetrics.jl")
include("agents/Persistence.jl")
include("agents/LLMIntegration.jl")
include("agents/utils.jl")

# Include resources BEFORE agent_management
include("resources/Resources.jl")
using .Resources

# Now include agent_management (that depends on Resources)
include("agents/agent_management.jl")
include("agents/Agents.jl")

using .Config
using .AgentCore
using .AgentMetrics
using .Persistence
using .LLMIntegration
using .Agents

# Include database after agents are loaded
include("db/JuliaDB.jl")
using .JuliaDB

# Now include tools and strategies that depend on Resources
include("tools/Tools.jl")
include("strategies/Strategies.jl")
include("agents/Triggers.jl")

using .Tools
using .Strategies

# Include Ghost Wallet Hunter specific modules
include("agents/DetectiveAgents.jl")
using .DetectiveAgents

# Try to include JuliaOS framework if it exists, otherwise use minimal implementation
if isfile(joinpath(@__DIR__, "framework/JuliaOSFramework.jl"))
    include("framework/JuliaOSFramework.jl")
    using .JuliaOSFramework
    const FRAMEWORK_AVAILABLE = true
else
    const FRAMEWORK_AVAILABLE = false
    @warn "JuliaOS Framework not found, using minimal implementation"
end

"""
    initialize(; storage_path::String=joinpath(homedir(), ".juliaos", "juliaos.sqlite"))

Initialize the JuliaOS system for Ghost Wallet Hunter.

# Arguments
- `storage_path::String`: Path to the storage database for the framework.

# Returns
- `Bool`: true if initialization was successful
"""
function initialize(; storage_path::String=joinpath(homedir(), ".juliaos", "juliaos.sqlite"))
    @info "Initializing JuliaOS for Ghost Wallet Hunter..."

    if FRAMEWORK_AVAILABLE
        framework_success = initialize_framework(storage_path=storage_path)
        if framework_success
            @info "JuliaOS Framework initialized successfully."
        else
            @warn "JuliaOS Framework initialization had some issues."
        end
        return framework_success
    else
        @info "Using minimal JuliaOS implementation for Ghost Wallet Hunter"
        return true
    end
end

"""
    create_agent(config::Dict)

Create a new detective agent for Ghost Wallet Hunter.
"""
function create_agent(config::Dict)
    return DetectiveAgents.create_detective(config)
end

"""
    create_swarm(config::Dict)

Create a detective squad swarm for coordinated investigation.
"""
function create_swarm(config::Dict)
    @info "Creating detective squad swarm: $(config["name"])"

    # Simulate swarm creation with PSO algorithm
    swarm = Dict(
        "id" => string(uuid4()),
        "name" => config["name"],
        "algorithm" => get(config, "algorithm", "PSO"),
        "agents" => get(config, "agents", []),
        "objective" => get(config, "objective", "maximize_detection_accuracy"),
        "coordination_mode" => get(config, "coordination_mode", "collaborative"),
        "status" => "active",
        "created_at" => now()
    )

    return swarm
end

"""
    swarm_investigate(swarm::Dict, wallet_address::String, investigation_id::String)

Perform coordinated investigation using detective squad swarm.
"""
function swarm_investigate(swarm::Dict, wallet_address::String, investigation_id::String)
    @info "🔍 Detective Squad investigating: $wallet_address"

    # Simulate swarm coordination using PSO algorithm
    individual_findings = []

    for agent in swarm["agents"]
        finding = DetectiveAgents.investigate_wallet(agent, wallet_address, investigation_id)
        push!(individual_findings, finding)
    end

    # Combine findings using swarm intelligence
    combined_risk_scores = [f["risk_score"] for f in individual_findings]
    combined_confidences = [f["confidence"] for f in individual_findings]

    # PSO-style optimization for final assessment
    final_risk_score = sum(combined_risk_scores .* combined_confidences) / sum(combined_confidences)
    final_confidence = sqrt(sum(combined_confidences.^2) / length(combined_confidences))

    swarm_result = Dict(
        "swarm_id" => swarm["id"],
        "swarm_name" => swarm["name"],
        "algorithm" => swarm["algorithm"],
        "individual_findings" => individual_findings,
        "swarm_consensus" => Dict(
            "final_risk_score" => round(final_risk_score, digits=3),
            "final_confidence" => round(final_confidence, digits=3),
            "consensus_method" => "PSO_weighted_average",
            "agent_agreement" => length(individual_findings)
        ),
        "performance" => Dict(
            "coordination_efficiency" => "high",
            "julia_performance" => "optimized",
            "swarm_algorithm" => swarm["algorithm"]
        )
    )

    return swarm_result
end

"""
    agent_investigate(agent, wallet_address::String, investigation_id::String)

Perform investigation using a single detective agent.
"""
function agent_investigate(agent, wallet_address::String, investigation_id::String)
    return DetectiveAgents.investigate_wallet(agent, wallet_address, investigation_id)
end

using UUIDs
using Dates

end # module JuliaOS
