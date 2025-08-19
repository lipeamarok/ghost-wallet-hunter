# julia/src/agents/AgentCore.jl
module AgentCore

# Config is loaded by the framework
# Legacy include removed; use JuliaOS.Configuration instead
export Agent, AgentConfig, AgentStatus, AgentType,
       AbstractAgentMemory, AbstractAgentQueue, AbstractLLMIntegration, AGENTS_LOCK, ABILITY_REGISTRY, register_ability, AGENTS,
       # Detective Agent Types and Structures
       DetectiveMemory, InvestigationTask, DetectiveAgentConfig,
       get_detective_abilities, get_detective_name,
       add_investigation!, get_investigation_history, cache_pattern!, get_cached_pattern,
       store_wallet_profile!, get_wallet_profile,
       # Detective Type Constants
       DETECTIVE_POIROT, DETECTIVE_MARPLE, DETECTIVE_SPADE, DETECTIVE_MARLOWEE,
       DETECTIVE_DUPIN, DETECTIVE_SHADOW, DETECTIVE_RAVEN, DETECTIVE_GENERIC,
       # Task and Agent Thread Storage
       AGENT_THREADS

using UUIDs, Dates
using DataStructures

# ----------------------------------------------------------------------
# CONSTANTS
# ----------------------------------------------------------------------
const MAX_TASK_HISTORY = Main.JuliaOS.Configuration.get_config().max_transaction_depth # or use an appropriate field

# ----------------------------------------------------------------------
# SCHEDULE TYPE
# ----------------------------------------------------------------------
abstract type Schedule end

# ----------------------------------------------------------------------
# ENUMS
# ----------------------------------------------------------------------
@enum AgentType begin
    TRADING = 1; MONITOR = 2; ARBITRAGE = 3; DATA_COLLECTION = 4;
    NOTIFICATION = 5; CUSTOM = 99; DEV = 100; # Added DEV type
    # Ghost Wallet Hunter Detective Types
    DETECTIVE_POIROT = 200; DETECTIVE_MARPLE = 201; DETECTIVE_SPADE = 202;
    DETECTIVE_MARLOWEE = 203; DETECTIVE_DUPIN = 204; DETECTIVE_SHADOW = 205;
    DETECTIVE_RAVEN = 206; DETECTIVE_GENERIC = 299
end

@enum AgentStatus begin
    CREATED = 1; INITIALIZING = 2; RUNNING = 3;
    PAUSED = 4; STOPPED = 5; ERROR = 6
end

@enum TaskStatus begin
    TASK_PENDING = 1
    TASK_RUNNING = 2
    TASK_COMPLETED = 3
    TASK_FAILED = 4
    TASK_CANCELLED = 5
    TASK_UNKNOWN = 99 # For loading potentially old/corrupt data
end

# ----------------------------------------------------------------------
# SKILL ENGINE (Registry defined here, processing logic in agent loop)
# ----------------------------------------------------------------------
# Schedule Struct for Advanced Scheduling is defined above

"""
    Skill

Represents a scheduled skill an agent can perform.

# Fields
- `name::String`: Skill name
- `fn::Function`: The Julia function implementing the skill logic
- `schedule::Union{Schedule, Nothing}`: The scheduling definition (nothing for on-demand only)
"""
struct Skill
    name::String
    fn::Function
    schedule::Union{Schedule, Nothing} # Use the new Schedule type
end

"""
    SkillState

Mutable state associated with an agent's skill.

# Fields
- `skill::Skill`: The skill definition
- `xp::Float64`: Experience points for the skill
- `last_exec::DateTime`: Timestamp of the last execution
"""
mutable struct SkillState
    skill::Skill
    xp::Float64
    last_exec::DateTime
end

# ----------------------------------------------------------------------
# ABSTRACT TYPES for Pluggability (NEW)
# ----------------------------------------------------------------------
"""
    AbstractAgentMemory

Abstract type for agent memory implementations.
Concrete types must implement:
- `get_value(mem::AbstractAgentMemory, key::String)`
- `set_value!(mem::AbstractAgentMemory, key::String, val)`
- `delete_value!(mem::AbstractAgentMemory, key::String)`
- `clear!(mem::AbstractAgentMemory)`
- `length(mem::AbstractAgentMemory)`
- `keys(mem::AbstractAgentMemory)`
"""
abstract type AbstractAgentMemory end

"""
    AbstractAgentQueue

Abstract type for agent task queue implementations.
Concrete types must implement:
- `enqueue!(q::AbstractAgentQueue, item, priority::Real)`
- `dequeue!(q::AbstractAgentQueue)`
- `peek(q::AbstractAgentQueue)`
- `isempty(q::AbstractAgentQueue)`
- `length(q::AbstractAgentQueue)`
"""
abstract type AbstractAgentQueue end

"""
    AbstractLLMIntegration

Abstract type for LLM integration implementations.
Concrete types must implement:
- `chat(llm::AbstractLLMIntegration, prompt::String; cfg::Dict)`
"""
abstract type AbstractLLMIntegration end

# ----------------------------------------------------------------------
# DEFAULT PLUGGABLE IMPLEMENTATIONS
# ----------------------------------------------------------------------
# Example Default Memory: OrderedDict Memory
struct OrderedDictAgentMemory <: AbstractAgentMemory
    data::OrderedDict{String, Any}
    max_size::Int
end
# Implement AbstractAgentMemory interface for OrderedDictAgentMemory
get_value(mem::OrderedDictAgentMemory, key::String) = get(mem.data, key, nothing)
set_value!(mem::OrderedDictAgentMemory, key::String, val) = (mem.data[key] = val; _touch!(mem.data, key); _enforce_lru_size!(mem)) # Need helper for size
delete_value!(mem::OrderedDictAgentMemory, key::String) = delete!(mem.data, key)
clear!(mem::OrderedDictAgentMemory) = empty!(mem.data)
Base.length(mem::OrderedDictAgentMemory) = length(mem.data)
Base.keys(mem::OrderedDictAgentMemory) = keys(mem.data)
_touch!(mem::OrderedDict{String,Any}, key) = (val = mem[key]; delete!(mem,key); mem[key] = val) # Helper for LRU
_enforce_lru_size!(mem::OrderedDictAgentMemory) = while length(mem.data) > mem.max_size; popfirst!(mem.data); end # Helper for size limit

# Example Default Queue: Priority Queue
struct PriorityAgentQueue <: AbstractAgentQueue
    queue::PriorityQueue{Any, Float64} # Stores task_ids
end
# Implement AbstractAgentQueue interface for PriorityAgentQueue
DataStructures.enqueue!(q::PriorityAgentQueue, item, priority::Real) = enqueue!(q.queue, item, priority)
DataStructures.dequeue!(q::PriorityAgentQueue) = dequeue!(q.queue)
DataStructures.peek(q::PriorityAgentQueue) = peek(q.queue)
Base.isempty(q::PriorityAgentQueue) = isempty(q.queue)
Base.length(q::PriorityAgentQueue) = length(q.queue)

# # Example Default LLM Integration (Uses LLMIntegration module)
# struct DefaultLLMIntegration <: AbstractLLMIntegration
#     # Could store config or other state here if needed
# end
# # Implement AbstractLLMIntegration interface
# LLMIntegration.chat(llm::DefaultLLMIntegration, prompt::String; cfg::Dict) = LLMIntegration.chat(prompt; cfg=cfg)

# ----------------------------------------------------------------------
# CONFIG STRUCT
# ----------------------------------------------------------------------
"""
    AgentConfig

Configuration for creating a new agent.

# Fields
- `name::String`: Agent name
- `type::AgentType`: Agent type (enum)
- `abilities::Vector{String}`: List of ability names this agent type can perform
- `chains::Vector{String}`: List of chain names this agent type can execute
- `parameters::Dict{String,Any}`: Agent-specific parameters
- `llm_config::Dict{String,Any}`: Configuration for the LLM provider (can specify implementation type)
- `memory_config::Dict{String,Any}`: Configuration for agent memory (can specify implementation type)
- `queue_config::Dict{String,Any}`: Configuration for agent queue (can specify implementation type) (NEW)
- `max_task_history::Int`: Maximum number of tasks to keep in history
"""
struct AgentConfig
    name::String
    type::AgentType
    abilities::Vector{String}
    chains::Vector{String}
    parameters::Dict{String,Any}
    llm_config::Dict{String,Any}
    memory_config::Dict{String,Any}
    queue_config::Dict{String,Any} # NEW: Queue config
    max_task_history::Int

    function AgentConfig(name::String, type::AgentType;
                         abilities::Vector{String}=String[], chains::Vector{String}=String[],
                         parameters::Dict{String,Any}=Dict(),
                         llm_config::Dict{String,Any}=Dict(),
                         memory_config::Dict{String,Any}=Dict(),
                         queue_config::Dict{String,Any}=Dict(), # NEW: Default queue config
                         max_task_history::Int=MAX_TASK_HISTORY)
        isempty(llm_config) && (llm_config = Dict("provider"=>"openai","model"=>"gpt-4o-mini","temperature"=>0.7,"max_tokens"=>1024))
        isempty(memory_config) && (memory_config = Dict("type"=>"ordered_dict","max_size"=>1000,"retention_policy"=>"lru")) # Added default type
        isempty(queue_config) && (queue_config = Dict("type"=>"priority_queue")) # NEW: Default queue type
        new(name, type, abilities, chains, parameters, llm_config, memory_config, queue_config, max_task_history)
    end
end

"""
    TaskResult

Holds the lifecycle info and outcome of a single agent task.

# Fields
- `task_id::String`               – unique identifier for this task
- `status::TaskStatus`            – current lifecycle status
- `submitted_time::DateTime`           – when the task was enqueued
- `start_time::Union{DateTime,Nothing}`    – when execution began (nothing if never started)
- `end_time::Union{DateTime,Nothing}`   – when execution ended (nothing if still pending/running)
- `input_task::Dict{String, Any}`: Input task data
- `output_result::Any`                   – the returned value on success (or partial output)
- `error_details::Union{String,Nothing}`  – error message if the task failed, else `nothing`
"""
mutable struct TaskResult
    task_id::String
    status::TaskStatus
    submitted_time::DateTime
    start_time::Union{DateTime, Nothing}
    end_time::Union{DateTime, Nothing}
    input_task::Dict{String, Any}
    output_result::Any
    error_details::Union{Exception, Nothing}

    function TaskResult(task_id::String;
                        status::TaskStatus=TASK_PENDING,
                        submitted_time::DateTime=now(),
                        start_time::Union{DateTime,Nothing}=nothing,
                        end_time::Union{DateTime,Nothing}=nothing,
                        input_task::Dict{String,Any}=Dict{String,Any}(),
                        output_result::Any=nothing,
                        error_details::Union{Exception,Nothing}=nothing)
        new(task_id, status, submitted_time, start_time, end_time, input_task, output_result, error_details)
    end
end

# ----------------------------------------------------------------------
# MAIN AGENT STRUCTURE
# ----------------------------------------------------------------------
"""
    Agent

Represents an autonomous agent instance.

# Fields
- `id::String`: Unique agent ID
- `name::String`: Agent name
- `type::AgentType`: Agent type
- `status::AgentStatus`: Current status
- `created::DateTime`: Creation timestamp
- `updated::DateTime`: Last update timestamp (reflects status/config changes)
- `config::AgentConfig`: Agent configuration
- `memory::AbstractAgentMemory`: Agent memory implementation (NEW: Abstract Type)
- `task_history::Vector{Dict{String,Any}}`: History of completed tasks (capped)
- `skills::Dict{String,SkillState}`: State of registered skills
- `queue::AbstractAgentQueue`: Agent task queue implementation (NEW: Abstract Type)
- `task_results::Dict{String, TaskResult}`: Dictionary to track submitted_time tasks by ID (NEW)
- `llm_integration::Union{AbstractLLMIntegration, Nothing}`: LLM integration instance (NEW: Abstract Type)
- `swarm_connection::Any`: Swarm connection object (type depends on backend) (Moved from Swarm module concept)
- `lock::ReentrantLock`: Lock for protecting mutable agent state (NEW)
- `condition::Condition`: Condition variable for signaling the agent loop (NEW)
- `last_error::Union{Exception, Nothing}`: The last error encountered (NEW)
- `last_error_timestamp::Union{DateTime, Nothing}`: Timestamp of the last error (NEW)
- `last_activity::DateTime`: Timestamp of the last significant activity (NEW)
"""
mutable struct Agent
    id::String; name::String; type::AgentType; status::AgentStatus
    created::DateTime; updated::DateTime; config::AgentConfig
    memory::AbstractAgentMemory          # LRU memory (NEW: Abstract Type)
    task_history::Vector{Dict{String,Any}}
    skills::Dict{String,SkillState}
    queue::AbstractAgentQueue        # message queue (stores task_ids) (NEW: Abstract Type)
    task_results::Dict{String, TaskResult} # NEW: Dictionary to track tasks by ID
    llm_integration::Union{AbstractLLMIntegration, Nothing} # NEW: LLM instance
    swarm_connection::Any # Swarm connection object (type depends on backend) (NEW)
    lock::ReentrantLock                      # NEW: Lock for protecting mutable state
    condition::Condition                     # NEW: Condition variable for signaling loop
    last_error::Union{Exception, Nothing}    # NEW: Last error object
    last_error_timestamp::Union{DateTime, Nothing} # NEW: Timestamp of last error
    last_activity::DateTime                  # NEW: Timestamp of last activity
end

# ----------------------------------------------------------------------
# GLOBAL REGISTRIES & AGENT STORAGE
# ----------------------------------------------------------------------
const AGENTS          = Dict{String,Agent}() # Global dictionary of agents
const AGENT_THREADS = Dict{String,Task}() # Map agent ID to its running task
const ABILITY_REGISTRY = Dict{String,Function}() # Global registry of ability functions
const AGENTS_LOCK     = ReentrantLock() # Lock for concurrent access to AGENTS dict and AGENT_THREADS

# ----------------------------------------------------------------------
# DETECTIVE AGENT SPECIALIZED TYPES & MEMORY
# ----------------------------------------------------------------------

"""
    DetectiveMemory <: AbstractAgentMemory

Specialized memory for detective agents with investigation history and pattern caching.
"""
mutable struct DetectiveMemory <: AbstractAgentMemory
    base_memory::OrderedDictAgentMemory
    investigation_history::Vector{Dict{String, Any}}
    pattern_cache::Dict{String, Any}
    wallet_profiles::Dict{String, Any}
    max_investigations::Int

    function DetectiveMemory(max_size::Int=1000, max_investigations::Int=100)
        base = OrderedDictAgentMemory(OrderedDict{String, Any}(), max_size)
        new(base, Vector{Dict{String, Any}}(), Dict{String, Any}(), Dict{String, Any}(), max_investigations)
    end
end

# Implement AbstractAgentMemory interface for DetectiveMemory
get_value(mem::DetectiveMemory, key::String) = get_value(mem.base_memory, key)
set_value!(mem::DetectiveMemory, key::String, val) = set_value!(mem.base_memory, key, val)
delete_value!(mem::DetectiveMemory, key::String) = delete_value!(mem.base_memory, key)
clear!(mem::DetectiveMemory) = (clear!(mem.base_memory); empty!(mem.investigation_history); empty!(mem.pattern_cache); empty!(mem.wallet_profiles))
Base.length(mem::DetectiveMemory) = length(mem.base_memory)
Base.keys(mem::DetectiveMemory) = keys(mem.base_memory)

# Detective-specific memory functions
function add_investigation!(mem::DetectiveMemory, investigation::Dict{String, Any})
    push!(mem.investigation_history, investigation)
    while length(mem.investigation_history) > mem.max_investigations
        popfirst!(mem.investigation_history)
    end
end

function get_investigation_history(mem::DetectiveMemory, wallet_address::String="")
    if isempty(wallet_address)
        return mem.investigation_history
    else
        return filter(inv -> get(inv, "wallet_address", "") == wallet_address, mem.investigation_history)
    end
end

function cache_pattern!(mem::DetectiveMemory, pattern_key::String, pattern_data::Any)
    mem.pattern_cache[pattern_key] = pattern_data
end

function get_cached_pattern(mem::DetectiveMemory, pattern_key::String)
    return get(mem.pattern_cache, pattern_key, nothing)
end

function store_wallet_profile!(mem::DetectiveMemory, wallet_address::String, profile::Dict{String, Any})
    mem.wallet_profiles[wallet_address] = profile
end

function get_wallet_profile(mem::DetectiveMemory, wallet_address::String)
    return get(mem.wallet_profiles, wallet_address, nothing)
end

"""
    InvestigationTask

Specialized task type for detective investigations.
"""
struct InvestigationTask
    task_id::String
    wallet_address::String
    investigation_type::String
    priority::Float64
    detective_type::AgentType
    additional_params::Dict{String, Any}
    created_at::DateTime

    function InvestigationTask(wallet_address::String, investigation_type::String="general",
                              detective_type::AgentType=DETECTIVE_GENERIC;
                              priority::Float64=1.0, additional_params::Dict{String, Any}=Dict{String, Any}())
        task_id = "investigation_" * string(UUIDs.uuid4())[1:8]
        new(task_id, wallet_address, investigation_type, priority, detective_type, additional_params, now())
    end
end

"""
    DetectiveAgentConfig

Specialized configuration for detective agents with blockchain-specific settings.
"""
struct DetectiveAgentConfig
    base_config::AgentConfig
    blockchain::String
    analysis_depth::String
    max_transactions::Int
    rate_limit_delay::Float64
    specialty_skills::Vector{String}
    investigation_style::String

    function DetectiveAgentConfig(name::String, detective_type::AgentType;
                                 blockchain::String="solana",
                                 analysis_depth::String="deep",
                                 max_transactions::Int=1000,
                                 rate_limit_delay::Float64=1.0,
                                 specialty_skills::Vector{String}=String[],
                                 investigation_style::String="methodical",
                                 abilities::Vector{String}=["investigate_wallet", "analyze_patterns", "generate_report"],
                                 parameters::Dict{String,Any}=Dict())

        # Create specialized memory config for detectives
        memory_config = Dict(
            "type" => "detective_memory",
            "max_size" => 2000,
            "max_investigations" => 200,
            "retention_policy" => "investigation_based"
        )

        # Detective-specific parameters
        detective_params = merge(parameters, Dict(
            "blockchain" => blockchain,
            "analysis_depth" => analysis_depth,
            "max_transactions" => max_transactions,
            "rate_limit_delay" => rate_limit_delay,
            "specialty_skills" => specialty_skills,
            "investigation_style" => investigation_style
        ))

        base = AgentConfig(name, detective_type;
                          abilities=abilities,
                          parameters=detective_params,
                          memory_config=memory_config)

        new(base, blockchain, analysis_depth, max_transactions, rate_limit_delay, specialty_skills, investigation_style)
    end
end

# ----------------------------------------------------------------------
# DETECTIVE AGENT FACTORY HELPERS
# ----------------------------------------------------------------------

"""
    get_detective_abilities(detective_type::AgentType) -> Vector{String}

Returns the standard abilities for a specific detective type.
"""
function get_detective_abilities(detective_type::AgentType)
    base_abilities = ["investigate_wallet", "analyze_patterns", "generate_report", "update_memory"]

    specialty_abilities = if detective_type == DETECTIVE_POIROT
        ["methodical_analysis", "transaction_tracing", "precision_detection"]
    elseif detective_type == DETECTIVE_MARPLE
        ["pattern_recognition", "anomaly_detection", "behavioral_analysis"]
    elseif detective_type == DETECTIVE_SPADE
        ["risk_assessment", "compliance_checking", "criminal_pattern_detection"]
    elseif detective_type == DETECTIVE_MARLOWEE
        ["deep_analysis", "corruption_detection", "narrative_investigation"]
    elseif detective_type == DETECTIVE_DUPIN
        ["logical_deduction", "analytical_reasoning", "pattern_synthesis"]
    elseif detective_type == DETECTIVE_SHADOW
        ["stealth_analysis", "hidden_pattern_detection", "network_mapping"]
    elseif detective_type == DETECTIVE_RAVEN
        ["dark_analytics", "ominous_pattern_detection", "cryptic_interpretation"]
    else
        ["general_investigation"]
    end

    return vcat(base_abilities, specialty_abilities)
end

"""
    get_detective_name(detective_type::AgentType) -> String

Returns the standard name for a detective type.
"""
function get_detective_name(detective_type::AgentType)
    if detective_type == DETECTIVE_POIROT
        return "Detective Hercule Poirot"
    elseif detective_type == DETECTIVE_MARPLE
        return "Detective Miss Jane Marple"
    elseif detective_type == DETECTIVE_SPADE
        return "Detective Sam Spade"
    elseif detective_type == DETECTIVE_MARLOWEE
        return "Detective Philip Marlowe"
    elseif detective_type == DETECTIVE_DUPIN
        return "Detective Auguste Dupin"
    elseif detective_type == DETECTIVE_SHADOW
        return "The Shadow"
    elseif detective_type == DETECTIVE_RAVEN
        return "Detective Raven"
    else
        return "Generic Detective"
    end
end

# ----------------------------------------------------------------------
# ABILITY REGISTRY (Definition here, registration function above) ------
# ----------------------------------------------------------------------
# register_ability function is defined above

"""
    register_ability(name::String, fn::Function)

Registers a function under a given name in the global ABILITY_REGISTRY.
"""
function register_ability(name::String, fn::Function)
    lock(AGENTS_LOCK) do
        ABILITY_REGISTRY[name] = fn
    end
end

end # module AgentCore
