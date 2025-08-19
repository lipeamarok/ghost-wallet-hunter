# backend-julia/src/agents/AgentMetrics.jl

"""
Agent Metrics Module

Handles collecting, storing, and retrieving metrics for individual agents.
"""
module AgentMetrics

using Dates, DataStructures, Statistics, Logging

# Use centralized Configuration module from JuliaOS
const get_config = Main.JuliaOS.Configuration.get_config
import ..AgentCore: AGENTS, AGENTS_LOCK, AgentStatus, RUNNING, PAUSED, DetectiveMemory, InvestigationTask

export record_metric, get_metrics, get_agent_metrics, reset_metrics, get_system_summary_metrics,
       MetricType, COUNTER, GAUGE, HISTOGRAM, SUMMARY, # Export MetricType enum and its values
       record_investigation_metric, record_risk_detection, get_detective_metrics,
       get_investigation_stats, get_risk_detection_stats

# ---------------------------------------------------------------------------
# Internal helpers (quantile safety & normalization)
# ---------------------------------------------------------------------------
_safe_quantile(arr::AbstractVector{T}, q::Real) where {T<:Real} = isempty(arr) ? missing : (length(arr)==1 ? first(arr) : try
    quantile(arr, q)
catch
    # Fallback: approximate quantile via sorted index
    s = sort(arr); idx = clamp(Int(ceil(q*length(s))), 1, length(s)); s[idx]
end)

function _compute_distribution_stats(values::AbstractVector{<:Real})
    if isempty(values)
    return Dict{String,Any}()  # empty
    end
    return Dict(
        "count" => length(values),
        "min" => minimum(values),
        "max" => maximum(values),
        "avg" => mean(values),
        "median" => median(values),
        "p50" => _safe_quantile(values, 0.50),
        "p95" => _safe_quantile(values, 0.95),
        "p99" => _safe_quantile(values, 0.99),
    )
end

_normalize_score(x) = x > 1 ? x/100 : x

# Metric types
@enum MetricType begin
    COUNTER = 1  # Monotonically increasing counter (e.g., tasks_executed)
    GAUGE = 2    # Value that can go up and down (e.g., memory_usage)
    HISTOGRAM = 3 # Distribution of values (e.g., execution_time observations)
    SUMMARY = 4  # Pre-calculated summary statistics (min, max, avg, percentiles, etc.)
end

# Metric data structure
mutable struct Metric
    name::String
    type::MetricType
    # For COUNTER/GAUGE: Number
    # For HISTOGRAM: Vector{Number} (a batch of observations recorded at this timestamp)
    # For SUMMARY: Dict{String, Any} (e.g., {"count"=>10, "sum"=>100, "avg"=>10, "p95"=>20})
    value::Union{Number, Vector{Number}, Dict{String, Any}}
    timestamp::DateTime
    tags::Dict{String, String} # For adding dimensions to metrics
end

# Global metrics storage
# Structure: Dict{agent_id, Dict{metric_name, CircularBuffer{Metric}}}
const METRICS_STORE = Dict{String, Dict{String, CircularBuffer{Metric}}}()
const METRICS_LOCK = ReentrantLock() # Lock for thread-safe access to METRICS_STORE

"""
    init_agent_metrics(agent_id::String)

Initializes the metrics storage for a new agent. Typically called during agent creation.
This function is idempotent.

# Arguments
- `agent_id::String`: The unique identifier of the agent.
"""
function init_agent_metrics(agent_id::String)
    lock(METRICS_LOCK) do
        if !haskey(METRICS_STORE, agent_id)
            METRICS_STORE[agent_id] = Dict{String, CircularBuffer{Metric}}()
            @debug "Initialized metrics store for agent $agent_id"
        end
    end
end

"""
    record_metric(agent_id::String, name::String, value::Any; type::MetricType=GAUGE, tags::Dict{String, String}=Dict{String, String}())

Records a metric for a specific agent.

# Arguments
- `agent_id::String`: The ID of the agent.
- `name::String`: The name of the metric (e.g., "cpu_usage", "tasks_processed").
- `value::Any`: The value of the metric.
    - For `COUNTER`, `GAUGE`: Should be a `Number`.
    - For `HISTOGRAM`: Should be a `Vector{Number}` representing one or more observations.
    - For `SUMMARY`: Should be a `Dict{String, Any}` containing summary statistics.
- `type::MetricType`: The type of the metric (default: `GAUGE`).
- `tags::Dict{String, String}`: Optional tags (dimensions) for the metric.

# Returns
- The recorded `Metric` object, or `nothing` if metrics are disabled or input is invalid.
"""
function record_metric(agent_id::String, name::String, value::Any;
                       type::MetricType=GAUGE,
                       tags::Dict{String, String}=Dict{String, String}())
    # Check if metrics are enabled globally
    if !get_config("metrics.enabled", true)
        return nothing
    end

    # Validate value type against metric type
    if type == HISTOGRAM && !isa(value, AbstractVector{<:Number})
        @warn "Invalid value for HISTOGRAM metric '$name'. Expected Vector{<:Number}, got $(typeof(value))."
        return nothing
    elseif (type == COUNTER || type == GAUGE) && !isa(value, Number)
        @warn "Invalid value for $type metric '$name'. Expected Number, got $(typeof(value))."
        return nothing
    elseif type == SUMMARY && !isa(value, AbstractDict)
        @warn "Invalid value for SUMMARY metric '$name'. Expected Dict, got $(typeof(value))."
        return nothing
    end

    lock(METRICS_LOCK) do
        # Initialize agent metrics if not already done (defensive)
        if !haskey(METRICS_STORE, agent_id)
             init_agent_metrics(agent_id) # This also acquires METRICS_LOCK (ReentrantLock handles this)
        end

        agent_specific_metrics = METRICS_STORE[agent_id]
        # Initialize buffer for this specific metric if it's new for this agent
        if !haskey(agent_specific_metrics, name)
            retention_period_seconds = get_config("metrics.retention_period_seconds", 86400) # Default 24 hours
            collection_interval_seconds = get_config("metrics.collection_interval_seconds", 60) # Default 60 seconds
            # Ensure buffer is large enough, with a sensible minimum
            buffer_size = max(100, ceil(Int, retention_period_seconds / collection_interval_seconds))
            agent_specific_metrics[name] = CircularBuffer{Metric}(buffer_size)
            @debug "Initialized metric buffer '$name' for agent $agent_id with size $buffer_size"
        end

        # Create and store the metric
        metric_entry = Metric(name, type, value, now(UTC), tags) # Use UTC for consistency
        push!(agent_specific_metrics[name], metric_entry)
        # @debug "Recorded metric '$name' for agent $agent_id: $value, type: $type" # More detailed debug

        return metric_entry
    end
end

"""
    get_agent_metrics(agent_id::String; metric_name::Union{String, Nothing}=nothing, start_time::Union{DateTime, Nothing}=nothing, end_time::Union{DateTime, Nothing}=nothing)

Retrieves processed metrics for a specific agent. Metrics can be filtered by name and a time range.

# Arguments
- `agent_id::String`: The ID of the agent.
- `metric_name::Union{String, Nothing}`: Optional. If provided, retrieves only this specific metric.
- `start_time::Union{DateTime, Nothing}`: Optional. Filters metrics recorded on or after this time.
- `end_time::Union{DateTime, Nothing}`: Optional. Filters metrics recorded on or before this time.

# Returns
- `Dict{String, Any}`: A dictionary where keys are metric names and values are processed metric data.
  Returns an empty dictionary if the agent is not found or no matching metrics are found.
"""
function get_agent_metrics(agent_id::String;
                           metric_name::Union{String, Nothing}=nothing,
                           start_time::Union{DateTime, Nothing}=nothing,
                           end_time::Union{DateTime, Nothing}=nothing)::Dict{String, Any}
    processed_result = Dict{String, Any}()

    lock(METRICS_LOCK) do
        if !haskey(METRICS_STORE, agent_id)
            return processed_result # Agent has no metrics recorded
        end

        agent_specific_metrics = METRICS_STORE[agent_id]
        metric_names_to_process = isnothing(metric_name) ? keys(agent_specific_metrics) : [metric_name]

        for name_key in metric_names_to_process
            if haskey(agent_specific_metrics, name_key)
                # Apply time filters
                # Collect converts CircularBuffer to Vector for easier filtering
                metrics_buffer_view = collect(agent_specific_metrics[name_key])

                filtered_metrics_list = filter(m ->
                    (isnothing(start_time) || m.timestamp >= start_time) &&
                    (isnothing(end_time) || m.timestamp <= end_time),
                    metrics_buffer_view
                )

                if !isempty(filtered_metrics_list)
                    # Use the type from the latest metric entry in the filtered list for processing logic
                    # This assumes all metrics with the same name have the same type, which record_metric should enforce.
                    latest_metric_entry = filtered_metrics_list[end]
                    metric_type = latest_metric_entry.type

                    if metric_type == COUNTER || metric_type == GAUGE
                        processed_result[name_key] = Dict(
                            "current" => latest_metric_entry.value,
                            "type" => string(metric_type),
                            # History provides (timestamp, value) tuples for plotting or analysis
                            "history" => [(m.timestamp, m.value) for m in filtered_metrics_list],
                            "last_updated" => string(latest_metric_entry.timestamp) # For JSON serialization
                        )
                    elseif metric_type == HISTOGRAM
                        # For histograms, concatenate all observed values (each m.value is a Vector{Number})
                        # and compute statistics over the combined set.
                        all_observed_values = vcat(Vector{Number}[m.value for m in filtered_metrics_list if isa(m.value, AbstractVector{<:Number})]...)

                        if !isempty(all_observed_values)
                            processed_result[name_key] = Dict(
                                "type" => "HISTOGRAM",
                                "count" => length(all_observed_values),
                                "min" => minimum(all_observed_values),
                                "max" => maximum(all_observed_values),
                                "mean" => mean(all_observed_values),
                                "median" => median(all_observed_values),
                                # Could add percentiles: "p95" => percentile(all_observed_values, 95)
                                "last_updated" => string(latest_metric_entry.timestamp)
                            )
                        end
                    elseif metric_type == SUMMARY
                        # For summaries, return the latest recorded summary dictionary.
                        # The assumption is that the summary was pre-calculated before being recorded.
                        processed_result[name_key] = Dict(
                            "type" => "SUMMARY",
                            "value" => latest_metric_entry.value, # This is already a Dict
                            "last_updated" => string(latest_metric_entry.timestamp)
                        )
                    end
                end
            end
        end
    end
    return processed_result
end

"""
    get_metrics(; metric_name::Union{String, Nothing}=nothing, start_time::Union{DateTime, Nothing}=nothing, end_time::Union{DateTime, Nothing}=nothing)

Retrieves metrics for all agents. Can be filtered by metric name and time range.

# Arguments
- `metric_name`, `start_time`, `end_time`: Same as for `get_agent_metrics`.

# Returns
- `Dict{String, Dict{String, Any}}`: A dictionary where keys are agent IDs, and values are
  the processed metrics for that agent (structure from `get_agent_metrics`).
"""
function get_metrics(; metric_name::Union{String, Nothing}=nothing,
                     start_time::Union{DateTime, Nothing}=nothing,
                     end_time::Union{DateTime, Nothing}=nothing)::Dict{String, Dict{String, Any}}
    all_agents_result = Dict{String, Dict{String, Any}}()
    lock(METRICS_LOCK) do
        for agent_id_key in keys(METRICS_STORE)
            agent_metrics_data = get_agent_metrics(agent_id_key;
                                             metric_name=metric_name,
                                             start_time=start_time,
                                             end_time=end_time)
            if !isempty(agent_metrics_data)
                all_agents_result[agent_id_key] = agent_metrics_data
            end
        end
    end
    return all_agents_result
end

"""
    reset_metrics(agent_id::Union{String, Nothing}=nothing)

Resets (clears) metrics for a specific agent or for all agents if `agent_id` is `nothing`.

# Arguments
- `agent_id::Union{String, Nothing}`: The ID of the agent whose metrics to reset.
  If `nothing`, metrics for all agents are reset.
"""
function reset_metrics(agent_id::Union{String, Nothing}=nothing)
    lock(METRICS_LOCK) do
        if isnothing(agent_id)
            # Reset metrics for all agents
            original_agent_count = length(METRICS_STORE)
            empty!(METRICS_STORE)
            @info "Reset metrics for all ($original_agent_count) agents."
        elseif haskey(METRICS_STORE, agent_id)
            # Reset metrics for a specific agent
            empty!(METRICS_STORE[agent_id]) # Clear the inner Dict of metric names
            # Optionally, to completely remove the agent entry if no new metrics are expected soon:
            # delete!(METRICS_STORE, agent_id)
            @info "Reset metrics for agent $agent_id."
        else
            @warn "Attempted to reset metrics for unknown or unmonitored agent $agent_id."
        end
    end
end

# No __init__ function needed for this module as it relies on Config.jl's initialization
# and its constants are defined at compile time.


"""
    get_system_summary_metrics()::Dict{String, Any}

Retrieves aggregated system-wide metrics.
"""
function get_system_summary_metrics()::Dict{String, Any}
    summary = Dict{String, Any}()

    # Agent counts
    total_agents = 0
    active_agents = 0 # RUNNING or PAUSED

    # This part requires access to Agents.AGENTS and Agents.AGENTS_LOCK
    # Ensure these are correctly imported or passed if AgentMetrics is truly standalone.
    # For now, assuming direct import works as per the try-catch block above.
    if @isdefined(AGENTS) && @isdefined(AGENTS_LOCK)
        lock(AGENTS_LOCK) do
            total_agents = length(AGENTS)
            for agent_instance in values(AGENTS)
                # Assuming agent_instance has a .status field of type AgentStatus
                if agent_instance.status == RUNNING || agent_instance.status == PAUSED
                    active_agents += 1
                end
            end
        end
    else
        @warn "Cannot access Agents.AGENTS for system metrics due to import issue."
    end
    summary["total_agents_managed"] = total_agents
    summary["active_agents_running_or_paused"] = active_agents

    # Aggregated metrics from METRICS_STORE
    total_tasks_executed_all_types = 0
    # Example: Sum a specific counter metric across all agents
    # This requires knowing the names of metrics that agents might record.
    # Let's assume agents record "tasks_executed_direct" and "tasks_executed_queued" as COUNTERs.

    lock(METRICS_LOCK) do
        for (agent_id, agent_metrics_map) in METRICS_STORE
            for metric_name_to_sum in ["tasks_executed_direct", "tasks_executed_queued", "skills_executed"]
                if haskey(agent_metrics_map, metric_name_to_sum)
                    metric_buffer = agent_metrics_map[metric_name_to_sum]
                    if !isempty(metric_buffer)
                        # For a COUNTER, the "current" value is the latest recorded value,
                        # which represents the total count for that agent if it's a monotonically increasing counter.
                        # If it's a gauge that resets, this logic would be different.
                        # Assuming these are true counters.
                        # We sum the latest value of these counters from each agent.
                        latest_metric_entry = last(metric_buffer) # Get the most recent entry
                        if latest_metric_entry.type == COUNTER && isa(latest_metric_entry.value, Number)
                            total_tasks_executed_all_types += latest_metric_entry.value
                        end
                    end
                end
            end
        end
    end
    summary["total_tasks_executed_across_all_agents"] = total_tasks_executed_all_types

    # Placeholder for actual system CPU/Memory (would require OS-specific calls or a library)
    summary["system_cpu_usage_placeholder"] = rand()
    summary["system_memory_usage_mb_placeholder"] = rand(50:500)

    summary["last_updated"] = string(now(UTC))
    return summary
end

# ----------------------------------------------------------------------
# DETECTIVE-SPECIFIC METRICS FUNCTIONS
# ----------------------------------------------------------------------

"""
    record_investigation_metric(agent_id::String, investigation::InvestigationTask, execution_time::Float64)

Records metrics for a completed investigation.
"""
function record_investigation_metric(agent_id::String, investigation::InvestigationTask, execution_time::Float64)
    tags = Dict(
        "detective_type" => get(investigation.parameters, "detective_type", "unknown"),
        "investigation_type" => investigation.task_type,
        "status" => string(investigation.status)
    )

    # Record investigation completion
    record_metric(agent_id, "investigations_completed", COUNTER, 1, tags)

    # Record execution time
    record_metric(agent_id, "investigation_execution_time", HISTOGRAM, execution_time, tags)

    # Record success/failure
    if investigation.status == :completed
        record_metric(agent_id, "investigations_successful", COUNTER, 1, tags)
    else
        record_metric(agent_id, "investigations_failed", COUNTER, 1, tags)
    end

    # Record patterns detected if available
    if haskey(investigation.result, "patterns_detected")
        patterns_count = length(investigation.result["patterns_detected"])
        record_metric(agent_id, "patterns_detected", COUNTER, patterns_count, tags)
    end

    @debug "Recorded investigation metrics for agent $agent_id: $(investigation.id)"
end

"""
    record_risk_detection(agent_id::String, wallet_address::String, risk_score::Float64, risk_level::String)

Records risk detection metrics.
"""
function record_risk_detection(agent_id::String, wallet_address::String, risk_score::Float64, risk_level::String)
    tags = Dict(
        "risk_level" => risk_level,
        "wallet_type" => "investigated"
    )

    # Normalize score if provided on 0-100 scale
    risk_score_norm = _normalize_score(risk_score)

    # Record risk score distribution
    record_metric(agent_id, "risk_score", HISTOGRAM, risk_score_norm, tags)

    # Record risk level counts
    record_metric(agent_id, "risk_detections_$(lowercase(risk_level))", COUNTER, 1, tags)

    # Record high-risk detections specifically
    if risk_score_norm >= 0.8
        record_metric(agent_id, "high_risk_detections", COUNTER, 1, tags)
    elseif risk_score_norm >= 0.6
        record_metric(agent_id, "medium_risk_detections", COUNTER, 1, tags)
    else
        record_metric(agent_id, "low_risk_detections", COUNTER, 1, tags)
    end

    @debug "Recorded risk detection for agent $agent_id: wallet $wallet_address, score $risk_score_norm (normalized)"
end

"""
    get_detective_metrics(agent_id::String, time_window_hours::Int=24) -> Dict{String, Any}

Gets detective-specific metrics for an agent within a time window.
"""
function get_detective_metrics(agent_id::String, time_window_hours::Int=24)
    metrics_summary = Dict{String, Any}(
        "agent_id" => agent_id,
        "time_window_hours" => time_window_hours,
        "investigations" => Dict{String, Any}(),
        "risk_detection" => Dict{String, Any}(),
        "performance" => Dict{String, Any}()
    )

    cutoff_time = now() - Hour(time_window_hours)

    lock(METRICS_LOCK) do
        if haskey(METRICS_STORE, agent_id)
            agent_metrics = METRICS_STORE[agent_id]

            # Investigation metrics
            investigations_completed = get_metric_count(agent_metrics, "investigations_completed", cutoff_time)
            investigations_successful = get_metric_count(agent_metrics, "investigations_successful", cutoff_time)
            investigations_failed = get_metric_count(agent_metrics, "investigations_failed", cutoff_time)

            metrics_summary["investigations"]["completed"] = investigations_completed
            metrics_summary["investigations"]["successful"] = investigations_successful
            metrics_summary["investigations"]["failed"] = investigations_failed
            metrics_summary["investigations"]["success_rate"] = investigations_completed > 0 ? investigations_successful / investigations_completed : 0.0

            # Risk detection metrics
            high_risk = get_metric_count(agent_metrics, "high_risk_detections", cutoff_time)
            medium_risk = get_metric_count(agent_metrics, "medium_risk_detections", cutoff_time)
            low_risk = get_metric_count(agent_metrics, "low_risk_detections", cutoff_time)

            metrics_summary["risk_detection"]["high_risk"] = high_risk
            metrics_summary["risk_detection"]["medium_risk"] = medium_risk
            metrics_summary["risk_detection"]["low_risk"] = low_risk
            metrics_summary["risk_detection"]["total_detections"] = high_risk + medium_risk + low_risk

            # Performance metrics
            if haskey(agent_metrics, "investigation_execution_time")
                execution_times = get_histogram_values(agent_metrics["investigation_execution_time"], cutoff_time)
                if !isempty(execution_times)
                    dist = _compute_distribution_stats(execution_times)
                    metrics_summary["performance"]["avg_execution_time"] = dist["avg"]
                    metrics_summary["performance"]["median_execution_time"] = dist["median"]
                    metrics_summary["performance"]["p50_execution_time"] = dist["p50"]
                    metrics_summary["performance"]["p95_execution_time"] = dist["p95"]
                    metrics_summary["performance"]["p99_execution_time"] = dist["p99"]
                end
            end

            # Pattern detection
            patterns_detected = get_metric_count(agent_metrics, "patterns_detected", cutoff_time)
            metrics_summary["performance"]["patterns_detected"] = patterns_detected
        end
    end

    metrics_summary["collected_at"] = string(now())
    return metrics_summary
end

"""
    get_investigation_stats(time_window_hours::Int=24) -> Dict{String, Any}

Gets investigation statistics across all detective agents.
"""
function get_investigation_stats(time_window_hours::Int=24)
    stats = Dict{String, Any}(
        "total_investigations" => 0,
        "successful_investigations" => 0,
        "failed_investigations" => 0,
        "by_detective_type" => Dict{String, Any}(),
        "performance" => Dict{String, Any}()
    )

    cutoff_time = now() - Hour(time_window_hours)
    all_execution_times = Float64[]

    lock(METRICS_LOCK) do
        for (agent_id, agent_metrics) in METRICS_STORE
            # Get investigation counts
            completed = get_metric_count(agent_metrics, "investigations_completed", cutoff_time)
            successful = get_metric_count(agent_metrics, "investigations_successful", cutoff_time)
            failed = get_metric_count(agent_metrics, "investigations_failed", cutoff_time)

            stats["total_investigations"] += completed
            stats["successful_investigations"] += successful
            stats["failed_investigations"] += failed

            # Collect execution times
            if haskey(agent_metrics, "investigation_execution_time")
                execution_times = get_histogram_values(agent_metrics["investigation_execution_time"], cutoff_time)
                append!(all_execution_times, execution_times)
            end

            # Group by detective type (if available in agent metadata)
            # This would need agent type information - simplified for now
            stats["by_detective_type"][agent_id] = Dict(
                "completed" => completed,
                "successful" => successful,
                "failed" => failed
            )
        end
    end

    # Calculate performance statistics
    if !isempty(all_execution_times)
    dist = _compute_distribution_stats(all_execution_times)
    stats["performance"]["avg_execution_time"] = dist["avg"]
    stats["performance"]["median_execution_time"] = dist["median"]
    stats["performance"]["p50_execution_time"] = dist["p50"]
    stats["performance"]["p95_execution_time"] = dist["p95"]
    stats["performance"]["p99_execution_time"] = dist["p99"]
    stats["performance"]["min_execution_time"] = dist["min"]
    stats["performance"]["max_execution_time"] = dist["max"]
    end

    stats["success_rate"] = stats["total_investigations"] > 0 ? stats["successful_investigations"] / stats["total_investigations"] : 0.0
    stats["collected_at"] = string(now())

    return stats
end

"""
    get_risk_detection_stats(time_window_hours::Int=24) -> Dict{String, Any}

Gets risk detection statistics across all detective agents.
"""
function get_risk_detection_stats(time_window_hours::Int=24)
    stats = Dict{String, Any}(
        "total_risk_detections" => 0,
        "high_risk_detections" => 0,
        "medium_risk_detections" => 0,
        "low_risk_detections" => 0,
        "risk_distribution" => Dict{String, Any}()
    )

    cutoff_time = now() - Hour(time_window_hours)
    all_risk_scores = Float64[]

    lock(METRICS_LOCK) do
        for (agent_id, agent_metrics) in METRICS_STORE
            high_risk = get_metric_count(agent_metrics, "high_risk_detections", cutoff_time)
            medium_risk = get_metric_count(agent_metrics, "medium_risk_detections", cutoff_time)
            low_risk = get_metric_count(agent_metrics, "low_risk_detections", cutoff_time)

            stats["high_risk_detections"] += high_risk
            stats["medium_risk_detections"] += medium_risk
            stats["low_risk_detections"] += low_risk
            stats["total_risk_detections"] += (high_risk + medium_risk + low_risk)

            # Collect risk scores
            if haskey(agent_metrics, "risk_score")
                risk_scores = get_histogram_values(agent_metrics["risk_score"], cutoff_time)
                append!(all_risk_scores, risk_scores)
            end
        end
    end

    # Calculate risk score distribution
    if !isempty(all_risk_scores)
        # Normalize scores to 0-1 if any exceed 1 (mixed scales defense)
        if any(x->x>1, all_risk_scores)
            all_risk_scores .= map(_normalize_score, all_risk_scores)
        end
        dist = _compute_distribution_stats(all_risk_scores)
        stats["risk_distribution"]["avg_risk_score"] = dist["avg"]
        stats["risk_distribution"]["median_risk_score"] = dist["median"]
        stats["risk_distribution"]["p50_risk_score"] = dist["p50"]
        stats["risk_distribution"]["p95_risk_score"] = dist["p95"]
        stats["risk_distribution"]["p99_risk_score"] = dist["p99"]
        stats["risk_distribution"]["min_risk_score"] = dist["min"]
        stats["risk_distribution"]["max_risk_score"] = dist["max"]
    end

    stats["collected_at"] = string(now())
    return stats
end

# Helper functions for metric aggregation
function get_metric_count(agent_metrics::Dict, metric_name::String, cutoff_time::DateTime)
    if !haskey(agent_metrics, metric_name)
        return 0
    end

    count = 0
    for metric in agent_metrics[metric_name]
        if metric.timestamp >= cutoff_time && metric.type == COUNTER
            count += metric.value
        end
    end
    return count
end

function get_histogram_values(metric_buffer::CircularBuffer, cutoff_time::DateTime)
    values = Float64[]
    for metric in metric_buffer
        if metric.timestamp >= cutoff_time && metric.type == HISTOGRAM
            if isa(metric.value, Vector)
                append!(values, metric.value)
            else
                push!(values, metric.value)
            end
        end
    end
    return values
end

"""
    initialize_detective_metrics()

Initialize the detective metrics system.
"""
function initialize_detective_metrics()
    @info "🔧 Initializing detective metrics system..."
    # Initialize any necessary detective-specific metrics
    return true
end

"""
    get_detective_performance_metrics() -> Dict{String, Any}

Get performance metrics for detective agents.
"""
function get_detective_performance_metrics()
    metrics = Dict{String, Any}()

    try
        # Get metrics for all agents
        system_metrics = get_system_summary_metrics()
        metrics["system"] = system_metrics

        # Add detective-specific metrics
        metrics["detectives"] = Dict{String, Any}()
        lock(AGENTS_LOCK) do
            for (agent_id, agent) in AGENTS
                if hasfield(typeof(agent), :detective_type)
                    agent_metrics = get_agent_metrics(agent_id)
                    metrics["detectives"][agent_id] = agent_metrics
                end
            end
        end

        metrics["status"] = "success"
        @info "📊 Retrieved detective performance metrics"

    catch e
        @error "Failed to get detective performance metrics" exception=e
        metrics["status"] = "error"
        metrics["error"] = string(e)
    end

    return metrics
end

# Export the new functions
export initialize_detective_metrics, get_detective_performance_metrics

end # module AgentMetrics
