"""
Ghost Wallet Hunter - Schema Definitions (Julia)

Julia-native schemas and data structures that replace Pydantic models.
Provides type safety, validation, and serialization for all API data.
"""

module Schemas

using Dates
using JSON3

# Include validators
include("../utils/Validators.jl")
using .Validators

# Risk level enumeration
@enum RiskLevel begin
    VERY_LOW = 1
    LOW = 2
    MEDIUM = 3
    HIGH = 4
    VERY_HIGH = 5
    CRITICAL = 6
end

# Convert risk level to string
function risk_level_to_string(level::RiskLevel)::String
    return if level == VERY_LOW
        "very_low"
    elseif level == LOW
        "low"
    elseif level == MEDIUM
        "medium"
    elseif level == HIGH
        "high"
    elseif level == VERY_HIGH
        "very_high"
    elseif level == CRITICAL
        "critical"
    else
        "unknown"
    end
end

# Convert string to risk level
function string_to_risk_level(s::String)::RiskLevel
    lower_s = lowercase(s)
    return if lower_s == "very_low"
        VERY_LOW
    elseif lower_s == "low"
        LOW
    elseif lower_s == "medium"
        MEDIUM
    elseif lower_s == "high"
        HIGH
    elseif lower_s == "very_high"
        VERY_HIGH
    elseif lower_s == "critical"
        CRITICAL
    else
        throw(ArgumentError("Invalid risk level: $s"))
    end
end

# Transaction information structure
mutable struct TransactionInfo
    signature::String
    block_time::Union{DateTime, Nothing}
    slot::Union{Int, Nothing}
    fee::Union{Int, Nothing}
    status::String
    instructions::Vector{Dict{String, Any}}

    function TransactionInfo(signature::String, block_time::Union{DateTime, Nothing} = nothing,
                           slot::Union{Int, Nothing} = nothing, fee::Union{Int, Nothing} = nothing,
                           status::String = "unknown", instructions::Vector{Dict{String, Any}} = Dict{String, Any}[])
        # Validate signature
        if !Validators.validate_transaction_signature(signature)
            throw(ArgumentError("Invalid transaction signature: $signature"))
        end

        new(signature, block_time, slot, fee, status, instructions)
    end
end

# Wallet cluster structure
mutable struct WalletCluster
    cluster_id::String
    addresses::Vector{String}
    total_connections::Int
    risk_score::Float64
    risk_level::RiskLevel
    transactions::Vector{TransactionInfo}
    created_at::DateTime
    updated_at::DateTime
    metadata::Dict{String, Any}

    function WalletCluster(cluster_id::String, addresses::Vector{String},
                          total_connections::Int = 0, risk_score::Float64 = 0.0,
                          risk_level::RiskLevel = LOW,
                          transactions::Vector{TransactionInfo} = TransactionInfo[],
                          metadata::Dict{String, Any} = Dict{String, Any}())

        # Validate addresses
        for addr in addresses
            if !Validators.validate_solana_address(addr)
                throw(ArgumentError("Invalid Solana address in cluster: $addr"))
            end
        end

        # Validate risk score
        if !Validators.validate_risk_score(risk_score)
            throw(ArgumentError("Invalid risk score: $risk_score"))
        end

        now_time = now()
        new(cluster_id, addresses, total_connections, risk_score, risk_level,
            transactions, now_time, now_time, metadata)
    end
end

# Analysis request structure
mutable struct AnalysisRequest
    address::String
    analysis_type::String
    depth::Int
    include_transactions::Bool
    risk_threshold::Float64
    cluster_analysis::Bool
    ai_analysis::Bool
    metadata::Dict{String, Any}

    function AnalysisRequest(address::String, analysis_type::String = "full",
                           depth::Int = 3, include_transactions::Bool = true,
                           risk_threshold::Float64 = 0.7, cluster_analysis::Bool = true,
                           ai_analysis::Bool = false,
                           metadata::Dict{String, Any} = Dict{String, Any}())

        # Validate address
        if !Validators.validate_solana_address(address)
            throw(ArgumentError("Invalid Solana address: $address"))
        end

        # Validate depth
        if !(1 <= depth <= 10)
            throw(ArgumentError("Analysis depth must be between 1 and 10"))
        end

        # Validate risk threshold
        if !Validators.validate_risk_score(risk_threshold)
            throw(ArgumentError("Invalid risk threshold: $risk_threshold"))
        end

        # Validate analysis type
        valid_types = ["quick", "standard", "full", "deep", "cluster_only"]
        if !(analysis_type in valid_types)
            throw(ArgumentError("Invalid analysis type. Must be one of: $(join(valid_types, ", "))"))
        end

        new(address, analysis_type, depth, include_transactions, risk_threshold,
            cluster_analysis, ai_analysis, metadata)
    end
end

# Analysis response structure
mutable struct AnalysisResponse
    address::String
    analysis_id::String
    status::String
    risk_score::Float64
    risk_level::RiskLevel
    cluster::Union{WalletCluster, Nothing}
    transactions::Vector{TransactionInfo}
    ai_insights::Union{Dict{String, Any}, Nothing}
    performance_metrics::Dict{String, Any}
    created_at::DateTime
    completed_at::Union{DateTime, Nothing}
    metadata::Dict{String, Any}

    function AnalysisResponse(address::String, analysis_id::String, status::String = "pending",
                            risk_score::Float64 = 0.0, risk_level::RiskLevel = LOW,
                            cluster::Union{WalletCluster, Nothing} = nothing,
                            transactions::Vector{TransactionInfo} = TransactionInfo[],
                            ai_insights::Union{Dict{String, Any}, Nothing} = nothing,
                            performance_metrics::Dict{String, Any} = Dict{String, Any}(),
                            completed_at::Union{DateTime, Nothing} = nothing,
                            metadata::Dict{String, Any} = Dict{String, Any}())

        # Validate address
        if !Validators.validate_solana_address(address)
            throw(ArgumentError("Invalid Solana address: $address"))
        end

        # Validate risk score
        if !Validators.validate_risk_score(risk_score)
            throw(ArgumentError("Invalid risk score: $risk_score"))
        end

        # Validate status
        valid_statuses = ["pending", "processing", "completed", "failed", "timeout"]
        if !(status in valid_statuses)
            throw(ArgumentError("Invalid status. Must be one of: $(join(valid_statuses, ", "))"))
        end

        created_time = now()
        new(address, analysis_id, status, risk_score, risk_level, cluster, transactions,
            ai_insights, performance_metrics, created_time, completed_at, metadata)
    end
end

# API health check response
mutable struct HealthCheckResponse
    status::String
    version::String
    timestamp::DateTime
    uptime_seconds::Float64
    services::Dict{String, Dict{String, Any}}

    function HealthCheckResponse(status::String = "operational", version::String = "0.2.0",
                               uptime_seconds::Float64 = 0.0,
                               services::Dict{String, Dict{String, Any}} = Dict{String, Dict{String, Any}}())
        new(status, version, now(), uptime_seconds, services)
    end
end

# Performance metrics structure
mutable struct PerformanceMetrics
    operation::String
    duration_ms::Float64
    memory_usage_mb::Float64
    cpu_usage_percent::Float64
    thread_count::Int
    success::Bool
    timestamp::DateTime
    metadata::Dict{String, Any}

    function PerformanceMetrics(operation::String, duration_ms::Float64 = 0.0,
                              memory_usage_mb::Float64 = 0.0, cpu_usage_percent::Float64 = 0.0,
                              thread_count::Int = Threads.nthreads(), success::Bool = true,
                              metadata::Dict{String, Any} = Dict{String, Any}())
        new(operation, duration_ms, memory_usage_mb, cpu_usage_percent,
            thread_count, success, now(), metadata)
    end
end

# Error response structure
mutable struct ErrorResponse
    error_code::String
    message::String
    details::Union{Dict{String, Any}, Nothing}
    timestamp::DateTime
    request_id::Union{String, Nothing}

    function ErrorResponse(error_code::String, message::String,
                         details::Union{Dict{String, Any}, Nothing} = nothing,
                         request_id::Union{String, Nothing} = nothing)
        new(error_code, message, details, now(), request_id)
    end
end

# Serialization functions

"""
Convert TransactionInfo to dictionary.
"""
function to_dict(tx::TransactionInfo)::Dict{String, Any}
    return Dict(
        "signature" => tx.signature,
        "block_time" => isnothing(tx.block_time) ? nothing : string(tx.block_time),
        "slot" => tx.slot,
        "fee" => tx.fee,
        "status" => tx.status,
        "instructions" => tx.instructions
    )
end

"""
Convert WalletCluster to dictionary.
"""
function to_dict(cluster::WalletCluster)::Dict{String, Any}
    return Dict(
        "cluster_id" => cluster.cluster_id,
        "addresses" => cluster.addresses,
        "total_connections" => cluster.total_connections,
        "risk_score" => cluster.risk_score,
        "risk_level" => risk_level_to_string(cluster.risk_level),
        "transactions" => [to_dict(tx) for tx in cluster.transactions],
        "created_at" => string(cluster.created_at),
        "updated_at" => string(cluster.updated_at),
        "metadata" => cluster.metadata
    )
end

"""
Convert AnalysisRequest to dictionary.
"""
function to_dict(request::AnalysisRequest)::Dict{String, Any}
    return Dict(
        "address" => request.address,
        "analysis_type" => request.analysis_type,
        "depth" => request.depth,
        "include_transactions" => request.include_transactions,
        "risk_threshold" => request.risk_threshold,
        "cluster_analysis" => request.cluster_analysis,
        "ai_analysis" => request.ai_analysis,
        "metadata" => request.metadata
    )
end

"""
Convert AnalysisResponse to dictionary.
"""
function to_dict(response::AnalysisResponse)::Dict{String, Any}
    return Dict(
        "address" => response.address,
        "analysis_id" => response.analysis_id,
        "status" => response.status,
        "risk_score" => response.risk_score,
        "risk_level" => risk_level_to_string(response.risk_level),
        "cluster" => isnothing(response.cluster) ? nothing : to_dict(response.cluster),
        "transactions" => [to_dict(tx) for tx in response.transactions],
        "ai_insights" => response.ai_insights,
        "performance_metrics" => response.performance_metrics,
        "created_at" => string(response.created_at),
        "completed_at" => isnothing(response.completed_at) ? nothing : string(response.completed_at),
        "metadata" => response.metadata
    )
end

"""
Convert HealthCheckResponse to dictionary.
"""
function to_dict(health::HealthCheckResponse)::Dict{String, Any}
    return Dict(
        "status" => health.status,
        "version" => health.version,
        "timestamp" => string(health.timestamp),
        "uptime_seconds" => health.uptime_seconds,
        "services" => health.services
    )
end

"""
Convert PerformanceMetrics to dictionary.
"""
function to_dict(metrics::PerformanceMetrics)::Dict{String, Any}
    return Dict(
        "operation" => metrics.operation,
        "duration_ms" => metrics.duration_ms,
        "memory_usage_mb" => metrics.memory_usage_mb,
        "cpu_usage_percent" => metrics.cpu_usage_percent,
        "thread_count" => metrics.thread_count,
        "success" => metrics.success,
        "timestamp" => string(metrics.timestamp),
        "metadata" => metrics.metadata
    )
end

"""
Convert ErrorResponse to dictionary.
"""
function to_dict(error::ErrorResponse)::Dict{String, Any}
    return Dict(
        "error_code" => error.error_code,
        "message" => error.message,
        "details" => error.details,
        "timestamp" => string(error.timestamp),
        "request_id" => error.request_id
    )
end

# Deserialization functions

"""
Create TransactionInfo from dictionary.
"""
function from_dict(::Type{TransactionInfo}, data::Dict{String, Any})::TransactionInfo
    block_time = if haskey(data, "block_time") && !isnothing(data["block_time"])
        DateTime(data["block_time"])
    else
        nothing
    end

    return TransactionInfo(
        data["signature"],
        block_time,
        get(data, "slot", nothing),
        get(data, "fee", nothing),
        get(data, "status", "unknown"),
        get(data, "instructions", Dict{String, Any}[])
    )
end

"""
Create WalletCluster from dictionary.
"""
function from_dict(::Type{WalletCluster}, data::Dict{String, Any})::WalletCluster
    risk_level = string_to_risk_level(data["risk_level"])

    transactions = if haskey(data, "transactions")
        [from_dict(TransactionInfo, tx_data) for tx_data in data["transactions"]]
    else
        TransactionInfo[]
    end

    cluster = WalletCluster(
        data["cluster_id"],
        data["addresses"],
        get(data, "total_connections", 0),
        data["risk_score"],
        risk_level,
        transactions,
        get(data, "metadata", Dict{String, Any}())
    )

    # Set timestamps if provided
    if haskey(data, "created_at")
        cluster.created_at = DateTime(data["created_at"])
    end
    if haskey(data, "updated_at")
        cluster.updated_at = DateTime(data["updated_at"])
    end

    return cluster
end

"""
Create AnalysisRequest from dictionary.
"""
function from_dict(::Type{AnalysisRequest}, data::Dict{String, Any})::AnalysisRequest
    return AnalysisRequest(
        data["address"],
        get(data, "analysis_type", "full"),
        get(data, "depth", 3),
        get(data, "include_transactions", true),
        get(data, "risk_threshold", 0.7),
        get(data, "cluster_analysis", true),
        get(data, "ai_analysis", false),
        get(data, "metadata", Dict{String, Any}())
    )
end

"""
Create AnalysisResponse from dictionary.
"""
function from_dict(::Type{AnalysisResponse}, data::Dict{String, Any})::AnalysisResponse
    risk_level = string_to_risk_level(data["risk_level"])

    cluster = if haskey(data, "cluster") && !isnothing(data["cluster"])
        from_dict(WalletCluster, data["cluster"])
    else
        nothing
    end

    transactions = if haskey(data, "transactions")
        [from_dict(TransactionInfo, tx_data) for tx_data in data["transactions"]]
    else
        TransactionInfo[]
    end

    completed_at = if haskey(data, "completed_at") && !isnothing(data["completed_at"])
        DateTime(data["completed_at"])
    else
        nothing
    end

    response = AnalysisResponse(
        data["address"],
        data["analysis_id"],
        get(data, "status", "pending"),
        data["risk_score"],
        risk_level,
        cluster,
        transactions,
        get(data, "ai_insights", nothing),
        get(data, "performance_metrics", Dict{String, Any}()),
        completed_at,
        get(data, "metadata", Dict{String, Any}())
    )

    # Set created_at if provided
    if haskey(data, "created_at")
        response.created_at = DateTime(data["created_at"])
    end

    return response
end

"""
JSON serialization for all schema types.
"""
function to_json(obj)::String
    return JSON3.write(to_dict(obj))
end

"""
JSON deserialization for schema types.
"""
function from_json(::Type{T}, json_str::String) where T
    data = JSON3.read(json_str, Dict{String, Any})
    return from_dict(T, data)
end

"""
Validate schema object based on its type.
"""
function validate_schema(obj::TransactionInfo)::Vector{String}
    errors = String[]

    if !Validators.validate_transaction_signature(obj.signature)
        push!(errors, "Invalid transaction signature")
    end

    if !isnothing(obj.slot) && obj.slot < 0
        push!(errors, "Slot number cannot be negative")
    end

    if !isnothing(obj.fee) && obj.fee < 0
        push!(errors, "Fee cannot be negative")
    end

    return errors
end

function validate_schema(obj::WalletCluster)::Vector{String}
    errors = String[]

    if isempty(obj.cluster_id)
        push!(errors, "Cluster ID cannot be empty")
    end

    if isempty(obj.addresses)
        push!(errors, "Cluster must have at least one address")
    end

    for addr in obj.addresses
        if !Validators.validate_solana_address(addr)
            push!(errors, "Invalid address in cluster: $addr")
        end
    end

    if !Validators.validate_risk_score(obj.risk_score)
        push!(errors, "Invalid risk score: $(obj.risk_score)")
    end

    if obj.total_connections < 0
        push!(errors, "Total connections cannot be negative")
    end

    return errors
end

function validate_schema(obj::AnalysisRequest)::Vector{String}
    errors = String[]

    if !Validators.validate_solana_address(obj.address)
        push!(errors, "Invalid Solana address")
    end

    if !(1 <= obj.depth <= 10)
        push!(errors, "Analysis depth must be between 1 and 10")
    end

    if !Validators.validate_risk_score(obj.risk_threshold)
        push!(errors, "Invalid risk threshold")
    end

    valid_types = ["quick", "standard", "full", "deep", "cluster_only"]
    if !(obj.analysis_type in valid_types)
        push!(errors, "Invalid analysis type")
    end

    return errors
end

function validate_schema(obj::AnalysisResponse)::Vector{String}
    errors = String[]

    if !Validators.validate_solana_address(obj.address)
        push!(errors, "Invalid Solana address")
    end

    if isempty(obj.analysis_id)
        push!(errors, "Analysis ID cannot be empty")
    end

    if !Validators.validate_risk_score(obj.risk_score)
        push!(errors, "Invalid risk score")
    end

    valid_statuses = ["pending", "processing", "completed", "failed", "timeout"]
    if !(obj.status in valid_statuses)
        push!(errors, "Invalid status")
    end

    # Validate cluster if present
    if !isnothing(obj.cluster)
        cluster_errors = validate_schema(obj.cluster)
        append!(errors, cluster_errors)
    end

    # Validate transactions
    for tx in obj.transactions
        tx_errors = validate_schema(tx)
        append!(errors, tx_errors)
    end

    return errors
end

"""
Health check for schemas module.
"""
function health_check()::Dict{String, Any}
    return Dict(
        "status" => "operational",
        "module" => "Schemas",
        "risk_levels" => [risk_level_to_string(level) for level in instances(RiskLevel)],
        "supported_types" => ["TransactionInfo", "WalletCluster", "AnalysisRequest", "AnalysisResponse", "HealthCheckResponse", "PerformanceMetrics", "ErrorResponse"],
        "timestamp" => string(now())
    )
end

# Export main types and functions
export RiskLevel, VERY_LOW, LOW, MEDIUM, HIGH, VERY_HIGH, CRITICAL,
       risk_level_to_string, string_to_risk_level,
       TransactionInfo, WalletCluster, AnalysisRequest, AnalysisResponse,
       HealthCheckResponse, PerformanceMetrics, ErrorResponse,
       to_dict, from_dict, to_json, from_json,
       validate_schema, health_check

end # module Schemas
