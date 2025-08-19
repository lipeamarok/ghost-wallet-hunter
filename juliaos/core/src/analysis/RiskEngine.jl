"""
F6 Risk Engine Module - Component-Based Risk Assessment

Implements sophisticated risk scoring using multiple components that replace
the simple average approach. Each component is normalized [0,1] and weighted
to produce a comprehensive risk assessment with full explainability.

No mocks - real deterministic risk assessment following golden rules.
"""

using Statistics
using Dates

"""
Individual risk component with scoring and metadata
"""
struct RiskComponent
    name::String
    score::Float64          # Normalized score [0, 1]
    weight::Float64         # Component weight in final calculation
    confidence::Float64     # Confidence in this component [0, 1]
    evidence::Vector{String} # Supporting evidence for this score
    threshold_breached::Bool # Whether this component exceeded critical threshold
    raw_value::Float64      # Original raw value before normalization
    metadata::Dict{String, Any} # Additional component-specific data
end

"""
Complete risk assessment result
"""
struct RiskAssessment
    final_score::Float64
    risk_level::String      # LOW, MEDIUM, HIGH, CRITICAL
    confidence::Float64
    components::Vector{RiskComponent}
    flagged_activities::Vector{String}
    recommendations::Vector{String}
    assessment_quality::Float64  # Overall quality of assessment [0, 1]
    computation_metadata::Dict{String, Any}
end

"""
Risk scoring configuration with thresholds and weights
"""
struct RiskConfig
    # Component weights (must sum to 1.0)
    weight_taint_proximity::Float64
    weight_convergence::Float64
    weight_control_signals::Float64
    weight_integration_events::Float64
    weight_large_outlier::Float64
    weight_data_quality_penalty::Float64

    # Risk level thresholds
    threshold_medium::Float64
    threshold_high::Float64
    threshold_critical::Float64

    # Component-specific thresholds
    taint_critical_threshold::Float64
    convergence_critical_threshold::Float64
    outlier_critical_threshold::Float64

    # Quality requirements
    min_confidence_threshold::Float64
    min_data_quality_threshold::Float64
end

"""
Default risk configuration with balanced weights
"""
function default_risk_config()::RiskConfig
    return RiskConfig(
        # Weights (sum = 1.0)
        0.30,  # taint_proximity (highest weight - most important)
        0.20,  # convergence (fund concentration patterns)
        0.15,  # control_signals (behavioral patterns)
        0.20,  # integration_events (CEX/bridge interactions)
        0.10,  # large_outlier (transaction size anomalies)
        0.05,  # data_quality_penalty (data reliability)

        # Risk level thresholds
        0.30,  # threshold_medium
        0.60,  # threshold_high
        0.85,  # threshold_critical

        # Component critical thresholds
        0.70,  # taint_critical_threshold
        0.80,  # convergence_critical_threshold
        0.90,  # outlier_critical_threshold

        # Quality requirements
        0.50,  # min_confidence_threshold
        0.70   # min_data_quality_threshold
    )
end

"""
Calculate Taint Proximity component score
"""
function calculate_taint_proximity(taint_analysis::Dict{String, Any}, config::RiskConfig)::RiskComponent
    evidence = String[]
    raw_score = 0.0
    confidence = 0.0

    if haskey(taint_analysis, "enabled") && !get(taint_analysis, "enabled", true)
        return RiskComponent(
            "TaintProximity",
            0.0,
            config.weight_taint_proximity,
            0.0,
            ["Taint analysis disabled or failed"],
            false,
            0.0,
            Dict("status" => "disabled")
        )
    end

    # Extract taint metrics
    taint_share = get(taint_analysis, "taint_share", 0.0)
    hop_distance = get(taint_analysis, "hop_distance", -1)
    max_taint_score = get(taint_analysis, "max_taint_score", 0.0)

    # Calculate base score from taint share (primary factor)
    taint_component = min(1.0, taint_share * 2.0)  # Scale up taint share impact

    # Distance penalty (closer to incident = higher risk)
    distance_component = if hop_distance > 0
        max(0.0, 1.0 - (hop_distance - 1) * 0.2)  # Penalty increases with distance
    else
        0.0  # No taint connection found
    end

    # Maximum individual taint score factor
    max_taint_component = min(1.0, max_taint_score)

    # Combine factors with weights
    raw_score = (taint_component * 0.6 + distance_component * 0.25 + max_taint_component * 0.15)

    # Build evidence
    if taint_share > 0.0
        push!(evidence, "Taint share: $(round(taint_share * 100, digits=2))%")
    end
    if hop_distance > 0
        push!(evidence, "Distance from incident: $(hop_distance) hops")
    end
    if max_taint_score > 0.0
        push!(evidence, "Max taint score: $(round(max_taint_score, digits=3))")
    end

    # Calculate confidence based on data quality
    taint_validation = get(taint_analysis, "validation", Dict())
    data_coverage = get(taint_validation, "coverage_ratio", 0.0)
    computation_quality = get(taint_validation, "computation_quality", 0.0)
    confidence = (data_coverage + computation_quality) / 2.0

    threshold_breached = raw_score > config.taint_critical_threshold

    return RiskComponent(
        "TaintProximity",
        raw_score,
        config.weight_taint_proximity,
        confidence,
        evidence,
        threshold_breached,
        taint_share,
        Dict(
            "hop_distance" => hop_distance,
            "max_taint_score" => max_taint_score,
            "data_coverage" => data_coverage
        )
    )
end

"""
Calculate Convergence component score (fund concentration patterns)
"""
function calculate_convergence(graph_stats::Dict{String, Any}, flow_attribution::Dict{String, Any}, config::RiskConfig)::RiskComponent
    evidence = String[]
    raw_score = 0.0
    confidence = 0.8  # Graph analysis is generally reliable

    # Extract graph metrics
    density = get(graph_stats, "density", 0.0)
    max_fan_out = get(graph_stats, "max_fan_out", 0)
    max_fan_in = get(graph_stats, "max_fan_in", 0)
    total_nodes = get(graph_stats, "nodes", 0)

    # Flow concentration from attribution analysis
    flow_efficiency = 0.0
    sink_concentration = 0.0

    if haskey(flow_attribution, "flow_efficiency")
        flow_efficiency = get(flow_attribution, "flow_efficiency", 0.0)
    end

    if haskey(flow_attribution, "sink_attribution")
        sink_attr = get(flow_attribution, "sink_attribution", Dict())
        if !isempty(sink_attr)
            total_flow = sum(values(sink_attr))
            if total_flow > 0
                # Calculate how concentrated the flow is (Gini-like coefficient)
                sorted_flows = sort(collect(values(sink_attr)), rev=true)
                cumulative = cumsum(sorted_flows)
                sink_concentration = length(sorted_flows) > 1 ? cumulative[1] / total_flow : 0.0
            end
        end
    end

    # Fan-out concentration score
    fan_out_score = 0.0
    if total_nodes > 0
        # High fan-out from few nodes suggests coordinated distribution
        fan_out_ratio = max_fan_out / total_nodes
        fan_out_score = min(1.0, fan_out_ratio * 5.0)  # Scale factor
    end

    # Fan-in concentration score
    fan_in_score = 0.0
    if total_nodes > 0
        # High fan-in to few nodes suggests fund aggregation
        fan_in_ratio = max_fan_in / total_nodes
        fan_in_score = min(1.0, fan_in_ratio * 5.0)  # Scale factor
    end

    # Combine scores
    raw_score = (sink_concentration * 0.4 + fan_out_score * 0.3 + fan_in_score * 0.3)

    # Build evidence
    if sink_concentration > 0.1
        push!(evidence, "Flow concentration: $(round(sink_concentration * 100, digits=1))% to top sink")
    end
    if max_fan_out > 5
        push!(evidence, "High fan-out detected: $(max_fan_out) outputs from single address")
    end
    if max_fan_in > 5
        push!(evidence, "High fan-in detected: $(max_fan_in) inputs to single address")
    end
    if flow_efficiency > 0.8
        push!(evidence, "Efficient flow paths detected ($(round(flow_efficiency * 100, digits=1))%)")
    end

    threshold_breached = raw_score > config.convergence_critical_threshold

    return RiskComponent(
        "Convergence",
        raw_score,
        config.weight_convergence,
        confidence,
        evidence,
        threshold_breached,
        sink_concentration,
        Dict(
            "density" => density,
            "max_fan_out" => max_fan_out,
            "max_fan_in" => max_fan_in,
            "flow_efficiency" => flow_efficiency
        )
    )
end

"""
Calculate Control Signals component score (behavioral patterns)
"""
function calculate_control_signals(entity_analysis::Dict{String, Any}, sample_transactions::Vector{Any}, config::RiskConfig)::RiskComponent
    evidence = String[]
    raw_score = 0.0
    confidence = 0.7

    # Fee payer concentration from entity analysis
    fee_payer_score = 0.0
    if haskey(entity_analysis, "fee_payer_analysis")
        fee_analysis = entity_analysis["fee_payer_analysis"]
        common_payers = get(fee_analysis, "common_fee_payers", 0)
        total_txs = get(fee_analysis, "total_transactions", 1)

        if total_txs > 0
            fee_concentration = common_payers / total_txs
            fee_payer_score = min(1.0, fee_concentration * 2.0)

            if fee_concentration > 0.3
                push!(evidence, "Fee payer concentration: $(round(fee_concentration * 100, digits=1))%")
            end
        end
    end

    # Temporal clustering from transactions
    temporal_score = 0.0
    if length(sample_transactions) > 3
        # Extract timestamps
        timestamps = Float64[]
        for tx in sample_transactions
            if haskey(tx, "block_time") && tx["block_time"] isa Number
                push!(timestamps, Float64(tx["block_time"]))
            end
        end

        if length(timestamps) > 3
            sort!(timestamps)
            # Calculate time gaps between consecutive transactions
            gaps = [timestamps[i+1] - timestamps[i] for i in 1:(length(timestamps)-1)]

            # Look for burst patterns (many transactions in short time)
            short_gaps = count(gap -> gap < 300, gaps)  # < 5 minutes
            burst_ratio = short_gaps / length(gaps)

            temporal_score = min(1.0, burst_ratio * 1.5)

            if burst_ratio > 0.3
                push!(evidence, "Temporal clustering: $(round(burst_ratio * 100, digits=1))% rapid sequences")
            end
        end
    end

    # Program pattern consistency
    program_score = 0.0
    if length(sample_transactions) > 2
        program_counts = Dict{String, Int}()
        for tx in sample_transactions
            if haskey(tx, "programs") && tx["programs"] isa Vector
                for program in tx["programs"]
                    program_str = string(program)
                    program_counts[program_str] = get(program_counts, program_str, 0) + 1
                end
            end
        end

        if !isempty(program_counts)
            total_program_uses = sum(values(program_counts))
            max_program_use = maximum(values(program_counts))
            program_concentration = max_program_use / total_program_uses

            program_score = min(1.0, program_concentration * 1.2)

            if program_concentration > 0.5
                push!(evidence, "Program concentration: $(round(program_concentration * 100, digits=1))% on dominant program")
            end
        end
    end

    # Combine control signal scores
    raw_score = (fee_payer_score * 0.5 + temporal_score * 0.3 + program_score * 0.2)

    return RiskComponent(
        "ControlSignals",
        raw_score,
        config.weight_control_signals,
        confidence,
        evidence,
        false,  # Control signals rarely breach critical threshold alone
        fee_payer_score,  # Use fee payer as primary raw value
        Dict(
            "temporal_score" => temporal_score,
            "program_score" => program_score,
            "fee_payer_concentration" => fee_payer_score
        )
    )
end

"""
Calculate Integration Events component score
"""
function calculate_integration_events(integration_analysis::Dict{String, Any}, config::RiskConfig)::RiskComponent
    evidence = String[]
    raw_score = 0.0
    confidence = 0.8

    if haskey(integration_analysis, "enabled") && !get(integration_analysis, "enabled", true)
        return RiskComponent(
            "IntegrationEvents",
            0.0,
            config.weight_integration_events,
            0.0,
            ["Integration analysis disabled or failed"],
            false,
            0.0,
            Dict("status" => "disabled")
        )
    end

    # Extract integration events
    events = get(integration_analysis, "integration_events", Vector{Any}())
    total_events = length(events)

    if total_events == 0
        return RiskComponent(
            "IntegrationEvents",
            0.0,
            config.weight_integration_events,
            confidence,
            ["No integration events detected"],
            false,
            0.0,
            Dict("total_events" => 0)
        )
    end

    # Analyze event types and risk
    high_risk_events = 0
    medium_risk_events = 0
    total_value = 0.0
    cash_out_events = 0
    bridge_events = 0

    for event in events
        event_type = get(event, "event_type", "")
        risk_score = get(event, "risk_score", 0.0)
        value = get(event, "value_sol", 0.0)

        total_value += value

        if risk_score > 0.7
            high_risk_events += 1
        elseif risk_score > 0.4
            medium_risk_events += 1
        end

        if contains(lowercase(event_type), "cash_out")
            cash_out_events += 1
        elseif contains(lowercase(event_type), "bridge")
            bridge_events += 1
        end
    end

    # Calculate risk score based on events
    risk_event_ratio = (high_risk_events * 2 + medium_risk_events) / (total_events * 2)
    volume_factor = min(1.0, total_value / 1000.0)  # Normalize by 1000 SOL

    raw_score = min(1.0, risk_event_ratio * 0.7 + volume_factor * 0.3)

    # Build evidence
    if high_risk_events > 0
        push!(evidence, "High-risk integration events: $(high_risk_events)")
    end
    if cash_out_events > 0
        push!(evidence, "Cash-out events detected: $(cash_out_events)")
    end
    if bridge_events > 0
        push!(evidence, "Cross-chain bridge events: $(bridge_events)")
    end
    if total_value > 100.0
        push!(evidence, "Total integration volume: $(round(total_value, digits=1)) SOL")
    end

    return RiskComponent(
        "IntegrationEvents",
        raw_score,
        config.weight_integration_events,
        confidence,
        evidence,
        risk_event_ratio > 0.6,  # Threshold for critical events
        total_value,
        Dict(
            "total_events" => total_events,
            "high_risk_events" => high_risk_events,
            "cash_out_events" => cash_out_events,
            "bridge_events" => bridge_events
        )
    )
end

"""
Calculate Large Outlier Transaction component score
"""
function calculate_large_outlier(sample_transactions::Vector{Any}, config::RiskConfig)::RiskComponent
    evidence = String[]
    raw_score = 0.0
    confidence = 0.9  # Transaction analysis is very reliable

    if length(sample_transactions) < 3
        return RiskComponent(
            "LargeOutlierTx",
            0.0,
            config.weight_large_outlier,
            0.5,  # Low confidence due to insufficient data
            ["Insufficient transactions for outlier analysis"],
            false,
            0.0,
            Dict("sample_size" => length(sample_transactions))
        )
    end

    # Extract transaction values
    values = Float64[]
    for tx in sample_transactions
        if haskey(tx, "net_flow") && tx["net_flow"] isa Number
            push!(values, abs(Float64(tx["net_flow"])))
        end
    end

    if length(values) < 3
        return RiskComponent(
            "LargeOutlierTx",
            0.0,
            config.weight_large_outlier,
            0.5,
            ["Insufficient transaction values for analysis"],
            false,
            0.0,
            Dict("valid_values" => length(values))
        )
    end

    # Statistical analysis
    mean_value = mean(values)
    std_value = std(values)
    max_value = maximum(values)

    # Z-score for largest transaction
    z_score = std_value > 0 ? (max_value - mean_value) / std_value : 0.0

    # Outlier score based on z-score
    outlier_score = if z_score > 3.0
        min(1.0, (z_score - 3.0) / 5.0 + 0.5)  # Strong outlier
    elseif z_score > 2.0
        (z_score - 2.0) / 2.0 * 0.5  # Moderate outlier
    else
        0.0  # No significant outlier
    end

    # Absolute size factor (independent of distribution)
    size_factor = min(1.0, max_value / 10000.0)  # Normalize by 10,000 SOL

    # Combine factors
    raw_score = max(outlier_score, size_factor * 0.8)

    # Build evidence
    if z_score > 2.0
        push!(evidence, "Statistical outlier: z-score $(round(z_score, digits=1))")
    end
    if max_value > 1000.0
        push!(evidence, "Large transaction: $(round(max_value, digits=1)) SOL")
    end
    if max_value > mean_value * 10
        push!(evidence, "Transaction $(round(max_value/mean_value, digits=1))x larger than average")
    end

    threshold_breached = raw_score > config.outlier_critical_threshold

    return RiskComponent(
        "LargeOutlierTx",
        raw_score,
        config.weight_large_outlier,
        confidence,
        evidence,
        threshold_breached,
        max_value,
        Dict(
            "z_score" => z_score,
            "mean_value" => mean_value,
            "std_value" => std_value,
            "size_factor" => size_factor
        )
    )
end

"""
Calculate Data Quality Penalty component
"""
function calculate_data_quality_penalty(data_quality::Dict{String, Any}, rpc_metrics::Dict{String, Any}, config::RiskConfig)::RiskComponent
    evidence = String[]
    penalty_score = 0.0  # Higher = worse quality = higher penalty
    confidence = 1.0  # Data quality assessment is always reliable

    # Timestamp quality
    timestamp_penalty = 0.0
    if haskey(data_quality, "timestamp_ok")
        if !get(data_quality, "timestamp_ok", true)
            timestamp_penalty = 0.3
            push!(evidence, "Timestamp validation failed")
        end
    end

    # Delta consistency
    delta_penalty = 0.0
    if haskey(data_quality, "delta_ok")
        if !get(data_quality, "delta_ok", true)
            delta_penalty = 0.2
            push!(evidence, "Balance delta inconsistencies detected")
        end
    end

    # RPC reliability
    rpc_penalty = 0.0
    if haskey(rpc_metrics, "fallback_count")
        fallback_count = get(rpc_metrics, "fallback_count", 0)
        total_attempts = get(rpc_metrics, "total_attempts", 1)

        if fallback_count > 0
            fallback_ratio = fallback_count / total_attempts
            rpc_penalty = min(0.3, fallback_ratio * 0.5)

            if fallback_ratio > 0.1
                push!(evidence, "RPC fallbacks: $(round(fallback_ratio * 100, digits=1))% of requests")
            end
        end
    end

    # Parse quality
    parse_penalty = 0.0
    if haskey(data_quality, "parse_success_rate")
        parse_rate = get(data_quality, "parse_success_rate", 1.0)
        if parse_rate < 0.9
            parse_penalty = (1.0 - parse_rate) * 0.4
            push!(evidence, "Parse success rate: $(round(parse_rate * 100, digits=1))%")
        end
    end

    # Total penalty (inverted to penalty score)
    total_penalty = timestamp_penalty + delta_penalty + rpc_penalty + parse_penalty
    penalty_score = min(1.0, total_penalty)

    if isempty(evidence)
        push!(evidence, "Data quality checks passed")
    end

    return RiskComponent(
        "DataQualityPenalty",
        penalty_score,
        config.weight_data_quality_penalty,
        confidence,
        evidence,
        penalty_score > 0.5,  # High penalty is critical
        total_penalty,
        Dict(
            "timestamp_penalty" => timestamp_penalty,
            "delta_penalty" => delta_penalty,
            "rpc_penalty" => rpc_penalty,
            "parse_penalty" => parse_penalty
        )
    )
end

"""
Main risk assessment function
"""
function assess_wallet_risk(
    taint_analysis::Dict{String, Any},
    graph_stats::Dict{String, Any},
    entity_analysis::Dict{String, Any},
    integration_analysis::Dict{String, Any},
    flow_attribution::Dict{String, Any},
    sample_transactions::Vector{Any},
    data_quality::Dict{String, Any},
    rpc_metrics::Dict{String, Any};
    config::RiskConfig = default_risk_config()
)::Dict{String, Any}

    start_time = time()

    try
        # Calculate all risk components
        components = Vector{RiskComponent}()

        # 1. Taint Proximity
        push!(components, calculate_taint_proximity(taint_analysis, config))

        # 2. Convergence (fund concentration)
        push!(components, calculate_convergence(graph_stats, flow_attribution, config))

        # 3. Control Signals (behavioral patterns)
        push!(components, calculate_control_signals(entity_analysis, sample_transactions, config))

        # 4. Integration Events
        push!(components, calculate_integration_events(integration_analysis, config))

        # 5. Large Outlier Transactions
        push!(components, calculate_large_outlier(sample_transactions, config))

        # 6. Data Quality Penalty
        push!(components, calculate_data_quality_penalty(data_quality, rpc_metrics, config))

        # Calculate weighted final score
        final_score = 0.0
        total_weight = 0.0
        total_confidence = 0.0

        for component in components
            final_score += component.score * component.weight
            total_weight += component.weight
            total_confidence += component.confidence * component.weight
        end

        # Normalize in case weights don't sum to exactly 1.0
        if total_weight > 0
            final_score = final_score / total_weight
            total_confidence = total_confidence / total_weight
        end

        # Determine risk level
        risk_level = if final_score >= config.threshold_critical
            "CRITICAL"
        elseif final_score >= config.threshold_high
            "HIGH"
        elseif final_score >= config.threshold_medium
            "MEDIUM"
        else
            "LOW"
        end

        # Generate flagged activities
        flagged_activities = String[]
        for component in components
            if component.threshold_breached
                push!(flagged_activities, "$(component.name): Critical threshold breached")
            end
            for evidence in component.evidence
                if contains(lowercase(evidence), "risk") || contains(lowercase(evidence), "critical")
                    push!(flagged_activities, "$(component.name): $(evidence)")
                end
            end
        end

        # Generate recommendations
        recommendations = String[]
        if final_score > config.threshold_high
            push!(recommendations, "Immediate investigation recommended due to high risk score")
        end
        if any(c -> c.name == "TaintProximity" && c.score > 0.5, components)
            push!(recommendations, "Investigate connection to known security incidents")
        end
        if any(c -> c.name == "IntegrationEvents" && c.score > 0.4, components)
            push!(recommendations, "Monitor CEX deposits and bridge transfers")
        end
        if any(c -> c.name == "Convergence" && c.score > 0.6, components)
            push!(recommendations, "Analyze fund concentration patterns for coordination")
        end
        if total_confidence < config.min_confidence_threshold
            push!(recommendations, "Increase data collection for more reliable assessment")
        end

        # Calculate assessment quality
        data_quality_score = 1.0 - components[findfirst(c -> c.name == "DataQualityPenalty", components)].score
        assessment_quality = (total_confidence * 0.7 + data_quality_score * 0.3)

        return Dict{String, Any}(
            "final_score" => final_score,
            "risk_level" => risk_level,
            "confidence" => total_confidence,
            "assessment_quality" => assessment_quality,
            "components" => [
                Dict{String, Any}(
                    "name" => c.name,
                    "score" => c.score,
                    "weight" => c.weight,
                    "confidence" => c.confidence,
                    "evidence" => c.evidence,
                    "threshold_breached" => c.threshold_breached,
                    "raw_value" => c.raw_value,
                    "metadata" => c.metadata
                ) for c in components
            ],
            "flagged_activities" => flagged_activities,
            "recommendations" => recommendations,
            "computation_time_s" => time() - start_time,
            "config_version" => "v1.0",
            "component_count" => length(components)
        )

    catch e
        return Dict{String, Any}(
            "final_score" => 0.0,
            "risk_level" => "UNKNOWN",
            "confidence" => 0.0,
            "assessment_quality" => 0.0,
            "components" => [],
            "flagged_activities" => [],
            "recommendations" => ["Risk assessment failed - manual review required"],
            "computation_time_s" => time() - start_time,
            "error" => "Risk assessment failed: $(string(e))"
        )
    end
end
