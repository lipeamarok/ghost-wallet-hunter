# juliaos/core/src/api/AnalysisHandlers.jl
"""
Analysis API Handlers
====================

Wallet clustering and risk assessment endpoints.
Migrated from backend/api/routes/analysis.py for maximum performance.

Features:
- Direct JuliaOS analysis service integration
- Advanced clustering algorithms
- Real-time risk assessment
- Background processing support
"""

module AnalysisHandlers

using Oxygen
using HTTP
using JSON3
using StructTypes
using Dates
using Statistics

# Import JuliaOS services
using ..analysis.AnalysisService: analyze_wallet, detect_clusters, calculate_risk_scores, analyze_transaction_patterns
using ..blockchain.SolanaService: get_wallet_transactions, validate_wallet_address
using ..resources.Resources: call_ai
using ..monitoring.MonitoringService: record_api_call
using ..security.BlacklistChecker: check_address as check_blacklist

# ===============================================================================
# REQUEST/RESPONSE MODELS
# ===============================================================================

struct AnalysisRequest
    wallet_address::String
    depth::Int  # Analysis depth (1-5)
    include_explanation::Bool
    analysis_type::String  # "quick", "comprehensive", "deep"
    include_ai_analysis::Bool
end

struct WalletCluster
    cluster_id::String
    cluster_type::String
    wallet_count::Int
    total_volume::Float64
    risk_score::Float64
    representative_wallets::Vector{String}
    common_patterns::Vector{String}
end

struct TransactionPattern
    pattern_type::String
    frequency::Int
    confidence::Float64
    description::String
    risk_indicator::Bool
end

struct RiskAssessment
    overall_risk_score::Float64
    risk_level::String  # "LOW", "MEDIUM", "HIGH", "CRITICAL"
    risk_factors::Vector{String}
    confidence_level::Float64
    recommendations::Vector{String}
end

struct AnalysisMetadata
    analysis_id::String
    analysis_type::String
    depth_level::Int
    processing_time_ms::Float64
    data_points_analyzed::Int
    algorithms_used::Vector{String}
    timestamp::String
end

struct AnalysisResponse
    wallet_address::String
    metadata::AnalysisMetadata
    clusters::Vector{WalletCluster}
    transaction_patterns::Vector{TransactionPattern}
    risk_assessment::RiskAssessment
    ai_explanation::String
    connections::Dict{String, Any}
    recommendations::Vector{String}
end

struct QuickAnalysisResponse
    wallet_address::String
    risk_score::Float64
    risk_level::String
    cluster_count::Int
    total_connections::Int
    analysis_timestamp::String
    processing_time_ms::Float64
end

# Enable JSON serialization
StructTypes.StructType(::Type{AnalysisRequest}) = StructTypes.Struct()
StructTypes.StructType(::Type{WalletCluster}) = StructTypes.Struct()
StructTypes.StructType(::Type{TransactionPattern}) = StructTypes.Struct()
StructTypes.StructType(::Type{RiskAssessment}) = StructTypes.Struct()
StructTypes.StructType(::Type{AnalysisMetadata}) = StructTypes.Struct()
StructTypes.StructType(::Type{AnalysisResponse}) = StructTypes.Struct()
StructTypes.StructType(::Type{QuickAnalysisResponse}) = StructTypes.Struct()

# ===============================================================================
# ANALYSIS PROCESSING FUNCTIONS
# ===============================================================================

"""
Perform comprehensive wallet analysis with clustering
"""
function perform_comprehensive_analysis(wallet_address::String, depth::Int, include_ai::Bool)
    @info "📊 Comprehensive analysis for: $wallet_address (depth: $depth)"

    start_time = time()
    analysis_id = "ANALYSIS_$(Dates.format(now(), "yyyymmdd_HHMMSS"))"

    # Validate wallet address
    if !validate_wallet_address(wallet_address)
        throw(ArgumentError("Invalid wallet address format"))
    end

    # Phase 1: Basic wallet analysis
    @info "Phase 1: Basic wallet analysis..."
    wallet_analysis = analyze_wallet(wallet_address, depth)

    # Phase 2: Cluster detection
    @info "Phase 2: Cluster detection..."
    clusters_raw = detect_clusters(wallet_address, depth)

    # Convert raw clusters to structured format
    clusters = WalletCluster[]
    for (i, cluster_data) in enumerate(clusters_raw)
        cluster = WalletCluster(
            "CLUSTER_$i",
            get(cluster_data, "type", "general"),
            get(cluster_data, "wallet_count", 0),
            get(cluster_data, "total_volume", 0.0),
            get(cluster_data, "risk_score", 0.0),
            get(cluster_data, "wallets", String[])[1:min(end, 5)],  # Top 5 wallets
            get(cluster_data, "patterns", String[])
        )
        push!(clusters, cluster)
    end

    # Phase 3: Transaction pattern analysis
    @info "Phase 3: Transaction pattern analysis..."
    patterns_raw = analyze_transaction_patterns(wallet_address)

    transaction_patterns = TransactionPattern[]
    for pattern_data in patterns_raw
        pattern = TransactionPattern(
            get(pattern_data, "type", "unknown"),
            get(pattern_data, "frequency", 0),
            get(pattern_data, "confidence", 0.0),
            get(pattern_data, "description", ""),
            get(pattern_data, "is_risk_indicator", false)
        )
        push!(transaction_patterns, pattern)
    end

    # Phase 4: Risk assessment
    @info "Phase 4: Risk assessment..."
    risk_scores = calculate_risk_scores(wallet_address, clusters_raw, patterns_raw)

    overall_risk = mean([cluster.risk_score for cluster in clusters])
    risk_level = if overall_risk >= 80.0
        "CRITICAL"
    elseif overall_risk >= 60.0
        "HIGH"
    elseif overall_risk >= 40.0
        "MEDIUM"
    else
        "LOW"
    end

    # Extract risk factors
    risk_factors = String[]
    for pattern in transaction_patterns
        if pattern.risk_indicator
            push!(risk_factors, pattern.description)
        end
    end

    # Security check
    blacklist_result = check_blacklist(wallet_address)
    if get(blacklist_result, "is_blacklisted", false)
        push!(risk_factors, "Address appears on blacklists")
        overall_risk = min(100.0, overall_risk + 20.0)
    end

    # Generate recommendations
    recommendations = String[]
    if overall_risk >= 80.0
        push!(recommendations, "🚨 HIGH RISK: Avoid all transactions")
        push!(recommendations, "🔍 Immediate investigation required")
        push!(recommendations, "📋 Report to compliance immediately")
    elseif overall_risk >= 60.0
        push!(recommendations, "⚠️ ELEVATED RISK: Enhanced due diligence required")
        push!(recommendations, "📊 Monitor all transactions closely")
        push!(recommendations, "🕒 Implement additional verification steps")
    elseif overall_risk >= 40.0
        push!(recommendations, "⚖️ MODERATE RISK: Standard due diligence")
        push!(recommendations, "📈 Regular monitoring recommended")
    else
        push!(recommendations, "✅ LOW RISK: Standard procedures sufficient")
    end

    risk_assessment = RiskAssessment(
        overall_risk,
        risk_level,
        risk_factors,
        0.85,  # Default confidence
        recommendations
    )

    # Phase 5: AI Explanation (if requested)
    ai_explanation = ""
    if include_ai
        @info "Phase 5: AI explanation..."

        ai_prompt = """
        Analyze this Solana wallet investigation results:

        Wallet: $wallet_address
        Risk Score: $(round(overall_risk, digits=2))
        Clusters Found: $(length(clusters))
        Transaction Patterns: $(length(transaction_patterns))
        Risk Factors: $(join(risk_factors, ", "))

        Provide a clear, professional explanation of:
        1. What the analysis reveals about this wallet
        2. Key risk indicators and their significance
        3. Recommended actions based on findings
        4. Confidence level in the assessment

        Be specific and actionable in your response.
        """

        try
            ai_explanation = call_ai(ai_prompt, "You are a blockchain forensic analyst providing professional wallet assessment reports.")
        catch e
            @warn "AI explanation failed: $e"
            ai_explanation = "AI analysis temporarily unavailable. Risk assessment based on algorithmic analysis only."
        end
    end

    # Compile connections data
    connections = Dict(
        "direct_connections" => length(clusters) > 0 ? clusters[1].wallet_count : 0,
        "cluster_connections" => sum([c.wallet_count for c in clusters]),
        "depth_analyzed" => depth,
        "total_volume_analyzed" => sum([c.total_volume for c in clusters])
    )

    processing_time = (time() - start_time) * 1000
    data_points = sum([c.wallet_count for c in clusters]) + length(transaction_patterns)

    metadata = AnalysisMetadata(
        analysis_id,
        "comprehensive",
        depth,
        processing_time,
        data_points,
        ["clustering", "pattern_analysis", "risk_assessment", "graph_analysis"],
        string(now())
    )

    @info "✅ Comprehensive analysis completed in $(round(processing_time, digits=2))ms"

    return AnalysisResponse(
        wallet_address,
        metadata,
        clusters,
        transaction_patterns,
        risk_assessment,
        ai_explanation,
        connections,
        recommendations
    )
end

"""
Perform quick analysis for fast results
"""
function perform_quick_analysis(wallet_address::String)
    @info "⚡ Quick analysis for: $wallet_address"

    start_time = time()

    # Quick validation and basic analysis
    if !validate_wallet_address(wallet_address)
        throw(ArgumentError("Invalid wallet address format"))
    end

    # Simplified analysis with depth 1
    wallet_analysis = analyze_wallet(wallet_address, 1)
    clusters = detect_clusters(wallet_address, 1)

    # Basic risk calculation
    risk_score = get(wallet_analysis, "risk_score", 25.0)
    cluster_count = length(clusters)
    total_connections = sum([get(c, "wallet_count", 0) for c in clusters])

    # Quick blacklist check
    blacklist_result = check_blacklist(wallet_address)
    if get(blacklist_result, "is_blacklisted", false)
        risk_score = min(100.0, risk_score + 30.0)
    end

    risk_level = if risk_score >= 70.0
        "HIGH"
    elseif risk_score >= 40.0
        "MEDIUM"
    else
        "LOW"
    end

    processing_time = (time() - start_time) * 1000

    @info "✅ Quick analysis completed in $(round(processing_time, digits=2))ms"

    return QuickAnalysisResponse(
        wallet_address,
        risk_score,
        risk_level,
        cluster_count,
        total_connections,
        string(now()),
        processing_time
    )
end

# ===============================================================================
# API ENDPOINTS
# ===============================================================================

"""
Comprehensive Wallet Analysis
==========================
"""
function analyze_wallet_handler(req::HTTP.Request)
    try
        # Parse request body
        body = String(req.body)
        request_data = JSON3.read(body, AnalysisRequest)

        @info "📊 Analysis request for: $(request_data.wallet_address)"

        # Record API call
        record_api_call("wallet_analysis", request_data.wallet_address, 0.05)

        # Validate depth parameter
        depth = clamp(request_data.depth, 1, 5)

        # Perform analysis based on type
        if request_data.analysis_type == "quick"
            # Quick analysis
            quick_result = perform_quick_analysis(request_data.wallet_address)
            return HTTP.Response(200, JSON3.write(quick_result))
        else
            # Comprehensive analysis
            result = perform_comprehensive_analysis(
                request_data.wallet_address,
                depth,
                request_data.include_ai_analysis
            )
            return HTTP.Response(200, JSON3.write(result))
        end

    catch e
        @error "❌ Analysis failed: $e"
        return HTTP.Response(500, JSON3.write(Dict(
            "error" => "Analysis failed: $(string(e))",
            "timestamp" => string(now())
        )))
    end
end

"""
Quick Risk Assessment
===================
"""
function quick_risk_assessment_handler(req::HTTP.Request, wallet_address::String)
    try
        @info "⚡ Quick risk assessment for: $wallet_address"

        record_api_call("quick_risk_assessment", wallet_address, 0.01)

        result = perform_quick_analysis(wallet_address)

        # Simplified response for quick assessment
        response = Dict(
            "wallet_address" => wallet_address,
            "risk_score" => result.risk_score,
            "risk_level" => result.risk_level,
            "assessment" => if result.risk_score >= 70.0
                "High risk - avoid interaction"
            elseif result.risk_score >= 40.0
                "Moderate risk - proceed with caution"
            else
                "Low risk - standard due diligence"
            end,
            "processing_time_ms" => result.processing_time_ms,
            "timestamp" => result.analysis_timestamp
        )

        return HTTP.Response(200, JSON3.write(response))

    catch e
        @error "❌ Quick risk assessment failed: $e"
        return HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
    end
end

"""
Cluster Analysis Only
==================
"""
function cluster_analysis_handler(req::HTTP.Request, wallet_address::String)
    try
        @info "🕸️ Cluster analysis for: $wallet_address"

        record_api_call("cluster_analysis", wallet_address, 0.02)

        if !validate_wallet_address(wallet_address)
            return HTTP.Response(400, JSON3.write(Dict("error" => "Invalid wallet address")))
        end

        # Perform cluster detection only
        clusters_raw = detect_clusters(wallet_address, 3)  # Medium depth

        clusters = [WalletCluster(
            "CLUSTER_$i",
            get(cluster_data, "type", "general"),
            get(cluster_data, "wallet_count", 0),
            get(cluster_data, "total_volume", 0.0),
            get(cluster_data, "risk_score", 0.0),
            get(cluster_data, "wallets", String[])[1:min(end, 10)],  # Top 10 wallets
            get(cluster_data, "patterns", String[])
        ) for (i, cluster_data) in enumerate(clusters_raw)]

        response = Dict(
            "wallet_address" => wallet_address,
            "clusters_found" => length(clusters),
            "clusters" => clusters,
            "total_connected_wallets" => sum([c.wallet_count for c in clusters]),
            "analysis_timestamp" => string(now())
        )

        return HTTP.Response(200, JSON3.write(response))

    catch e
        @error "❌ Cluster analysis failed: $e"
        return HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
    end
end

"""
Batch Analysis for Multiple Wallets
=================================
"""
function batch_analysis_handler(req::HTTP.Request)
    try
        # Parse wallet addresses
        body = String(req.body)
        wallet_addresses = JSON3.read(body, Vector{String})

        if length(wallet_addresses) > 20
            return HTTP.Response(400, JSON3.write(Dict(
                "error" => "Maximum 20 wallets per batch request"
            )))
        end

        @info "📊 Batch analysis for $(length(wallet_addresses)) wallets"

        record_api_call("batch_analysis", "$(length(wallet_addresses))_wallets", 0.1)

        # Process each wallet
        results = []
        for wallet_address in wallet_addresses
            try
                result = perform_quick_analysis(wallet_address)
                push!(results, result)
            catch e
                @warn "Failed to analyze $wallet_address: $e"
                push!(results, Dict(
                    "wallet_address" => wallet_address,
                    "error" => "Analysis failed: $(string(e))"
                ))
            end
        end

        # Summary statistics
        successful_results = filter(r -> !haskey(r, "error"), results)
        avg_risk_score = if !isempty(successful_results)
            mean([r.risk_score for r in successful_results])
        else
            0.0
        end

        response = Dict(
            "total_wallets" => length(wallet_addresses),
            "successful_analyses" => length(successful_results),
            "failed_analyses" => length(wallet_addresses) - length(successful_results),
            "average_risk_score" => round(avg_risk_score, digits=2),
            "results" => results,
            "timestamp" => string(now())
        )

        return HTTP.Response(200, JSON3.write(response))

    catch e
        @error "❌ Batch analysis failed: $e"
        return HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
    end
end

# ===============================================================================
# ROUTE REGISTRATION
# ===============================================================================

function register_analysis_routes()
    @info "🚀 Registering Analysis API routes (JuliaOS Native)..."

    # Main analysis endpoints
    @post "/api/v1/analysis/analyze" analyze_wallet_handler
    @get "/api/v1/analysis/quick/{wallet_address}" quick_risk_assessment_handler
    @get "/api/v1/analysis/clusters/{wallet_address}" cluster_analysis_handler
    @post "/api/v1/analysis/batch" batch_analysis_handler

    # Legacy routes for compatibility
    @post "/api/analysis/analyze" analyze_wallet_handler
    @get "/api/analysis/quick/{wallet_address}" quick_risk_assessment_handler

    @info "✅ Analysis API routes registered successfully!"
end

# Auto-register routes when module is loaded
__init__() = register_analysis_routes()

end # module AnalysisHandlers
