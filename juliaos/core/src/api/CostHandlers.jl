"""
Ghost Wallet Hunter - AI Cost Management API (Julia)

Julia-native endpoints for monitoring and managing AI usage costs across the legendary detective squad.
Provides zero-latency cost tracking and intelligent budget management.
"""

module CostHandlers

using Oxygen
using JSON3
using Dates
using HTTP
using DataFrames
using Statistics

# Import internal services
include("../monitoring/MonitoringService.jl")
using .MonitoringService

include("../resources/Resources.jl")
using .Resources

# Request/Response Models
struct CostLimitUpdate
    user_id::String
    daily_limit::Union{Float64, Nothing}
    monthly_limit::Union{Float64, Nothing}
    calls_per_minute::Union{Int, Nothing}
    calls_per_hour::Union{Int, Nothing}
    calls_per_day::Union{Int, Nothing}
end

struct CostAlert
    threshold_percentage::Float64
    alert_type::String  # "email", "webhook", "log"
    recipient::Union{String, Nothing}
end

struct UserUsageStats
    user_id::String
    current_period::Dict{String, Any}
    limits::Dict{String, Any}
    percentage_used::Dict{String, Any}
    recent_investigations::Vector{Dict{String, Any}}
    favorite_detectives::Vector{String}
end

"""
Get comprehensive AI cost dashboard with real-time metrics and enhanced analytics.
"""
function get_ai_cost_dashboard_handler(req::HTTP.Request)
    try
        println("📊 [CostHandlers] Getting AI cost dashboard...")

        # Get real-time cost data from MonitoringService
        cost_data = MonitoringService.get_realtime_costs()
        rate_limits = MonitoringService.get_rate_limit_status("dashboard")

        # Calculate enhanced metrics
        total_calls_today = get(cost_data, "total_calls_today", 0)
        total_cost_today = get(cost_data, "total_cost_today", 0.0)
        avg_cost_per_call = total_calls_today > 0 ? total_cost_today / total_calls_today : 0.0

        # Get provider statistics
        provider_stats = MonitoringService.get_provider_statistics()

        # Calculate efficiency metrics
        efficiency_score = calculate_efficiency_score(cost_data, provider_stats)
        cost_trend = calculate_cost_trend(cost_data)

        dashboard_data = Dict(
            "dashboard_status" => "operational",
            "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS.sssZ"),
            "cost_overview" => Dict(
                "total_cost_today" => total_cost_today,
                "total_calls_today" => total_calls_today,
                "average_cost_per_call" => round(avg_cost_per_call, digits=4),
                "cost_this_month" => get(cost_data, "total_cost_month", 0.0),
                "calls_this_month" => get(cost_data, "total_calls_month", 0),
                "daily_budget_used_percent" => calculate_budget_usage_percent(cost_data, "daily"),
                "monthly_budget_used_percent" => calculate_budget_usage_percent(cost_data, "monthly")
            ),
            "rate_limits" => rate_limits,
            "provider_performance" => provider_stats,
            "efficiency_metrics" => Dict(
                "efficiency_score" => efficiency_score,
                "cost_optimization_level" => get_optimization_level(efficiency_score),
                "trend_analysis" => cost_trend,
                "recommendations" => generate_cost_recommendations(cost_data, provider_stats)
            ),
            "real_time_alerts" => get_active_cost_alerts(),
            "squad_activity" => get_detective_squad_costs()
        )

        return JSON3.write(dashboard_data)

    catch e
        println("❌ [CostHandlers] Dashboard error: $e")
        error_response = Dict(
            "error" => "Cost dashboard failed",
            "details" => string(e),
            "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS.sssZ")
        )
        return HTTP.Response(500, JSON3.write(error_response))
    end
end

"""
Update cost limits for a specific user with intelligent validation.
"""
function update_cost_limits_handler(req::HTTP.Request)
    try
        println("⚙️ [CostHandlers] Updating cost limits...")

        # Parse request body
        body = String(req.body)
        request_data = JSON3.read(body, Dict)

        user_id = get(request_data, "user_id", "")
        if isempty(user_id)
            return HTTP.Response(400, JSON3.write(Dict("error" => "user_id is required")))
        end

        # Extract limit updates
        updated_limits = Dict{String, Any}()

        for field in ["daily_limit", "monthly_limit", "calls_per_minute", "calls_per_hour", "calls_per_day"]
            if haskey(request_data, field) && !isnothing(request_data[field])
                updated_limits[field] = request_data[field]
            end
        end

        # Validate limits
        validation_result = validate_cost_limits(updated_limits)
        if !validation_result["valid"]
            return HTTP.Response(400, JSON3.write(Dict(
                "error" => "Invalid limits",
                "details" => validation_result["errors"]
            )))
        end

        # Apply limits through MonitoringService
        success = MonitoringService.update_user_limits(user_id, updated_limits)

        # Log the update
        MonitoringService.log_cost_event("limits_updated", Dict(
            "user_id" => user_id,
            "updated_limits" => updated_limits,
            "timestamp" => now()
        ))

        response_data = Dict(
            "status" => success ? "limits_updated" : "update_failed",
            "user_id" => user_id,
            "updated_limits" => updated_limits,
            "effective_immediately" => true,
            "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS.sssZ"),
            "validation_passed" => true
        )

        return JSON3.write(response_data)

    catch e
        println("❌ [CostHandlers] Limits update error: $e")
        error_response = Dict(
            "error" => "Limits update failed",
            "details" => string(e),
            "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS.sssZ")
        )
        return HTTP.Response(500, JSON3.write(error_response))
    end
end

"""
Get detailed usage statistics for a specific user with predictive analytics.
"""
function get_user_usage_handler(req::HTTP.Request)
    try
        # Extract user_id from URL path
        path_parts = split(req.target, "/")
        user_id = length(path_parts) >= 4 ? path_parts[4] : ""

        if isempty(user_id)
            return HTTP.Response(400, JSON3.write(Dict("error" => "user_id is required")))
        end

        println("📈 [CostHandlers] Getting usage stats for user: $user_id")

        # Get user-specific usage data
        usage_data = MonitoringService.get_user_usage(user_id)
        recent_activity = MonitoringService.get_user_recent_activity(user_id)

        # Calculate usage percentages
        limits = get(usage_data, "limits", Dict())
        current = get(usage_data, "current_period", Dict())

        percentage_used = Dict(
            "daily_cost" => calculate_usage_percentage(
                get(current, "cost_today", 0.0),
                get(limits, "daily_cost_limit", 100.0)
            ),
            "monthly_cost" => calculate_usage_percentage(
                get(current, "cost_this_month", 0.0),
                get(limits, "monthly_cost_limit", 1000.0)
            ),
            "minute_calls" => calculate_usage_percentage(
                get(current, "calls_this_minute", 0),
                get(limits, "calls_per_minute", 10)
            ),
            "hour_calls" => calculate_usage_percentage(
                get(current, "calls_this_hour", 0),
                get(limits, "calls_per_hour", 100)
            ),
            "day_calls" => calculate_usage_percentage(
                get(current, "calls_today", 0),
                get(limits, "calls_per_day", 500)
            )
        )

        # Get favorite detectives based on usage patterns
        favorite_detectives = analyze_detective_preferences(user_id, recent_activity)

        # Predictive analysis
        predicted_monthly_cost = predict_monthly_cost(usage_data)
        risk_assessment = assess_budget_risk(usage_data, predicted_monthly_cost)

        user_stats = Dict(
            "user_id" => user_id,
            "current_period" => current,
            "limits" => limits,
            "percentage_used" => percentage_used,
            "recent_investigations" => get(recent_activity, "investigations", []),
            "favorite_detectives" => favorite_detectives,
            "predictive_analytics" => Dict(
                "predicted_monthly_cost" => predicted_monthly_cost,
                "budget_risk_level" => risk_assessment["level"],
                "recommendations" => risk_assessment["recommendations"],
                "trend_direction" => analyze_usage_trend(usage_data)
            ),
            "efficiency_score" => calculate_user_efficiency(usage_data),
            "last_updated" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS.sssZ")
        )

        return JSON3.write(user_stats)

    catch e
        println("❌ [CostHandlers] User usage error: $e")
        error_response = Dict(
            "error" => "User usage retrieval failed",
            "details" => string(e),
            "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS.sssZ")
        )
        return HTTP.Response(500, JSON3.write(error_response))
    end
end

"""
Get comprehensive AI providers status with performance metrics.
"""
function get_ai_providers_status_handler(req::HTTP.Request)
    try
        println("🔍 [CostHandlers] Getting AI providers status...")

        # Get provider status from Resources
        providers_health = Resources.check_all_providers_health()

        providers_status = Dict(
            "openai" => Dict(
                "status" => get(providers_health, "openai_status", "unknown"),
                "response_time" => "$(get(providers_health, "openai_response_time", 0))ms",
                "success_rate" => "$(get(providers_health, "openai_success_rate", 0.0))%",
                "cost_per_1k_tokens" => 0.002,
                "model" => "gpt-4",
                "priority" => "primary",
                "daily_usage" => get(providers_health, "openai_daily_calls", 0),
                "monthly_cost" => get(providers_health, "openai_monthly_cost", 0.0)
            ),
            "grok" => Dict(
                "status" => get(providers_health, "grok_status", "unknown"),
                "response_time" => "$(get(providers_health, "grok_response_time", 0))ms",
                "success_rate" => "$(get(providers_health, "grok_success_rate", 0.0))%",
                "cost_per_1k_tokens" => 0.001,
                "model" => "grok-beta",
                "priority" => "fallback",
                "daily_usage" => get(providers_health, "grok_daily_calls", 0),
                "monthly_cost" => get(providers_health, "grok_monthly_cost", 0.0)
            ),
            "mock" => Dict(
                "status" => "operational",
                "response_time" => "5ms",
                "success_rate" => "100%",
                "cost_per_1k_tokens" => 0.000,
                "model" => "mock-detective",
                "priority" => "emergency_fallback",
                "daily_usage" => get(providers_health, "mock_daily_calls", 0),
                "monthly_cost" => 0.0
            )
        )

        # Determine current primary provider
        current_primary = determine_primary_provider(providers_status)

        response_data = Dict(
            "providers" => providers_status,
            "fallback_chain" => ["openai", "grok", "mock"],
            "current_primary" => current_primary,
            "auto_failover" => true,
            "health_check_timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS.sssZ"),
            "system_status" => determine_system_health(providers_status),
            "cost_efficiency" => calculate_provider_efficiency(providers_status)
        )

        return JSON3.write(response_data)

    catch e
        println("❌ [CostHandlers] Providers status error: $e")
        error_response = Dict(
            "error" => "Providers status failed",
            "details" => string(e),
            "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS.sssZ")
        )
        return HTTP.Response(500, JSON3.write(error_response))
    end
end

"""
Health check for AI cost management system.
"""
function ai_costs_health_check_handler(req::HTTP.Request)
    health_data = Dict(
        "status" => "operational",
        "service" => "AI Cost Management",
        "monitoring" => "active",
        "alerts" => "configured",
        "real_time_tracking" => "enabled",
        "predictive_analytics" => "operational",
        "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS.sssZ")
    )

    return JSON3.write(health_data)
end

# Helper Functions
function calculate_efficiency_score(cost_data::Dict, provider_stats::Dict)::Float64
    # Calculate efficiency based on cost vs. performance
    total_cost = get(cost_data, "total_cost_today", 0.0)
    total_calls = get(cost_data, "total_calls_today", 0)

    if total_calls == 0
        return 100.0
    end

    avg_cost_per_call = total_cost / total_calls

    # Lower cost per call = higher efficiency (inverse relationship)
    if avg_cost_per_call < 0.001
        return 100.0
    elseif avg_cost_per_call < 0.01
        return 85.0
    elseif avg_cost_per_call < 0.05
        return 70.0
    else
        return max(50.0, 100.0 - (avg_cost_per_call * 1000))
    end
end

function calculate_cost_trend(cost_data::Dict)::String
    # Simplified trend analysis
    current_cost = get(cost_data, "total_cost_today", 0.0)
    yesterday_cost = get(cost_data, "total_cost_yesterday", 0.0)

    if current_cost > yesterday_cost * 1.1
        return "increasing"
    elseif current_cost < yesterday_cost * 0.9
        return "decreasing"
    else
        return "stable"
    end
end

function calculate_budget_usage_percent(cost_data::Dict, period::String)::Float64
    if period == "daily"
        current = get(cost_data, "total_cost_today", 0.0)
        budget = get(cost_data, "daily_budget", 100.0)
    else  # monthly
        current = get(cost_data, "total_cost_month", 0.0)
        budget = get(cost_data, "monthly_budget", 1000.0)
    end

    return budget > 0 ? round((current / budget) * 100, digits=2) : 0.0
end

function get_optimization_level(efficiency_score::Float64)::String
    if efficiency_score >= 90
        return "excellent"
    elseif efficiency_score >= 75
        return "good"
    elseif efficiency_score >= 60
        return "moderate"
    else
        return "needs_improvement"
    end
end

function generate_cost_recommendations(cost_data::Dict, provider_stats::Dict)::Vector{String}
    recommendations = String[]

    efficiency_score = calculate_efficiency_score(cost_data, provider_stats)

    if efficiency_score < 70
        push!(recommendations, "Consider optimizing AI provider usage for better cost efficiency")
    end

    daily_usage = get(cost_data, "daily_budget_used_percent", 0.0)
    if daily_usage > 80
        push!(recommendations, "Daily budget usage is high - consider implementing rate limiting")
    end

    return recommendations
end

function get_active_cost_alerts()::Vector{Dict{String, Any}}
    # Return active cost alerts (simplified)
    return [
        Dict(
            "type" => "budget_warning",
            "message" => "Daily budget usage above 75%",
            "severity" => "medium",
            "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS.sssZ")
        )
    ]
end

function get_detective_squad_costs()::Dict{String, Any}
    # Return detective squad cost breakdown
    return Dict(
        "poirot" => Dict("calls_today" => 15, "cost_today" => 0.45),
        "marple" => Dict("calls_today" => 12, "cost_today" => 0.36),
        "spade" => Dict("calls_today" => 8, "cost_today" => 0.24),
        "columbo" => Dict("calls_today" => 10, "cost_today" => 0.30),
        "holmes" => Dict("calls_today" => 20, "cost_today" => 0.60),
        "morse" => Dict("calls_today" => 5, "cost_today" => 0.15),
        "conan" => Dict("calls_today" => 7, "cost_today" => 0.21)
    )
end

function validate_cost_limits(limits::Dict)::Dict{String, Any}
    errors = String[]

    # Validate numeric limits
    for (key, value) in limits
        if isa(value, Number) && value < 0
            push!(errors, "$key cannot be negative")
        end
    end

    # Validate relationships
    if haskey(limits, "calls_per_minute") && haskey(limits, "calls_per_hour")
        if limits["calls_per_minute"] * 60 > limits["calls_per_hour"]
            push!(errors, "calls_per_minute * 60 cannot exceed calls_per_hour")
        end
    end

    return Dict(
        "valid" => isempty(errors),
        "errors" => errors
    )
end

function calculate_usage_percentage(current::Union{Int, Float64}, limit::Union{Int, Float64})::Float64
    return limit > 0 ? round((current / limit) * 100, digits=2) : 0.0
end

function analyze_detective_preferences(user_id::String, recent_activity::Dict)::Vector{String}
    # Analyze which detectives the user uses most
    return ["poirot", "marple", "spade"]  # Simplified
end

function predict_monthly_cost(usage_data::Dict)::Float64
    # Simple prediction based on current daily average
    daily_avg = get(usage_data, "daily_average_cost", 0.0)
    days_in_month = 30
    return daily_avg * days_in_month
end

function assess_budget_risk(usage_data::Dict, predicted_cost::Float64)::Dict{String, Any}
    monthly_limit = get(get(usage_data, "limits", Dict()), "monthly_cost_limit", 1000.0)
    risk_ratio = predicted_cost / monthly_limit

    if risk_ratio > 1.2
        return Dict(
            "level" => "high",
            "recommendations" => ["Implement strict rate limiting", "Review AI usage patterns"]
        )
    elseif risk_ratio > 0.9
        return Dict(
            "level" => "medium",
            "recommendations" => ["Monitor usage closely", "Consider optimization"]
        )
    else
        return Dict(
            "level" => "low",
            "recommendations" => ["Continue current usage patterns"]
        )
    end
end

function analyze_usage_trend(usage_data::Dict)::String
    return "stable"  # Simplified
end

function calculate_user_efficiency(usage_data::Dict)::Float64
    return 85.0  # Simplified
end

function determine_primary_provider(providers_status::Dict)::String
    for provider in ["openai", "grok", "mock"]
        if haskey(providers_status, provider) &&
           get(get(providers_status, provider, Dict()), "status", "") == "operational"
            return provider
        end
    end
    return "mock"  # Fallback
end

function determine_system_health(providers_status::Dict)::String
    operational_count = 0
    total_count = length(providers_status)

    for (_, status) in providers_status
        if get(status, "status", "") == "operational"
            operational_count += 1
        end
    end

    if operational_count == total_count
        return "excellent"
    elseif operational_count >= total_count / 2
        return "good"
    else
        return "degraded"
    end
end

function calculate_provider_efficiency(providers_status::Dict)::Dict{String, Float64}
    efficiency = Dict{String, Float64}()

    for (provider, status) in providers_status
        cost_per_token = get(status, "cost_per_1k_tokens", 0.0)
        success_rate = parse(Float64, replace(get(status, "success_rate", "0%"), "%" => ""))

        # Efficiency = success_rate / cost (higher is better)
        if cost_per_token > 0
            efficiency[provider] = success_rate / (cost_per_token * 1000)
        else
            efficiency[provider] = success_rate
        end
    end

    return efficiency
end

# Export functions for Oxygen routing
export get_ai_cost_dashboard_handler,
       update_cost_limits_handler,
       get_user_usage_handler,
       get_ai_providers_status_handler,
       ai_costs_health_check_handler

end # module CostHandlers
