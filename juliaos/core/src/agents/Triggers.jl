module Triggers

using ..CommonTypes: TriggerType, CommonTypes, WebhookTriggerParams, PeriodicTriggerParams, TriggerParams
using ..AgentCore: InvestigationTask, DetectiveMemory
using Dates

export trigger_name_to_enum, process_trigger_params, should_trigger_investigation,
       create_investigation_trigger, check_wallet_risk_trigger

function trigger_name_to_enum(trigger_name::String)::TriggerType
    if trigger_name == "periodic"
        return CommonTypes.PERIODIC_TRIGGER
    elseif trigger_name == "webhook"
        return CommonTypes.WEBHOOK_TRIGGER
    else
        error("Unknown trigger type: $trigger_name")
    end
end

function process_trigger_params(trigger_type::TriggerType, params::Union{Dict{String, Any}, Nothing})::TriggerParams
    if params === nothing
        params = Dict{String, Any}()
    end
    if trigger_type == CommonTypes.PERIODIC_TRIGGER
        interval = get(params, "interval")  # Default to 60 seconds if not provided
        return PeriodicTriggerParams(interval)
    elseif trigger_type == CommonTypes.WEBHOOK_TRIGGER
        return WebhookTriggerParams()
    else
        error("Unsupported trigger type: $trigger_type")
    end
end

# ----------------------------------------------------------------------
# DETECTIVE-SPECIFIC TRIGGER FUNCTIONS
# ----------------------------------------------------------------------

"""
    should_trigger_investigation(memory::DetectiveMemory, trigger_params::Dict{String, Any}) -> Bool

Determines if an investigation should be triggered based on detective memory and parameters.
"""
function should_trigger_investigation(memory::DetectiveMemory, trigger_params::Dict{String, Any})
    # Check time-based triggers
    if haskey(trigger_params, "min_time_between_investigations")
        min_interval = trigger_params["min_time_between_investigations"]  # in seconds
        if memory.last_investigation !== nothing
            time_since_last = (now() - memory.last_investigation).value / 1000  # convert to seconds
            if time_since_last < min_interval
                return false
            end
        end
    end

    # Check pattern-based triggers
    if haskey(trigger_params, "pattern_threshold")
        threshold = trigger_params["pattern_threshold"]
        cached_patterns = length(memory.pattern_cache)
        if cached_patterns < threshold
            return false
        end
    end

    # Check investigation history triggers
    if haskey(trigger_params, "max_investigations_per_hour")
        max_per_hour = trigger_params["max_investigations_per_hour"]
        one_hour_ago = now() - Hour(1)
        recent_investigations = count(inv -> inv.created_at >= one_hour_ago, memory.investigation_history)
        if recent_investigations >= max_per_hour
            return false
        end
    end

    # Check wallet address cooldown
    if haskey(trigger_params, "wallet_address") && haskey(trigger_params, "wallet_cooldown_hours")
        wallet_address = trigger_params["wallet_address"]
        cooldown_hours = trigger_params["wallet_cooldown_hours"]
        cooldown_time = now() - Hour(cooldown_hours)

        # Check if this wallet was investigated recently
        recent_wallet_investigation = any(inv ->
            inv.wallet_address == wallet_address && inv.created_at >= cooldown_time,
            memory.investigation_history
        )

        if recent_wallet_investigation
            return false
        end
    end

    return true
end

"""
    create_investigation_trigger(investigation_type::String, priority::Int=1) -> Dict{String, Any}

Creates trigger parameters for different types of investigations.
"""
function create_investigation_trigger(investigation_type::String, priority::Int=1)
    base_trigger = Dict{String, Any}(
        "investigation_type" => investigation_type,
        "priority" => priority,
        "created_at" => string(now())
    )

    if investigation_type == "routine_scan"
        merge!(base_trigger, Dict{String, Any}(
            "min_time_between_investigations" => 3600,  # 1 hour
            "max_investigations_per_hour" => 5,
            "wallet_cooldown_hours" => 24
        ))
    elseif investigation_type == "high_priority_alert"
        merge!(base_trigger, Dict{String, Any}(
            "min_time_between_investigations" => 300,   # 5 minutes
            "max_investigations_per_hour" => 20,
            "wallet_cooldown_hours" => 1
        ))
    elseif investigation_type == "deep_analysis"
        merge!(base_trigger, Dict{String, Any}(
            "min_time_between_investigations" => 7200,  # 2 hours
            "max_investigations_per_hour" => 2,
            "wallet_cooldown_hours" => 72,
            "pattern_threshold" => 5
        ))
    elseif investigation_type == "real_time_monitoring"
        merge!(base_trigger, Dict{String, Any}(
            "min_time_between_investigations" => 60,    # 1 minute
            "max_investigations_per_hour" => 30,
            "wallet_cooldown_hours" => 0.5
        ))
    end

    return base_trigger
end

"""
    check_wallet_risk_trigger(wallet_address::String, risk_indicators::Vector{String}) -> Dict{String, Any}

Checks if a wallet should trigger an investigation based on risk indicators.
"""
function check_wallet_risk_trigger(wallet_address::String, risk_indicators::Vector{String})
    trigger_result = Dict{String, Any}(
        "should_trigger" => false,
        "trigger_reason" => "",
        "investigation_type" => "routine_scan",
        "priority" => 1,
        "wallet_address" => wallet_address,
        "risk_indicators" => risk_indicators
    )

    high_risk_indicators = [
        "high_frequency_small_transactions",
        "circular_transaction_patterns",
        "cross_chain_obfuscation",
        "privacy_coin_mixing",
        "known_malicious_address"
    ]

    medium_risk_indicators = [
        "unusual_gas_patterns",
        "temporal_clustering",
        "layered_transactions",
        "new_address_high_activity"
    ]

    # Count risk indicators
    high_risk_count = count(indicator -> indicator in high_risk_indicators, risk_indicators)
    medium_risk_count = count(indicator -> indicator in medium_risk_indicators, risk_indicators)

    # Determine trigger based on risk level
    if high_risk_count >= 2
        trigger_result["should_trigger"] = true
        trigger_result["trigger_reason"] = "Multiple high-risk indicators detected"
        trigger_result["investigation_type"] = "high_priority_alert"
        trigger_result["priority"] = 3
    elseif high_risk_count >= 1 && medium_risk_count >= 1
        trigger_result["should_trigger"] = true
        trigger_result["trigger_reason"] = "High-risk and medium-risk indicators combination"
        trigger_result["investigation_type"] = "high_priority_alert"
        trigger_result["priority"] = 2
    elseif high_risk_count >= 1
        trigger_result["should_trigger"] = true
        trigger_result["trigger_reason"] = "High-risk indicator detected"
        trigger_result["investigation_type"] = "routine_scan"
        trigger_result["priority"] = 2
    elseif medium_risk_count >= 3
        trigger_result["should_trigger"] = true
        trigger_result["trigger_reason"] = "Multiple medium-risk indicators"
        trigger_result["investigation_type"] = "routine_scan"
        trigger_result["priority"] = 1
    elseif length(risk_indicators) >= 5
        trigger_result["should_trigger"] = true
        trigger_result["trigger_reason"] = "High number of risk indicators"
        trigger_result["investigation_type"] = "routine_scan"
        trigger_result["priority"] = 1
    end

    return trigger_result
end

"""
    create_periodic_investigation_trigger(interval_hours::Int, detective_type::String="any") -> Dict{String, Any}

Creates a periodic trigger for regular investigations.
"""
function create_periodic_investigation_trigger(interval_hours::Int, detective_type::String="any")
    return Dict{String, Any}(
        "trigger_type" => "periodic",
        "interval_hours" => interval_hours,
        "detective_type" => detective_type,
        "investigation_type" => "routine_scan",
        "next_trigger" => string(now() + Hour(interval_hours)),
        "created_at" => string(now())
    )
end

"""
    evaluate_investigation_triggers(memory::DetectiveMemory, available_triggers::Vector{Dict{String, Any}}) -> Vector{Dict{String, Any}}

Evaluates multiple triggers and returns those that should be activated.
"""
function evaluate_investigation_triggers(memory::DetectiveMemory, available_triggers::Vector{Dict{String, Any}})
    active_triggers = Vector{Dict{String, Any}}()

    for trigger in available_triggers
        if should_trigger_investigation(memory, trigger)
            # Add timestamp when trigger was activated
            trigger_copy = copy(trigger)
            trigger_copy["triggered_at"] = string(now())
            push!(active_triggers, trigger_copy)
        end
    end

    # Sort by priority (higher priority first)
    sort!(active_triggers, by=t -> get(t, "priority", 1), rev=true)

    return active_triggers
end

end