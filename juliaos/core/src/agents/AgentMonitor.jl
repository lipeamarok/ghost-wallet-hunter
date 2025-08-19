# backend-julia/src/agents/AgentMonitor.jl

"""
Agent Monitor Module

Periodically checks the health and status of running agents,
detects stalls, and can trigger configured actions like auto-restarts.
"""
module AgentMonitor

using Dates, Logging, Base.Threads

# Import necessary modules and types
# Assumes these modules are siblings within the 'agents' directory/module scope
# Config is now loaded by framework
import ..Config: get_config
# We need access to the Agent struct, its status, and lifecycle functions
# This import style assumes DetectiveAgents.jl defines "module DetectiveAgents"
import ..AgentCore: Agent, AgentStatus, AGENTS, AGENTS_LOCK, DetectiveMemory, InvestigationTask
import ..DetectiveAgents: getAgentStatus, listAgents, startAgent
import ..AgentMetrics: record_metric, COUNTER, GAUGE

export start_monitor, stop_monitor, get_health_status, HealthStatus,
       get_detective_system_health, monitor_investigation_performance, detect_stalled_investigations

# Enum for overall system/agent health
@enum HealthStatus begin
    HEALTHY = 1
    DEGRADED = 2 # Some agents might be in error or stalled
    UNHEALTHY = 3 # Critical issues, many agents failing
    UNKNOWN = 4
end

# --- Monitor State ---
const MONITOR_TASK = Ref{Union{Task, Nothing}}(nothing)
const MONITOR_RUNNING = Ref{Bool}(false)
const MONITOR_LOCK = ReentrantLock() # Lock for MONITOR_RUNNING and MONITOR_TASK

# Cache for last health status to avoid re-computation on every API call
const LAST_HEALTH_SNAPSHOT = Ref{Dict{String, Any}}(Dict())
const SNAPSHOT_LOCK = ReentrantLock()

"""
    _check_agent_health(agent::Agent)

Checks the health of a single agent.
Returns a Dict with health information for this agent.
"""
function _check_agent_health(agent_dict::Dict{String, Any})::Dict{String, Any}
    # Handle Dict representation of agent (from DetectiveAgents compatibility layer)
    agent_id = get(agent_dict, "id", "unknown")

    # Basic health check for detective agents
    health_info = Dict{String, Any}(
        "agent_id" => agent_id,
        "status" => get(agent_dict, "status", "unknown"),
        "is_stalled" => false, # Detective agents don't use traditional stalling concept
        "last_activity" => now(),
        "health_score" => 1.0,
        "memory_usage_mb" => 0.0,
        "task_queue_size" => 0
    )

    return health_info
end

# Original function for AgentCore.Agent objects (if needed)
function _check_agent_health(agent::Agent)::Dict{String, Any}
    # This function assumes the caller might not hold agent.lock,
    # so it should rely on functions like getAgentStatus that handle locking.
    status_info = getAgentStatus(agent.id) # getAgentStatus handles agent.lock

    is_stalled = false
    max_stall_seconds = get_config("agent.max_stall_seconds", 300)

    # Check for stall only if agent is supposed to be running or initializing
    if agent.status == DetectiveAgents.RUNNING || agent.status == DetectiveAgents.INITIALIZING
        time_since_last_activity = Dates.value(now(UTC) - agent.last_activity) / 1000 # in seconds
        if time_since_last_activity > max_stall_seconds
            is_stalled = true
            @warn "Agent $(agent.name) ($(agent.id)) appears stalled. Last activity: $(agent.last_activity) ($(round(time_since_last_activity, digits=1))s ago)."
            # Optionally, record a metric for stalled agents via AgentMetrics
            # AgentMetrics.record_metric(agent.id, "agent_stalled_status", 1; type=AgentMetrics.GAUGE)
        end
    end

    health_details = Dict(
        "id" => agent.id,
        "name" => agent.name,
        "status" => status_info["status"], # string representation from getAgentStatus
        "is_stalled" => is_stalled,
        "last_activity" => string(agent.last_activity),
        "uptime_seconds" => status_info["uptime_seconds"],
        "last_error" => status_info["last_error"]
    )
    return health_details
end

"""
    _perform_health_check()

Performs a health check on all registered agents and updates the health snapshot.
"""
function _perform_health_check()
    @debug "Performing system-wide agent health check..."
    num_agents_total = 0
    num_agents_running = 0
    num_agents_error = 0
    num_agents_stalled = 0

    agent_health_reports = Dict{String, Any}()

    # Use listAgents to get a snapshot of current agents.
    # listAgents handles AGENTS_LOCK correctly.
    all_agents_list = listAgents() # Gets a Vector{Agent}
    num_agents_total = length(all_agents_list)

    for agent_instance in all_agents_list
        # It's important that _check_agent_health uses functions that
        # correctly handle locking for individual agent state if needed.
        # `agent_instance` here is a copy of the Agent struct.
        # If _check_agent_health needs the most up-to-date mutable state,
        # it should re-fetch the agent or use status functions that lock.
        # getAgentStatus already does this.

        # We pass the agent_instance which contains its ID and other immutable parts.
        # _check_agent_health primarily uses getAgentStatus(agent_instance.id)
        # which fetches the current state of the agent.
        report = _check_agent_health(agent_instance)
        agent_id = get(agent_instance, "id", "unknown") # Get ID from Dict
        agent_health_reports[agent_id] = report

        if report["status"] == "active" # Detective agents use "active" status
            num_agents_running += 1
        elseif report["status"] == "error"
            num_agents_error += 1
        end
        if report["is_stalled"]
            num_agents_stalled += 1
        end

        # Auto-restart logic (optional)
        if (report["status"] == "error" || report["is_stalled"]) && get_config("agent.auto_restart", false)
            agent_name = get(agent_instance, "name", "unknown")
            @warn "Auto-restarting agent $agent_name ($agent_id) due to status: $(report["status"]), stalled: $(report["is_stalled"])"
            try
                # Ensure stopAgent is called first if it's stalled but not stopped.
                # startAgent should handle the logic of starting a stopped/errored agent.
                DetectiveAgents.stopAgent(agent_id) # Attempt to gracefully stop if needed
                success = DetectiveAgents.startAgent(agent_id) # startAgent handles status checks
                if success
                    @info "Agent $agent_name restarted successfully."
                    # AgentMetrics.record_metric(agent_id, "agent_auto_restarts", 1; type=AgentMetrics.COUNTER)
                else
                    @error "Failed to auto-restart agent $agent_name."
                end
            catch e
                @error "Exception during auto-restart of agent $agent_name" exception=(e, catch_backtrace())
            end
        end
    end

    overall_status = HEALTHY
    if num_agents_error > 0 || num_agents_stalled > 0
        overall_status = DEGRADED
    end
    # Define more sophisticated logic for UNHEALTHY if needed (e.g., >50% agents in error)
    if num_agents_total > 0 && (num_agents_error + num_agents_stalled) > num_agents_total / 2
        overall_status = UNHEALTHY
    elseif num_agents_total == 0 && num_agents_error == 0 # No agents, no errors
         overall_status = HEALTHY # Or perhaps UNKNOWN/IDLE depending on desired semantics
    end


    snapshot_data = Dict(
        "overall_status" => string(overall_status),
        "timestamp" => string(now(UTC)),
        "total_agents" => num_agents_total,
        "running_agents" => num_agents_running,
        "error_agents" => num_agents_error,
        "stalled_agents" => num_agents_stalled,
        "agent_details" => agent_health_reports # Dict of individual agent health reports
    )

    lock(SNAPSHOT_LOCK) do
        LAST_HEALTH_SNAPSHOT[] = snapshot_data
    end
    @info "Health check complete. Overall: $(overall_status), Total: $num_agents_total, Running: $num_agents_running, Error: $num_agents_error, Stalled: $num_agents_stalled"
end


"""
    monitor_loop()

The main loop for the agent monitor task. Periodically calls `_perform_health_check`.
"""
function monitor_loop()
    monitor_interval = get_config("agent.monitor_interval_seconds", 30)
    if monitor_interval <= 0
        @warn "Agent monitor interval is <= 0 (value: $monitor_interval). Monitor will not run periodically."
        # Ensure MONITOR_RUNNING is set to false if we decide not to loop.
        lock(MONITOR_LOCK) do
            MONITOR_RUNNING[] = false # Stop the loop if interval is invalid
        end
        return
    end

    @info "Agent monitor task started. Check interval: $(monitor_interval)s"
    try
        while true
            running = false
            lock(MONITOR_LOCK) do
                running = MONITOR_RUNNING[]
            end

            if !running
                break
            end

            _perform_health_check()
            sleep(monitor_interval)
        end
    catch e
        # Allow InterruptException to cleanly stop the task during shutdown
        if isa(e, InterruptException)
            @info "Agent monitor task interrupted."
        else
            @error "Agent monitor task crashed!" exception=(e, catch_backtrace())
        end
    finally
        @info "Agent monitor task stopped."
        lock(MONITOR_LOCK) do # Ensure lock for state modification
            MONITOR_RUNNING[] = false
            MONITOR_TASK[] = nothing
        end
    end
end

"""
    start_monitor()::Bool

Starts the agent monitoring background task if not already running and if enabled in config.
"""
function start_monitor()::Bool
    if !get_config("agent.monitor_enabled", true) # Add a config option to disable monitor
        @info "Agent monitor is disabled by configuration."
        return false
    end

    lock(MONITOR_LOCK) do
        if MONITOR_RUNNING[]
            @warn "Agent monitor task is already running."
            return false
        end

        monitor_interval = get_config("agent.monitor_interval_seconds", 30)
        if monitor_interval <= 0
            @warn "Agent monitor interval is non-positive ($monitor_interval seconds). Monitor will not start."
            return false
        end

        MONITOR_RUNNING[] = true
        MONITOR_TASK[] = @task monitor_loop()
        schedule(MONITOR_TASK[])
        return true
    end
end

"""
    stop_monitor()::Bool

Stops the agent monitoring background task.
"""
function stop_monitor()::Bool
    task_to_stop = nothing
    lock(MONITOR_LOCK) do
        if !MONITOR_RUNNING[]
            @warn "Agent monitor task is not running."
            return false
        end
        MONITOR_RUNNING[] = false # Signal the loop to stop
        task_to_stop = MONITOR_TASK[]
    end

    # Attempt to interrupt and wait for the task to finish
    if !isnothing(task_to_stop) && !istaskdone(task_to_stop)
        try
            @info "Attempting to interrupt agent monitor task..."
            schedule(task_to_stop, InterruptException(), error=true)
            # Wait for a short period, but don't block indefinitely
            # yield() # Give the task a chance to process the interrupt
            # For more robust stopping, you might need a timed wait or check istaskdone in a loop.
            # For now, we've signaled it. The finally block in monitor_loop will clean up.
        catch e
            @error "Error while trying to interrupt monitor task" exception=e
        end
    end
    @info "Agent monitor stop signal sent."
    return true
end

"""
    get_health_status()::Dict{String, Any}

Retrieves the last recorded health snapshot of the agent system.
"""
function get_health_status()::Dict{String, Any}
    lock(SNAPSHOT_LOCK) do
        if isempty(LAST_HEALTH_SNAPSHOT[])
            # If no snapshot yet, perform an initial check or return UNKNOWN
            # For simplicity, let's return UNKNOWN if called before first check.
            # Or, trigger a check: _perform_health_check() here, but that might take time.
            return Dict(
                "overall_status" => string(UNKNOWN),
                "timestamp" => string(now(UTC)),
                "message" => "No health snapshot available yet. Monitor might be starting or not run."
            )
        end
        return deepcopy(LAST_HEALTH_SNAPSHOT[]) # Return a copy to prevent external modification
    end
end

"""
    __init__()

Module initialization function. Starts the monitor task automatically if enabled.
"""
function __init__()
    # Automatically start the monitor when the module is loaded if enabled
    # This ensures the monitor runs when the application starts.
    if get_config("agent.monitor_enabled", true) && get_config("agent.monitor_autostart", true)
        # Run as an async task to avoid blocking module loading if start_monitor takes time
        # or if there are delays in its initial setup.
        @async begin
            sleep(get_config("agent.monitor_initial_delay_seconds", 5)) # Optional delay
            start_monitor()
        end
    else
        @info "Agent monitor auto-start disabled by configuration."
    end
end

# ----------------------------------------------------------------------
# DETECTIVE-SPECIFIC MONITORING FUNCTIONS
# ----------------------------------------------------------------------

"""
    get_detective_system_health() -> Dict{String, Any}

Gets comprehensive health status of the detective agent system.
"""
function get_detective_system_health()
    health_report = Dict{String, Any}(
        "overall_status" => "UNKNOWN",
        "detective_agents" => Dict{String, Any}(),
        "investigation_performance" => Dict{String, Any}(),
        "system_metrics" => Dict{String, Any}(),
        "alerts" => [],
        "recommendations" => [],
        "last_checked" => string(now())
    )

    detective_agents = []
    total_agents = 0
    healthy_agents = 0
    degraded_agents = 0
    failed_agents = 0

    lock(AGENTS_LOCK) do
        for (agent_id, agent) in AGENTS
            total_agents += 1

            # Check if this is a detective agent
            is_detective = occursin("detective", lowercase(agent_id)) ||
                          occursin("poirot", lowercase(agent_id)) ||
                          occursin("marple", lowercase(agent_id)) ||
                          occursin("spade", lowercase(agent_id)) ||
                          occursin("marlowee", lowercase(agent_id)) ||
                          occursin("dupin", lowercase(agent_id)) ||
                          occursin("shadow", lowercase(agent_id)) ||
                          occursin("raven", lowercase(agent_id))

            if is_detective
                agent_health = check_detective_agent_health(agent)
                push!(detective_agents, agent_health)

                if agent_health["status"] == "HEALTHY"
                    healthy_agents += 1
                elseif agent_health["status"] == "DEGRADED"
                    degraded_agents += 1
                else
                    failed_agents += 1
                end
            end
        end
    end

    # Determine overall system health
    if failed_agents > 0
        health_report["overall_status"] = "UNHEALTHY"
        push!(health_report["alerts"], "$(failed_agents) detective agents are in failed state")
    elseif degraded_agents > healthy_agents
        health_report["overall_status"] = "DEGRADED"
        push!(health_report["alerts"], "More detective agents are degraded than healthy")
    elseif length(detective_agents) > 0
        health_report["overall_status"] = "HEALTHY"
    else
        health_report["overall_status"] = "UNKNOWN"
        push!(health_report["alerts"], "No detective agents found in system")
    end

    health_report["detective_agents"]["total"] = length(detective_agents)
    health_report["detective_agents"]["healthy"] = healthy_agents
    health_report["detective_agents"]["degraded"] = degraded_agents
    health_report["detective_agents"]["failed"] = failed_agents
    health_report["detective_agents"]["details"] = detective_agents

    # Get investigation performance metrics
    health_report["investigation_performance"] = get_investigation_performance_metrics()

    # Add recommendations
    if failed_agents > 0
        push!(health_report["recommendations"], "Restart failed detective agents")
    end
    if degraded_agents > 0
        push!(health_report["recommendations"], "Investigate degraded agents for performance issues")
    end
    if length(detective_agents) == 0
        push!(health_report["recommendations"], "Initialize detective agent system")
    end

    return health_report
end

"""
    check_detective_agent_health(agent::Agent) -> Dict{String, Any}

Checks the health of a specific detective agent.
"""
function check_detective_agent_health(agent::Agent)
    agent_health = Dict{String, Any}(
        "agent_id" => agent.id,
        "agent_name" => agent.name,
        "status" => "UNKNOWN",
        "last_activity" => string(agent.last_activity),
        "investigations" => Dict{String, Any}(),
        "memory_health" => Dict{String, Any}(),
        "performance" => Dict{String, Any}(),
        "issues" => []
    )

    # Check agent status
    current_time = now()
    time_since_activity = current_time - agent.last_activity

    if agent.status == AgentCore.RUNNING_STATE
        if time_since_activity > Hour(1)
            agent_health["status"] = "DEGRADED"
            push!(agent_health["issues"], "No activity for over 1 hour")
        else
            agent_health["status"] = "HEALTHY"
        end
    elseif agent.status == AgentCore.PAUSED_STATE
        agent_health["status"] = "DEGRADED"
        push!(agent_health["issues"], "Agent is paused")
    else
        agent_health["status"] = "UNHEALTHY"
        push!(agent_health["issues"], "Agent is not running")
    end

    # Check detective memory if available
    if isa(agent.memory, DetectiveMemory)
        memory_health = check_detective_memory_health(agent.memory)
        agent_health["memory_health"] = memory_health

        if haskey(memory_health, "issues")
            append!(agent_health["issues"], memory_health["issues"])
        end

        # Investigation statistics
        agent_health["investigations"]["total"] = length(agent.memory.investigation_history)

        # Recent investigation activity
        recent_investigations = filter(
            inv -> inv.created_at >= current_time - Hour(24),
            agent.memory.investigation_history
        )
        agent_health["investigations"]["last_24h"] = length(recent_investigations)

        # Success rate
        completed_investigations = filter(
            inv -> inv.status == :completed,
            agent.memory.investigation_history
        )

        if !isempty(agent.memory.investigation_history)
            success_rate = length(completed_investigations) / length(agent.memory.investigation_history)
            agent_health["investigations"]["success_rate"] = round(success_rate, digits=3)
        else
            agent_health["investigations"]["success_rate"] = 0.0
        end
    end

    # Record health metrics
    record_metric(agent.id, "agent_health_check", COUNTER, 1, Dict("status" => agent_health["status"]))

    return agent_health
end

"""
    check_detective_memory_health(memory::DetectiveMemory) -> Dict{String, Any}

Checks the health of detective memory.
"""
function check_detective_memory_health(memory::DetectiveMemory)
    memory_health = Dict{String, Any}(
        "investigation_count" => length(memory.investigation_history),
        "pattern_cache_size" => length(memory.pattern_cache),
        "last_investigation" => memory.last_investigation !== nothing ? string(memory.last_investigation) : "never",
        "issues" => []
    )

    # Check for memory issues
    max_cache_size = get_config("detective.pattern_cache_max_size", 1000)
    if length(memory.pattern_cache) >= max_cache_size
        push!(memory_health["issues"], "Pattern cache is at maximum size")
    end

    # Check for old investigations
    if memory.last_investigation !== nothing
        time_since_last = now() - memory.last_investigation
        if time_since_last > Day(7)
            push!(memory_health["issues"], "No investigations in the last 7 days")
        end
    else
        push!(memory_health["issues"], "No investigations recorded")
    end

    # Check for failed investigations
    failed_investigations = filter(
        inv -> inv.status == :failed,
        memory.investigation_history
    )

    if length(failed_investigations) > length(memory.investigation_history) * 0.3
        push!(memory_health["issues"], "High failure rate (>30%)")
    end

    return memory_health
end

"""
    monitor_investigation_performance() -> Dict{String, Any}

Monitors the performance of ongoing and recent investigations.
"""
function monitor_investigation_performance()
    performance_report = Dict{String, Any}(
        "ongoing_investigations" => [],
        "recent_completions" => [],
        "performance_alerts" => [],
        "avg_completion_time" => 0.0,
        "success_rate" => 0.0
    )

    current_time = now()
    all_investigations = []

    # Collect investigations from all detective agents
    lock(AGENTS_LOCK) do
        for (agent_id, agent) in AGENTS
            if isa(agent.memory, DetectiveMemory)
                for investigation in agent.memory.investigation_history
                    investigation_data = Dict{String, Any}(
                        "agent_id" => agent_id,
                        "investigation_id" => investigation.id,
                        "wallet_address" => investigation.wallet_address,
                        "status" => string(investigation.status),
                        "created_at" => investigation.created_at,
                        "completed_at" => investigation.completed_at
                    )

                    # Check for ongoing investigations
                    if investigation.status == :running
                        duration = current_time - investigation.created_at
                        investigation_data["duration_minutes"] = duration.value / (1000 * 60)
                        push!(performance_report["ongoing_investigations"], investigation_data)

                        # Alert for long-running investigations
                        if duration > Hour(1)
                            push!(performance_report["performance_alerts"],
                                "Investigation $(investigation.id) has been running for over 1 hour")
                        end
                    end

                    # Recent completions (last 24 hours)
                    if investigation.completed_at !== nothing &&
                       investigation.completed_at >= current_time - Hour(24)

                        completion_time = investigation.completed_at - investigation.created_at
                        investigation_data["completion_time_seconds"] = completion_time.value / 1000
                        push!(performance_report["recent_completions"], investigation_data)
                    end

                    push!(all_investigations, investigation_data)
                end
            end
        end
    end

    # Calculate performance metrics
    if !isempty(performance_report["recent_completions"])
        completion_times = [inv["completion_time_seconds"] for inv in performance_report["recent_completions"]]
        performance_report["avg_completion_time"] = sum(completion_times) / length(completion_times)

        successful = count(inv -> inv["status"] == "completed", performance_report["recent_completions"])
        performance_report["success_rate"] = successful / length(performance_report["recent_completions"])
    end

    return performance_report
end

"""
    detect_stalled_investigations() -> Vector{Dict{String, Any}}

Detects investigations that appear to be stalled.
"""
function detect_stalled_investigations()
    stalled_investigations = []
    current_time = now()
    stall_threshold = Hour(2)  # Consider investigations stalled after 2 hours

    lock(AGENTS_LOCK) do
        for (agent_id, agent) in AGENTS
            if isa(agent.memory, DetectiveMemory)
                for investigation in agent.memory.investigation_history
                    if investigation.status == :running
                        duration = current_time - investigation.created_at

                        if duration > stall_threshold
                            stalled_info = Dict{String, Any}(
                                "agent_id" => agent_id,
                                "investigation_id" => investigation.id,
                                "wallet_address" => investigation.wallet_address,
                                "duration_hours" => duration.value / (1000 * 60 * 60),
                                "created_at" => string(investigation.created_at),
                                "stall_severity" => duration > Hour(6) ? "CRITICAL" : "WARNING"
                            )

                            push!(stalled_investigations, stalled_info)

                            # Record stall metric
                            record_metric(agent_id, "stalled_investigation", COUNTER, 1,
                                Dict("severity" => stalled_info["stall_severity"]))
                        end
                    end
                end
            end
        end
    end

    return stalled_investigations
end

"""
    get_investigation_performance_metrics() -> Dict{String, Any}

Gets performance metrics for investigation system.
"""
function get_investigation_performance_metrics()
    metrics = Dict{String, Any}(
        "investigations_last_hour" => 0,
        "investigations_last_day" => 0,
        "avg_completion_time_minutes" => 0.0,
        "current_success_rate" => 0.0,
        "active_investigations" => 0,
        "stalled_investigations" => 0
    )

    current_time = now()
    one_hour_ago = current_time - Hour(1)
    one_day_ago = current_time - Hour(24)

    completion_times = Float64[]
    total_investigations = 0
    successful_investigations = 0

    lock(AGENTS_LOCK) do
        for (agent_id, agent) in AGENTS
            if isa(agent.memory, DetectiveMemory)
                for investigation in agent.memory.investigation_history
                    # Count investigations by time period
                    if investigation.created_at >= one_hour_ago
                        metrics["investigations_last_hour"] += 1
                    end

                    if investigation.created_at >= one_day_ago
                        metrics["investigations_last_day"] += 1
                        total_investigations += 1

                        if investigation.status == :completed
                            successful_investigations += 1

                            if investigation.completed_at !== nothing
                                completion_time = investigation.completed_at - investigation.created_at
                                push!(completion_times, completion_time.value / (1000 * 60))  # minutes
                            end
                        elseif investigation.status == :running
                            metrics["active_investigations"] += 1

                            # Check for stalled
                            if current_time - investigation.created_at > Hour(2)
                                metrics["stalled_investigations"] += 1
                            end
                        end
                    end
                end
            end
        end
    end

    # Calculate averages
    if !isempty(completion_times)
        metrics["avg_completion_time_minutes"] = sum(completion_times) / length(completion_times)
    end

    if total_investigations > 0
        metrics["current_success_rate"] = successful_investigations / total_investigations
    end

    return metrics
end

end # module AgentMonitor
