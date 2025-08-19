"""
Ghost Wallet Hunter - Configuration Management (Julia)

Julia-native configuration system with environment variable support,
type safety, and validation. Replaces Pydantic BaseSettings with
Julia-optimized configuration management.
"""

module Configuration

using Dates
using JSON3

# Configuration structure
mutable struct AppConfig
    # Application Info
    app_name::String
    app_version::String
    debug::Bool
    environment::String

    # Security
    secret_key::String
    algorithm::String
    access_token_expire_minutes::Int

    # Database
    database_url::String

    # AI Services
    openai_api_key::Union{String, Nothing}
    grok_api_key::Union{String, Nothing}

    # Solana
    solana_rpc_url::String
    solana_ws_url::String
    solana_network::String

    # CORS
    allowed_origins::Vector{String}
    allowed_methods::Vector{String}
    allowed_headers::Vector{String}

    # Rate Limiting
    rate_limit_requests::Int
    rate_limit_window::Int

    # Caching
    cache_ttl_seconds::Int
    cache_max_size::Int

    # Analysis Settings
    max_cluster_size::Int
    max_transaction_depth::Int
    suspicious_threshold::Float64
    min_connections_for_cluster::Int

    # JuliaOS Integration
    juliaos_base_url::String
    juliaos_api_key::Union{String, Nothing}
    juliaos_environment::String
    juliaos_enabled::Bool

    # A2A Protocol Integration
    a2a_host::String
    a2a_port::Int
    juliaos_timeout::Int
    juliaos_retry_attempts::Int
    juliaos_health_check_interval::Int

    # Performance Settings
    max_concurrent_requests::Int
    worker_threads::Int
    gc_optimization::Bool

    # Logging
    log_level::String
    log_file_path::String
    log_max_size_mb::Int

    # Constructor with defaults
    function AppConfig()
        new(
            # Application Info
            get_env("APP_NAME", "Ghost Wallet Hunter"),
            get_env("APP_VERSION", "0.2.0"),
            parse_bool(get_env("DEBUG", "true")),
            get_env("ENVIRONMENT", "development"),

            # Security
            get_env("SECRET_KEY", "change-this-secret-key-in-production"),
            get_env("ALGORITHM", "HS256"),
            parse_int(get_env("ACCESS_TOKEN_EXPIRE_MINUTES", "30")),

            # Database
            get_env("DATABASE_URL", "sqlite:///./ghost_wallet_hunter.db"),

            # AI Services
            get_env("OPENAI_API_KEY", nothing),
            get_env("GROK_API_KEY", nothing),

            # Solana
            get_env("SOLANA_RPC_URL", "https://api.mainnet-beta.solana.com"),
            get_env("SOLANA_WS_URL", "wss://api.mainnet-beta.solana.com"),
            get_env("SOLANA_NETWORK", "mainnet-beta"),

            # CORS
            parse_string_list(get_env("ALLOWED_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000")),
            parse_string_list(get_env("ALLOWED_METHODS", "GET,POST,PUT,DELETE,OPTIONS")),
            parse_string_list(get_env("ALLOWED_HEADERS", "*")),

            # Rate Limiting
            parse_int(get_env("RATE_LIMIT_REQUESTS", "100")),
            parse_int(get_env("RATE_LIMIT_WINDOW", "60")),

            # Caching
            parse_int(get_env("CACHE_TTL_SECONDS", "300")),
            parse_int(get_env("CACHE_MAX_SIZE", "1000")),

            # Analysis Settings
            parse_int(get_env("MAX_CLUSTER_SIZE", "50")),
            parse_int(get_env("MAX_TRANSACTION_DEPTH", "10")),
            parse_float(get_env("SUSPICIOUS_THRESHOLD", "0.7")),
            parse_int(get_env("MIN_CONNECTIONS_FOR_CLUSTER", "3")),

            # JuliaOS Integration
            get_env("JULIAOS_BASE_URL", "http://localhost:10000"),
            get_env("JULIAOS_API_KEY", nothing),
            get_env("JULIAOS_ENVIRONMENT", "development"),
            parse_bool(get_env("JULIAOS_ENABLED", "true")),

            # A2A Protocol Integration
            get_env("A2A_HOST", "localhost"),
            parse_int(get_env("A2A_PORT", "9100")),
            parse_int(get_env("JULIAOS_TIMEOUT", "30")),
            parse_int(get_env("JULIAOS_RETRY_ATTEMPTS", "3")),
            parse_int(get_env("JULIAOS_HEALTH_CHECK_INTERVAL", "60")),

            # Performance Settings
            parse_int(get_env("MAX_CONCURRENT_REQUESTS", "100")),
            parse_int(get_env("WORKER_THREADS", string(Threads.nthreads()))),
            parse_bool(get_env("GC_OPTIMIZATION", "true")),

            # Logging
            get_env("LOG_LEVEL", "INFO"),
            get_env("LOG_FILE_PATH", "logs/ghost_wallet_hunter.log"),
            parse_int(get_env("LOG_MAX_SIZE_MB", "100"))
        )
    end
end

# Helper functions for environment variable parsing
function get_env(key::String, default_value::Union{String, Nothing} = nothing)::Union{String, Nothing}
    value = get(ENV, key, nothing)
    return isnothing(value) ? default_value : value
end

function parse_bool(value::Union{String, Nothing})::Bool
    isnothing(value) && return false
    lowercase_value = lowercase(strip(value))
    return lowercase_value in ["true", "1", "yes", "on"]
end

function parse_int(value::Union{String, Nothing})::Int
    isnothing(value) && return 0
    try
        return parse(Int, strip(value))
    catch
        return 0
    end
end

function parse_float(value::Union{String, Nothing})::Float64
    isnothing(value) && return 0.0
    try
        return parse(Float64, strip(value))
    catch
        return 0.0
    end
end

function parse_string_list(value::Union{String, Nothing})::Vector{String}
    isnothing(value) && return String[]
    return [strip(item) for item in split(value, ',') if !isempty(strip(item))]
end

# Global configuration instance
const CONFIG = Ref{Union{AppConfig, Nothing}}(nothing)

"""
Get the global configuration instance.
Creates a new instance if one doesn't exist.
"""
function get_config()::AppConfig
    if isnothing(CONFIG[])
        CONFIG[] = AppConfig()
    end
    return CONFIG[]
end

"""
Get the current environment (e.g., 'development', 'production').
"""
function get_environment()::String
    return get_config().environment
end

"""
Reload configuration from environment variables.
"""
function reload_config!()::AppConfig
    CONFIG[] = AppConfig()
    println("✅ Configuration reloaded from environment variables")
    return CONFIG[]
end

"""
Get JuliaOS URL based on environment.
"""
function get_juliaos_url(config::AppConfig = get_config())::String
    if config.environment == "production"
        return "https://ghost-julia.onrender.com"
    else
        return config.juliaos_base_url
    end
end

"""
Get A2A URL based on environment.
"""
function get_a2a_url(config::AppConfig = get_config())::String
    if config.environment == "production"
        return "https://ghost-wallet-hunter-a2a.onrender.com"
    else
        protocol = config.a2a_port == 443 ? "https" : "http"
        return "$(protocol)://$(config.a2a_host):$(config.a2a_port)"
    end
end

"""
Validate configuration settings.
"""
function validate_config(config::AppConfig = get_config())::Dict{String, Any}
    validation_results = Dict{String, Any}()
    errors = String[]
    warnings = String[]

    # Check required settings
    if isempty(config.app_name)
        push!(errors, "APP_NAME cannot be empty")
    end

    if config.environment == "production" && config.secret_key == "change-this-secret-key-in-production"
        push!(errors, "SECRET_KEY must be changed in production")
    end

    if isnothing(config.openai_api_key) && isnothing(config.grok_api_key)
        push!(warnings, "No AI API keys configured - AI features will be limited")
    end

    # Validate numeric ranges
    if config.max_cluster_size <= 0
        push!(errors, "MAX_CLUSTER_SIZE must be positive")
    end

    if !(0.0 <= config.suspicious_threshold <= 1.0)
        push!(errors, "SUSPICIOUS_THRESHOLD must be between 0.0 and 1.0")
    end

    if config.rate_limit_requests <= 0
        push!(errors, "RATE_LIMIT_REQUESTS must be positive")
    end

    # Validate URLs
    if !startswith(config.solana_rpc_url, "http")
        push!(errors, "SOLANA_RPC_URL must be a valid HTTP URL")
    end

    validation_results["valid"] = isempty(errors)
    validation_results["errors"] = errors
    validation_results["warnings"] = warnings
    validation_results["timestamp"] = string(now())

    return validation_results
end

"""
Get configuration as a dictionary for logging/debugging.
"""
function config_to_dict(config::AppConfig = get_config())::Dict{String, Any}
    return Dict(
        "app_name" => config.app_name,
        "app_version" => config.app_version,
        "debug" => config.debug,
        "environment" => config.environment,
        "solana_network" => config.solana_network,
        "juliaos_enabled" => config.juliaos_enabled,
        "max_cluster_size" => config.max_cluster_size,
        "max_transaction_depth" => config.max_transaction_depth,
        "suspicious_threshold" => config.suspicious_threshold,
        "rate_limit_requests" => config.rate_limit_requests,
        "cache_ttl_seconds" => config.cache_ttl_seconds,
        "worker_threads" => config.worker_threads,
        "log_level" => config.log_level,
        # Exclude sensitive information
        "has_openai_key" => !isnothing(config.openai_api_key),
        "has_grok_key" => !isnothing(config.grok_api_key),
        "has_juliaos_key" => !isnothing(config.juliaos_api_key)
    )
end

"""
Save current configuration to JSON file.
"""
function save_config_to_file(filepath::String, config::AppConfig = get_config())::Bool
    try
        config_dict = config_to_dict(config)
        config_dict["saved_at"] = string(now())

        open(filepath, "w") do file
            JSON3.pretty(file, config_dict)
        end

        println("✅ Configuration saved to: $filepath")
        return true

    catch e
        println("❌ Error saving configuration: $e")
        return false
    end
end

"""
Load configuration from JSON file (for reference only - env vars take precedence).
"""
function load_config_from_file(filepath::String)::Union{Dict{String, Any}, Nothing}
    try
        if isfile(filepath)
            content = read(filepath, String)
            return JSON3.read(content, Dict{String, Any})
        else
            println("⚠️ Configuration file not found: $filepath")
            return nothing
        end
    catch e
        println("❌ Error loading configuration file: $e")
        return nothing
    end
end

"""
Get environment-specific database URL.
"""
function get_database_url(config::AppConfig = get_config())::String
    if config.environment == "production"
        # In production, you might use PostgreSQL or another database
        return get_env("DATABASE_URL", "postgresql://user:pass@host:5432/dbname")
    else
        return config.database_url
    end
end

"""
Get performance-optimized settings based on system capabilities.
"""
function get_performance_settings(config::AppConfig = get_config())::Dict{String, Any}
    # Detect system capabilities
    available_threads = Threads.nthreads()
    total_memory_gb = Sys.total_memory() / (1024^3)

    # Optimize settings based on system
    optimized_settings = Dict{String, Any}(
        "worker_threads" => min(config.worker_threads, available_threads),
        "max_concurrent_requests" => min(config.max_concurrent_requests, available_threads * 10),
        "cache_max_size" => min(config.cache_max_size, Int(floor(total_memory_gb * 100))),
        "gc_optimization" => config.gc_optimization,
        "recommended_threads" => available_threads,
        "system_memory_gb" => round(total_memory_gb, digits=2)
    )

    return optimized_settings
end

"""
Print configuration summary.
"""
function print_config_summary(config::AppConfig = get_config())
    println("🚀 Ghost Wallet Hunter Configuration Summary")
    println("=" ^ 50)
    println("App Name: $(config.app_name) v$(config.app_version)")
    println("Environment: $(config.environment)")
    println("Debug Mode: $(config.debug)")
    println("Solana Network: $(config.solana_network)")
    println("JuliaOS Enabled: $(config.juliaos_enabled)")
    println("AI Keys Available: OpenAI=$(!isnothing(config.openai_api_key)), Grok=$((!isnothing(config.grok_api_key)))")
    println("Worker Threads: $(config.worker_threads)")
    println("Cache TTL: $(config.cache_ttl_seconds)s")
    println("Rate Limit: $(config.rate_limit_requests) req/$(config.rate_limit_window)s")
    println("=" ^ 50)
end

"""
Health check for configuration module.
"""
function health_check()::Dict{String, Any}
    config = get_config()
    validation = validate_config(config)

    return Dict(
        "status" => validation["valid"] ? "operational" : "configuration_errors",
        "module" => "Configuration",
        "environment" => config.environment,
        "validation_passed" => validation["valid"],
        "errors_count" => length(validation["errors"]),
        "warnings_count" => length(validation["warnings"]),
        "timestamp" => string(now())
    )
end

# Export main functions
export AppConfig,
       get_config,
       get_environment,
       reload_config!,
       get_juliaos_url,
       get_a2a_url,
       validate_config,
       config_to_dict,
       save_config_to_file,
       load_config_from_file,
       get_database_url,
       get_performance_settings,
       print_config_summary,
       health_check

end # module Configuration
