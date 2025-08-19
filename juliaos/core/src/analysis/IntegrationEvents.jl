"""
IntegrationEvents.jl - F3 Integration Event Detection

Detects and analyzes integration events such as:
- Cash-out events (tainted funds entering CEX/bridges)
- Cross-chain bridge operations
- Large value DEX interactions
- Suspicious integration patterns
- Real event detection without mocks following golden rules
"""

# Dependencies are made available by the parent Analysis module

# Integration event structures
struct IntegrationEvent
    event_id::String
    event_type::String              # "cash_out", "bridge_operation", "dex_interaction", "suspicious_pattern"
    timestamp::Int                  # Block timestamp
    slot::Union{Nothing,Int}        # Block slot
    addresses::Vector{String}       # Addresses involved
    service_info::Union{Nothing,ServiceEndpoint}  # Integration service details
    transaction_signature::String  # Transaction hash
    value::Float64                 # SOL amount
    metadata::Dict{String,Any}     # Event-specific data
    risk_score::Float64            # Event risk score [0,1]
    taint_involvement::Union{Nothing,TaintResult}  # Taint data if applicable
end

struct EventDetectionConfig
    min_cash_out_value::Float64     # Minimum SOL for cash-out detection
    min_taint_threshold::Float64    # Minimum taint to flag as suspicious
    max_time_window_hours::Int      # Time window for event clustering
    enable_bridge_detection::Bool   # Detect cross-chain operations
    enable_dex_monitoring::Bool     # Monitor large DEX trades
    suspicious_velocity_threshold::Float64  # SOL/hour for velocity flagging
end

const DEFAULT_EVENT_CONFIG = EventDetectionConfig(10.0, 0.1, 24, true, true, 100.0)

"""
    detect_cash_out_events(graph::TxGraph, taint_results::Dict{String,TaintResult}, catalog_config::CatalogConfig=DEFAULT_CATALOG_CONFIG)

Detect cash-out events where tainted funds flow into CEX addresses.
"""
function detect_cash_out_events(graph::TxGraph, taint_results::Dict{String,TaintResult}, catalog_config::CatalogConfig=DEFAULT_CATALOG_CONFIG)
    events = IntegrationEvent[]

    # Get CEX services from catalog
    cex_services = get_services_by_type("cex", catalog_config)
    cex_addresses = Set(service.address for service in cex_services)

    event_id = 1

    for edge in graph.edges
        # Check if transaction involves CEX
        if edge.to in cex_addresses && edge.value >= DEFAULT_EVENT_CONFIG.min_cash_out_value
            # Check if source address has taint
            taint_result = get(taint_results, edge.from, nothing)

            if taint_result !== nothing && taint_result.taint_share >= DEFAULT_EVENT_CONFIG.min_taint_threshold
                # Find the service info
                service_info = lookup_service(edge.to, catalog_config)

                # Calculate risk score based on taint and value
                risk_score = min(1.0, (taint_result.taint_share * 0.7) + (min(edge.value / 1000.0, 1.0) * 0.3))

                event = IntegrationEvent(
                    "cash_out_$(event_id)",
                    "cash_out",
                    edge.block_time === nothing ? 0 : edge.block_time,
                    edge.slot,
                    [edge.from, edge.to],
                    service_info,
                    edge.tx_signature,
                    edge.value,
                    Dict{String,Any}(
                        "cex_name" => service_info === nothing ? "Unknown" : service_info.service_name,
                        "taint_incident" => taint_result.incident_id,
                        "hop_distance" => taint_result.hop_distance,
                        "cash_out_percentage" => taint_result.taint_share
                    ),
                    risk_score,
                    taint_result
                )

                push!(events, event)
                event_id += 1
            end
        end
    end

    return events
end

"""
    detect_bridge_operations(graph::TxGraph, catalog_config::CatalogConfig=DEFAULT_CATALOG_CONFIG)

Detect cross-chain bridge operations that could indicate fund movement.
"""
function detect_bridge_operations(graph::TxGraph, catalog_config::CatalogConfig=DEFAULT_CATALOG_CONFIG)
    events = IntegrationEvent[]

    if !DEFAULT_EVENT_CONFIG.enable_bridge_detection
        return events
    end

    # Get bridge services from catalog
    bridge_services = get_services_by_type("bridge", catalog_config)
    bridge_addresses = Set(service.address for service in bridge_services)

    event_id = 1

    for edge in graph.edges
        # Check if transaction involves bridge
        if (edge.to in bridge_addresses || edge.from in bridge_addresses) && edge.value >= 1.0  # Minimum 1 SOL for bridge ops
            service_address = edge.to in bridge_addresses ? edge.to : edge.from
            service_info = lookup_service(service_address, catalog_config)

            # Bridge operations typically have higher base risk
            risk_score = min(1.0, 0.4 + (min(edge.value / 500.0, 1.0) * 0.4))

            event = IntegrationEvent(
                "bridge_op_$(event_id)",
                "bridge_operation",
                edge.block_time === nothing ? 0 : edge.block_time,
                edge.slot,
                [edge.from, edge.to],
                service_info,
                edge.tx_signature,
                edge.value,
                Dict{String,Any}(
                    "bridge_name" => service_info === nothing ? "Unknown" : service_info.service_name,
                    "direction" => edge.to in bridge_addresses ? "to_bridge" : "from_bridge",
                    "potential_chains" => service_info === nothing ? [] : get(service_info.metadata, "supported_chains", [])
                ),
                risk_score,
                nothing
            )

            push!(events, event)
            event_id += 1
        end
    end

    return events
end

"""
    detect_dex_interactions(graph::TxGraph, target_address::String, catalog_config::CatalogConfig=DEFAULT_CATALOG_CONFIG)

Detect large DEX interactions that might indicate fund processing.
"""
function detect_dex_interactions(graph::TxGraph, target_address::String, catalog_config::CatalogConfig=DEFAULT_CATALOG_CONFIG)
    events = IntegrationEvent[]

    if !DEFAULT_EVENT_CONFIG.enable_dex_monitoring
        return events
    end

    # Get DEX services from catalog
    dex_services = get_services_by_type("dex", catalog_config)
    dex_addresses = Set(service.address for service in dex_services)

    event_id = 1

    for edge in graph.edges
        # Check if target wallet interacts with DEX
        if (edge.from == target_address || edge.to == target_address) &&
           (edge.to in dex_addresses || edge.from in dex_addresses) &&
           edge.value >= 5.0  # Minimum 5 SOL for significant DEX interaction

            service_address = edge.to in dex_addresses ? edge.to : edge.from
            service_info = lookup_service(service_address, catalog_config)

            # DEX interactions are generally lower risk unless very large
            risk_score = min(1.0, 0.2 + (min(edge.value / 100.0, 1.0) * 0.3))

            event = IntegrationEvent(
                "dex_interaction_$(event_id)",
                "dex_interaction",
                edge.block_time === nothing ? 0 : edge.block_time,
                edge.slot,
                [edge.from, edge.to],
                service_info,
                edge.tx_signature,
                edge.value,
                Dict{String,Any}(
                    "dex_name" => service_info === nothing ? "Unknown" : service_info.service_name,
                    "interaction_type" => edge.from == target_address ? "outgoing" : "incoming",
                    "protocol_features" => service_info === nothing ? [] : get(service_info.metadata, "features", [])
                ),
                risk_score,
                nothing
            )

            push!(events, event)
            event_id += 1
        end
    end

    return events
end

"""
    detect_suspicious_patterns(events::Vector{IntegrationEvent})

Detect suspicious patterns across multiple integration events.
"""
function detect_suspicious_patterns(events::Vector{IntegrationEvent})
    suspicious_events = IntegrationEvent[]

    if length(events) < 2
        return suspicious_events
    end

    # Sort events by timestamp
    sorted_events = sort(events, by = e -> e.timestamp)

    # Detect rapid cash-out patterns
    cash_out_events = filter(e -> e.event_type == "cash_out", sorted_events)

    if length(cash_out_events) >= 2
        for i in 1:(length(cash_out_events)-1)
            current_event = cash_out_events[i]
            next_event = cash_out_events[i+1]

            # Check for rapid sequential cash-outs (within 1 hour)
            time_diff = next_event.timestamp - current_event.timestamp

            if time_diff <= 3600 && current_event.value + next_event.value >= 50.0  # Rapid + significant
                # Create suspicious pattern event
                pattern_event = IntegrationEvent(
                    "suspicious_rapid_cashout_$(i)",
                    "suspicious_pattern",
                    current_event.timestamp,
                    current_event.slot,
                    unique(vcat(current_event.addresses, next_event.addresses)),
                    nothing,
                    current_event.transaction_signature,
                    current_event.value + next_event.value,
                    Dict{String,Any}(
                        "pattern_type" => "rapid_cash_out",
                        "event_count" => 2,
                        "time_span_seconds" => time_diff,
                        "total_value" => current_event.value + next_event.value,
                        "involved_services" => unique([
                            current_event.service_info === nothing ? "Unknown" : current_event.service_info.service_name,
                            next_event.service_info === nothing ? "Unknown" : next_event.service_info.service_name
                        ])
                    ),
                    0.8,  # High risk for rapid cash-out patterns
                    current_event.taint_involvement
                )

                push!(suspicious_events, pattern_event)
            end
        end
    end

    # Detect high-velocity patterns
    if length(sorted_events) >= 3
        total_value = sum(event.value for event in sorted_events)
        time_span = sorted_events[end].timestamp - sorted_events[1].timestamp

        if time_span > 0
            velocity = total_value / (time_span / 3600.0)  # SOL per hour

            if velocity >= DEFAULT_EVENT_CONFIG.suspicious_velocity_threshold
                velocity_event = IntegrationEvent(
                    "high_velocity_pattern",
                    "suspicious_pattern",
                    sorted_events[1].timestamp,
                    sorted_events[1].slot,
                    unique(vcat([event.addresses for event in sorted_events]...)),
                    nothing,
                    sorted_events[1].transaction_signature,
                    total_value,
                    Dict{String,Any}(
                        "pattern_type" => "high_velocity",
                        "event_count" => length(sorted_events),
                        "time_span_hours" => time_span / 3600.0,
                        "velocity_sol_per_hour" => velocity,
                        "threshold_exceeded" => velocity / DEFAULT_EVENT_CONFIG.suspicious_velocity_threshold
                    ),
                    min(1.0, 0.6 + (velocity / DEFAULT_EVENT_CONFIG.suspicious_velocity_threshold) * 0.3),
                    nothing
                )

                push!(suspicious_events, velocity_event)
            end
        end
    end

    return suspicious_events
end

"""
    analyze_integration_events(graph::TxGraph, target_address::String, taint_results::Dict{String,TaintResult})

Perform complete integration event analysis for a wallet.
"""
function analyze_integration_events(graph::TxGraph, target_address::String, taint_results::Dict{String,TaintResult})
    all_events = IntegrationEvent[]

    # Detect different types of events
    cash_out_events = detect_cash_out_events(graph, taint_results)
    append!(all_events, cash_out_events)

    bridge_events = detect_bridge_operations(graph)
    append!(all_events, bridge_events)

    dex_events = detect_dex_interactions(graph, target_address)
    append!(all_events, dex_events)

    # Detect suspicious patterns across all events
    suspicious_events = detect_suspicious_patterns(all_events)
    append!(all_events, suspicious_events)

    # Calculate overall risk metrics
    high_risk_events = filter(event -> event.risk_score >= 0.7, all_events)
    total_cash_out_value = sum(event.value for event in cash_out_events)

    return Dict{String, Any}(
        "enabled" => true,
        "total_events" => length(all_events),
        "event_breakdown" => Dict(
            "cash_out" => length(cash_out_events),
            "bridge_operations" => length(bridge_events),
            "dex_interactions" => length(dex_events),
            "suspicious_patterns" => length(suspicious_events)
        ),
        "high_risk_events" => length(high_risk_events),
        "total_cash_out_value" => total_cash_out_value,
        "risk_metrics" => Dict(
            "has_tainted_cash_outs" => any(event.taint_involvement !== nothing for event in cash_out_events),
            "rapid_cash_out_detected" => any(event.event_type == "suspicious_pattern" &&
                                           get(event.metadata, "pattern_type", "") == "rapid_cash_out"
                                           for event in suspicious_events),
            "high_velocity_detected" => any(event.event_type == "suspicious_pattern" &&
                                          get(event.metadata, "pattern_type", "") == "high_velocity"
                                          for event in suspicious_events),
            "bridge_activity" => length(bridge_events) > 0
        ),
        "events" => [
            Dict(
                "event_id" => event.event_id,
                "type" => event.event_type,
                "timestamp" => event.timestamp,
                "value" => event.value,
                "risk_score" => event.risk_score,
                "service_name" => event.service_info === nothing ? "Unknown" : event.service_info.service_name,
                "has_taint" => event.taint_involvement !== nothing
            ) for event in all_events
        ]
    )
end

"""
    validate_integration_events(events::Vector{IntegrationEvent})

Validate integration event detection results.
"""
function validate_integration_events(events::Vector{IntegrationEvent})
    validation = Dict{String, Any}(
        "is_valid" => true,
        "issues" => String[],
        "stats" => Dict{String, Any}()
    )

    # Check for invalid risk scores
    invalid_risk_events = filter(event -> event.risk_score < 0 || event.risk_score > 1, events)
    if !isempty(invalid_risk_events)
        validation["is_valid"] = false
        push!(validation["issues"], "Found $(length(invalid_risk_events)) events with invalid risk scores")
    end

    # Check for events with negative values
    negative_value_events = filter(event -> event.value < 0, events)
    if !isempty(negative_value_events)
        validation["is_valid"] = false
        push!(validation["issues"], "Found $(length(negative_value_events)) events with negative values")
    end

    # Add quality stats
    validation["stats"]["total_events"] = length(events)
    validation["stats"]["avg_risk_score"] = isempty(events) ? 0.0 :
        sum(event.risk_score for event in events) / length(events)
    validation["stats"]["avg_value"] = isempty(events) ? 0.0 :
        sum(event.value for event in events) / length(events)
    validation["stats"]["event_types"] = length(unique(event.event_type for event in events))

    return validation
end

# Export functions for use in analysis pipeline
export IntegrationEvent, EventDetectionConfig, DEFAULT_EVENT_CONFIG
export detect_cash_out_events, detect_bridge_operations, detect_dex_interactions
export detect_suspicious_patterns, analyze_integration_events, validate_integration_events
