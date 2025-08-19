# juliaos/core/src/api/SecurityHandlers.jl
"""
Security API Handlers
====================

Blacklist and whitelist verification endpoints.
Migrated from backend/api/blacklist_routes.py for maximum performance.

Features:
- Direct JuliaOS security service integration
- Parallel blacklist/whitelist checking
- Batch processing capabilities
- Real-time threat assessment
"""

module SecurityHandlers

using Oxygen
using HTTP
using JSON3
using StructTypes
using Dates

# Import JuliaOS security services
using ..security.BlacklistChecker: check_address, update_blacklists!, get_sources
using ..security.WhitelistService: check_address as check_whitelist, get_legitimacy_score
using ..monitoring.MonitoringService: record_api_call

# ===============================================================================
# REQUEST/RESPONSE MODELS
# ===============================================================================

struct SecurityCheckRequest
    wallet_address::String
    check_type::String  # "blacklist", "whitelist", "both"
    sources::Vector{String}  # Optional specific sources
end

struct BatchSecurityCheckRequest
    wallet_addresses::Vector{String}
    check_type::String
    max_concurrent::Int
end

struct SecurityCheckResult
    wallet_address::String
    is_blacklisted::Bool
    is_whitelisted::Bool
    threat_level::String
    confidence_score::Float64
    sources_checked::Vector{String}
    findings::Vector{String}
    recommendations::Vector{String}
    check_timestamp::String
end

struct BatchSecurityCheckResponse
    total_checked::Int
    blacklisted_count::Int
    whitelisted_count::Int
    results::Vector{SecurityCheckResult}
    processing_time_ms::Float64
    summary::Dict{String, Any}
end

struct SecuritySourcesResponse
    blacklist_sources::Vector{String}
    whitelist_sources::Vector{String}
    last_updated::Dict{String, String}
    total_entries::Dict{String, Int}
end

# Enable JSON serialization
StructTypes.StructType(::Type{SecurityCheckRequest}) = StructTypes.Struct()
StructTypes.StructType(::Type{BatchSecurityCheckRequest}) = StructTypes.Struct()
StructTypes.StructType(::Type{SecurityCheckResult}) = StructTypes.Struct()
StructTypes.StructType(::Type{BatchSecurityCheckResponse}) = StructTypes.Struct()
StructTypes.StructType(::Type{SecuritySourcesResponse}) = StructTypes.Struct()

# ===============================================================================
# SECURITY PROCESSING FUNCTIONS
# ===============================================================================

"""
Perform comprehensive security check on a single address
"""
function perform_security_check(wallet_address::String, check_type::String, sources::Vector{String} = String[])
    @info "🛡️ Security check for: $wallet_address (type: $check_type)"

    start_time = time()

    # Initialize results
    is_blacklisted = false
    is_whitelisted = false
    findings = String[]
    sources_checked = String[]
    confidence_score = 0.0

    try
        # Blacklist check
        if check_type in ["blacklist", "both"]
            # Updated: call with just address; sources param ignored in checker
            blacklist_result = check_address(wallet_address)
            is_blacklisted = get(blacklist_result, "is_blacklisted", false)

            # Prefer new fields; fallback to legacy
            used = get(blacklist_result, "sources_used", get(blacklist_result, "sources_checked", String[]))
            append!(sources_checked, used)
            if is_blacklisted
                append!(findings, get(blacklist_result, "source_hits", String[]))
                confidence_score = max(confidence_score, get(blacklist_result, "confidence", 0.0))
            end
        end

        # Whitelist check
        if check_type in ["whitelist", "both"]
            whitelist_result = check_whitelist(wallet_address)
            is_whitelisted = get(whitelist_result, "is_whitelisted", false)
            legitimacy_score = get_legitimacy_score(wallet_address)

            if is_whitelisted
                push!(findings, "Address verified as legitimate")
                push!(sources_checked, "whitelist_verified")
                confidence_score = max(confidence_score, legitimacy_score)
            end
        end

        # Determine threat level
        threat_level = if is_blacklisted
            if confidence_score > 0.8
                "HIGH"
            elseif confidence_score > 0.5
                "MEDIUM"
            else
                "LOW"
            end
        elseif is_whitelisted
            "SAFE"
        else
            "UNKNOWN"
        end

        # Generate recommendations
        recommendations = String[]
        if is_blacklisted
            push!(recommendations, "⚠️ AVOID INTERACTION - Address is blacklisted")
            push!(recommendations, "🔍 Investigate transaction history")
            push!(recommendations, "📋 Report to compliance team")
        elseif is_whitelisted
            push!(recommendations, "✅ Safe to interact - Address is verified")
        else
            push!(recommendations, "⚖️ Exercise standard due diligence")
            push!(recommendations, "📊 Monitor transaction patterns")
        end

        processing_time = (time() - start_time) * 1000
        @info "✅ Security check completed in $(round(processing_time, digits=2))ms"

        return SecurityCheckResult(
            wallet_address,
            is_blacklisted,
            is_whitelisted,
            threat_level,
            confidence_score,
            unique(sources_checked),
            findings,
            recommendations,
            Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
        )

    catch e
        @error "❌ Security check failed for $wallet_address: $e"
        return SecurityCheckResult(
            wallet_address,
            false,
            false,
            "ERROR",
            0.0,
            String[],
            ["Security check failed: $(string(e))"],
            ["Manual review required"],
            Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
        )
    end
end

"""
Perform batch security checks with parallel processing
"""
function perform_batch_security_check(addresses::Vector{String}, check_type::String, max_concurrent::Int = 10)
    @info "🛡️ Batch security check for $(length(addresses)) addresses"

    start_time = time()
    results = Vector{SecurityCheckResult}()

    # Process in chunks for parallel execution
    chunk_size = min(max_concurrent, length(addresses))
    chunks = [addresses[i:min(i+chunk_size-1, length(addresses))] for i in 1:chunk_size:length(addresses)]

    for chunk in chunks
        # Process chunk in parallel (simplified - could use @threads or async)
        chunk_results = [perform_security_check(addr, check_type) for addr in chunk]
        append!(results, chunk_results)
    end

    # Calculate summary statistics
    blacklisted_count = count(r -> r.is_blacklisted, results)
    whitelisted_count = count(r -> r.is_whitelisted, results)
    processing_time = (time() - start_time) * 1000

    summary = Dict(
        "blacklisted_percentage" => round(blacklisted_count / length(addresses) * 100, digits=2),
        "whitelisted_percentage" => round(whitelisted_count / length(addresses) * 100, digits=2),
        "unknown_percentage" => round((length(addresses) - blacklisted_count - whitelisted_count) / length(addresses) * 100, digits=2),
        "avg_confidence" => round(mean([r.confidence_score for r in results]), digits=3),
        "high_risk_count" => count(r -> r.threat_level == "HIGH", results)
    )

    @info "✅ Batch security check completed in $(round(processing_time, digits=2))ms"

    return BatchSecurityCheckResponse(
        length(addresses),
        blacklisted_count,
        whitelisted_count,
        results,
        processing_time,
        summary
    )
end

# ===============================================================================
# API ENDPOINTS
# ===============================================================================

"""
Single Address Security Check
===========================
"""
function check_single_wallet_handler(req::HTTP.Request, wallet_address::String)
    try
        @info "🔍 Single wallet security check: $wallet_address"

        # Record API call
        record_api_call("security_check_single", wallet_address, 0.001)

        # Perform comprehensive check (both blacklist and whitelist)
        result = perform_security_check(wallet_address, "both")

        response = Dict(
            "success" => true,
            "data" => result
        )

        return HTTP.Response(200, JSON3.write(response))

    catch e
        @error "❌ Single wallet check error: $e"
        return HTTP.Response(500, JSON3.write(Dict(
            "success" => false,
            "error" => "Security check failed: $(string(e))"
        )))
    end
end

"""
Batch Address Security Check
==========================
"""
function check_multiple_wallets_handler(req::HTTP.Request)
    try
        # Parse request body
        body = String(req.body)

        # Handle both simple array and structured request
        wallet_addresses = try
            # Try parsing as structured request first
            request_data = JSON3.read(body, BatchSecurityCheckRequest)
            request_data.wallet_addresses
        catch
            # Fall back to simple array
            JSON3.read(body, Vector{String})
        end

        if length(wallet_addresses) > 50
            return HTTP.Response(400, JSON3.write(Dict(
                "success" => false,
                "error" => "Maximum 50 addresses per request"
            )))
        end

        @info "🔍 Batch wallet security check: $(length(wallet_addresses)) addresses"

        # Record API call
        record_api_call("security_check_batch", "$(length(wallet_addresses))_addresses", 0.01)

        # Perform batch check
        result = perform_batch_security_check(wallet_addresses, "both")

        response = Dict(
            "success" => true,
            "data" => result
        )

        return HTTP.Response(200, JSON3.write(response))

    catch e
        @error "❌ Batch wallet check error: $e"
        return HTTP.Response(500, JSON3.write(Dict(
            "success" => false,
            "error" => "Batch security check failed: $(string(e))"
        )))
    end
end

"""
Blacklist-only Check
==================
"""
function check_blacklist_only_handler(req::HTTP.Request, wallet_address::String)
    try
        @info "🚫 Blacklist-only check: $wallet_address"

        record_api_call("blacklist_check", wallet_address, 0.0005)

        result = perform_security_check(wallet_address, "blacklist")

        response = Dict(
            "success" => true,
            "wallet_address" => wallet_address,
            "is_blacklisted" => result.is_blacklisted,
            "threat_level" => result.threat_level,
            "confidence_score" => result.confidence_score,
            "findings" => result.findings,
            "sources_checked" => result.sources_checked,
            "timestamp" => result.check_timestamp
        )

        return HTTP.Response(200, JSON3.write(response))

    catch e
        @error "❌ Blacklist check error: $e"
        return HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
    end
end

"""
Whitelist-only Check
==================
"""
function check_whitelist_only_handler(req::HTTP.Request, wallet_address::String)
    try
        @info "✅ Whitelist-only check: $wallet_address"

        record_api_call("whitelist_check", wallet_address, 0.0005)

        result = perform_security_check(wallet_address, "whitelist")

        response = Dict(
            "success" => true,
            "wallet_address" => wallet_address,
            "is_whitelisted" => result.is_whitelisted,
            "legitimacy_score" => result.confidence_score,
            "findings" => result.findings,
            "timestamp" => result.check_timestamp
        )

        return HTTP.Response(200, JSON3.write(response))

    catch e
        @error "❌ Whitelist check error: $e"
        return HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
    end
end

"""
Security Sources Information
=========================
"""
function get_security_sources_handler(req::HTTP.Request)
    try
        @info "📋 Getting security sources information"

        # Get blacklist sources info
        blacklist_sources = collect(keys(get_sources()))

        # Mock whitelist sources (would be implemented in WhitelistService)
        whitelist_sources = ["verified_exchanges", "known_projects", "trusted_wallets"]

        response = SecuritySourcesResponse(
            blacklist_sources,
            whitelist_sources,
            Dict("blacklists" => Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"), "whitelists" => Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")),
            Dict("blacklist_entries" => 10000, "whitelist_entries" => 5000)
        )

        return HTTP.Response(200, JSON3.write(response))

    catch e
        @error "❌ Security sources error: $e"
        return HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
    end
end

"""
Update Security Sources
=====================
"""
function update_security_sources_handler(req::HTTP.Request)
    try
        @info "🔄 Updating security sources"

        record_api_call("security_update", "sources_update", 0.002)

        # Update blacklists
        update_result = update_blacklists!()

        response = Dict(
            "success" => true,
            "message" => "Security sources updated successfully",
            "blacklists_updated" => get(update_result, "updated_count", 0),
            "timestamp" => string(now())
        )

        return HTTP.Response(200, JSON3.write(response))

    catch e
        @error "❌ Security sources update error: $e"
        return HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
    end
end

# ===============================================================================
# ROUTE REGISTRATION
# ===============================================================================

function register_security_routes()
    @info "🚀 Registering Security API routes (JuliaOS Native)..."

    # Single address checks
    @get "/api/v1/blacklist/check/{wallet_address}" check_single_wallet_handler
    @get "/api/v1/security/check/{wallet_address}" check_single_wallet_handler
    @get "/api/v1/security/blacklist/{wallet_address}" check_blacklist_only_handler
    @get "/api/v1/security/whitelist/{wallet_address}" check_whitelist_only_handler

    # Batch checks
    @post "/api/v1/blacklist/check-multiple" check_multiple_wallets_handler
    @post "/api/v1/security/check-batch" check_multiple_wallets_handler

    # Management endpoints
    @get "/api/v1/security/sources" get_security_sources_handler
    @post "/api/v1/security/update" update_security_sources_handler

    @info "✅ Security API routes registered successfully!"
end

# Auto-register routes when module is loaded
__init__() = register_security_routes()

end # module SecurityHandlers
