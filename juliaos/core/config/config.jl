module Config

using TOML, Logging

export load, get_value, load_detective_config, get_detective_config, get_blockchain_config
export get_investigation_config, validate_detective_config, create_detective_runtime_config
export get_config, set_config

# Thread-safe configuration management
const CONFIG_LOCK = ReentrantLock()
const CURRENT_CONFIG = Dict{String, Any}()

# Environment variable prefix for overrides
const ENV_VAR_PREFIX = "JULIAOS_"

# Default configuration
const DEFAULT_CONFIG = Dict(
    "api" => Dict(
        "host" => "127.0.0.1",
        "port" => 8052,
        "log_level" => "info"
    ),
    "storage" => Dict(
        "local_db_path" => joinpath(homedir(), ".juliaos", "juliaos.sqlite"),
        "arweave_wallet_file" => get(ENV, "ARWEAVE_WALLET_FILE", ""),
        "arweave_gateway" => get(ENV, "ARWEAVE_GATEWAY", "arweave.net"),
        "arweave_port" => parse(Int, get(ENV, "ARWEAVE_PORT", "443")),
        "arweave_protocol" => get(ENV, "ARWEAVE_PROTOCOL", "https"),
        "arweave_timeout" => parse(Int, get(ENV, "ARWEAVE_TIMEOUT", "20000")),
        "arweave_logging" => parse(Bool, get(ENV, "ARWEAVE_LOGGING", "false"))
    ),
    "blockchain" => Dict(
        "default_chain" => "ethereum",
        "rpc_urls" => Dict(
            "ethereum" => "https://mainnet.infura.io/v3/YOUR_API_KEY",
            "polygon" => "https://polygon-rpc.com",
            "solana" => "https://api.mainnet-beta.solana.com"
        ),
        "max_gas_price" => 100.0,
        "max_slippage" => 0.01,
        "supported_chains" => ["ethereum", "polygon", "solana"]
    ),
    "swarm" => Dict(
        "default_algorithm" => "DE",
        "default_population_size" => 50,
        "max_iterations" => 1000,
        "parallel_evaluation" => true
    ),
    "security" => Dict(
        "rate_limit" => 100,  # requests per minute
        "max_request_size" => 1048576,  # 1MB
        "enable_authentication" => true, # Enabled by default
        "api_keys" => ["default-secret-key-please-change"] # List of valid API keys
    ),
    "bridge" => Dict(
        "port" => 8052,
        "host" => "localhost",
        "bridge_api_url" => "http://localhost:3001/api/v1"
    ),

    "wormhole" => Dict(
        "enabled" => true,
        "network" => "testnet",
        "networks" => Dict(
            "ethereum" => Dict(
                "rpcUrl" => "https://goerli.infura.io/v3/your-infura-key",
                "enabled" => true
            ),
            "solana" => Dict(
                "rpcUrl" => "https://api.devnet.solana.com",
                "enabled" => true
            )
        )
    ),
    "detective" => Dict(
        "investigation_timeout" => 300,  # 5 minutes max per investigation
        "max_concurrent_investigations" => 10,
        "pattern_cache_max_size" => 1000,
        "memory_retention_days" => 30,
        "blockchain_analysis" => Dict(
            "max_transaction_depth" => 100,
            "suspicious_amount_threshold" => 1000000,  # 1M USD
            "quick_scan_transaction_limit" => 50,
            "deep_scan_transaction_limit" => 500,
            "pattern_confidence_threshold" => 0.7
        ),
        "ai_analysis" => Dict(
            "enabled" => true,
            "model" => "gpt-4",
            "max_tokens" => 4000,
            "temperature" => 0.1,  # Low temperature for more consistent analysis
            "analysis_depth" => "comprehensive"  # quick, standard, comprehensive
        ),
        "detection_rules" => Dict(
            "min_suspicious_score" => 0.6,
            "ghost_wallet_indicators" => [
                "high_frequency_small_transactions",
                "circular_transaction_patterns",
                "unusual_gas_patterns",
                "cross_chain_obfuscation",
                "temporal_clustering"
            ],
            "alert_thresholds" => Dict(
                "high_risk" => 0.8,
                "medium_risk" => 0.6,
                "low_risk" => 0.4
            )
        ),
        "agents" => Dict(
            "poirot" => Dict(
                "specialty" => "meticulous_analysis",
                "transaction_depth" => 100,
                "pattern_focus" => ["methodical_patterns", "logical_sequences"]
            ),
            "marple" => Dict(
                "specialty" => "intuitive_detection",
                "social_analysis" => true,
                "community_patterns" => true
            ),
            "spade" => Dict(
                "specialty" => "hard_boiled_investigation",
                "aggressive_scanning" => true,
                "deep_blockchain_analysis" => true
            ),
            "marlowee" => Dict(
                "specialty" => "cynical_analysis",
                "corruption_detection" => true,
                "power_structure_analysis" => true
            ),
            "dupin" => Dict(
                "specialty" => "analytical_reasoning",
                "mathematical_analysis" => true,
                "statistical_patterns" => true
            ),
            "shadow" => Dict(
                "specialty" => "stealth_investigation",
                "covert_patterns" => true,
                "hidden_connections" => true
            ),
            "raven" => Dict(
                "specialty" => "dark_psychology",
                "behavioral_analysis" => true,
                "psychological_profiling" => true
            )
        )
    ),
    "logging" => Dict(
        "level" => "info",
        "format" => "json",
        "retention_days" => 7
    )
)

# Configuration object with dot notation access
struct Configuration
    data::Dict{String, Any}

    # Constructor that allows dot notation access to nested dictionaries
    function Configuration(data::Dict)
        new(convert(Dict{String, Any}, data))
    end

    # Allow dot notation access
    function Base.getproperty(config::Configuration, key::Symbol)
        key_str = String(key)
        if key_str == "data"
            return getfield(config, :data)
        elseif haskey(config.data, key_str)
            value = config.data[key_str]
            if value isa Dict{String, Any}
                return Configuration(value)
            else
                return value
            end
        else
            error("Configuration key not found: $key_str")
        end
    end

    # Check if a key exists
    function Base.haskey(config::Configuration, key::Symbol)
        key_str = String(key)
        return haskey(config.data, key_str)
    end

    # Allow string indexing like config["key"]
    function Base.getindex(config::Configuration, key::String)
        if haskey(config.data, key)
            value = config.data[key]
            if value isa Dict{String, Any}
                return Configuration(value)
            else
                return value
            end
        else
            error("Configuration key not found: $key")
        end
    end

    # Check if a string key exists
    function Base.haskey(config::Configuration, key::String)
        return haskey(config.data, key)
    end
end

"""
    load_detective_config(config_path=nothing)

Load detective configuration from TOML files with thread-safe access.
Environment variables take precedence over file configuration.
"""
function load_detective_config(config_path=nothing)
    actual_config_path = ""

    if !isnothing(config_path) && isfile(config_path)
        actual_config_path = config_path
    else
        # 1. Check project's config directory
        path_in_project = joinpath(@__DIR__, "detective.toml")
        # 2. Check user's home directory
        path_in_home = joinpath(homedir(), ".juliaos", "config", "detective.toml")
        # 3. Fallback to main config
        path_main_config = joinpath(@__DIR__, "config.toml")

        if isfile(path_in_project)
            actual_config_path = path_in_project
        elseif isfile(path_in_home)
            actual_config_path = path_in_home
        elseif isfile(path_main_config)
            actual_config_path = path_main_config
        end
    end

    if !isempty(actual_config_path) && isfile(actual_config_path)
        try
            @info "Loading detective configuration from: $actual_config_path"
            config_data_from_file = TOML.parsefile(actual_config_path)

            lock(CONFIG_LOCK) do
                # Reset CURRENT_CONFIG to defaults before merging
                empty!(CURRENT_CONFIG)
                merge!(CURRENT_CONFIG, deepcopy(DEFAULT_CONFIG))
                _recursive_merge!(CURRENT_CONFIG, config_data_from_file)
            end
            @info "Successfully loaded detective configuration from $actual_config_path"
            return Configuration(CURRENT_CONFIG)
        catch e
            @error "Failed to load detective configuration from $actual_config_path. Using defaults." exception=(e, catch_backtrace())
            lock(CONFIG_LOCK) do
                if !isequal(CURRENT_CONFIG, DEFAULT_CONFIG)
                    empty!(CURRENT_CONFIG)
                    merge!(CURRENT_CONFIG, deepcopy(DEFAULT_CONFIG))
                end
            end
            return Configuration(DEFAULT_CONFIG)
        end
    else
        @info "No detective configuration file found. Using default configuration."
        lock(CONFIG_LOCK) do
            if !isequal(CURRENT_CONFIG, DEFAULT_CONFIG)
                empty!(CURRENT_CONFIG)
                merge!(CURRENT_CONFIG, deepcopy(DEFAULT_CONFIG))
            end
        end
        return Configuration(DEFAULT_CONFIG)
    end
end

"""
    _recursive_merge!(target::Dict, source::Dict)

Recursively merges source Dict into target Dict.
Values in source overwrite values in target.
"""
function _recursive_merge!(target::Dict{String, Any}, source::Dict{String, Any})
    for (key, src_val) in source
        if isa(src_val, Dict) && haskey(target, key) && isa(target[key], Dict)
            _recursive_merge!(target[key], src_val)
        else
            target[key] = src_val
        end
    end
end

# More flexible fallback for different Dict types
function _recursive_merge!(target::Dict, source::Dict)
    for (key, src_val) in source
        if isa(src_val, Dict) && haskey(target, key) && isa(target[key], Dict)
            # Convert to compatible types and merge
            if isa(target[key], Dict{String, Any})
                _recursive_merge!(target[key], src_val)
            else
                # Convert target to Any and merge
                target_any = Dict{String, Any}(target[key])
                _recursive_merge!(target_any, src_val)
                target[key] = target_any
            end
        else
            target[key] = src_val
        end
    end
end

"""
    get_config() -> Configuration

Get the global configuration object.
"""
function get_config()
    # Use the global configuration loaded during module initialization
    if isdefined(Main, :JULIAOS_CONFIG) && Main.JULIAOS_CONFIG !== nothing
        return Main.JULIAOS_CONFIG
    else
        # Fallback: load configuration on demand
        return load_detective_config()
    end
end

"""
    get_config(key::String, default_value::Any=nothing)

Thread-safe retrieval of configuration values with environment variable support.
Checks environment variables first, then loaded configuration, then defaults.
"""
function get_config(key::String, default_value::Any=nothing)
    env_var_name = _construct_env_var_name(key)
    env_val_str = get(ENV, env_var_name, nothing)

    target_type_from_default = default_value !== nothing ? typeof(default_value) : nothing

    # Check environment variable first
    if env_val_str !== nothing
        parsed_env_val = _try_parse_to_type(env_val_str, target_type_from_default)
        if parsed_env_val !== nothing
            return parsed_env_val
        else
            @warn "Environment variable $env_var_name could not be parsed. Ignoring."
        end
    end

    # Check current configuration
    parts = split(key, ".")
    current_dict_level = lock(CONFIG_LOCK) do
        deepcopy(CURRENT_CONFIG)
    end

    for part in parts[1:end-1]
        if haskey(current_dict_level, part) && isa(current_dict_level[part], Dict)
            current_dict_level = current_dict_level[part]
        else
            return default_value
        end
    end

    final_value = get(current_dict_level, parts[end], default_value)

    # Type coercion if needed
    if default_value !== nothing && final_value !== nothing && typeof(final_value) != typeof(default_value)
        coerced_value = _try_parse_to_type(string(final_value), typeof(default_value))
        return coerced_value !== nothing ? coerced_value : final_value
    end

    return final_value
end

"""
    set_config(key::String, value::Any)

Thread-safe setting of configuration values using dot notation.
Creates nested dictionaries if necessary.
"""
function set_config(key::String, value::Any)
    lock(CONFIG_LOCK) do
        parts = split(key, ".")
        current = CURRENT_CONFIG

        for part in parts[1:end-1]
            if !haskey(current, part) || !isa(current[part], Dict)
                current[part] = Dict{String, Any}()
            end
            current = current[part]
        end

        current[parts[end]] = value
        return value
    end
end

"""
    load(config_path=nothing)

Load configuration from environment variables and optionally from a TOML file.
Environment variables take precedence over file configuration.
"""
function load(config_path=nothing)
    # Start with default configuration
    config_data = deepcopy(DEFAULT_CONFIG)
    println("Starting to load configuration...")

    # Load from file if provided
    if !isnothing(config_path) && isfile(config_path)
        println("Attempting to load configuration from specified path: $config_path")
        try
            file_config = TOML.parsefile(config_path)
            println("Successfully loaded configuration from specified path")
            merge_configs!(config_data, file_config)
        catch e
            @warn "Failed to load configuration from specified path: $e"
        end
    elseif isfile(joinpath(@__DIR__, "config.toml"))
        println("Attempting to load configuration from default path: $(joinpath(@__DIR__, "config.toml"))")
        try
            file_config = TOML.parsefile(joinpath(@__DIR__, "config.toml"))
            println("Successfully loaded configuration from default path")
            merge_configs!(config_data, file_config)
        catch e
            @warn "Failed to load configuration from default path: $e"
        end
    else
        println("No configuration file found")
    end

    # Override with environment variables
    println("Starting to load configuration from environment variables...")
    override_from_env!(config_data)

    return Configuration(config_data)
end

"""
    merge_configs!(target, source)

Recursively merge source configuration into target.
"""
function merge_configs!(target::Dict, source::Dict)
    for (key, value) in source
        if haskey(target, key) && target[key] isa Dict && value isa Dict
            merge_configs!(target[key], value)
        else
            target[key] = value
        end
    end
end

"""
    override_from_env!(config)

Override configuration values from environment variables.
Environment variables should be in the format JULIAOS_SECTION_KEY.
"""
function override_from_env!(config::Dict)
    for (env_key, env_value) in ENV
        if startswith(env_key, "JULIAOS_")
            parts = split(env_key[9:end], "_")
            if length(parts) >= 2
                section = lowercase(parts[1])
                key = lowercase(join(parts[2:end], "_"))

                if haskey(config, section) && haskey(config[section], key)
                    # Convert value to the appropriate type
                    original_value = config[section][key]
                    if original_value isa Bool
                        config[section][key] = lowercase(env_value) in ["true", "1", "yes"]
                    elseif original_value isa Integer
                        config[section][key] = parse(Int, env_value)
                    elseif original_value isa AbstractFloat
                        config[section][key] = parse(Float64, env_value)
                    else
                        config[section][key] = env_value
                    end
                end
            end
        end
    end
end

"""
    get_value(config::Configuration, path::String, default=nothing)

Get a configuration value by path (e.g., "server.port").
Returns the default value if the path doesn't exist.
"""
function get_value(config::Configuration, path::String, default=nothing)
    parts = split(path, ".")
    current = config

    for part in parts
        if !haskey(current, Symbol(part))
            return default
        end
        current = getproperty(current, Symbol(part))
    end

    return current
end

# ----------------------------------------------------------------------
# DETECTIVE CONFIGURATION HELPERS
# ----------------------------------------------------------------------

"""
    get_detective_config(config::Configuration, detective_type::String="") -> Dict{String, Any}

Get detective-specific configuration. If detective_type is provided, returns
configuration for that specific detective, otherwise returns general detective config.

# Arguments
- `config::Configuration`: The main configuration object
- `detective_type::String`: Optional detective type ("poirot", "marple", etc.)

# Returns
- `Dict{String, Any}`: Detective configuration
"""
function get_detective_config(config::Configuration, detective_type::String="")
    # Get detective configuration section
    if !haskey(config, "detective")
        @warn "Detective configuration not found, using defaults"
        return Dict{String, Any}()
    end

    detective_config = config["detective"]

    if isempty(detective_type)
        # Return the raw data for general config
        return detective_config isa Configuration ? detective_config.data : detective_config
    end

    # Get specific detective config and merge with general config
    general_config = Dict{String, Any}()

    # Safely extract general config values
    detective_data = detective_config isa Configuration ? detective_config.data : detective_config

    for key in ["investigation_timeout", "pattern_cache_max_size", "blockchain_analysis", "ai_analysis", "detection_rules"]
        if haskey(detective_data, key)
            value = detective_data[key]
            general_config[key] = value isa Dict ? value : (value isa Configuration ? value.data : value)
        end
    end

    # Get specific detective config
    specific_config = Dict{String, Any}()
    if haskey(detective_data, "agents") && isa(detective_data["agents"], Dict)
        agents = detective_data["agents"]
        if haskey(agents, detective_type)
            agent_config = agents[detective_type]
            specific_config = agent_config isa Dict ? agent_config : (agent_config isa Configuration ? agent_config.data : Dict{String, Any}())
        end
    end

    return merge(general_config, specific_config)
end

# Convenience method with just detective type (uses global config)
function get_detective_config(detective_type::String)
    config = get_config()
    return get_detective_config(config, detective_type)
end

"""
    get_blockchain_config(config::Configuration, chain::String="solana") -> Dict{String, Any}

Get blockchain-specific configuration for detective investigations.

# Arguments
- `config::Configuration`: The main configuration object
- `chain::String`: Blockchain name (default: "solana")

# Returns
- `Dict{String, Any}`: Blockchain configuration
"""
function get_blockchain_config(config::Configuration, chain::String="solana")
    blockchain_config = get_value(config, "blockchain", Dict{String, Any}())
    detective_blockchain = get_value(config, "detective.blockchain_analysis", Dict{String, Any}())

    # Merge general blockchain config with detective-specific blockchain config
    merged_config = merge(blockchain_config, Dict("detective_analysis" => detective_blockchain))

    # Add chain-specific RPC if available
    rpc_urls = get(blockchain_config, "rpc_urls", Dict{String, Any}())
    if haskey(rpc_urls, chain)
        merged_config["rpc_url"] = rpc_urls[chain]
    end

    return merged_config
end

"""
    get_investigation_config(config::Configuration, investigation_type::String="standard") -> Dict{String, Any}

Get configuration for different types of investigations.

# Arguments
- `config::Configuration`: The main configuration object
- `investigation_type::String`: Type of investigation ("quick", "standard", "deep")

# Returns
- `Dict{String, Any}`: Investigation configuration
"""
function get_investigation_config(config::Configuration, investigation_type::String="standard")
    detective_config = get_detective_config(config)
    base_config = Dict{String, Any}()

    # Set investigation-specific parameters
    if investigation_type == "quick"
        base_config["timeout"] = get(detective_config, "investigation_timeout", 300) ÷ 3  # 1/3 of normal timeout
        base_config["transaction_limit"] = get(detective_config["blockchain_analysis"], "quick_scan_transaction_limit", 50)
        base_config["analysis_depth"] = "quick"
        base_config["ai_enabled"] = false  # Skip AI for quick scans

    elseif investigation_type == "deep"
        base_config["timeout"] = get(detective_config, "investigation_timeout", 300) * 3  # 3x normal timeout
        base_config["transaction_limit"] = get(detective_config["blockchain_analysis"], "deep_scan_transaction_limit", 500)
        base_config["analysis_depth"] = "comprehensive"
        base_config["ai_enabled"] = get(detective_config["ai_analysis"], "enabled", true)
        base_config["max_transaction_depth"] = get(detective_config["blockchain_analysis"], "max_transaction_depth", 100) * 2

    else  # standard
        base_config["timeout"] = get(detective_config, "investigation_timeout", 300)
        base_config["transaction_limit"] = 100  # Middle ground
        base_config["analysis_depth"] = "standard"
        base_config["ai_enabled"] = get(detective_config["ai_analysis"], "enabled", true)
        base_config["max_transaction_depth"] = get(detective_config["blockchain_analysis"], "max_transaction_depth", 100)
    end

    # Add common investigation settings
    base_config["pattern_confidence_threshold"] = get(detective_config["blockchain_analysis"], "pattern_confidence_threshold", 0.7)
    base_config["suspicious_amount_threshold"] = get(detective_config["blockchain_analysis"], "suspicious_amount_threshold", 1000000)
    base_config["detection_rules"] = get(detective_config, "detection_rules", Dict{String, Any}())

    return base_config
end

"""
    validate_detective_config(config::Configuration) -> Dict{String, Any}

Validates detective configuration and returns validation results.

# Arguments
- `config::Configuration`: The configuration to validate

# Returns
- `Dict{String, Any}`: Validation results with warnings and errors
"""
function validate_detective_config(config::Configuration)
    validation_results = Dict{String, Any}(
        "valid" => true,
        "warnings" => [],
        "errors" => []
    )

    detective_config = get_detective_config(config)

    # Check required detective configuration
    required_keys = ["investigation_timeout", "blockchain_analysis", "agents"]
    for key in required_keys
        if !haskey(detective_config, key)
            push!(validation_results["errors"], "Missing required detective configuration: $key")
            validation_results["valid"] = false
        end
    end

    # Validate timeout values
    timeout = get(detective_config, "investigation_timeout", 0)
    if timeout < 60
        push!(validation_results["warnings"], "Investigation timeout is very low: $(timeout)s")
    elseif timeout > 1800  # 30 minutes
        push!(validation_results["warnings"], "Investigation timeout is very high: $(timeout)s")
    end

    # Validate blockchain analysis config
    if haskey(detective_config, "blockchain_analysis")
        blockchain_config = detective_config["blockchain_analysis"]

        max_depth = get(blockchain_config, "max_transaction_depth", 0)
        if max_depth > 1000
            push!(validation_results["warnings"], "Very high transaction depth: $max_depth")
        end

        threshold = get(blockchain_config, "pattern_confidence_threshold", 0.5)
        if threshold > 0.95
            push!(validation_results["warnings"], "Very high confidence threshold may miss patterns: $threshold")
        elseif threshold < 0.3
            push!(validation_results["warnings"], "Very low confidence threshold may create false positives: $threshold")
        end
    end

    # Validate AI configuration
    ai_config = get(detective_config, "ai_analysis", Dict{String, Any}())
    if get(ai_config, "enabled", false)
        if !haskey(ai_config, "model")
            push!(validation_results["warnings"], "AI analysis enabled but no model specified")
        end

        max_tokens = get(ai_config, "max_tokens", 0)
        if max_tokens > 8000
            push!(validation_results["warnings"], "Very high max_tokens may be expensive: $max_tokens")
        end
    end

    # Validate detective agents configuration
    agents_config = get(detective_config, "agents", Dict{String, Any}())
    expected_detectives = ["poirot", "marple", "spade", "marlowee", "dupin", "shadow", "raven"]

    for detective in expected_detectives
        if !haskey(agents_config, detective)
            push!(validation_results["warnings"], "No configuration found for detective: $detective")
        end
    end

    return validation_results
end

"""
    create_detective_runtime_config(config::Configuration, detective_type::String, investigation_params::Dict{String, Any}=Dict()) -> Dict{String, Any}

Creates a runtime configuration for a specific detective investigation.

# Arguments
- `config::Configuration`: The main configuration
- `detective_type::String`: Type of detective
- `investigation_params::Dict`: Runtime investigation parameters

# Returns
- `Dict{String, Any}`: Complete runtime configuration for the investigation
"""
function create_detective_runtime_config(config::Configuration, detective_type::String, investigation_params::Dict{String, Any}=Dict())
    # Get base detective config
    detective_config = get_detective_config(config, detective_type)

    # Get investigation type from params or default to "standard"
    investigation_type = get(investigation_params, "investigation_type", "standard")
    investigation_config = get_investigation_config(config, investigation_type)

    # Get blockchain config
    blockchain_chain = get(investigation_params, "blockchain", "solana")
    blockchain_config = get_blockchain_config(config, blockchain_chain)

    # Merge all configurations
    runtime_config = merge(
        detective_config,
        investigation_config,
        Dict("blockchain" => blockchain_config),
        investigation_params  # Runtime params override everything
    )

    # Add metadata
    runtime_config["created_at"] = string(now())
    runtime_config["detective_type"] = detective_type
    runtime_config["investigation_type"] = investigation_type
    runtime_config["blockchain_chain"] = blockchain_chain

    return runtime_config
end

# ----------------------------------------------------------------------
# UTILITY FUNCTIONS
# ----------------------------------------------------------------------

"""
Environment variable name construction helper
"""
function _construct_env_var_name(key::String)
    return ENV_VAR_PREFIX * uppercase(replace(key, "." => "_"))
end

"""
Type parsing helper for environment variables and config values
"""
function _try_parse_to_type(val_str::String, target_type::Union{Type, Nothing})
    isnothing(target_type) && return val_str

    try
        if target_type <: Integer
            return parse(Int, val_str)
        elseif target_type <: AbstractFloat
            return parse(Float64, val_str)
        elseif target_type == Bool
            lc_val = lowercase(val_str)
            if lc_val in ["true", "1", "yes", "on"]
                return true
            elseif lc_val in ["false", "0", "no", "off"]
                return false
            else
                return nothing
            end
        elseif target_type <: AbstractString
            return val_str
        else
            @warn "Unsupported target type for parsing: $target_type"
            return val_str
        end
    catch e
        @warn "Failed to parse '$val_str' to type $target_type" exception=(e, catch_backtrace())
        return nothing
    end
end

# Auto-initialize configuration when module loads
function __init__()
    try
        load_detective_config()
    catch e
        @error "Critical error during configuration loading in __init__." exception=(e, catch_backtrace())
        lock(CONFIG_LOCK) do
            global CURRENT_CONFIG = deepcopy(DEFAULT_CONFIG)
        end
    end
end

end # module Config
