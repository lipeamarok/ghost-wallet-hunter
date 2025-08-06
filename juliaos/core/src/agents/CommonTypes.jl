module CommonTypes

using StructTypes

# Export basic types
export ToolConfig, ToolMetadata, ToolSpecification, InstantiatedTool
export AgentState, AgentContext, TriggerType, TriggerParams, TriggerConfig
export PeriodicTriggerParams, WebhookTriggerParams
export StrategyConfig, StrategyMetadata, StrategyInput, StrategySpecification, InstantiatedStrategy
export ToolBlueprint, StrategyBlueprint, AgentBlueprint, Agent

# Export detective-specific types
export DetectiveTriggerType, WalletMonitorTriggerParams, InvestigationRequestTriggerParams, ScheduledAnalysisTriggerParams
export BlockchainAnalysisToolConfig, PatternDetectionToolConfig, ComplianceCheckToolConfig
export MethodicalAnalysisStrategyConfig, PatternAnomalyDetectionStrategyConfig, HardBoiledInvestigationStrategyConfig
export DeepAnalysisStrategyConfig, AnalyticalReasoningStrategyConfig, StealthInvestigationStrategyConfig, DarkInvestigationStrategyConfig
export DetectiveAgentBlueprint

# Export detective blueprint functions
export create_detective_blueprint, get_all_detective_blueprints, create_wallet_monitor_blueprint
export create_poirot_blueprint, create_marple_blueprint, create_spade_blueprint, create_marlowee_blueprint
export create_dupin_blueprint, create_shadow_blueprint, create_raven_blueprint

# Tools:

abstract type ToolConfig end

struct ToolMetadata
    name::String
    description::String
end

struct ToolSpecification
    execute::Function
    config_type::DataType
    metadata::ToolMetadata
end

struct InstantiatedTool
    execute::Function
    config::ToolConfig
    metadata::ToolMetadata
end

# Agent internals:

@enum AgentState CREATED_STATE RUNNING_STATE PAUSED_STATE STOPPED_STATE

struct AgentContext
    tools::Vector{InstantiatedTool}
    logs::Vector{String}
end

# Triggers:

@enum TriggerType PERIODIC_TRIGGER WEBHOOK_TRIGGER

abstract type TriggerParams end

struct TriggerConfig
    type::TriggerType
    params::TriggerParams
end

struct PeriodicTriggerParams <: TriggerParams
    interval::Int  # Interval in seconds
end

struct WebhookTriggerParams <: TriggerParams
end

# Strategies:

abstract type StrategyConfig end

struct StrategyMetadata
    name::String
end

abstract type StrategyInput end
StructTypes.StructType(::Type{T}) where {T<:StrategyInput} = StructTypes.Struct()

struct StrategySpecification
    run::Function
    initialize::Union{Nothing, Function}
    config_type::DataType
    metadata::StrategyMetadata
    input_type::Union{DataType,Nothing}
end

struct InstantiatedStrategy
    run::Function
    initialize::Union{Nothing, Function}
    config::StrategyConfig
    metadata::StrategyMetadata
    input_type::Union{DataType,Nothing}
end

# Blueprints:

struct ToolBlueprint
    name::String
    config_data::Dict{String, Any}
end

struct StrategyBlueprint
    name::String
    config_data::Dict{String, Any}
end

struct AgentBlueprint
    tools::Vector{ToolBlueprint}
    strategy::StrategyBlueprint
    trigger::TriggerConfig
end

# Agent proper:

mutable struct Agent
    id::String
    name::String
    description::String
    context::AgentContext
    strategy::InstantiatedStrategy
    trigger::TriggerConfig
    state::AgentState
end

# ----------------------------------------------------------------------
# DETECTIVE AGENTS SPECIALIZED TYPES & BLUEPRINTS
# ----------------------------------------------------------------------

# Detective-specific trigger types
@enum DetectiveTriggerType WALLET_MONITOR_TRIGGER INVESTIGATION_REQUEST_TRIGGER SCHEDULED_ANALYSIS_TRIGGER

struct WalletMonitorTriggerParams <: TriggerParams
    wallet_addresses::Vector{String}
    check_interval::Int  # Interval in seconds
    analysis_depth::String
end

struct InvestigationRequestTriggerParams <: TriggerParams
    priority_queue::Bool
    auto_assign::Bool
end

struct ScheduledAnalysisTriggerParams <: TriggerParams
    cron_schedule::String  # Cron expression for scheduling
    batch_size::Int
    target_detective_types::Vector{String}
end

# Detective-specific tool configurations
struct BlockchainAnalysisToolConfig <: ToolConfig
    blockchain::String
    max_transactions::Int
    analysis_depth::String
    rate_limit_delay::Float64
    include_ai_analysis::Bool
end

struct PatternDetectionToolConfig <: ToolConfig
    pattern_types::Vector{String}
    sensitivity_threshold::Float64
    cache_results::Bool
end

struct ComplianceCheckToolConfig <: ToolConfig
    regulations::Vector{String}  # ["AML", "KYC", "FATF", etc.]
    risk_tolerance::Float64
    automated_reporting::Bool
end

# Detective-specific strategy configurations
struct MethodicalAnalysisStrategyConfig <: StrategyConfig
    precision_level::Float64
    step_by_step_analysis::Bool
    documentation_detail::String
end

struct PatternAnomalyDetectionStrategyConfig <: StrategyConfig
    anomaly_threshold::Float64
    pattern_sensitivity::Float64
    behavioral_analysis_depth::String
end

struct HardBoiledInvestigationStrategyConfig <: StrategyConfig
    investigation_style::String
    risk_tolerance::Float64
    compliance_integration::Bool
end

struct DeepAnalysisStrategyConfig <: StrategyConfig
    narrative_depth::Int
    corruption_detection_level::String
    multi_layer_analysis::Bool
end

struct AnalyticalReasoningStrategyConfig <: StrategyConfig
    ratiocination_level::Int
    logical_consistency_check::Bool
    mathematical_modeling::Bool
end

struct StealthInvestigationStrategyConfig <: StrategyConfig
    stealth_level::Float64
    hidden_pattern_detection::Bool
    anonymity_preservation::Bool
end

struct DarkInvestigationStrategyConfig <: StrategyConfig
    darkness_detection_level::Float64
    psychological_profiling::Bool
    cryptic_interpretation::Bool
end

# Detective Agent Blueprint - Specialized version of AgentBlueprint
struct DetectiveAgentBlueprint
    detective_type::String  # "poirot", "marple", "spade", etc.
    name::String
    description::String
    tools::Vector{ToolBlueprint}
    strategy::StrategyBlueprint
    trigger::TriggerConfig
    blockchain_config::Dict{String, Any}
    investigation_params::Dict{String, Any}
    memory_config::Dict{String, Any}
end

# Factory functions for creating detective blueprints
"""
    create_detective_blueprint(detective_type::String, custom_config::Dict{String, Any}=Dict()) -> DetectiveAgentBlueprint

Creates a blueprint for a specific detective agent type with predefined tools and strategies.
"""
function create_detective_blueprint(detective_type::String, custom_config::Dict{String, Any}=Dict())
    if detective_type == "poirot"
        return create_poirot_blueprint(custom_config)
    elseif detective_type == "marple"
        return create_marple_blueprint(custom_config)
    elseif detective_type == "spade"
        return create_spade_blueprint(custom_config)
    elseif detective_type == "marlowee"
        return create_marlowee_blueprint(custom_config)
    elseif detective_type == "dupin"
        return create_dupin_blueprint(custom_config)
    elseif detective_type == "shadow"
        return create_shadow_blueprint(custom_config)
    elseif detective_type == "raven"
        return create_raven_blueprint(custom_config)
    else
        throw(ArgumentError("Unknown detective type: $detective_type"))
    end
end

# Individual detective blueprint creators
function create_poirot_blueprint(custom_config::Dict{String, Any}=Dict())
    tools = [
        ToolBlueprint("blockchain_analysis", Dict(
            "type" => "BlockchainAnalysisToolConfig",
            "blockchain" => "solana",
            "max_transactions" => 1000,
            "analysis_depth" => "deep",
            "rate_limit_delay" => 0.8,
            "include_ai_analysis" => false
        )),
        ToolBlueprint("pattern_detection", Dict(
            "type" => "PatternDetectionToolConfig",
            "pattern_types" => ["methodical", "systematic", "precision"],
            "sensitivity_threshold" => 0.85,
            "cache_results" => true
        ))
    ]

    strategy = StrategyBlueprint("methodical_analysis", Dict(
        "type" => "MethodicalAnalysisStrategyConfig",
        "precision_level" => 0.95,
        "step_by_step_analysis" => true,
        "documentation_detail" => "comprehensive"
    ))

    trigger = TriggerConfig(PERIODIC_TRIGGER, PeriodicTriggerParams(300))  # Every 5 minutes

    return DetectiveAgentBlueprint(
        "poirot",
        "Detective Hercule Poirot",
        "Belgian master of deduction specialized in methodical transaction analysis",
        tools,
        strategy,
        trigger,
        Dict("blockchain" => "solana", "precision_focus" => true),
        Dict("analysis_style" => "methodical", "catchphrase" => "Ah, mon ami, the little grey cells, they work!"),
        Dict("type" => "detective_memory", "max_investigations" => 200)
    )
end

function create_marple_blueprint(custom_config::Dict{String, Any}=Dict())
    tools = [
        ToolBlueprint("blockchain_analysis", Dict(
            "type" => "BlockchainAnalysisToolConfig",
            "blockchain" => "solana",
            "max_transactions" => 1000,
            "analysis_depth" => "deep",
            "rate_limit_delay" => 1.0,
            "include_ai_analysis" => false
        )),
        ToolBlueprint("pattern_detection", Dict(
            "type" => "PatternDetectionToolConfig",
            "pattern_types" => ["behavioral", "anomaly", "statistical"],
            "sensitivity_threshold" => 0.70,
            "cache_results" => true
        ))
    ]

    strategy = StrategyBlueprint("pattern_anomaly_detection", Dict(
        "type" => "PatternAnomalyDetectionStrategyConfig",
        "anomaly_threshold" => 0.70,
        "pattern_sensitivity" => 0.85,
        "behavioral_analysis_depth" => "comprehensive"
    ))

    trigger = TriggerConfig(PERIODIC_TRIGGER, PeriodicTriggerParams(420))  # Every 7 minutes

    return DetectiveAgentBlueprint(
        "marple",
        "Detective Miss Jane Marple",
        "Perceptive observer who notices details others miss in blockchain patterns",
        tools,
        strategy,
        trigger,
        Dict("blockchain" => "solana", "pattern_focus" => true),
        Dict("analysis_style" => "observational", "catchphrase" => "Oh my dear, that's rather peculiar, isn't it?"),
        Dict("type" => "detective_memory", "max_investigations" => 250)
    )
end

function create_spade_blueprint(custom_config::Dict{String, Any}=Dict())
    tools = [
        ToolBlueprint("blockchain_analysis", Dict(
            "type" => "BlockchainAnalysisToolConfig",
            "blockchain" => "solana",
            "max_transactions" => 1000,
            "analysis_depth" => "deep",
            "rate_limit_delay" => 0.9,
            "include_ai_analysis" => false
        )),
        ToolBlueprint("compliance_check", Dict(
            "type" => "ComplianceCheckToolConfig",
            "regulations" => ["AML", "KYC", "FATF", "BSA"],
            "risk_tolerance" => 0.8,
            "automated_reporting" => true
        ))
    ]

    strategy = StrategyBlueprint("hard_boiled_investigation", Dict(
        "type" => "HardBoiledInvestigationStrategyConfig",
        "investigation_style" => "aggressive",
        "risk_tolerance" => 0.8,
        "compliance_integration" => true
    ))

    trigger = TriggerConfig(PERIODIC_TRIGGER, PeriodicTriggerParams(240))  # Every 4 minutes

    return DetectiveAgentBlueprint(
        "spade",
        "Detective Sam Spade",
        "Hard-boiled private detective with compliance expertise and risk assessment",
        tools,
        strategy,
        trigger,
        Dict("blockchain" => "solana", "compliance_focus" => true),
        Dict("analysis_style" => "hard_boiled", "catchphrase" => "When you're slapped, you'll take it and like it."),
        Dict("type" => "detective_memory", "max_investigations" => 300)
    )
end

function create_marlowee_blueprint(custom_config::Dict{String, Any}=Dict())
    tools = [
        ToolBlueprint("blockchain_analysis", Dict(
            "type" => "BlockchainAnalysisToolConfig",
            "blockchain" => "solana",
            "max_transactions" => 1000,
            "analysis_depth" => "deep",
            "rate_limit_delay" => 1.2,
            "include_ai_analysis" => false
        ))
    ]

    strategy = StrategyBlueprint("deep_analysis", Dict(
        "type" => "DeepAnalysisStrategyConfig",
        "narrative_depth" => 5,
        "corruption_detection_level" => "comprehensive",
        "multi_layer_analysis" => true
    ))

    trigger = TriggerConfig(PERIODIC_TRIGGER, PeriodicTriggerParams(600))  # Every 10 minutes

    return DetectiveAgentBlueprint(
        "marlowee",
        "Detective Philip Marlowe",
        "Knight of the mean streets with deep analysis and narrative investigation",
        tools,
        strategy,
        trigger,
        Dict("blockchain" => "solana", "narrative_focus" => true),
        Dict("analysis_style" => "narrative_deep", "catchphrase" => "Down these mean streets a man must go who is not himself mean."),
        Dict("type" => "detective_memory", "max_investigations" => 150)
    )
end

function create_dupin_blueprint(custom_config::Dict{String, Any}=Dict())
    tools = [
        ToolBlueprint("blockchain_analysis", Dict(
            "type" => "BlockchainAnalysisToolConfig",
            "blockchain" => "solana",
            "max_transactions" => 1000,
            "analysis_depth" => "deep",
            "rate_limit_delay" => 0.8,
            "include_ai_analysis" => false
        ))
    ]

    strategy = StrategyBlueprint("analytical_reasoning", Dict(
        "type" => "AnalyticalReasoningStrategyConfig",
        "ratiocination_level" => 5,
        "logical_consistency_check" => true,
        "mathematical_modeling" => true
    ))

    trigger = TriggerConfig(PERIODIC_TRIGGER, PeriodicTriggerParams(360))  # Every 6 minutes

    return DetectiveAgentBlueprint(
        "dupin",
        "Detective Auguste Dupin",
        "Master of ratiocination and analytical reasoning with pure logic approach",
        tools,
        strategy,
        trigger,
        Dict("blockchain" => "solana", "logic_focus" => true),
        Dict("analysis_style" => "analytical_deductive", "catchphrase" => "The mental features discoursed of as the analytical..."),
        Dict("type" => "detective_memory", "max_investigations" => 180)
    )
end

function create_shadow_blueprint(custom_config::Dict{String, Any}=Dict())
    tools = [
        ToolBlueprint("blockchain_analysis", Dict(
            "type" => "BlockchainAnalysisToolConfig",
            "blockchain" => "solana",
            "max_transactions" => 1000,
            "analysis_depth" => "deep",
            "rate_limit_delay" => 1.2,
            "include_ai_analysis" => false
        ))
    ]

    strategy = StrategyBlueprint("stealth_investigation", Dict(
        "type" => "StealthInvestigationStrategyConfig",
        "stealth_level" => 0.9,
        "hidden_pattern_detection" => true,
        "anonymity_preservation" => true
    ))

    trigger = TriggerConfig(PERIODIC_TRIGGER, PeriodicTriggerParams(480))  # Every 8 minutes

    return DetectiveAgentBlueprint(
        "shadow",
        "The Shadow",
        "Master of stealth and hidden network investigations",
        tools,
        strategy,
        trigger,
        Dict("blockchain" => "solana", "stealth_focus" => true),
        Dict("analysis_style" => "stealth_covert", "catchphrase" => "Who knows what evil lurks in the hearts of wallets? The Shadow knows!"),
        Dict("type" => "detective_memory", "max_investigations" => 220)
    )
end

function create_raven_blueprint(custom_config::Dict{String, Any}=Dict())
    tools = [
        ToolBlueprint("blockchain_analysis", Dict(
            "type" => "BlockchainAnalysisToolConfig",
            "blockchain" => "solana",
            "max_transactions" => 1000,
            "analysis_depth" => "deep",
            "rate_limit_delay" => 1.1,
            "include_ai_analysis" => false
        ))
    ]

    strategy = StrategyBlueprint("dark_investigation", Dict(
        "type" => "DarkInvestigationStrategyConfig",
        "darkness_detection_level" => 0.92,
        "psychological_profiling" => true,
        "cryptic_interpretation" => true
    ))

    trigger = TriggerConfig(PERIODIC_TRIGGER, PeriodicTriggerParams(540))  # Every 9 minutes

    return DetectiveAgentBlueprint(
        "raven",
        "Detective Raven",
        "Investigator of the darkest blockchain mysteries with gothic analysis",
        tools,
        strategy,
        trigger,
        Dict("blockchain" => "solana", "darkness_focus" => true),
        Dict("analysis_style" => "dark_gothic", "catchphrase" => "Nevermore shall evil transactions escape my vigilant gaze."),
        Dict("type" => "detective_memory", "max_investigations" => 190)
    )
end

# Utility functions for blueprint management
"""
    get_all_detective_blueprints() -> Vector{DetectiveAgentBlueprint}

Returns blueprints for all available detective agent types.
"""
function get_all_detective_blueprints()
    detective_types = ["poirot", "marple", "spade", "marlowee", "dupin", "shadow", "raven"]
    return [create_detective_blueprint(dt) for dt in detective_types]
end

"""
    create_wallet_monitor_blueprint(wallet_addresses::Vector{String}, check_interval::Int=300) -> AgentBlueprint

Creates a blueprint for a wallet monitoring agent that periodically checks specified wallets.
"""
function create_wallet_monitor_blueprint(wallet_addresses::Vector{String}, check_interval::Int=300)
    tools = [
        ToolBlueprint("blockchain_analysis", Dict(
            "type" => "BlockchainAnalysisToolConfig",
            "blockchain" => "solana",
            "max_transactions" => 100,  # Lighter analysis for monitoring
            "analysis_depth" => "standard",
            "rate_limit_delay" => 2.0,
            "include_ai_analysis" => false
        ))
    ]

    strategy = StrategyBlueprint("wallet_monitoring", Dict(
        "type" => "MonitoringStrategyConfig",
        "target_wallets" => wallet_addresses,
        "alert_threshold" => 0.6,
        "continuous_monitoring" => true
    ))

    trigger_params = WalletMonitorTriggerParams(wallet_addresses, check_interval, "standard")
    trigger = TriggerConfig(PERIODIC_TRIGGER, PeriodicTriggerParams(check_interval))

    return AgentBlueprint(tools, strategy, trigger)
end

end