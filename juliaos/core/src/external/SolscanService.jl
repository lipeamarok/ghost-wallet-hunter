"""
SolscanService.jl - High-performance Solscan API integration service

Migrated from backend/services/solscan_service.py for native Julia performance.
Provides verification of addresses through Solscan API to check if they are official/verified.
"""
module SolscanService

using HTTP
using JSON3
using Dates
using Logging

export check_address_verification, is_verified_token, is_official_program, batch_check_verification, get_service_stats

# ========================================
# CONSTANTS
# ========================================

const BASE_URL = "https://public-api.solscan.io"
const RATE_LIMIT = 100  # requests per minute
const CACHE_DURATION_MS = 21600000  # 6 hours in milliseconds

# ========================================
# STATE MANAGEMENT
# ========================================

mutable struct SolscanState
    verification_cache::Dict{String, Dict{String, Any}}
    request_count::Int
    last_reset::DateTime
    lock::ReentrantLock
end

# Global state
const STATE = SolscanState(
    Dict{String, Dict{String, Any}}(),
    0,
    now(UTC),
    ReentrantLock()
)

# ========================================
# MAIN API FUNCTIONS
# ========================================

"""
    check_address_verification(address::String)::Dict

Check if an address is verified/official through Solscan.
Returns comprehensive verification information.
"""
function check_address_verification(address::String)::Dict
    lock(STATE.lock) do
        try
            # Check rate limit
            if !_check_rate_limit()
                @warn "Solscan rate limit reached, using cached data only"
                cached_result = _get_cached_verification(address)
                if !isnothing(cached_result)
                    return cached_result
                else
                    return _create_error_result(address, "Rate limit reached")
                end
            end

            # Check cache first
            cached_result = _get_cached_verification(address)
            if !isnothing(cached_result)
                @debug "Solscan cache hit for $address"
                return cached_result
            end

            verification_info = Dict(
                "address" => address,
                "is_verified" => false,
                "is_official" => false,
                "confidence" => 0.0,
                "verification_sources" => String[],
                "token_info" => nothing,
                "account_info" => nothing,
                "error" => nothing,
                "last_checked" => now(UTC)
            )

            # Check if it's a token
            token_info = _get_token_info(address)
            if !isnothing(token_info)
                verification_info["token_info"] = token_info
                verification_info["is_verified"] = get(token_info, "verified", false)
                verification_info["confidence"] = token_info["verified"] ? 0.8 : 0.3
                push!(verification_info["verification_sources"], "solscan_token_registry")
            end

            # Check account information
            account_info = _get_account_info(address)
            if !isnothing(account_info)
                verification_info["account_info"] = account_info

                # Check if it's a known program
                if get(account_info, "executable", false)
                    verification_info["is_official"] = true
                    verification_info["confidence"] = max(verification_info["confidence"], 0.9)
                    push!(verification_info["verification_sources"], "solscan_program_registry")
                end
            end

            # Cache the result
            _cache_verification_result(address, verification_info)

            return verification_info

        catch e
            @error "Error checking Solscan verification" address=address error=e
            return _create_error_result(address, string(e))
        end
    end
end

"""
    is_verified_token(address::String)::Bool

Simple check if token is verified.
"""
function is_verified_token(address::String)::Bool
    result = check_address_verification(address)
    return get(result, "is_verified", false)
end

"""
    is_official_program(address::String)::Bool

Simple check if address is an official program.
"""
function is_official_program(address::String)::Bool
    result = check_address_verification(address)
    return get(result, "is_official", false)
end

"""
    batch_check_verification(addresses::Vector{String})::Dict

Check verification for multiple addresses with rate limiting.
"""
function batch_check_verification(addresses::Vector{String})::Dict
    results = Dict{String, Dict}()
    batch_size = 10

    # Process in batches to respect rate limits
    for i in 1:batch_size:length(addresses)
        batch_end = min(i + batch_size - 1, length(addresses))
        batch = addresses[i:batch_end]

        @info "Processing Solscan batch $(div(i-1, batch_size) + 1)/$(div(length(addresses) - 1, batch_size) + 1)"

        # Process batch with parallel tasks
        tasks = []
        for addr in batch
            task = Threads.@spawn check_address_verification(addr)
            push!(tasks, task)
        end

        # Collect results
        batch_results = fetch.(tasks)
        for (addr, result) in zip(batch, batch_results)
            results[addr] = result
        end

        # Small delay between batches
        if batch_end < length(addresses)
            sleep(0.5)
        end
    end

    return results
end

"""
    get_service_stats()::Dict

Get service statistics and current state.
"""
function get_service_stats()::Dict
    lock(STATE.lock) do
        return Dict(
            "base_url" => BASE_URL,
            "rate_limit" => RATE_LIMIT,
            "requests_this_minute" => STATE.request_count,
            "cache_enabled" => true,
            "cache_size" => length(STATE.verification_cache),
            "cache_duration_hours" => CACHE_DURATION_MS ÷ 3600000,
            "last_reset" => STATE.last_reset
        )
    end
end

# ========================================
# INTERNAL FUNCTIONS
# ========================================

"""
Get token information from Solscan API
"""
function _get_token_info(address::String)::Union{Dict, Nothing}
    try
        url = "$BASE_URL/token/meta"
        params = Dict("tokenAddress" => address)

        response = HTTP.get(url,
            query=params,
            headers=Dict("User-Agent" => "Ghost-Wallet-Hunter-Julia/1.0")
        )

        if response.status == 200
            data = JSON3.read(response.body)

            return Dict(
                "name" => get(data, "name", nothing),
                "symbol" => get(data, "symbol", nothing),
                "decimals" => get(data, "decimals", nothing),
                "supply" => get(data, "supply", nothing),
                "verified" => get(data, "verified", false),
                "icon" => get(data, "icon", nothing),
                "website" => get(data, "website", nothing),
                "description" => get(data, "description", nothing),
                "holders" => get(data, "holders", nothing),
                "market_cap" => get(data, "marketCap", nothing),
                "volume_24h" => get(data, "volume24h", nothing)
            )
        elseif response.status == 404
            # Not a token, that's ok
            return nothing
        else
            @warn "Solscan token API error" status=response.status address=address
            return nothing
        end

    catch e
        @warn "Error fetching token info from Solscan" address=address error=e
        return nothing
    end
end

"""
Get account information from Solscan API
"""
function _get_account_info(address::String)::Union{Dict, Nothing}
    try
        url = "$BASE_URL/account/$address"

        response = HTTP.get(url,
            headers=Dict("User-Agent" => "Ghost-Wallet-Hunter-Julia/1.0")
        )

        if response.status == 200
            data = JSON3.read(response.body)

            return Dict(
                "lamports" => get(data, "lamports", nothing),
                "owner" => get(data, "owner", nothing),
                "executable" => get(data, "executable", false),
                "rent_epoch" => get(data, "rentEpoch", nothing),
                "type" => get(data, "type", nothing),
                "program" => get(data, "program", nothing),
                "space" => get(data, "space", nothing)
            )
        elseif response.status == 404
            # Account doesn't exist or not public
            return nothing
        else
            @warn "Solscan account API error" status=response.status address=address
            return nothing
        end

    catch e
        @warn "Error fetching account info from Solscan" address=address error=e
        return nothing
    end
end

"""
Check if we're within rate limits
"""
function _check_rate_limit()::Bool
    now_time = now(UTC)

    # Reset counter every minute
    if (now_time - STATE.last_reset).value >= 60000  # 60 seconds in milliseconds
        STATE.request_count = 0
        STATE.last_reset = now_time
    end

    if STATE.request_count >= RATE_LIMIT
        return false
    end

    STATE.request_count += 1
    return true
end

"""
Get cached verification result
"""
function _get_cached_verification(address::String)::Union{Dict, Nothing}
    if !haskey(STATE.verification_cache, address)
        return nothing
    end

    cached = STATE.verification_cache[address]
    cache_age = (now(UTC) - cached["timestamp"]).value

    if cache_age < CACHE_DURATION_MS
        return cached["data"]
    else
        # Remove expired cache entry
        delete!(STATE.verification_cache, address)
        return nothing
    end
end

"""
Cache verification result
"""
function _cache_verification_result(address::String, result::Dict)
    STATE.verification_cache[address] = Dict(
        "data" => result,
        "timestamp" => now(UTC)
    )
end

"""
Create error result structure
"""
function _create_error_result(address::String, error::String)::Dict
    return Dict(
        "address" => address,
        "is_verified" => false,
        "is_official" => false,
        "confidence" => 0.0,
        "verification_sources" => String[],
        "token_info" => nothing,
        "account_info" => nothing,
        "error" => error,
        "last_checked" => now(UTC)
    )
end

end # module SolscanService
