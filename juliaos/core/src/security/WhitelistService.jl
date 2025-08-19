"""
WhitelistService.jl - High-performance legitimate address verification service

Migrated from backend/services/whitelist_service.py for native Julia performance.
Maintains whitelists of verified tokens, exchanges, and official programs to prevent false positives.
"""
module WhitelistService

using HTTP
using JSON3
using Dates
using Logging

export check_address_legitimacy, is_legitimate_project, get_legitimacy_confidence, get_whitelist_stats

# ========================================
# DATA STRUCTURES & STATE
# ========================================

mutable struct WhitelistState
    verified_tokens::Dict{String, Dict{String, Any}}
    official_exchanges::Set{String}
    last_update::Union{DateTime, Nothing}
    update_interval_seconds::Int
    lock::ReentrantLock
end

# Sources for dynamic whitelist updates
const SOURCES = Dict(
    "solana_token_list" => "https://raw.githubusercontent.com/solana-labs/token-list/main/src/tokens/solana.tokenlist.json",
    "coingecko_verified" => "https://api.coingecko.com/api/v3/coins/list?include_platform=true"
)

# Global state
const STATE = WhitelistState(
    Dict{String, Dict{String, Any}}(),
    Set{String}(),
    nothing,
    3600,  # 1 hour
    ReentrantLock()
)

# ========================================
# INITIALIZATION
# ========================================

"""
    initialize_whitelist()

Initialize the whitelist service with static data and fetch dynamic sources.
"""
function initialize_whitelist()
    @info "Initializing WhitelistService..."

    _init_static_whitelist!()
    _init_official_exchanges!()

    # Update from dynamic sources
    try
        update_from_sources!()
        @info "Whitelist initialized successfully with $(length(STATE.verified_tokens)) tokens and $(length(STATE.official_exchanges)) exchanges."
    catch e
        @warn "Failed to update from dynamic sources during initialization" error=e
        @info "Whitelist initialized with static data only: $(length(STATE.verified_tokens)) tokens and $(length(STATE.official_exchanges)) exchanges."
    end
end

"""
Initialize static whitelist with manually curated legitimate addresses
"""
function _init_static_whitelist!()
    lock(STATE.lock) do
        # Major tokens on Solana
        STATE.verified_tokens = Dict{String, Dict{String, Any}}(
            # Native SOL
            "So11111111111111111111111111111111111111112" => Dict(
                "name" => "Wrapped SOL",
                "symbol" => "SOL",
                "type" => "native",
                "verified" => true,
                "official" => true
            ),
            # USDC
            "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" => Dict(
                "name" => "USD Coin",
                "symbol" => "USDC",
                "type" => "stablecoin",
                "verified" => true,
                "official" => true
            ),
            # USDT
            "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB" => Dict(
                "name" => "Tether USD",
                "symbol" => "USDT",
                "type" => "stablecoin",
                "verified" => true,
                "official" => true
            ),
            # SAMO
            "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU" => Dict(
                "name" => "Samoyedcoin",
                "symbol" => "SAMO",
                "type" => "memecoin",
                "verified" => true,
                "official" => true
            ),
            # mSOL
            "mSoLzYCxHdYgdzU16g5QSh3i5K3z3KZK7ytfqcJm7So" => Dict(
                "name" => "Marinade staked SOL",
                "symbol" => "mSOL",
                "type" => "liquid_staking",
                "verified" => true,
                "official" => true
            ),
            # RAY
            "4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R" => Dict(
                "name" => "Raydium",
                "symbol" => "RAY",
                "type" => "defi",
                "verified" => true,
                "official" => true
            ),
            # SRM
            "SRMuApVNdxXokk5GT7XD5cUUgXMBCoAz2LHeuAoKWRt" => Dict(
                "name" => "Serum",
                "symbol" => "SRM",
                "type" => "defi",
                "verified" => true,
                "official" => true
            )
        )
    end
end

"""
Initialize official exchanges and programs
"""
function _init_official_exchanges!()
    lock(STATE.lock) do
        STATE.official_exchanges = Set{String}([
            # Raydium
            "675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8",
            "5Q544fKrFoe6tsEbD7S8EmxGTJYAKtTVhAW5Q5pge4j1",
            # Orca
            "whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc",
            "9W959DqEETiGZocYWCQPaJ6sBmUzgfxXfqGeTEdp3aQP",
            # Jupiter
            "JUP4Fb2cqiRUcaTHdrPC8h2gNsA2ETXiPDD33WcGuJB",
            "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4",
            # Serum
            "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin",
            "EhqXDsotvYZGAzGJKS4t1JthyaS6U6mE2JNGNwFYkrn",
            # System programs
            "11111111111111111111111111111111",  # System Program
            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",  # Token Program
        ])
    end
end

# ========================================
# MAIN API FUNCTIONS
# ========================================

"""
    check_address_legitimacy(address::String)::Dict

Check if an address is known to be legitimate.
Returns comprehensive legitimacy information with confidence scores.
"""
function check_address_legitimacy(address::String)::Dict
    try
        # Auto-update if needed
        if _should_update()
            @info "Whitelist is stale, triggering update..."
            Threads.@spawn update_from_sources!()
        end

        legitimacy_info = Dict(
            "address" => address,
            "is_legitimate" => false,
            "confidence" => 0.0,
            "sources" => String[],
            "token_info" => nothing,
            "exchange_info" => nothing,
            "verification_level" => "unknown",
            "last_checked" => now(UTC)
        )

        # Check verified tokens
        if haskey(STATE.verified_tokens, address)
            token_info = STATE.verified_tokens[address]
            legitimacy_info["is_legitimate"] = true
            legitimacy_info["confidence"] = token_info["official"] ? 0.95 : 0.85
            legitimacy_info["sources"] = ["static_whitelist", "verified_tokens"]
            legitimacy_info["token_info"] = token_info
            legitimacy_info["verification_level"] = token_info["official"] ? "official" : "verified"

        # Check official exchanges/programs
        elseif address in STATE.official_exchanges
            legitimacy_info["is_legitimate"] = true
            legitimacy_info["confidence"] = 0.90
            legitimacy_info["sources"] = ["static_whitelist", "official_exchanges"]
            legitimacy_info["exchange_info"] = Dict("type" => "official_program")
            legitimacy_info["verification_level"] = "official"
        end

        return legitimacy_info

    catch e
        @error "Error checking address legitimacy" address=address error=e
        return Dict(
            "address" => address,
            "is_legitimate" => false,
            "confidence" => 0.0,
            "sources" => String[],
            "error" => string(e),
            "verification_level" => "unknown",
            "last_checked" => now(UTC)
        )
    end
end

"""
    is_legitimate_project(address::String)::Bool

Simple boolean check for legitimacy.
"""
function is_legitimate_project(address::String)::Bool
    result = check_address_legitimacy(address)
    return get(result, "is_legitimate", false)
end

"""
    get_legitimacy_confidence(address::String)::Float64

Get confidence score for legitimacy (0.0 to 1.0).
"""
function get_legitimacy_confidence(address::String)::Float64
    result = check_address_legitimacy(address)
    return get(result, "confidence", 0.0)
end

"""
    get_whitelist_stats()::Dict

Get whitelist statistics and status information.
"""
function get_whitelist_stats()::Dict
    return Dict(
        "total_verified_tokens" => length(STATE.verified_tokens),
        "total_official_exchanges" => length(STATE.official_exchanges),
        "last_update" => STATE.last_update,
        "cache_type" => "In-Memory",
        "sources_configured" => length(SOURCES),
        "update_interval_minutes" => STATE.update_interval_seconds ÷ 60
    )
end

# ========================================
# DYNAMIC UPDATES
# ========================================

"""
    update_from_sources!()

Update whitelist from external sources in parallel.
"""
function update_from_sources!()
    lock(STATE.lock) do
        @info "Updating whitelist from external sources..."

        tasks = []
        for (source_name, url) in SOURCES
            task = Threads.@spawn _fetch_and_parse_source(source_name, url)
            push!(tasks, task)
        end

        # Wait for all tasks and collect results
        results = fetch.(tasks)

        # Process results
        for (i, result) in enumerate(results)
            source_name = collect(keys(SOURCES))[i]
            if result isa Dict && !isempty(result)
                # Merge new tokens into existing whitelist
                merge!(STATE.verified_tokens, result)
                @info "Updated from $source_name: $(length(result)) tokens"
            else
                @warn "No data received from $source_name"
            end
        end

        STATE.last_update = now(UTC)
        @info "Whitelist update completed. Total verified tokens: $(length(STATE.verified_tokens))"
    end
end

"""
Fetch and parse a single whitelist source
"""
function _fetch_and_parse_source(source_name::String, url::String)::Dict{String, Dict{String, Any}}
    try
        @info "Fetching from $source_name..."
        response = HTTP.get(url, Dict("User-Agent" => "Ghost-Wallet-Hunter-Julia-Client/1.0"))

        if response.status == 200
            data = JSON3.read(response.body)

            if source_name == "solana_token_list"
                return _parse_solana_token_list(data, source_name)
            elseif source_name == "coingecko_verified"
                return _parse_coingecko_verified(data, source_name)
            else
                @warn "No parser for source: $source_name"
            end
        else
            @warn "Failed to fetch $source_name" status=response.status
        end
    catch e
        @error "Error fetching or parsing $source_name" url=url error=e
    end

    return Dict{String, Dict{String, Any}}()
end

"""
Parse official Solana token list
"""
function _parse_solana_token_list(data, source_name::String)::Dict{String, Dict{String, Any}}
    tokens = Dict{String, Dict{String, Any}}()

    try
        if haskey(data, "tokens")
            for token in data.tokens
                if haskey(token, "address") && !haskey(STATE.verified_tokens, token.address)
                    tokens[token.address] = Dict(
                        "name" => get(token, "name", "Unknown"),
                        "symbol" => get(token, "symbol", "UNK"),
                        "type" => "token",
                        "verified" => true,
                        "official" => true,
                        "source" => source_name
                    )
                end
            end
        end

        @info "Parsed $(length(tokens)) tokens from $source_name"
    catch e
        @error "Error parsing $source_name" error=e
    end

    return tokens
end

"""
Parse CoinGecko verified tokens
"""
function _parse_coingecko_verified(data, source_name::String)::Dict{String, Dict{String, Any}}
    tokens = Dict{String, Dict{String, Any}}()

    try
        solana_count = 0
        for coin in data
            if haskey(coin, "platforms") && haskey(coin.platforms, "solana")
                address = coin.platforms.solana
                if !isempty(address) && !haskey(STATE.verified_tokens, address)
                    tokens[address] = Dict(
                        "name" => get(coin, "name", "Unknown"),
                        "symbol" => uppercase(get(coin, "symbol", "UNK")),
                        "type" => "token",
                        "verified" => true,
                        "official" => false,
                        "source" => source_name,
                        "coingecko_id" => get(coin, "id", "")
                    )
                    solana_count += 1
                end
            end
        end

        @info "Parsed $solana_count Solana tokens from $source_name"
    catch e
        @error "Error parsing $source_name" error=e
    end

    return tokens
end

# ========================================
# UTILITY FUNCTIONS
# ========================================

"""
Check if whitelist needs updating
"""
function _should_update()::Bool
    lock(STATE.lock) do
        if isnothing(STATE.last_update)
            return true
        end
        return (now(UTC) - STATE.last_update).value > (STATE.update_interval_seconds * 1000)
    end
end

"""
    add_to_whitelist!(address::String, info::Dict)

Manually add address to whitelist.
"""
function add_to_whitelist!(address::String, info::Dict)
    lock(STATE.lock) do
        STATE.verified_tokens[address] = merge(info, Dict(
            "verified" => true,
            "source" => "manual",
            "added_at" => now(UTC)
        ))
        @info "Added $address to whitelist manually"
    end
end

"""
    remove_from_whitelist!(address::String)

Remove address from whitelist.
"""
function remove_from_whitelist!(address::String)
    lock(STATE.lock) do
        if haskey(STATE.verified_tokens, address)
            delete!(STATE.verified_tokens, address)
            @info "Removed $address from whitelist"
        end
    end
end

end # module WhitelistService
