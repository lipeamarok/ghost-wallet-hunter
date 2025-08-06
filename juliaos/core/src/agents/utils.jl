using .CommonTypes: InstantiatedTool, InstantiatedStrategy, StrategyBlueprint, ToolBlueprint, AgentState, TriggerType
using .AgentCore: DetectiveMemory, InvestigationTask
# using JSONSchemaGenerator  # Commented out - not needed for basic functionality
using Dates

function deserialize_object(object_type::DataType, data::Dict{String, Any})
    expected_fields = fieldnames(object_type)
    provided_fields = Symbol.(keys(data))

    unexpected_fields = setdiff(provided_fields, expected_fields)
    missing_fields = setdiff(expected_fields, provided_fields)

    if !isempty(missing_fields)
        @warn "Missing fields in data: $(missing_fields)"
    end
    if !isempty(unexpected_fields)
        @warn "Unexpected fields in data: $(unexpected_fields)"
    end

    #@info "Deserializing object of type $(object_type) with data: $(data)"
    symbolic_data = Dict(Symbol(k) => v for (k, v) in data)
    return object_type(; symbolic_data...)
end

function instantiate_tool(blueprint::ToolBlueprint)::InstantiatedTool
    if !haskey(Tools.TOOL_REGISTRY, blueprint.name)
        error("Tool '$(blueprint.name)' is not registered.")
    end

    tool_spec = Tools.TOOL_REGISTRY[blueprint.name]

    tool_config = deserialize_object(tool_spec.config_type, blueprint.config_data)

    return InstantiatedTool(tool_spec.execute, tool_config, tool_spec.metadata)
end


function instantiate_strategy(blueprint::StrategyBlueprint)::InstantiatedStrategy
    if !haskey(Strategies.STRATEGY_REGISTRY, blueprint.name)
        error("Strategy '$(blueprint.name)' is not registered.")
    end

    strategy_spec = Strategies.STRATEGY_REGISTRY[blueprint.name]

    strategy_config = deserialize_object(strategy_spec.config_type, blueprint.config_data)

    return InstantiatedStrategy(strategy_spec.run, strategy_spec.initialize, strategy_config, strategy_spec.metadata, strategy_spec.input_type)
end

const AGENT_STATE_NAMES = Dict(
    CommonTypes.CREATED_STATE  => "CREATED",
    CommonTypes.RUNNING_STATE  => "RUNNING",
    CommonTypes.PAUSED_STATE   => "PAUSED",
    CommonTypes.STOPPED_STATE  => "STOPPED",
)

function agent_state_to_string(state::AgentState)::String
    return get(AGENT_STATE_NAMES, state) do
        error("Unknown AgentState: $state")
    end
end

const NAME_TO_AGENT_STATE = Dict(v => k for (k, v) in AGENT_STATE_NAMES)

function string_to_agent_state(name::String)::AgentState
    return get(NAME_TO_AGENT_STATE, name) do
        error("Invalid AgentState name: $name")
    end
end

const TRIGGER_TYPE_NAMES = Dict(
    CommonTypes.PERIODIC_TRIGGER => "PERIODIC",
    CommonTypes.WEBHOOK_TRIGGER => "WEBHOOK",
)

function trigger_type_to_string(trigger::TriggerType)::String
    return get(TRIGGER_TYPE_NAMES, trigger) do
        error("Unknown TriggerType: $trigger")
    end
end

"""
    input_schema_json(agent) -> String

Same, but as a compact JSON string.
"""
function input_type_json(agent::CommonTypes.Agent)
    isnothing(agent.strategy.input_type) ? Dict{String, Any}() : JSONSchemaGenerator.schema(agent.strategy.input_type)
end

const NAME_TO_TRIGGER_TYPE = Dict(v => k for (k, v) in TRIGGER_TYPE_NAMES)

function string_to_trigger_type(name::String)::TriggerType
    return get(NAME_TO_TRIGGER_TYPE, name) do
        error("Invalid TriggerType name: $name")
    end
end

const TRIGGER_PARAM_TYPES = Dict(
    CommonTypes.PERIODIC_TRIGGER => CommonTypes.PeriodicTriggerParams,
    CommonTypes.WEBHOOK_TRIGGER => CommonTypes.WebhookTriggerParams,
)

function trigger_type_to_params_type(trigger::TriggerType)::DataType
    return get(TRIGGER_PARAM_TYPES, trigger) do
        error("Unknown TriggerType: $trigger")
    end
end

# ----------------------------------------------------------------------
# DETECTIVE-SPECIFIC UTILITY FUNCTIONS
# ----------------------------------------------------------------------

"""
    format_investigation_summary(investigation::InvestigationTask) -> String

Creates a formatted summary of an investigation for logging and display.
"""
function format_investigation_summary(investigation::InvestigationTask)
    status_emoji = investigation.status == :completed ? "✅" : investigation.status == :failed ? "❌" : "⏳"

    duration_str = ""
    if investigation.completed_at !== nothing
        duration = investigation.completed_at - investigation.created_at
        duration_str = " ($(round(duration.value/1000, digits=2))s)"
    end

    summary = "$(status_emoji) Investigation $(investigation.id)\n"
    summary *= "   📍 Wallet: $(investigation.wallet_address)\n"
    summary *= "   🔍 Type: $(investigation.task_type)\n"
    summary *= "   ⏰ Created: $(investigation.created_at)$duration_str\n"

    if haskey(investigation.result, "risk_score")
        risk_score = investigation.result["risk_score"]
        risk_emoji = risk_score >= 0.8 ? "🚨" : risk_score >= 0.6 ? "⚠️" : "✅"
        summary *= "   $(risk_emoji) Risk Score: $(round(risk_score, digits=3))\n"
    end

    if haskey(investigation.result, "patterns_detected")
        patterns = length(investigation.result["patterns_detected"])
        summary *= "   🔎 Patterns Found: $patterns\n"
    end

    return summary
end

"""
    calculate_detective_memory_stats(memory::DetectiveMemory) -> Dict{String, Any}

Calculates statistics about detective memory usage and performance.
"""
function calculate_detective_memory_stats(memory::DetectiveMemory)
    stats = Dict{String, Any}(
        "total_investigations" => length(memory.investigation_history),
        "successful_investigations" => 0,
        "failed_investigations" => 0,
        "avg_investigation_time" => 0.0,
        "pattern_cache_size" => length(memory.pattern_cache),
        "unique_wallets_investigated" => 0,
        "investigation_types" => Dict{String, Int}(),
        "time_period" => Dict{String, Any}()
    )

    if isempty(memory.investigation_history)
        return stats
    end

    # Calculate success/failure rates
    completed_investigations = filter(inv -> inv.status == :completed, memory.investigation_history)
    failed_investigations = filter(inv -> inv.status == :failed, memory.investigation_history)

    stats["successful_investigations"] = length(completed_investigations)
    stats["failed_investigations"] = length(failed_investigations)

    # Calculate average investigation time for completed investigations
    if !isempty(completed_investigations)
        durations = [inv.completed_at - inv.created_at for inv in completed_investigations if inv.completed_at !== nothing]
        if !isempty(durations)
            avg_duration_ms = sum(d.value for d in durations) / length(durations)
            stats["avg_investigation_time"] = avg_duration_ms / 1000  # Convert to seconds
        end
    end

    # Count unique wallets
    unique_wallets = Set(inv.wallet_address for inv in memory.investigation_history)
    stats["unique_wallets_investigated"] = length(unique_wallets)

    # Count investigation types
    for inv in memory.investigation_history
        task_type = inv.task_type
        stats["investigation_types"][task_type] = get(stats["investigation_types"], task_type, 0) + 1
    end

    # Time period analysis
    if !isempty(memory.investigation_history)
        earliest = minimum(inv.created_at for inv in memory.investigation_history)
        latest = maximum(inv.created_at for inv in memory.investigation_history)

        stats["time_period"]["earliest_investigation"] = string(earliest)
        stats["time_period"]["latest_investigation"] = string(latest)
        stats["time_period"]["span_days"] = (latest - earliest).value / (1000 * 60 * 60 * 24)
    end

    return stats
end

"""
    validate_wallet_address(address::String) -> Bool

Validates if a wallet address has the correct format (simplified Solana validation).
"""
function validate_wallet_address(address::String)
    # Basic Solana address validation (44 characters, base58)
    if length(address) != 44
        return false
    end

    # Check if it contains only valid base58 characters
    base58_chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    return all(char -> char in base58_chars, address)
end

"""
    sanitize_investigation_parameters(params::Dict{String, Any}) -> Dict{String, Any}

Sanitizes and validates investigation parameters.
"""
function sanitize_investigation_parameters(params::Dict{String, Any})
    sanitized = Dict{String, Any}()

    # Copy safe parameters
    safe_keys = [
        "investigation_type", "detective_type", "priority", "timeout",
        "max_transactions", "include_ai_analysis", "pattern_threshold",
        "risk_threshold", "blockchain", "deep_scan"
    ]

    for key in safe_keys
        if haskey(params, key)
            sanitized[key] = params[key]
        end
    end

    # Validate and sanitize specific parameters
    if haskey(sanitized, "timeout")
        timeout = sanitized["timeout"]
        if isa(timeout, Number) && timeout > 0
            sanitized["timeout"] = min(timeout, 1800)  # Max 30 minutes
        else
            delete!(sanitized, "timeout")
        end
    end

    if haskey(sanitized, "max_transactions")
        max_tx = sanitized["max_transactions"]
        if isa(max_tx, Number) && max_tx > 0
            sanitized["max_transactions"] = min(max_tx, 1000)  # Max 1000 transactions
        else
            delete!(sanitized, "max_transactions")
        end
    end

    if haskey(sanitized, "priority")
        priority = sanitized["priority"]
        if isa(priority, Number)
            sanitized["priority"] = clamp(priority, 1, 5)  # Priority 1-5
        else
            sanitized["priority"] = 1
        end
    end

    return sanitized
end

"""
    create_investigation_id(wallet_address::String, detective_type::String="") -> String

Creates a unique investigation ID.
"""
function create_investigation_id(wallet_address::String, detective_type::String="")
    timestamp = replace(string(now()), ":" => "", "." => "", "-" => "")
    wallet_short = wallet_address[1:min(8, length(wallet_address))]
    detective_prefix = isempty(detective_type) ? "" : "$(detective_type[1:min(3, length(detective_type))])_"

    return "inv_$(detective_prefix)$(wallet_short)_$(timestamp)"
end

"""
    extract_risk_indicators(investigation_result::Dict{String, Any}) -> Vector{String}

Extracts risk indicators from investigation results.
"""
function extract_risk_indicators(investigation_result::Dict{String, Any})
    indicators = Vector{String}()

    # Check for patterns in results
    if haskey(investigation_result, "patterns_detected")
        append!(indicators, investigation_result["patterns_detected"])
    end

    # Check for suspicious activities
    if haskey(investigation_result, "suspicious_activities")
        append!(indicators, investigation_result["suspicious_activities"])
    end

    # Check for risk flags
    if haskey(investigation_result, "risk_flags")
        append!(indicators, investigation_result["risk_flags"])
    end

    # Extract indicators from nested analysis
    if haskey(investigation_result, "analysis")
        analysis = investigation_result["analysis"]
        if isa(analysis, Dict)
            if haskey(analysis, "suspicious_indicators")
                append!(indicators, analysis["suspicious_indicators"])
            end
        end
    end

    return unique(indicators)
end

"""
    format_risk_score_display(risk_score::Float64) -> String

Formats risk score for display with appropriate emoji and color coding.
"""
function format_risk_score_display(risk_score::Float64)
    clamped_score = clamp(risk_score, 0.0, 1.0)
    percentage = round(clamped_score * 100, digits=1)

    if clamped_score >= 0.8
        return "🚨 HIGH RISK ($(percentage)%)"
    elseif clamped_score >= 0.6
        return "⚠️  MEDIUM RISK ($(percentage)%)"
    elseif clamped_score >= 0.3
        return "⚡ LOW RISK ($(percentage)%)"
    else
        return "✅ MINIMAL RISK ($(percentage)%)"
    end
end

"""
    get_detective_specialties() -> Dict{String, String}

Returns a mapping of detective types to their specialties.
"""
function get_detective_specialties()
    return Dict{String, String}(
        "poirot" => "Meticulous Analysis & Logical Sequences",
        "marple" => "Intuitive Detection & Social Patterns",
        "spade" => "Hard-boiled Investigation & Criminal Patterns",
        "marlowee" => "Cynical Analysis & Corruption Detection",
        "dupin" => "Analytical Reasoning & Mathematical Patterns",
        "shadow" => "Stealth Investigation & Hidden Networks",
        "raven" => "Dark Psychology & Behavioral Analysis"
    )
end

"""
    choose_best_detective_for_case(risk_indicators::Vector{String}, case_complexity::String="standard") -> String

Recommends the best detective type based on risk indicators and case complexity.
"""
function choose_best_detective_for_case(risk_indicators::Vector{String}, case_complexity::String="standard")
    detective_scores = Dict{String, Int}(
        "poirot" => 0, "marple" => 0, "spade" => 0,
        "marlowee" => 0, "dupin" => 0, "shadow" => 0, "raven" => 0
    )

    # Score detectives based on risk indicators
    for indicator in risk_indicators
        if indicator in ["methodical_patterns", "logical_sequences", "financial_inconsistencies"]
            detective_scores["poirot"] += 3
        elseif indicator in ["social_networks", "behavioral_patterns", "community_anomalies"]
            detective_scores["marple"] += 3
        elseif indicator in ["criminal_patterns", "money_laundering", "illicit_activities"]
            detective_scores["spade"] += 3
        elseif indicator in ["corruption_indicators", "power_abuse", "institutional_fraud"]
            detective_scores["marlowee"] += 3
        elseif indicator in ["mathematical_anomalies", "statistical_outliers", "algorithmic_patterns"]
            detective_scores["dupin"] += 3
        elseif indicator in ["hidden_networks", "stealth_operations", "covert_activities"]
            detective_scores["shadow"] += 3
        elseif indicator in ["psychological_patterns", "behavioral_anomalies", "dark_motivations"]
            detective_scores["raven"] += 3
        end

        # General scoring for certain common patterns
        if indicator in ["high_frequency_small_transactions", "circular_transaction_patterns"]
            detective_scores["poirot"] += 1
            detective_scores["dupin"] += 1
        elseif indicator in ["cross_chain_obfuscation", "privacy_coin_mixing"]
            detective_scores["shadow"] += 2
            detective_scores["spade"] += 1
        end
    end

    # Adjust for case complexity
    if case_complexity == "simple"
        detective_scores["marple"] += 2  # Intuitive approach works well for simple cases
    elseif case_complexity == "complex"
        detective_scores["poirot"] += 2  # Methodical approach for complex cases
        detective_scores["dupin"] += 2   # Analytical approach for complex cases
    elseif case_complexity == "forensic"
        detective_scores["poirot"] += 3  # Most methodical for forensic work
    end

    # Return detective with highest score
    best_detective = argmax(detective_scores)
    return best_detective
end