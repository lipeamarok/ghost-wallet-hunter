module JuliaDB

# Import necessary types from parent modules
using ..Agents: Agent, AgentState, trigger_type_to_string, agent_state_to_string

include("utils.jl")
include("connection_management.jl")
include("updating.jl")
include("loading.jl")

end