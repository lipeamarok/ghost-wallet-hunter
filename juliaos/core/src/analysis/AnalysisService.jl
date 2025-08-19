"""
AnalysisService.jl - Core wallet analysis service for Ghost Wallet Hunter

Provides comprehensive wallet cluster analysis and risk assessment.
Migrated from backend/services/analysis_service.py for optimal performance.
"""
module AnalysisService

using HTTP
using JSON3
using Dates
using Statistics
using Logging

# Import other JuliaOS modules
include("../blockchain/SolanaService.jl")
using .SolanaService

include("../resources/Resources.jl")
using .Resources

export AnalysisResult, WalletAnalyzer, analyze_wallet, calculate_risk_score

# ========================================
# DATA STRUCTURES
# ========================================

"""Risk levels for wallet analysis"""
@enum RiskLevel LOW=1 MEDIUM=2 HIGH=3 CRITICAL=4

"""
Analysis result container
"""
mutable struct AnalysisResult
    wallet_address::String
    risk_score::Float64
    risk_level::RiskLevel
    total_connections::Int
    clusters::Vector{Dict{String,Any}}
    transactions_analyzed::Int
    patterns_detected::Vector{String}
    ai_insights::String
    analysis_duration_ms::Float64
    analysis_method::String

    function AnalysisResult(wallet_address::String)
        new(
            wallet_address,
            0.0,
            LOW,
            0,
            [],
            0,
            [],
            "",
            0.0,
            "julia_native"
        )
    end
end

"""
Wallet analyzer with Solana integration
"""
mutable struct WalletAnalyzer
    solana_client::SolanaService.SolanaClient
    max_depth::Int
    max_transactions::Int

    function WalletAnalyzer(; rpc_url::String = get(ENV, "SOLANA_RPC_URL", "https://api.mainnet-beta.solana.com"), max_depth::Int = 3, max_transactions::Int = 1000)
        solana_client = SolanaService.SolanaClient(rpc_url)
        new(solana_client, max_depth, max_transactions)
    end
end

# ========================================
# MAIN ANALYSIS FUNCTIONS
# ========================================

"""
    analyze_wallet(analyzer::WalletAnalyzer, wallet_address::String; depth::Int=2, include_ai::Bool=true) -> AnalysisResult

Perform comprehensive wallet analysis enhanced with AI.
Migrated from Python AnalysisService.analyze_wallet().
"""
function analyze_wallet(
    analyzer::WalletAnalyzer,
    wallet_address::String;
    depth::Int = 2,
    include_ai::Bool = true
)
    start_time = now()
    result = AnalysisResult(wallet_address)

    try
        @info "Starting analysis for wallet: $wallet_address with depth $depth"

        # Validate wallet address
        if !SolanaService.validate_wallet_address(wallet_address)
            throw(ArgumentError("Invalid wallet address format"))
        end

        # Get wallet transactions
        transactions = get_wallet_transactions(analyzer, wallet_address)
        result.transactions_analyzed = length(transactions)

        if isempty(transactions)
            @warn "No transactions found for wallet: $wallet_address"
            result.analysis_duration_ms = (now() - start_time).value
            return result
        end

        # Build transaction graph
        graph = build_transaction_graph(analyzer, wallet_address, transactions, depth)
        result.total_connections = length(get(graph, wallet_address, []))

        # Detect clusters
        clusters = detect_clusters(graph, wallet_address)
        result.clusters = clusters

        # Calculate risk scores
        risk_analysis = calculate_risk_scores(clusters, transactions)
        result.risk_score = risk_analysis["overall_risk"]
        result.patterns_detected = risk_analysis["patterns"]

        # Enhanced AI Analysis (if enabled)
        if include_ai
            ai_analysis = perform_ai_analysis(wallet_address, transactions, clusters)

            # Combine traditional and AI analysis
            result.risk_score = combine_risk_scores(result.risk_score, ai_analysis["risk_score"])
            result.ai_insights = ai_analysis["insights"]
            result.analysis_method = "julia_native+ai"

            # Add AI-detected patterns
            append!(result.patterns_detected, ai_analysis["suspicious_patterns"])
        end

        # Determine final risk level
        result.risk_level = determine_risk_level(result.risk_score)

        # Record duration
        result.analysis_duration_ms = (now() - start_time).value

        @info "Analysis completed for $wallet_address" risk_score=result.risk_score risk_level=result.risk_level
        return result

    catch e
        @error "Analysis failed for wallet: $wallet_address" error=e
        result.analysis_duration_ms = (now() - start_time).value
        rethrow(e)
    end
end

# ========================================
# TRANSACTION PROCESSING
# ========================================

"""
Get wallet transactions with caching and filtering
"""
function get_wallet_transactions(analyzer::WalletAnalyzer, wallet_address::String)
    try
        # Get transactions from Solana
        signatures = SolanaService.get_wallet_transactions(
            analyzer.solana_client,
            wallet_address;
            limit = min(analyzer.max_transactions, 1000)
        )

        # Process and enrich transaction data
        transactions = []
        for sig_info in signatures
            if haskey(sig_info, "signature")
                # Get detailed transaction if needed
                tx_details = SolanaService.get_transaction_details(
                    analyzer.solana_client,
                    sig_info["signature"]
                )

                # Merge signature info with details
                merged_tx = merge(sig_info, tx_details)
                push!(transactions, merged_tx)
            end
        end

        @info "Retrieved $(length(transactions)) transactions for analysis"
        return transactions

    catch e
        @error "Failed to get wallet transactions" wallet=wallet_address error=e
        return []
    end
end

# ========================================
# GRAPH BUILDING
# ========================================

"""
Build transaction graph for cluster analysis
"""
function build_transaction_graph(
    analyzer::WalletAnalyzer,
    root_wallet::String,
    transactions::Vector,
    depth::Int
)
    graph = Dict{String, Vector{String}}()
    visited = Set{String}()

    function explore_wallet(wallet::String, current_depth::Int)
        if current_depth > depth || wallet in visited
            return
        end

        push!(visited, wallet)
        graph[wallet] = String[]

        # Extract connected wallets from transactions
        for tx in transactions
            connected_wallets = extract_connected_wallets(tx, wallet)
            for connected in connected_wallets
                if connected != wallet && SolanaService.validate_wallet_address(connected)
                    push!(graph[wallet], connected)

                    # Recursive exploration for next depth
                    if current_depth < depth
                        explore_wallet(connected, current_depth + 1)
                    end
                end
            end
        end
    end

    explore_wallet(root_wallet, 1)
    return graph
end

"""
Extract connected wallet addresses from transaction
"""
function extract_connected_wallets(transaction::Dict, focus_wallet::String)
    connected = String[]

    try
        # Extract from transaction structure
        if haskey(transaction, "transaction") && haskey(transaction["transaction"], "message")
            message = transaction["transaction"]["message"]

            if haskey(message, "accountKeys")
                for account in message["accountKeys"]
                    if isa(account, String) && account != focus_wallet
                        push!(connected, account)
                    end
                end
            end
        end
    catch e
        @debug "Error extracting connected wallets" error=e
    end

    return unique(connected)
end

# ========================================
# CLUSTER DETECTION
# ========================================

"""
Detect wallet clusters based on transaction patterns
"""
function detect_clusters(graph::Dict{String, Vector{String}}, root_wallet::String)
    clusters = []

    try
        # Simple clustering based on connection frequency
        wallet_connections = Dict{String, Int}()

        for (wallet, connections) in graph
            for connected in connections
                wallet_connections[connected] = get(wallet_connections, connected, 0) + 1
            end
        end

        # Group highly connected wallets
        high_connection_threshold = 3
        cluster_wallets = String[]

        for (wallet, count) in wallet_connections
            if count >= high_connection_threshold
                push!(cluster_wallets, wallet)
            end
        end

        if !isempty(cluster_wallets)
            push!(clusters, Dict(
                "cluster_id" => "high_activity_cluster",
                "wallets" => cluster_wallets,
                "connection_strength" => mean(values(wallet_connections)),
                "risk_indicator" => length(cluster_wallets) > 5 ? "HIGH" : "MEDIUM"
            ))
        end

    catch e
        @error "Error in cluster detection" error=e
    end

    return clusters
end

# ========================================
# RISK CALCULATION
# ========================================

"""
Calculate risk scores based on transaction patterns and clusters
"""
function calculate_risk_scores(clusters::Vector, transactions::Vector)
    risk_analysis = Dict{String, Any}(
        "overall_risk" => 0.0,
        "patterns" => String[]
    )

    try
        base_risk = 0.0
        patterns = String[]

        # Risk from cluster analysis
        for cluster in clusters
            cluster_risk = 0.2 # Base cluster risk

            if haskey(cluster, "risk_indicator")
                if cluster["risk_indicator"] == "HIGH"
                    cluster_risk = 0.4
                    push!(patterns, "high_risk_cluster")
                elseif cluster["risk_indicator"] == "MEDIUM"
                    cluster_risk = 0.2
                    push!(patterns, "medium_risk_cluster")
                end
            end

            base_risk += cluster_risk
        end

        # Risk from transaction frequency
        if length(transactions) > 1000
            base_risk += 0.3
            push!(patterns, "high_frequency_transactions")
        elseif length(transactions) > 100
            base_risk += 0.1
            push!(patterns, "moderate_frequency_transactions")
        end

        # Cap risk score at 1.0
        risk_analysis["overall_risk"] = min(base_risk, 1.0)
        risk_analysis["patterns"] = patterns

    catch e
        @error "Error calculating risk scores" error=e
    end

    return risk_analysis
end

# ========================================
# AI ANALYSIS INTEGRATION
# ========================================

"""
Perform AI-enhanced analysis using Resources.call_ai
"""
function perform_ai_analysis(wallet_address::String, transactions::Vector, clusters::Vector)
    ai_analysis = Dict{String, Any}(
        "risk_score" => 0.0,
        "insights" => "AI analysis unavailable",
        "suspicious_patterns" => String[]
    )

    try
        # Prepare data summary for AI
        summary = prepare_analysis_summary(wallet_address, transactions, clusters)

        # Call AI for analysis
        prompt = """
        Analyze this Solana wallet for suspicious activity:

        Wallet: $wallet_address
        Transactions: $(length(transactions))
        Clusters detected: $(length(clusters))

        Summary: $summary

        Provide:
        1. Risk score (0.0 to 1.0)
        2. Key insights
        3. Suspicious patterns found

        Format: JSON with keys: risk_score, insights, suspicious_patterns
        """

        ai_response = Resources.call_ai_with_retry("openai", prompt; max_retries=2)

        # Parse AI response
        parsed_response = JSON3.read(ai_response)

        ai_analysis["risk_score"] = get(parsed_response, "risk_score", 0.0)
        ai_analysis["insights"] = get(parsed_response, "insights", "AI analysis completed")
        ai_analysis["suspicious_patterns"] = get(parsed_response, "suspicious_patterns", String[])

        @info "AI analysis completed" risk_score=ai_analysis["risk_score"]

    catch e
        @warn "AI analysis failed, using traditional analysis only" error=e
        ai_analysis["insights"] = "AI analysis failed: $e"
    end

    return ai_analysis
end

"""
Prepare analysis summary for AI processing
"""
function prepare_analysis_summary(wallet_address::String, transactions::Vector, clusters::Vector)
    summary = Dict(
        "transaction_count" => length(transactions),
        "cluster_count" => length(clusters),
        "unique_connections" => 0,
        "recent_activity" => false
    )

    try
        # Count unique connections
        unique_wallets = Set{String}()
        for tx in transactions
            connected = extract_connected_wallets(tx, wallet_address)
            union!(unique_wallets, connected)
        end
        summary["unique_connections"] = length(unique_wallets)

        # Check recent activity (last 24 hours)
        if !isempty(transactions) && haskey(transactions[1], "blockTime")
            latest_time = transactions[1]["blockTime"]
            current_time = time()
            summary["recent_activity"] = (current_time - latest_time) < 86400 # 24 hours
        end

    catch e
        @debug "Error preparing analysis summary" error=e
    end

    return JSON3.write(summary)
end

# ========================================
# UTILITY FUNCTIONS
# ========================================

"""
Combine traditional risk score with AI risk score
"""
function combine_risk_scores(traditional_risk::Float64, ai_risk::Float64)
    # Weighted combination: 60% traditional, 40% AI
    combined = 0.6 * traditional_risk + 0.4 * ai_risk
    return min(combined, 1.0)
end

"""
Determine risk level from numeric score
"""
function determine_risk_level(risk_score::Float64)
    if risk_score >= 0.8
        return CRITICAL
    elseif risk_score >= 0.6
        return HIGH
    elseif risk_score >= 0.3
        return MEDIUM
    else
        return LOW
    end
end

end # module AnalysisService
