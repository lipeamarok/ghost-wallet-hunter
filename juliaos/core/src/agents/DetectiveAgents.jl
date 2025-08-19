# DetectiveAgents.jl
# Detective Agents Orchestrator - Real Blockchain Investigation
# Ghost Wallet Hunter - English Language Version

module DetectiveAgents

using Dates
using UUIDs
using Logging
using Statistics
const Threads = Base.Threads

# CommonTypes will be available from parent module JuliaOS
include("CommonTypes.jl")
using .CommonTypes

# Import all individual detective agents
include("PoirotAgent.jl")
include("MarpleAgent.jl")
include("SpadeAgent.jl")
include("MarloweeAgent.jl")
include("DupinAgent.jl")
include("ShadowAgent.jl")
include("RavenAgent.jl")

# Ensure SolanaService is loaded ONCE into Main (avoid per-agent nested modules that break constructors)
try
    if !isdefined(Main, :SolanaService)
        Base.include(Main, joinpath(@__DIR__, "..", "blockchain", "SolanaService.jl"))
        @info "SolanaService loaded into Main from DetectiveAgents preload"
    else
        @debug "SolanaService already present in Main (skipping preload)"
    end
catch e
    @warn "Failed to preload SolanaService into Main" error=e
end

using .PoirotAgent
using .MarpleAgent
using .SpadeAgent
using .MarloweeAgent
using .DupinAgent
using .ShadowAgent
using .RavenAgent

export Detective, GhostDetectives
export create_detective, investigate_wallet, get_all_detectives, create_detective_by_type
export investigate_wallet_multi_detective, create_detective_squad
export count_active_detectives, investigate

# ==========================================
# DETECTIVE BASE STRUCTURE
# ==========================================

struct Detective
    id::String
    type::String
    name::String
    specialty::String
    skills::Vector{String}
    blockchain::String
    status::String
    created_at::DateTime
    investigation_count::Int
    persona::String
    catchphrase::String
end

# ==========================================
# DETECTIVE ORCHESTRATION FUNCTIONS
# ==========================================

# Get all available detectives
function get_all_detectives()
    """Returns a list of all available detective agents"""
    return [
        Dict{String,Any}(
            "id" => "poirot",
            "name" => "Detective Hercule Poirot",
            "specialty" => "methodical_transaction_analysis",
            "status" => "active",
            "persona" => "Belgian master of deduction applied to blockchain analysis",
            "catchphrase" => "Ah, mon ami, the little grey cells, they work!"
        ),
        Dict{String,Any}(
            "id" => "marple",
            "name" => "Detective Miss Jane Marple",
            "specialty" => "pattern_anomaly_detection",
            "status" => "active",
            "persona" => "Perceptive observer who notices details others miss",
            "catchphrase" => "Oh my dear, that's rather peculiar, isn't it?"
        ),
        Dict{String,Any}(
            "id" => "spade",
            "name" => "Detective Sam Spade",
            "specialty" => "hard_boiled_investigation_compliance",
            "status" => "active",
            "persona" => "Hard-boiled private detective with compliance expertise",
            "catchphrase" => "When you're slapped, you'll take it and like it."
        ),
        Dict{String,Any}(
            "id" => "marlowee",
            "name" => "Detective Philip Marlowe",
            "specialty" => "deep_analysis_investigation",
            "status" => "active",
            "persona" => "Knight of the mean streets with narrative depth",
            "catchphrase" => "Down these mean streets a man must go who is not himself mean."
        ),
        Dict{String,Any}(
            "id" => "dupin",
            "name" => "Detective Auguste Dupin",
            "specialty" => "analytical_reasoning_investigation",
            "status" => "active",
            "persona" => "Master of ratiocination and pure logic",
            "catchphrase" => "The mental features discoursed of as the analytical, are, in themselves, but little susceptible of analysis."
        ),
        Dict{String,Any}(
            "id" => "shadow",
            "name" => "The Shadow",
            "specialty" => "stealth_investigation",
            "status" => "active",
            "persona" => "Master of stealth and hidden network investigations",
            "catchphrase" => "Who knows what evil lurks in the hearts of wallets? The Shadow knows!"
        ),
        Dict{String,Any}(
            "id" => "raven",
            "name" => "Detective Raven",
            "specialty" => "dark_investigation",
            "status" => "active",
            "persona" => "Investigator of the darkest blockchain mysteries",
            "catchphrase" => "Nevermore shall evil transactions escape my vigilant gaze."
        )
    ]
end

# Count active detectives
function count_active_detectives()::Int
    return length(get_all_detectives())
end

# Create detective by type
function create_detective_by_type(detective_type::String)
    """Factory function to create specific detective types"""
    if detective_type == "poirot"
        return create_poirot_agent()
    elseif detective_type == "marple"
        return create_marple_agent()
    elseif detective_type == "spade"
        return create_spade_agent()
    elseif detective_type == "marlowee"
        return create_marlowee_agent()
    elseif detective_type == "dupin"
        return create_dupin_agent()
    elseif detective_type == "shadow"
        return create_shadow_agent()
    elseif detective_type == "raven"
        return create_raven_agent()
    else
        throw(ArgumentError("Unknown detective type: $detective_type. Available: poirot, marple, spade, marlowee, dupin, shadow, raven"))
    end
end

"""
Initialize all detective agents into a squad.
"""
function create_detective_squad()::Vector{Any}
    detective_types = ["poirot", "marple", "spade", "marlowee", "dupin", "shadow", "raven"]
    squad = Vector{Any}()

    for detective_type in detective_types
        try
            detective = create_detective_by_type(detective_type)
            push!(squad, detective)
            @info "Detective $detective_type initialized successfully"
        catch e
            @warn "Failed to initialize detective $detective_type: $e"
        end
    end

    @info "Detective squad created with $(length(squad)) active detectives"
    return squad
end

# Create a new detective agent
function create_detective(config::Dict)
    @info "Creating detective agent: $(config["name"])"

    detective = Detective(
        get(config, "id", string(uuid4())),
        get(config, "type", "generic"),
        get(config, "name", "Unknown Detective"),
        get(config, "specialty", "general_investigation"),
        get(config, "skills", String[]),
        get(config, "blockchain", "solana"),
        get(config, "status", "active"),
        get(config, "created_at", now()),
        get(config, "investigation_count", 0),
        get(config, "persona", "Generic detective"),
        get(config, "catchphrase", "Justice will prevail!")
    )

    return detective
end

# Helper to normalize outward-facing detective IDs (keep internal ids intact)
const DETECTIVE_ID_OUTPUT_MAP = Dict(
    "marlowee" => "marlowe",
)

_display_id(id::String) = get(DETECTIVE_ID_OUTPUT_MAP, id, id)

# Investigate wallet using specific detective methodology - REAL BLOCKCHAIN ANALYSIS
function investigate_wallet(detective_type::String, wallet_address::String, investigation_id::String)
    @info "🔍 Orchestrating investigation with $detective_type for wallet: $wallet_address"

    try
        # Route to appropriate detective agent for real investigation
        investigation_result = if detective_type == "poirot"
            investigate_poirot_style(wallet_address, investigation_id)
        elseif detective_type == "marple"
            investigate_marple_style(wallet_address, investigation_id)
        elseif detective_type == "spade"
            investigate_spade_style(wallet_address, investigation_id)
        elseif detective_type == "marlowee"
            investigate_marlowee_style(wallet_address, investigation_id)
        elseif detective_type == "dupin"
            investigate_dupin_style(wallet_address, investigation_id)
        elseif detective_type == "shadow"
            investigate_shadow_style(wallet_address, investigation_id)
        elseif detective_type == "raven"
            investigate_raven_style(wallet_address, investigation_id)
        else
            Dict(
                "detective" => "Unknown",
                "error" => "Unknown detective type: $detective_type",
                "methodology" => "none",
                "risk_score" => 0,
                "confidence" => 0,
                "status" => "failed"
            )
        end

        # Add orchestration metadata
        investigation_result["orchestrated_by"] = "DetectiveAgents"
        investigation_result["orchestration_timestamp"] = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
        investigation_result["investigation_id"] = investigation_id

        return investigation_result

    catch e
        @error "Error in detective orchestration: $e"
        return Dict(
            "detective" => detective_type,
            "error" => "Investigation failed: $e",
            "methodology" => "orchestration_error",
            "risk_score" => 0,
            "confidence" => 0,
            "status" => "error",
            "orchestrated_by" => "DetectiveAgents",
            "investigation_id" => investigation_id
        )
    end
end

# Orchestrate multi-detective investigation (parallel across all 7 by default)
function investigate_wallet_multi_detective(wallet_address::String, investigation_id::String, detective_types::Vector{String} = ["poirot", "marple", "spade", "marlowee", "dupin", "shadow", "raven"])
    @info "🔍 Multi-detective investigation for wallet: $wallet_address"

    # Pre-warm: run a quick Poirot fetch to populate cache and basic analysis
    try
        @info "⚡ Pre-warming cache with quick Poirot run"
        # Minimal depth and no AI to be fast but fill cache sufficiently
        cfg = PoirotAgent.ToolAnalyzeWalletConfig(max_transactions=300, analysis_depth="quick", include_ai_analysis=false, rate_limit_delay=0.2)
        task = Dict("wallet_address"=>wallet_address)
        base = PoirotAgent.tool_analyze_wallet(cfg, task)
        if !(get(base, "success", false))
            @warn "Pre-warm failed: $(get(base, "error", "unknown"))"
        end
    catch e
        @warn "Pre-warm error: $e"
    end

    results = Dict{String,Any}()

    # Run each detective in parallel
    tasks = Dict{String,Task}()
    for detective_type in detective_types
        tasks[detective_type] = Threads.@spawn investigate_wallet(detective_type, wallet_address, investigation_id)
    end

    # Collect results
    for (detective_type, t) in tasks
        try
            results[detective_type] = fetch(t)
        catch e
            @error "Failed investigation with $detective_type: $e"
            results[detective_type] = Dict(
                "detective" => detective_type,
                "error" => "Investigation failed: $e",
                "status" => "failed"
            )
        end
    end

    # Calculate consensus (consider only fully completed agents as successful)
    valid_results = filter(r -> get(r.second, "status", "") == "completed", results)

    if length(valid_results) > 0
        avg_risk = mean([get(r.second, "risk_score", 0.0) for r in valid_results])
        avg_confidence = mean([get(r.second, "confidence", 0.0) for r in valid_results])

        # Map internal ids to outward-facing ids for output with stable ordering
        display_results = Dict{String,Any}()
        for dt in detective_types
            if haskey(results, dt)
                display_results[_display_id(dt)] = results[dt]
            end
        end
        display_detectives = [_display_id(x) for x in detective_types]

        consensus = Dict(
            "multi_detective_analysis" => true,
            "participating_detectives" => display_detectives,
            "successful_investigations" => length(valid_results),
            "failed_investigations" => length(detective_types) - length(valid_results),
            "consensus_risk_score" => avg_risk,
            "consensus_confidence" => avg_confidence,
            "individual_results" => display_results,
            "investigation_id" => investigation_id,
            "wallet_address" => wallet_address,
            "timestamp" => Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
        )

        return consensus
    else
        return Dict(
            "multi_detective_analysis" => true,
            "error" => "All detective investigations failed",
            "participating_detectives" => [_display_id(x) for x in detective_types],
            "successful_investigations" => 0,
            "failed_investigations" => length(detective_types),
            "individual_results" => Dict{String,Any}([_display_id(k) => v for (k,v) in results]),
            "investigation_id" => investigation_id,
            "status" => "all_failed"
        )
    end
end

# ==========================================
# FRAMEWORK COMPATIBILITY INTERFACE
# ==========================================

"""
    create_detective_by_type(detective_type::String) -> Detective

Framework-compatible function to create detective agents by type.
"""
function create_detective_by_type(detective_type::String)
    try
        config = Dict(
            "id" => string(uuid4()),
            "type" => detective_type,
            "name" => get_detective_name(detective_type),
            "specialty" => get_detective_specialty(detective_type),
            "skills" => get_detective_skills(detective_type),
            "blockchain" => "solana",
            "status" => "active",
            "created_at" => now(),
            "investigation_count" => 0,
            "persona" => get_detective_persona(detective_type),
            "catchphrase" => get_detective_catchphrase(detective_type)
        )

        return create_detective(config)
    catch e
        @error "Failed to create detective by type '$detective_type': $e"
        return nothing
    end
end

"""
    get_detective_registry() -> Dict{String, Any}

Get the registry of all available detective agents.
"""
function get_detective_registry()
    return Dict(
        "available_detectives" => ["poirot", "marple", "spade", "marlowee", "dupin", "shadow", "raven"],
        "total_count" => 7,
        "status" => "active",
        "version" => "2.0_refactored"
    )
end

"""
    investigate_with_agent(detective_type::String, wallet_address::String, params::Dict = Dict())

Framework-compatible investigation function.
"""
function investigate_with_agent(detective_type::String, wallet_address::String, params::Dict = Dict())
    investigation_id = get(params, "investigation_id", string(uuid4()))
    return investigate_wallet(detective_type, wallet_address, investigation_id)
end

# High-level investigate entry used by JuliaOS.investigate_wallet
function investigate(squad::Vector{Any}, wallet_address::String, detective_type::String)
    inv_id = string(uuid4())
    if lowercase(detective_type) in ("comprehensive", "multi", "all")
        return investigate_wallet_multi_detective(wallet_address, inv_id)
    else
        return investigate_wallet(lowercase(detective_type), wallet_address, inv_id)
    end
end

# Legacy compatibility function for JuliaOS.jl
function investigate_wallet(agent::Dict, wallet_address::String, investigation_id::String)
    detective_type = lowercase(get(agent, "detective_type", "unknown"))
    return investigate_wallet(detective_type, wallet_address, investigation_id)
end

# Helper functions for detective metadata
function get_detective_name(detective_type::String)
    detective_names = Dict(
        "poirot" => "Hercule Poirot",
        "marple" => "Miss Jane Marple",
        "spade" => "Sam Spade",
        "marlowee" => "Philip Marlowe",
        "dupin" => "Auguste Dupin",
        "shadow" => "The Shadow",
        "raven" => "Edgar Allan Raven"
    )
    return get(detective_names, detective_type, "Unknown Detective")
end

function get_detective_specialty(detective_type::String)
    specialties = Dict(
        "poirot" => "methodical_transaction_analysis",
        "marple" => "behavioral_pattern_detection",
        "spade" => "risk_assessment_compliance",
        "marlowee" => "deep_analysis_investigation",
        "dupin" => "analytical_reasoning",
        "shadow" => "stealth_investigation",
        "raven" => "dark_investigation_synthesis"
    )
    return get(specialties, detective_type, "general_investigation")
end

function get_detective_skills(detective_type::String)
    skills_map = Dict(
        "poirot" => ["transaction_analysis", "methodical_investigation", "pattern_recognition"],
        "marple" => ["behavioral_analysis", "social_patterns", "intuitive_detection"],
        "spade" => ["risk_assessment", "compliance_checking", "threat_evaluation"],
        "marlowee" => ["corruption_detection", "deep_analysis", "cynical_investigation"],
        "dupin" => ["analytical_reasoning", "mathematical_analysis", "logical_deduction"],
        "shadow" => ["stealth_analysis", "hidden_patterns", "covert_investigation"],
        "raven" => ["dark_psychology", "synthesis", "narrative_creation"]
    )
    return get(skills_map, detective_type, ["general_investigation"])
end

function get_detective_persona(detective_type::String)
    personas = Dict(
        "poirot" => "Meticulous Belgian detective with methodical approach to blockchain analysis",
        "marple" => "Observant elderly sleuth with intuitive understanding of human behavior",
        "spade" => "Hard-boiled private investigator focused on risk and compliance",
        "marlowee" => "Cynical detective specializing in corruption and power structure analysis",
        "dupin" => "Analytical reasoner using pure logic and mathematical deduction",
        "shadow" => "Mysterious investigator operating in the shadows of blockchain networks",
        "raven" => "Dark analyst providing comprehensive investigation synthesis"
    )
    return get(personas, detective_type, "General purpose detective agent")
end

function get_detective_catchphrase(detective_type::String)
    catchphrases = Dict(
        "poirot" => "These little grey cells, they show me the truth in the blockchain!",
        "marple" => "Human nature is the same everywhere, even in crypto transactions.",
        "spade" => "The facts, ma'am. Just the blockchain facts.",
        "marlowee" => "In this crypto city, every wallet tells a story of corruption or virtue.",
        "dupin" => "Through pure analytical reasoning, all blockchain mysteries unfold.",
        "shadow" => "Who knows what evil lurks in the hearts of crypto wallets? The Shadow knows!",
        "raven" => "Nevermore shall suspicious transactions escape our dark investigation."
    )
    return get(catchphrases, detective_type, "Justice will prevail in the blockchain!")
end

# Update exports for framework compatibility
export create_detective_by_type, get_detective_registry, investigate_with_agent
export get_detective_name, get_detective_specialty, get_detective_skills

# ADD MISSING FUNCTIONS FOR FRAMEWORK COMPATIBILITY
function getAgent(agent_id::String)
    """Get agent by ID - compatibility function"""
    return create_detective_by_type(agent_id)
end

function executeAgentTask(agent::Detective, task::Dict)
    """Execute agent task - compatibility function"""
    wallet_address = get(task, "wallet_address", "")
    if !isempty(wallet_address)
        return investigate_wallet(agent, wallet_address)
    end
    return Dict("error" => "No wallet address provided")
end

function getAgentStatus(agent::Detective)
    """Get agent status - compatibility function"""
    return agent.status
end

function listAgents()
    """List all agents - compatibility function"""
    return get_all_detectives()
end

function startAgent(agent_type::String)
    """Start agent - compatibility function"""
    return create_detective_by_type(agent_type)
end

# Export compatibility functions
export getAgent, executeAgentTask, getAgentStatus, listAgents, startAgent

end # module DetectiveAgents
