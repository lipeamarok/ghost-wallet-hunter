# julia/src/agents/Agent_Management2.jl

using .CommonTypes: Agent, AgentBlueprint, AgentContext, AgentState, InstantiatedTool, InstantiatedStrategy
using .AgentCore: AGENTS, AGENTS_LOCK, DetectiveMemory, InvestigationTask, RUNNING, STOPPED
using UUIDs, Dates

# Simple agent management registry
const DETECTIVE_AGENTS = Dict{String, Agent}()

"""
    register_agent(agent::Agent)

Registers an agent in the system.
"""
function register_agent(agent::Agent)
    agent_id = agent.id
    lock(AGENTS_LOCK) do
        if haskey(AGENTS, agent_id)
            @warn "Agent with ID '$agent_id' already exists - updating"
        end
        AGENTS[agent_id] = agent
    end
    @info "Registered agent: $agent_id"
end

"""
    register_detective_agent(agent::Agent, detective_type::String)

Registers a detective agent.
"""
function register_detective_agent(agent::Agent, detective_type::String)
    register_agent(agent)
    DETECTIVE_AGENTS[agent.id] = agent
    @info "Registered detective agent: $(agent.name) ($detective_type)"
end

"""
    get_detective_system_status() -> Dict{String, Any}

Gets status of the detective system.
"""
function get_detective_system_status()
    return Dict(
        "total_agents" => length(AGENTS),
        "detective_agents" => length(DETECTIVE_AGENTS),
        "timestamp" => string(now())
    )
end

"""
    list_detective_agents() -> Vector{Dict{String, Any}}

Lists all detective agents.
"""
function list_detective_agents()
    agents_info = []
    for (agent_id, agent) in DETECTIVE_AGENTS
        push!(agents_info, Dict(
            "id" => agent.id,
            "name" => agent.name,
            "type" => string(agent.type),
            "status" => string(agent.status)
        ))
    end
    return agents_info
end

"""
    initialize_detective_system() -> Dict{String, Any}

Initializes the detective system.
"""
function initialize_detective_system()
    @info "Detective system initialized"
    return Dict(
        "success" => true,
        "total_agents" => length(AGENTS),
        "detective_agents" => length(DETECTIVE_AGENTS),
        "timestamp" => string(now())
    )
end

# Export functions
export register_agent, register_detective_agent, get_detective_system_status
export list_detective_agents, initialize_detective_system
