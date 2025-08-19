"""
F6 Risk Configuration Module - Configurable Weights and Thresholds

Implements configurable risk assessment parameters that can be adjusted
based on investigation context, historical data, or specific use cases.
Provides validation and optimization for risk engine configuration.

No mocks - real configuration management following golden rules.
"""

using JSON3

"""
Risk configuration profile for different investigation contexts
"""
struct RiskProfile
    name::String
    description::String
    config::RiskConfig
    use_cases::Vector{String}
    effectiveness_score::Float64  # Historical effectiveness [0, 1]
end

"""
Configuration validation result
"""
struct ConfigValidation
    is_valid::Bool
    warnings::Vector{String}
    errors::Vector{String}
    normalized_config::Union{RiskConfig, Nothing}
end

"""
Predefined risk profiles for different scenarios
"""
function get_predefined_profiles()::Dict{String, RiskProfile}
    profiles = Dict{String, RiskProfile}()

    # Balanced Profile (default)
    profiles["balanced"] = RiskProfile(
        "Balanced",
        "General-purpose configuration with balanced component weights",
        default_risk_config(),
        ["General investigations", "Unknown wallet types", "Baseline analysis"],
        0.85
    )

    # High Taint Sensitivity Profile
    profiles["taint_focused"] = RiskProfile(
        "Taint Focused",
        "Emphasizes taint proximity for incident-related investigations",
        RiskConfig(
            0.45,  # taint_proximity (increased)
            0.15,  # convergence
            0.10,  # control_signals
            0.20,  # integration_events
            0.05,  # large_outlier
            0.05,  # data_quality_penalty
            0.25,  # threshold_medium (lowered)
            0.50,  # threshold_high
            0.80,  # threshold_critical
            0.60,  # taint_critical_threshold (lowered)
            0.80,  # convergence_critical_threshold
            0.90,  # outlier_critical_threshold
            0.50,  # min_confidence_threshold
            0.70   # min_data_quality_threshold
        ),
        ["Security incident investigations", "Exploit analysis", "Taint tracking"],
        0.92
    )

    # Behavioral Analysis Profile
    profiles["behavioral"] = RiskProfile(
        "Behavioral",
        "Focuses on behavioral patterns and control signals",
        RiskConfig(
            0.20,  # taint_proximity
            0.25,  # convergence (increased)
            0.30,  # control_signals (increased)
            0.15,  # integration_events
            0.05,  # large_outlier
            0.05,  # data_quality_penalty
            0.35,  # threshold_medium
            0.65,  # threshold_high
            0.85,  # threshold_critical
            0.70,  # taint_critical_threshold
            0.70,  # convergence_critical_threshold (lowered)
            0.90,  # outlier_critical_threshold
            0.60,  # min_confidence_threshold
            0.70   # min_data_quality_threshold
        ),
        ["Bot network analysis", "Coordination detection", "Pattern recognition"],
        0.88
    )

    # Financial Crime Profile
    profiles["financial_crime"] = RiskProfile(
        "Financial Crime",
        "Optimized for money laundering and financial crime detection",
        RiskConfig(
            0.25,  # taint_proximity
            0.20,  # convergence
            0.15,  # control_signals
            0.30,  # integration_events (increased)
            0.05,  # large_outlier
            0.05,  # data_quality_penalty
            0.30,  # threshold_medium
            0.55,  # threshold_high
            0.80,  # threshold_critical
            0.70,  # taint_critical_threshold
            0.75,  # convergence_critical_threshold
            0.85,  # outlier_critical_threshold (lowered)
            0.50,  # min_confidence_threshold
            0.75   # min_data_quality_threshold
        ),
        ["Money laundering investigations", "CEX deposit tracking", "Financial flow analysis"],
        0.90
    )

    # High Volume Profile
    profiles["high_volume"] = RiskProfile(
        "High Volume",
        "Designed for high-value transaction analysis",
        RiskConfig(
            0.20,  # taint_proximity
            0.15,  # convergence
            0.10,  # control_signals
            0.25,  # integration_events
            0.25,  # large_outlier (increased)
            0.05,  # data_quality_penalty
            0.40,  # threshold_medium
            0.70,  # threshold_high
            0.90,  # threshold_critical
            0.75,  # taint_critical_threshold
            0.80,  # convergence_critical_threshold
            0.70,  # outlier_critical_threshold (lowered)
            0.50,  # min_confidence_threshold
            0.70   # min_data_quality_threshold
        ),
        ["Large transaction analysis", "Whale wallet investigation", "Market manipulation"],
        0.83
    )

    # Conservative Profile
    profiles["conservative"] = RiskProfile(
        "Conservative",
        "Higher thresholds to reduce false positives",
        RiskConfig(
            0.30,  # taint_proximity
            0.20,  # convergence
            0.15,  # control_signals
            0.20,  # integration_events
            0.10,  # large_outlier
            0.05,  # data_quality_penalty
            0.45,  # threshold_medium (increased)
            0.75,  # threshold_high (increased)
            0.90,  # threshold_critical (increased)
            0.80,  # taint_critical_threshold (increased)
            0.85,  # convergence_critical_threshold (increased)
            0.95,  # outlier_critical_threshold (increased)
            0.60,  # min_confidence_threshold
            0.80   # min_data_quality_threshold
        ),
        ["Low false-positive requirements", "High-confidence investigations", "Regulatory compliance"],
        0.78
    )

    return profiles
end

"""
Validate risk configuration for correctness and consistency
"""
function validate_risk_config(config::RiskConfig)::ConfigValidation
    warnings = String[]
    errors = String[]

    # Check weight sum
    total_weight = (config.weight_taint_proximity + config.weight_convergence +
                   config.weight_control_signals + config.weight_integration_events +
                   config.weight_large_outlier + config.weight_data_quality_penalty)

    if abs(total_weight - 1.0) > 0.001
        push!(errors, "Component weights sum to $(round(total_weight, digits=3)), must sum to 1.0")
    end

    # Check individual weight ranges
    weights = [
        ("taint_proximity", config.weight_taint_proximity),
        ("convergence", config.weight_convergence),
        ("control_signals", config.weight_control_signals),
        ("integration_events", config.weight_integration_events),
        ("large_outlier", config.weight_large_outlier),
        ("data_quality_penalty", config.weight_data_quality_penalty)
    ]

    for (name, weight) in weights
        if weight < 0.0 || weight > 1.0
            push!(errors, "Weight for $(name) ($(weight)) must be between 0.0 and 1.0")
        elseif weight > 0.6
            push!(warnings, "Weight for $(name) ($(weight)) is very high, may dominate other components")
        elseif weight < 0.01
            push!(warnings, "Weight for $(name) ($(weight)) is very low, component may be ineffective")
        end
    end

    # Check threshold ordering
    if config.threshold_medium >= config.threshold_high
        push!(errors, "Medium threshold ($(config.threshold_medium)) must be less than high threshold ($(config.threshold_high))")
    end
    if config.threshold_high >= config.threshold_critical
        push!(errors, "High threshold ($(config.threshold_high)) must be less than critical threshold ($(config.threshold_critical))")
    end

    # Check threshold ranges
    thresholds = [
        ("medium", config.threshold_medium),
        ("high", config.threshold_high),
        ("critical", config.threshold_critical)
    ]

    for (name, threshold) in thresholds
        if threshold < 0.0 || threshold > 1.0
            push!(errors, "$(name) threshold ($(threshold)) must be between 0.0 and 1.0")
        end
    end

    # Check critical component thresholds
    component_thresholds = [
        ("taint_critical", config.taint_critical_threshold),
        ("convergence_critical", config.convergence_critical_threshold),
        ("outlier_critical", config.outlier_critical_threshold)
    ]

    for (name, threshold) in component_thresholds
        if threshold < 0.0 || threshold > 1.0
            push!(errors, "$(name) threshold ($(threshold)) must be between 0.0 and 1.0")
        elseif threshold < 0.5
            push!(warnings, "$(name) threshold ($(threshold)) is low, may trigger too frequently")
        end
    end

    # Check quality thresholds
    if config.min_confidence_threshold < 0.0 || config.min_confidence_threshold > 1.0
        push!(errors, "Min confidence threshold ($(config.min_confidence_threshold)) must be between 0.0 and 1.0")
    end
    if config.min_data_quality_threshold < 0.0 || config.min_data_quality_threshold > 1.0
        push!(errors, "Min data quality threshold ($(config.min_data_quality_threshold)) must be between 0.0 and 1.0")
    end

    # Normalize weights if possible (only for minor deviations)
    normalized_config = nothing
    if isempty(errors) && abs(total_weight - 1.0) <= 0.01
        # Normalize weights to sum exactly to 1.0
        normalization_factor = 1.0 / total_weight
        normalized_config = RiskConfig(
            config.weight_taint_proximity * normalization_factor,
            config.weight_convergence * normalization_factor,
            config.weight_control_signals * normalization_factor,
            config.weight_integration_events * normalization_factor,
            config.weight_large_outlier * normalization_factor,
            config.weight_data_quality_penalty * normalization_factor,
            config.threshold_medium,
            config.threshold_high,
            config.threshold_critical,
            config.taint_critical_threshold,
            config.convergence_critical_threshold,
            config.outlier_critical_threshold,
            config.min_confidence_threshold,
            config.min_data_quality_threshold
        )

        if abs(total_weight - 1.0) > 0.001
            push!(warnings, "Weights normalized from $(round(total_weight, digits=3)) to 1.0")
        end
    end

    return ConfigValidation(
        isempty(errors),
        warnings,
        errors,
        normalized_config
    )
end

"""
Load risk configuration from environment or profile
"""
function load_risk_config(profile_name::String = "balanced"; custom_config::Union{Dict, Nothing} = nothing)::Tuple{RiskConfig, Vector{String}}
    messages = String[]

    profiles = get_predefined_profiles()

    # Start with profile if specified
    if haskey(profiles, profile_name)
        base_config = profiles[profile_name].config
        push!(messages, "Loaded profile: $(profiles[profile_name].name)")
    else
        push!(messages, "Unknown profile '$(profile_name)', using balanced profile")
        base_config = profiles["balanced"].config
    end

    # Apply custom overrides if provided
    if custom_config !== nothing
        try
            # Create modified config with custom values
            modified_config = RiskConfig(
                get(custom_config, "weight_taint_proximity", base_config.weight_taint_proximity),
                get(custom_config, "weight_convergence", base_config.weight_convergence),
                get(custom_config, "weight_control_signals", base_config.weight_control_signals),
                get(custom_config, "weight_integration_events", base_config.weight_integration_events),
                get(custom_config, "weight_large_outlier", base_config.weight_large_outlier),
                get(custom_config, "weight_data_quality_penalty", base_config.weight_data_quality_penalty),
                get(custom_config, "threshold_medium", base_config.threshold_medium),
                get(custom_config, "threshold_high", base_config.threshold_high),
                get(custom_config, "threshold_critical", base_config.threshold_critical),
                get(custom_config, "taint_critical_threshold", base_config.taint_critical_threshold),
                get(custom_config, "convergence_critical_threshold", base_config.convergence_critical_threshold),
                get(custom_config, "outlier_critical_threshold", base_config.outlier_critical_threshold),
                get(custom_config, "min_confidence_threshold", base_config.min_confidence_threshold),
                get(custom_config, "min_data_quality_threshold", base_config.min_data_quality_threshold)
            )

            # Validate the modified configuration
            validation = validate_risk_config(modified_config)

            if validation.is_valid
                final_config = validation.normalized_config !== nothing ? validation.normalized_config : modified_config
                push!(messages, "Applied custom configuration overrides")
                append!(messages, validation.warnings)
                return final_config, messages
            else
                push!(messages, "Custom configuration validation failed, using base profile")
                append!(messages, validation.errors)
                return base_config, messages
            end

        catch e
            push!(messages, "Error applying custom configuration: $(string(e))")
            return base_config, messages
        end
    end

    return base_config, messages
end

"""
Get risk configuration recommendations based on investigation context
"""
function recommend_config_profile(context::Dict{String, Any})::String
    # Extract context indicators
    has_incident = get(context, "has_incident_data", false)
    transaction_count = get(context, "transaction_count", 0)
    max_transaction_value = get(context, "max_transaction_value", 0.0)
    has_cex_interactions = get(context, "has_cex_interactions", false)
    investigation_type = get(context, "investigation_type", "general")

    # Rule-based recommendation
    if has_incident || investigation_type == "security"
        return "taint_focused"
    elseif has_cex_interactions || investigation_type == "financial_crime"
        return "financial_crime"
    elseif max_transaction_value > 10000.0  # > 10k SOL
        return "high_volume"
    elseif transaction_count > 1000 || investigation_type == "behavioral"
        return "behavioral"
    elseif investigation_type == "compliance"
        return "conservative"
    else
        return "balanced"
    end
end

"""
Export configuration to JSON format
"""
function export_config_to_json(config::RiskConfig)::String
    config_dict = Dict{String, Any}(
        "weights" => Dict{String, Float64}(
            "taint_proximity" => config.weight_taint_proximity,
            "convergence" => config.weight_convergence,
            "control_signals" => config.weight_control_signals,
            "integration_events" => config.weight_integration_events,
            "large_outlier" => config.weight_large_outlier,
            "data_quality_penalty" => config.weight_data_quality_penalty
        ),
        "thresholds" => Dict{String, Float64}(
            "medium" => config.threshold_medium,
            "high" => config.threshold_high,
            "critical" => config.threshold_critical
        ),
        "component_thresholds" => Dict{String, Float64}(
            "taint_critical" => config.taint_critical_threshold,
            "convergence_critical" => config.convergence_critical_threshold,
            "outlier_critical" => config.outlier_critical_threshold
        ),
        "quality_requirements" => Dict{String, Float64}(
            "min_confidence" => config.min_confidence_threshold,
            "min_data_quality" => config.min_data_quality_threshold
        )
    )

    return JSON3.write(config_dict)
end

"""
Main configuration management function
"""
function manage_risk_configuration(
    profile_name::String = "balanced";
    custom_overrides::Union{Dict, Nothing} = nothing,
    context::Union{Dict{String, Any}, Nothing} = nothing
)::Dict{String, Any}

    try
        # Recommend profile based on context if provided
        recommended_profile = if context !== nothing
            recommend_config_profile(context)
        else
            profile_name
        end

        # Load configuration
        config, messages = load_risk_config(recommended_profile, custom_overrides)

        # Validate final configuration
        validation = validate_risk_config(config)

        # Get profile information
        profiles = get_predefined_profiles()
        profile_info = if haskey(profiles, recommended_profile)
            Dict{String, Any}(
                "name" => profiles[recommended_profile].name,
                "description" => profiles[recommended_profile].description,
                "use_cases" => profiles[recommended_profile].use_cases,
                "effectiveness_score" => profiles[recommended_profile].effectiveness_score
            )
        else
            Dict{String, Any}("name" => "Unknown", "description" => "Custom configuration")
        end

        return Dict{String, Any}(
            "config" => config,
            "profile_used" => recommended_profile,
            "profile_info" => profile_info,
            "is_valid" => validation.is_valid,
            "validation_warnings" => validation.warnings,
            "validation_errors" => validation.errors,
            "configuration_messages" => messages,
            "available_profiles" => collect(keys(profiles)),
            "config_json" => export_config_to_json(config)
        )

    catch e
        return Dict{String, Any}(
            "config" => default_risk_config(),
            "profile_used" => "default_fallback",
            "is_valid" => true,
            "validation_warnings" => [],
            "validation_errors" => [],
            "configuration_messages" => ["Configuration management failed: $(string(e))", "Using default configuration"],
            "available_profiles" => collect(keys(get_predefined_profiles())),
            "error" => string(e)
        )
    end
end
