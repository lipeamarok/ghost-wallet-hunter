module JuliaDB

# Import necessary types and functions from parent module
using ..CommonTypes: AgentState
using ..Agents: Agent

# Note: trigger_type_to_string and agent_state_to_string are included directly in parent JuliaOS module
# They will be available through the parent scope

# Include local files
include("utils.jl")
include("connection_management.jl")
include("updating.jl")
include("loading.jl")

end