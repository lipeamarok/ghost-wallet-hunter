"""
SolanaService.jl - Solana blockchain interactions for Ghost Wallet Hunter

Provides real Solana RPC calls for wallet analysisfunction get_wallet_transactions(client:    while length(collected) < limit
        batch_limit = min(page_size, limit - length(collected))
        # Always use Dict{String,Any} to avoid type conflicts with commitment string
        cfg = Dict{String,Any}("limit" => batch_limit, "commitment" => client.commitment)
        if before_sig !== nothing; cfg["before"] = before_sig; end
        params = [wallet_address, cfg]Client, wallet_address::String; limit::Int=100, before::Union{String,Nothing}=nothing)
    try
        # Always use Dict{String,Any} to avoid type conflicts with commitment string
        cfg = Dict{String,Any}("limit" => limit, "commitment" => client.commitment)
        if before !== nothing; cfg["before"] = before; end
        params = [wallet_address, cfg]
        sigs = make_rpc_call(client, "getSignaturesForAddress", params)nsaction processing.
Migrated from backend/services/solana_service.py for optimal performance.
"""
module SolanaService

using HTTP
using JSON3
using Dates
using Logging

# Delegate endpoint selection & retries to ProviderPool (real data only)
include("../providers/ProviderPool.jl")
using .ProviderPool

export SolanaClient, get_wallet_transactions, get_wallet_balance, validate_wallet_address, validate_address_detailed, get_wallet_signatures_paginated

# ========================================
# ENV CONFIG DEFAULTS
# ========================================
const _TIMEOUT_MS = try parse(Int, get(ENV, "SOLANA_TIMEOUT_MS", "30000")) catch; 30000 end
const _TIMEOUT_S  = _TIMEOUT_MS / 1000
const _RETRY_MAX  = try parse(Int, get(ENV, "SOLANA_RETRY_MAX", "3")) catch; 3 end
const _RETRY_BASE = try parse(Int, get(ENV, "SOLANA_RETRY_BASE_MS", "250")) catch; 250 end
const _RETRY_BASE_S = _RETRY_BASE / 1000
const _COMMITMENT = get(ENV, "SOLANA_COMMITMENT", "confirmed")
const _SIG_CACHE_TTL_S = try parse(Int, get(ENV, "SOLANA_SIGNATURE_CACHE_TTL_S", "60")) catch; 60 end

# ========================================
# SOLANA CLIENT STRUCT
# ========================================

mutable struct SolanaClient
    # List of RPC endpoints (primary first, then fallbacks)
    rpc_urls::Vector{String}
    timeout::Float64
    retry_max::Int
    retry_base_s::Float64
    commitment::String

    function SolanaClient(rpc_url::String = get(ENV, "SOLANA_RPC_URL", "https://api.mainnet-beta.solana.com");
                           timeout::Float64 = _TIMEOUT_S,
                           retry_max::Int = _RETRY_MAX,
                           retry_base_s::Float64 = _RETRY_BASE_S,
                           commitment::String = _COMMITMENT)
        # Build fallback list from ENV and add safe public defaults at the end
        env_fallbacks_raw = get(ENV, "SOLANA_RPC_FALLBACK_URLS", "")
        env_fallbacks = [strip(u) for u in split(env_fallbacks_raw, ",") if !isempty(strip(u))]
        public_defaults = [
            "https://solana-api.projectserum.com",
            "https://rpc.ankr.com/solana",
            "https://api.mainnet-beta.solana.com",
        ]
        urls = unique([rpc_url; env_fallbacks; public_defaults])
        client = new(urls, timeout, retry_max, retry_base_s, commitment)
        @info "SolanaService initialized" primary=rpc_url fallbacks=env_fallbacks total_endpoints=length(urls) timeout=timeout retries=retry_max commitment=commitment
        return client
    end
end

# ========================================
# RPC HELPER FUNCTIONS
# ========================================

"""Unified RPC invocation routed through ProviderPool (real endpoints only)."""
function make_rpc_call(client::SolanaClient, method::String, params::Vector)
    # Ensures provider pool initialized (idempotent inside rpc_request)
    resp = ProviderPool.rpc_request(method, params; retries=client.retry_max)
    if isa(resp, Dict) && haskey(resp, "result")
        return resp["result"]
    end
    return resp
end

# ========================================
# SIMPLE SIGNATURE CACHE (per address)
# ========================================

mutable struct _SigCacheEntry
    signatures::Vector{Any}
    fetched_at::DateTime
end

const _SIG_CACHE = Dict{String,_SigCacheEntry}()

function _cache_get(address::String)
    if haskey(_SIG_CACHE, address)
        entry = _SIG_CACHE[address]
        if (now() - entry.fetched_at) < Millisecond(_SIG_CACHE_TTL_S * 1000)
            return entry.signatures
        else
            delete!(_SIG_CACHE, address)
        end
    end
    return nothing
end

function _cache_put(address::String, sigs)
    _SIG_CACHE[address] = _SigCacheEntry(sigs, now())
    return sigs
end

# ========================================
# WALLET TRANSACTION FUNCTIONS
# ========================================

"""
    get_wallet_transactions(client::SolanaClient, wallet_address::String; limit::Int=100, before::Union{String,Nothing}=nothing) -> Vector{Dict}

Get transactions for a wallet address using REAL Solana RPC.
"""
function get_wallet_transactions(client::SolanaClient, wallet_address::String; limit::Int=100, before::Union{String,Nothing}=nothing)
    try
        # Always use Dict{String,Any} to avoid type conflicts with commitment string
        cfg = Dict{String,Any}("limit" => limit, "commitment" => client.commitment)
        if before !== nothing; cfg["before"] = before; end
        params = [wallet_address, cfg]
        sigs = make_rpc_call(client, "getSignaturesForAddress", params)
        if sigs === nothing
            return Any[]
        end
        return sigs
    catch e
        @error "RPC failure get_wallet_transactions (degraded)" wallet=wallet_address error=e
        # Provide a structured degraded marker so upstream can flag
        return Any[Dict("degraded"=>true, "reason"=>"rpc_failure", "wallet"=>wallet_address)]
    end
end

"""
    get_wallet_signatures_paginated(client, wallet_address; limit=500, page_size=100) -> Vector

Fetch up to `limit` signatures using repeated real RPC calls with the `before` cursor.
Caches the combined signature list for a short TTL to mitigate rapid re-queries in tests.
"""
function get_wallet_signatures_paginated(client::SolanaClient, wallet_address::String; limit::Int=500, page_size::Int=100)
    # Serve from cache if adequate
    cached = _cache_get(wallet_address)
    if cached !== nothing && length(cached) >= min(limit, page_size)
        return first(cached, min(limit, length(cached)))
    end

    collected = Any[]
    before_sig = nothing
    while length(collected) < limit
        batch_limit = min(page_size, limit - length(collected))
        # Always use Dict{String,Any} to avoid type conflicts with commitment string
        cfg = Dict{String,Any}("limit" => batch_limit, "commitment" => client.commitment)
        if before_sig !== nothing; cfg["before"] = before_sig; end
        params = [wallet_address, cfg]
    result = make_rpc_call(client, "getSignaturesForAddress", params)
    sigs = (result === nothing) ? Any[] : result
        isempty(sigs) && break
        append!(collected, sigs)
        # Prepare next page cursor (last signature of current batch)
        last_entry = sigs[end]
        if last_entry isa Dict && haskey(last_entry, "signature")
            before_sig = last_entry["signature"]
        else
            break
        end
        # Avoid overwhelming RPC
        sleep(0.05)
    end
    _cache_put(wallet_address, collected)
    return collected
end

# ========================================
# WALLET BALANCE FUNCTIONS
# ========================================

"""
    get_wallet_balance(client::SolanaClient, wallet_address::String) -> Float64

Get wallet balance in SOL using REAL Solana RPC.
"""
function get_wallet_balance(client::SolanaClient, wallet_address::String)
    try
        @info "Getting REAL balance for wallet" wallet=wallet_address
        result = make_rpc_call(client, "getBalance", [wallet_address, Dict{String,Any}("commitment" => client.commitment)])
        if result !== nothing && (haskey(result, "value") || haskey(result, :value))
            lamports = haskey(result, "value") ? result["value"] : result[:value]
            bal = lamports / 1_000_000_000
            return bal
        end
        @warn "Balance response missing value" wallet=wallet_address
        return 0.0
    catch e
    @error "Failed to get wallet balance (degraded)" wallet=wallet_address error=e
    # Use negative sentinel to distinguish degraded vs real zero
    return -1.0
    end
end

# ========================================
# VALIDATION FUNCTIONS
# ========================================

"""
    validate_wallet_address(wallet_address::String) -> Bool

Validate if a wallet address is valid Solana address format.
"""
function validate_wallet_address(wallet_address::String)
    try
        # Basic Solana address validation
        # Solana addresses are base58 encoded and typically 32-44 characters
        if length(wallet_address) < 32 || length(wallet_address) > 44
            return false
        end

        # Check if it contains only valid base58 characters
        valid_chars = Set("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
        for char in wallet_address
            if !(char in valid_chars)
                return false
            end
        end

        return true
    catch e
        @error "Address validation failed" address=wallet_address error=e
        return false
    end
end

"""
    validate_address_detailed(address::String) -> Dict

Extended validation returning structured diagnostics used by tests/tools:
  - format_valid
  - length_valid / character_valid / pattern_valid
  - checksum_valid (placeholder true if format valid)
  - reason (if invalid)
  - validation_time_ms
Never throws; always returns Dict.
"""
function validate_address_detailed(address::String)
    start = now()
    valid_chars = Set("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
    len = length(address)
    # Tests expect canonical 44-char base58 length (Solana pubkey) for full validity
    length_valid = len == 44
    char_valid = all(c-> c in valid_chars, address)
    pattern_valid = !(address in ["0000000000000000000000000000000000000000000","1111111111111111111111111111111111111111111"]) # forbidden patterns
    format_valid = length_valid && char_valid && pattern_valid
    # Lightweight Base58 decode to validate byte length (expected 32 for public keys)
    checksum_valid = false
    if format_valid
        base58_map = Dict{Char,Int}()
        alphabet = collect("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
        for (i,ch) in enumerate(alphabet)
            base58_map[ch] = i-1
        end
        try
            value = BigInt(0)
            for c in address
                value = value * 58 + base58_map[c]
            end
            # Count leading '1's as leading zero bytes
            leading_zeros = length(takewhile(c->c=='1', address))
            bytes = Vector{UInt8}()
            while value > 0
                push!(bytes, UInt8(value & 0xff))
                value >>= 8
            end
            for i in 1:leading_zeros
                push!(bytes, 0x00)
            end
            decoded_len = length(bytes)
            # Solana public key should decode to 32 bytes (44-char base58 form)
            checksum_valid = (decoded_len == 32) && length_valid
        catch
            checksum_valid = false
        end
    end
    reason = format_valid ? "ok" : (!length_valid ? "invalid_length" : (!char_valid ? "invalid_characters" : "forbidden_pattern"))
    return Dict(
        "address" => address,
        "format_valid" => format_valid,
        "length_valid" => length_valid,
        "character_valid" => char_valid,
        "pattern_valid" => pattern_valid,
        "checksum_valid" => checksum_valid,
        "reason" => reason,
        "validation_time_ms" => Dates.value(now() - start)
    )
end

# ========================================
# TRANSACTION DETAIL FUNCTIONS
# ========================================

"""
    get_transaction_details(client::SolanaClient, signature::String) -> Dict

Get detailed transaction information by signature.
"""
function get_transaction_details(client::SolanaClient, signature::String)
    try
        @info "Getting transaction details for signature" signature=signature
        cfg = Dict{String,Any}("encoding" => "json", "commitment" => client.commitment)
        tx = make_rpc_call(client, "getTransaction", [signature, cfg])
        if tx === nothing
            @warn "Transaction not found" signature=signature
            return Dict()
        end
        return tx
    catch e
        @error "Failed to get transaction details" signature=signature error=e
        return Dict()
    end
end

end # module SolanaService
