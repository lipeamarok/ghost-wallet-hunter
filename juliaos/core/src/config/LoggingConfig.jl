"""
Ghost Wallet Hunter - Logging Configuration (Julia)

Julia-native logging system with enhanced performance, structured logging,
file rotation, and integration with the configuration system.
"""

module LoggingConfig

using Logging
using Dates
using JSON3
using Printf

# Include configuration module
include("Configuration.jl")
using .Configuration

# Custom log levels
const TRACE = Logging.LogLevel(-100)
const PERFORMANCE = Logging.LogLevel(450)  # Between Warn and Error

# Log formatters
abstract type LogFormatter end

struct ConsoleFormatter <: LogFormatter
    colorized::Bool
    timestamp_format::String

    function ConsoleFormatter(colorized::Bool = true, timestamp_format::String = "yyyy-mm-dd HH:MM:SS")
        new(colorized, timestamp_format)
    end
end

struct FileFormatter <: LogFormatter
    json_format::Bool
    timestamp_format::String

    function FileFormatter(json_format::Bool = false, timestamp_format::String = "yyyy-mm-dd HH:MM:SS.sss")
        new(json_format, timestamp_format)
    end
end

# Custom log record structure
mutable struct LogRecord
    timestamp::DateTime
    level::Logging.LogLevel
    module_name::String
    function_name::String
    message::String
    metadata::Dict{String, Any}
    thread_id::Int

    function LogRecord(level::Logging.LogLevel, module_name::String, function_name::String,
                      message::String, metadata::Dict{String, Any} = Dict{String, Any}())
        new(now(), level, module_name, function_name, message, metadata, Threads.threadid())
    end
end

# File handler with rotation
mutable struct RotatingFileHandler
    filepath::String
    max_size_mb::Int
    backup_count::Int
    current_size::Int
    file_handle::Union{IO, Nothing}
    formatter::LogFormatter

    function RotatingFileHandler(filepath::String, max_size_mb::Int = 100,
                                backup_count::Int = 5, formatter::LogFormatter = FileFormatter())
        # Create directory if it doesn't exist
        dir = dirname(filepath)
        if !isdir(dir) && !isempty(dir)
            mkpath(dir)
        end

        handler = new(filepath, max_size_mb, backup_count, 0, nothing, formatter)

        # Initialize file and get current size
        if isfile(filepath)
            handler.current_size = filesize(filepath)
        end

        handler
    end
end

# Global logger state
mutable struct GhostLogger
    console_handler::Union{ConsoleFormatter, Nothing}
    file_handler::Union{RotatingFileHandler, Nothing}
    min_level::Logging.LogLevel
    performance_tracking::Bool
    context_stack::Vector{String}

    function GhostLogger()
        new(nothing, nothing, Logging.Info, false, String[])
    end
end

const GHOST_LOGGER = Ref{GhostLogger}(GhostLogger())

"""
Configure logging system based on configuration.
"""
function setup_logging(config::AppConfig = Configuration.get_config())
    logger = GHOST_LOGGER[]

    # Parse log level
    level_str = uppercase(config.log_level)
    min_level = if level_str == "TRACE"
        TRACE
    elseif level_str == "DEBUG"
        Logging.Debug
    elseif level_str == "INFO"
        Logging.Info
    elseif level_str == "WARN"
        Logging.Warn
    elseif level_str == "ERROR"
        Logging.Error
    else
        Logging.Info
    end

    logger.min_level = min_level

    # Setup console handler
    logger.console_handler = ConsoleFormatter(config.debug)

    # Setup file handler if log file path is specified
    if !isempty(config.log_file_path)
        logger.file_handler = RotatingFileHandler(
            config.log_file_path,
            config.log_max_size_mb,
            5,  # backup_count
            FileFormatter(true)  # JSON format for files
        )
    end

    # Enable performance tracking in debug mode
    logger.performance_tracking = config.debug

    println("✅ Logging configured - Level: $(level_str), File: $(config.log_file_path)")

    return logger
end

"""
Format timestamp for display.
"""
function format_timestamp(dt::DateTime, format::String)::String
    return Dates.format(dt, format)
end

"""
Get color code for log level (console output).
"""
function get_level_color(level::Logging.LogLevel)::String
    if level == TRACE
        return "\033[90m"  # Dark gray
    elseif level == Logging.Debug
        return "\033[36m"  # Cyan
    elseif level == Logging.Info
        return "\033[32m"  # Green
    elseif level == Logging.Warn
        return "\033[33m"  # Yellow
    elseif level == Logging.Error
        return "\033[31m"  # Red
    elseif level == PERFORMANCE
        return "\033[35m"  # Magenta
    else
        return "\033[0m"   # Reset
    end
end

"""
Format log record for console output.
"""
function format_console(record::LogRecord, formatter::ConsoleFormatter)::String
    timestamp_str = format_timestamp(record.timestamp, formatter.timestamp_format)
    level_str = string(record.level)

    if formatter.colorized
        color = get_level_color(record.level)
        reset = "\033[0m"
        formatted = "$(color)[$(timestamp_str)] $(uppercase(level_str)) - $(record.module_name).$(record.function_name): $(record.message)$(reset)"
    else
        formatted = "[$(timestamp_str)] $(uppercase(level_str)) - $(record.module_name).$(record.function_name): $(record.message)"
    end

    # Add metadata if present
    if !isempty(record.metadata)
        metadata_str = join(["$(k)=$(v)" for (k, v) in record.metadata], ", ")
        formatted *= " | $(metadata_str)"
    end

    return formatted
end

"""
Format log record for file output.
"""
function format_file(record::LogRecord, formatter::FileFormatter)::String
    if formatter.json_format
        log_data = Dict(
            "timestamp" => format_timestamp(record.timestamp, formatter.timestamp_format),
            "level" => string(record.level),
            "module" => record.module_name,
            "function" => record.function_name,
            "message" => record.message,
            "thread_id" => record.thread_id,
            "metadata" => record.metadata
        )
        return JSON3.write(log_data)
    else
        timestamp_str = format_timestamp(record.timestamp, formatter.timestamp_format)
        level_str = string(record.level)
        formatted = "[$(timestamp_str)] $(uppercase(level_str)) - $(record.module_name).$(record.function_name): $(record.message)"

        if !isempty(record.metadata)
            metadata_str = join(["$(k)=$(v)" for (k, v) in record.metadata], ", ")
            formatted *= " | $(metadata_str)"
        end

        return formatted
    end
end

"""
Rotate log file if it exceeds maximum size.
"""
function rotate_file_if_needed(handler::RotatingFileHandler)
    if handler.current_size >= handler.max_size_mb * 1024 * 1024
        # Close current file
        if !isnothing(handler.file_handle)
            close(handler.file_handle)
            handler.file_handle = nothing
        end

        # Rotate existing backup files
        for i in handler.backup_count:-1:1
            old_file = "$(handler.filepath).$(i)"
            new_file = "$(handler.filepath).$(i+1)"

            if isfile(old_file)
                if i == handler.backup_count
                    rm(old_file)  # Remove oldest backup
                else
                    mv(old_file, new_file)
                end
            end
        end

        # Move current file to .1
        if isfile(handler.filepath)
            mv(handler.filepath, "$(handler.filepath).1")
        end

        # Reset size counter
        handler.current_size = 0

        println("📝 Log file rotated: $(handler.filepath)")
    end
end

"""
Write log record to file.
"""
function write_to_file(handler::RotatingFileHandler, record::LogRecord)
    try
        # Check if rotation is needed
        rotate_file_if_needed(handler)

        # Open file if not already open
        if isnothing(handler.file_handle)
            handler.file_handle = open(handler.filepath, "a")
        end

        # Format and write record
        formatted_message = format_file(record, handler.formatter)
        write(handler.file_handle, formatted_message * "\n")
        flush(handler.file_handle)

        # Update size counter
        handler.current_size += length(formatted_message) + 1

    catch e
        println("❌ Error writing to log file: $e")
    end
end

"""
Main logging function.
"""
function log_message(level::Logging.LogLevel, module_name::String, function_name::String,
                    message::String, metadata::Dict{String, Any} = Dict{String, Any}())
    logger = GHOST_LOGGER[]

    # Check if level is enabled
    if level < logger.min_level
        return
    end

    # Create log record
    record = LogRecord(level, module_name, function_name, message, metadata)

    # Add context if available
    if !isempty(logger.context_stack)
        record.metadata["context"] = join(logger.context_stack, " → ")
    end

    # Output to console
    if !isnothing(logger.console_handler)
        console_output = format_console(record, logger.console_handler)
        println(console_output)
    end

    # Output to file
    if !isnothing(logger.file_handler)
        write_to_file(logger.file_handler, record)
    end
end

"""
Convenience logging functions.
"""
function log_trace(module_name::String, function_name::String, message::String, metadata::Dict{String, Any} = Dict{String, Any}())
    log_message(TRACE, module_name, function_name, message, metadata)
end

function log_debug(module_name::String, function_name::String, message::String, metadata::Dict{String, Any} = Dict{String, Any}())
    log_message(Logging.Debug, module_name, function_name, message, metadata)
end

function log_info(module_name::String, function_name::String, message::String, metadata::Dict{String, Any} = Dict{String, Any}())
    log_message(Logging.Info, module_name, function_name, message, metadata)
end

function log_warn(module_name::String, function_name::String, message::String, metadata::Dict{String, Any} = Dict{String, Any}())
    log_message(Logging.Warn, module_name, function_name, message, metadata)
end

function log_error(module_name::String, function_name::String, message::String, metadata::Dict{String, Any} = Dict{String, Any}())
    log_message(Logging.Error, module_name, function_name, message, metadata)
end

function log_performance(module_name::String, function_name::String, message::String, metadata::Dict{String, Any} = Dict{String, Any}())
    log_message(PERFORMANCE, module_name, function_name, message, metadata)
end

"""
Performance timing decorator.
"""
macro timed_log(module_name, function_name, expr)
    quote
        logger = GHOST_LOGGER[]
        if logger.performance_tracking
            start_time = time()
            result = $(esc(expr))
            elapsed = time() - start_time

            log_performance(
                $(esc(module_name)),
                $(esc(function_name)),
                "Function executed successfully",
                Dict("execution_time_ms" => round(elapsed * 1000, digits=3))
            )

            result
        else
            $(esc(expr))
        end
    end
end

"""
Context manager for structured logging.
"""
function with_context(f::Function, context::String)
    logger = GHOST_LOGGER[]
    push!(logger.context_stack, context)

    try
        return f()
    finally
        pop!(logger.context_stack)
    end
end

"""
Log function entry and exit.
"""
macro log_function(module_name, function_name)
    quote
        log_trace($(esc(module_name)), $(esc(function_name)), "Function entered")
        try
            result = yield
            log_trace($(esc(module_name)), $(esc(function_name)), "Function completed")
            result
        catch e
            log_error($(esc(module_name)), $(esc(function_name)), "Function failed: $e")
            rethrow(e)
        end
    end
end

"""
Structured logging for API requests.
"""
function log_api_request(method::String, path::String, status_code::Int,
                        duration_ms::Float64, metadata::Dict{String, Any} = Dict{String, Any}())
    metadata_with_request = merge(metadata, Dict(
        "method" => method,
        "path" => path,
        "status_code" => status_code,
        "duration_ms" => round(duration_ms, digits=3)
    ))

    level = if status_code >= 500
        Logging.Error
    elseif status_code >= 400
        Logging.Warn
    else
        Logging.Info
    end

    log_message(level, "API", "request", "$(method) $(path) → $(status_code)", metadata_with_request)
end

"""
Log system metrics.
"""
function log_system_metrics()
    try
        gc_stats = Base.gc_num()
        memory_mb = Sys.maxrss() / 1024 / 1024

        metadata = Dict(
            "memory_usage_mb" => round(memory_mb, digits=2),
            "gc_collections" => gc_stats.total_time,
            "active_threads" => Threads.nthreads(),
            "current_thread" => Threads.threadid()
        )

        log_info("System", "metrics", "System performance metrics", metadata)

    catch e
        log_error("System", "metrics", "Failed to collect system metrics: $e")
    end
end

"""
Close all log handlers.
"""
function close_logging()
    logger = GHOST_LOGGER[]

    if !isnothing(logger.file_handler) && !isnothing(logger.file_handler.file_handle)
        close(logger.file_handler.file_handle)
        logger.file_handler.file_handle = nothing
        println("📝 Log file closed")
    end
end

"""
Health check for logging system.
"""
function health_check()::Dict{String, Any}
    logger = GHOST_LOGGER[]

    status = "operational"
    issues = String[]

    # Check console handler
    console_ok = !isnothing(logger.console_handler)

    # Check file handler
    file_ok = true
    if !isnothing(logger.file_handler)
        try
            # Test write access
            test_record = LogRecord(Logging.Info, "HealthCheck", "test", "Health check test")
            write_to_file(logger.file_handler, test_record)
        catch e
            file_ok = false
            push!(issues, "File logging error: $e")
            status = "degraded"
        end
    end

    return Dict(
        "status" => status,
        "module" => "LoggingConfig",
        "console_handler" => console_ok,
        "file_handler" => !isnothing(logger.file_handler),
        "file_writable" => file_ok,
        "min_level" => string(logger.min_level),
        "performance_tracking" => logger.performance_tracking,
        "issues" => issues,
        "timestamp" => string(now())
    )
end

"""
Get logging statistics.
"""
function get_logging_stats()::Dict{String, Any}
    logger = GHOST_LOGGER[]

    stats = Dict{String, Any}(
        "min_level" => string(logger.min_level),
        "performance_tracking" => logger.performance_tracking,
        "context_depth" => length(logger.context_stack),
        "console_enabled" => !isnothing(logger.console_handler),
        "file_enabled" => !isnothing(logger.file_handler)
    )

    # File handler stats
    if !isnothing(logger.file_handler)
        stats["file_path"] = logger.file_handler.filepath
        stats["file_size_mb"] = round(logger.file_handler.current_size / (1024 * 1024), digits=2)
        stats["max_file_size_mb"] = logger.file_handler.max_size_mb
        stats["backup_count"] = logger.file_handler.backup_count
    end

    return stats
end

# Export main functions
export setup_logging,
       log_trace, log_debug, log_info, log_warn, log_error, log_performance,
       @timed_log, with_context, @log_function,
       log_api_request, log_system_metrics,
       close_logging, health_check, get_logging_stats,
       TRACE, PERFORMANCE

end # module LoggingConfig
