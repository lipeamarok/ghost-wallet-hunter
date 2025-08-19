module UnifiedInvestigationHandler

using Oxygen
using HTTP
using JSON3
using Dates
using StructTypes
import ..FrontendHandlers: INVESTIGATION_STORE
import Main.JuliaOS.DetectiveAgents

const HAS_REAL_AI = isdefined(Main.JuliaOS, :InvestigationHandlers)

# ---------------- NEW: Config & Helpers for Async Mode ----------------
const MULTI_DETECTIVE_TYPES = ["poirot","marple","spade","marlowee","dupin","shadow","raven"]
const INTERNAL_TO_DISPLAY = Dict("marlowee"=>"marlowe")
_display_id(id::String) = get(INTERNAL_TO_DISPLAY, id, id)

function _compute_consensus(individual::Dict{String,Any})
    vals = collect(values(individual))
    valid = filter(v-> get(v, "status", "") != "failed", vals)
    if isempty(valid)
        return 0.0, 0.0, 0, length(vals)
    end
    rs = [get(v, "risk_score", 0.0) for v in valid]
    cs = [get(v, "confidence", 0.0) for v in valid]
    return mean(rs), mean(cs), length(valid), length(vals)-length(valid)
end

# Normalized response struct
struct UnifiedInvestigationResponse
    success::Bool
    investigation_id::String
    shortId::String
    status::String
    wallet_address::String
    investigation_type::String
    timestamp::String
    timing::Dict{String,Any}
    results::Dict{String,Any}
    metrics::Dict{String,Any}
    version::String
    deprecated::Bool
    use::String
end

StructTypes.StructType(::Type{UnifiedInvestigationResponse}) = StructTypes.Struct()

function _now(); Dates.now(); end
function _gen_id(); "INV_" * Dates.format(_now(), "yyyymmdd_HHMMSS"); end

# Build normalized block (frontend expects results.raw + results.normalized)
function build_normalized(raw::Dict, id::String, wallet::String, inv_type::String)
    # --- Risk score normalization (always provide both 0-100 and 0-1 forms) ---
    risk_raw_any = get(raw, "consensus_risk_score", get(raw, "risk_score", get(raw, "riskScore", 0.0)))
    # Accept either 0-1 or 0-100; detect scale heuristically
    risk_0_1 = risk_raw_any <= 1 ? Float64(risk_raw_any) : clamp(risk_raw_any / 100, 0.0, 1.0)
    risk_0_100 = round(risk_0_1 * 100; digits=2)
    conf_raw_any = get(raw, "consensus_confidence", get(raw, "confidence", 0.75))
    conf_0_1 = conf_raw_any <= 1 ? Float64(conf_raw_any) : clamp(conf_raw_any / 100, 0.0, 1.0)
    conf_0_100 = round(conf_0_1 * 100; digits=2)
    flagged = get(raw, "flagged_activities", get(raw, "flaggedActivities", Any[]))
    recommendations = get(raw, "recommendations", Any[])
    duration_ms = get(raw, "duration_ms", get(raw, "processing_time_ms", 0.0))

    detailed = haskey(raw, "detailedFindings") ? raw["detailedFindings"] : get(raw, "individual_results", get(raw, "agents", Dict()))

    # Fallback / degradation detection: if underlying raw claims multi_detective but no individual results or all zeros
    degraded = false
    degraded_agents = get(raw, "degraded_agents", false)
    if haskey(raw, "multi_detective_analysis")
        indiv = get(raw, "individual_results", Dict())
        if isempty(indiv)
            degraded = true
        end
    end
    degraded = degraded || degraded_agents

    normalized = Dict(
        "id" => id,
        "investigationId" => id,
        "walletAddress" => wallet,
        "investigationType" => inv_type,
        "summary" => Dict(
            "riskScore" => risk_0_100,               # legacy (0-100)
            "riskScoreNormalized" => round(risk_0_1; digits=4), # new (0-1)
            "riskScoreRaw" => risk_raw_any,           # raw original value
            "confidence" => conf_0_100,               # 0-100 for UI gauge
            "confidenceNormalized" => round(conf_0_1; digits=4),
            "flaggedActivities" => flagged,
            "recommendations" => recommendations,
            "degraded" => degraded,
            "degradedAgents" => degraded_agents,
        ),
        "detailedFindings" => detailed,
        "metadata" => Dict(
            "walletAddress" => wallet,
            "investigationType" => inv_type,
            "duration" => duration_ms,
            "completionTime" => string(_now()),
            "servicesUsed" => Dict("julia"=>true),
            "agents" => collect(keys(get(raw, "individual_results", Dict()))),
            "version" => "v2",
        )
    )

    # Also reflect normalized scores back into raw (idempotent, harmless for downstream)
    raw["risk_score_normalized"] = risk_0_1
    raw["risk_score_100"] = risk_0_100
    raw["confidence_normalized"] = conf_0_1
    raw["confidence_100"] = conf_0_100
    return normalized
end

# ---------------- NEW: Async Orchestration ----------------
function _start_async_investigation(id::String, wallet::String, inv_type::String, started_iso::String)
    @info "🚀 Starting async investigation $id for $wallet"
    # Initialize agents map with pending statuses
    local agents_init = Dict{String,Any}()
    for dt in MULTI_DETECTIVE_TYPES
        agents_init[_display_id(dt)] = Dict(
            "status"=>"pending"
        )
    end
    INVESTIGATION_STORE[id] = Dict(
        "status" => "running",
        "wallet_address" => wallet,
        "type" => inv_type,
        "started_at" => started_iso,
        "progress" => Dict(
            "overall"=>0.0,
            "agents_completed"=>0,
            "total_agents"=>length(MULTI_DETECTIVE_TYPES),
            "consensus"=>Dict("risk_score"=>0.0,"confidence"=>0.0)
        ),
        "agents" => agents_init,
        "results" => Dict(
            "raw" => Dict(
                "investigation_id"=>id,
                "wallet_address"=>wallet,
                "individual_results"=>Dict{String,Any}(),
                "multi_detective_analysis"=>true,
                "participating_detectives"=>[ _display_id(x) for x in MULTI_DETECTIVE_TYPES ],
                "consensus_risk_score"=>0.0,
                "consensus_confidence"=>0.0,
                "successful_investigations"=>0,
                "failed_investigations"=>0,
            ),
            "normalized" => Dict()
        )
    )

    ch = Channel{Tuple{String,Dict{String,Any}}}(length(MULTI_DETECTIVE_TYPES))

    for detective_type in MULTI_DETECTIVE_TYPES
        Threads.@spawn begin
            # Stagger start slightly to ensure observable incremental progress
            sleep(0.15)
            local res::Dict{String,Any}
            try
                res = DetectiveAgents.investigate_wallet(detective_type, wallet, id)
            catch e
                res = Dict("detective"=>detective_type, "status"=>"failed", "error"=>string(e), "risk_score"=>0.0, "confidence"=>0.0)
            end
            put!(ch, (detective_type, res))
        end
    end

    @async begin
        completed = 0; total = length(MULTI_DETECTIVE_TYPES)
        while completed < total
            dt, res = take!(ch)
            out_id = _display_id(dt)
            store = INVESTIGATION_STORE[id]
            agents = store["agents"]
            agents[out_id] = Dict(
                "status" => get(res, "status", "completed"),
                "risk_score" => get(res, "risk_score", 0.0),
                "confidence" => get(res, "confidence", 0.0),
                "finished_at" => string(_now())
            )
            raw = store["results"]["raw"]
            raw_individual = raw["individual_results"]
            raw_individual[out_id] = res
            # Recompute consensus but also strict success/failure counts
            avg_risk, avg_conf, _, _ = _compute_consensus(raw_individual)
            # Strict classification
            succ = count(v->get(v, "status", "") == "completed", values(raw_individual))
            failed = count(v->get(v, "status", "") != "completed", values(raw_individual))
            raw["consensus_risk_score"] = avg_risk
            raw["consensus_confidence"] = avg_conf
            raw["successful_investigations"] = succ
            raw["failed_investigations"] = failed
            completed = succ + failed
            progress_pct = completed / total * 100
            store["progress"]["overall"] = progress_pct
            store["progress"]["agents_completed"] = completed
            store["progress"]["consensus"] = Dict(
                "risk_score"=>avg_risk,
                "confidence"=>avg_conf,
                "successful"=>succ,
                "failed"=>failed
            )
            INVESTIGATION_STORE[id] = store
        end
        store = INVESTIGATION_STORE[id]
        raw = store["results"]["raw"]
        raw["timestamp"] = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
        # degraded flags
        raw["degraded_agents"] = (get(raw, "successful_investigations", 0) == 0)
        normalized = build_normalized(raw, id, wallet, inv_type)
        normalized["version"] = "v2"
        shortId = replace(id, "INV_"=>"")[(end-7):end]
        store["results"]["normalized"] = normalized
        store["status"] = "completed"
        store["completed_at"] = string(_now())
        store["shortId"] = shortId
        INVESTIGATION_STORE[id] = store
        @info "✅ Async investigation $id completed"
    end
end

function unified_investigate_handler(req::HTTP.Request; deprecated::Bool=false)
    id = _gen_id()
    t_start = time(); started_iso = string(_now())
    try
        data = JSON3.read(String(req.body))
        wallet = haskey(data, "wallet_address") ? String(data["wallet_address"]) : (haskey(data, "wallet") ? String(data["wallet"]) : (haskey(data, "address") ? String(data["address"]) : ""))
        inv_type = haskey(data, "investigation_type") ? String(data["investigation_type"]) : (haskey(data, "type") ? String(data["type"]) : "comprehensive")
        if isempty(strip(wallet))
            return HTTP.Response(400, JSON3.write(Dict("error"=>"wallet_address is required")))
        end
        # Basic Solana address validation: base58 charset and typical length (32-44)
        let w = strip(wallet)
            valid_chars = all(c -> c in "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz", w)
            if !(valid_chars && (length(w) >= 32 && length(w) <= 44))
                return HTTP.Response(400, JSON3.write(Dict("error"=>"invalid_wallet_address")))
            end
        end
        # NEW: synchronous flag parsing (robusto)
        synchronous = true
        if haskey(data, "synchronous")
            val = data["synchronous"]
            if (val === false) || (val == 0) || (val isa String && lowercase(String(val)) in ("false","0","no"))
                synchronous = false
            else
                synchronous = true
            end
        elseif haskey(data, "async")
            val = data["async"]
            if (val === true) || (val == 1) || (val isa String && lowercase(String(val)) in ("true","1","yes"))
                synchronous = false
            end
        elseif haskey(data, "return_mode") && lowercase(String(data["return_mode"])) in ("deferred","async")
            synchronous = false
        end
        @info "UnifiedInvestigate request" id wallet inv_type synchronous
        use_real_ai = (lowercase(inv_type) in ("real_ai","deep")) && HAS_REAL_AI && synchronous # keep real_ai path synchronous for now

        # Async branch
        if !synchronous && lowercase(inv_type) in ("comprehensive","multi","all")
            @info "Entering async branch" id wallet inv_type
            # Fire-and-forget quick prewarm with a single fast agent to seed caches
            try
                Threads.@spawn begin
                    try
                        DetectiveAgents.investigate_wallet("poirot", wallet, id*"_prewarm")
                    catch e
                        @debug "Prewarm failed" e
                    end
                end
            catch
            end
            _start_async_investigation(id, wallet, inv_type, started_iso)
            shortId = replace(id, "INV_"=>"")[(end-7):end]
            resp = Dict(
                "success"=>true,
                "investigation_id"=>id,
                "shortId"=>shortId,
                "status"=>"running",
                "wallet_address"=>wallet,
                "investigation_type"=>inv_type,
                "timestamp"=>started_iso,
                "progress"=>Dict("overall"=>0.0, "agents_completed"=>0, "total_agents"=>length(MULTI_DETECTIVE_TYPES)),
                "results"=>Dict("raw"=>Dict("individual_results"=>Dict()), "normalized"=>Dict()),
                "version"=>"v2",
                "deprecated"=>deprecated,
                "use"=>"/api/v1/investigate"
            )
            return HTTP.Response(202, JSON3.write(resp))
        end

        # ---------------- Existing synchronous path ----------------
        raw_result = Dict{String,Any}()
        if use_real_ai
            ai_body = JSON3.write(Dict(
                "wallet_address"=>wallet,
                "investigation_type"=> (lowercase(inv_type)=="deep" ? "deep" : "comprehensive"),
                "max_transactions"=> (lowercase(inv_type)=="deep" ? 100 : 50),
                "include_network_analysis"=> (lowercase(inv_type)=="deep"),
                "ai_analysis_level"=> (lowercase(inv_type)=="deep" ? "expert" : "advanced")
            ))
            real_req = HTTP.Request("POST", HTTP.URI("/api/real-ai/investigate"), [], ai_body)
            real_resp = Main.JuliaOS.InvestigationHandlers.investigate_wallet_real_ai_handler(real_req)
            raw_result = JSON3.read(String(real_resp.body))
            raw_result["investigation_id"] = get(raw_result, "case_id", id)
        else
            if lowercase(inv_type) == "comprehensive"
                raw_result = DetectiveAgents.investigate_wallet_multi_detective(wallet, id)
            else
                raw_result = DetectiveAgents.investigate_wallet("poirot", wallet, id)
            end
            raw_result["investigation_id"] = id
        end
        normalized = build_normalized(raw_result, id, wallet, inv_type)
        normalized["version"] = "v2"
        shortId = replace(id, "INV_"=>"")[(end-7):end]  # last 8 chars for compactness
        INVESTIGATION_STORE[id] = Dict(
            "status"=>"completed",
            "results"=>Dict("raw"=>raw_result, "normalized"=>normalized),
            "wallet_address"=>wallet,
            "type"=>inv_type,
            "timestamp"=>started_iso,
            "shortId"=>shortId
        )
        duration_ms = (time() - t_start)*1000; completed_iso = string(_now())
        local overall_success = get(raw_result, "successful_investigations", 0) > 0
        if !overall_success
            normalized["summary"]["analysisAvailable"] = false
            normalized["summary"]["failureReason"] = get(raw_result, "error", "all_agents_failed_or_returned_no_data")
        else
            normalized["summary"]["analysisAvailable"] = true
        end
    resp = UnifiedInvestigationResponse(overall_success, id, shortId, "completed", wallet, inv_type, completed_iso,
            Dict("started_at"=>started_iso, "completed_at"=>completed_iso, "duration_ms"=>duration_ms),
            Dict("raw"=>raw_result, "normalized"=>normalized),
            Dict("riskScore"=>normalized["summary"]["riskScore"], "confidence"=>normalized["summary"]["confidence"]),
            "v2", deprecated, "/api/v1/investigate")
        return HTTP.Response(200, JSON3.write(resp))
    catch e
        return HTTP.Response(500, JSON3.write(Dict("error"=>string(e), "investigation_id"=>id)))
    end
end

function get_investigation_status_handler(req::HTTP.Request)
    try
        id = split(req.target, "/")[5]
        if haskey(INVESTIGATION_STORE, id)
            data = INVESTIGATION_STORE[id]
            status = get(data, "status", "completed")
            progress_obj = haskey(data, "progress") ? data["progress"] : Dict("overall"=> (status=="completed" ? 100.0 : 0.0))
            return HTTP.Response(200, JSON3.write(Dict(
                "investigation_id" => id,
                "status" => status,
                "progress" => progress_obj,
                "timestamp" => string(_now()),
                "shortId" => get(data, "shortId", replace(id, "INV_"=>""))
            )))
        else
            return HTTP.Response(404, JSON3.write(Dict("error"=>"not_found")))
        end
    catch e
        return HTTP.Response(500, JSON3.write(Dict("error"=>string(e))))
    end
end

function get_investigation_results_handler(req::HTTP.Request)
    try
        id = split(req.target, "/")[5]
        if haskey(INVESTIGATION_STORE, id)
            data = INVESTIGATION_STORE[id]
            return HTTP.Response(200, JSON3.write(Dict(
                "investigation_id" => id,
                "status" => get(data, "status", "completed"),
                "results" => get(data, "results", Dict()),
                "timestamp" => string(_now()),
                "shortId" => get(data, "shortId", replace(id, "INV_"=>""))
            )))
        else
            return HTTP.Response(404, JSON3.write(Dict("error"=>"not_found")))
        end
    catch e
        return HTTP.Response(500, JSON3.write(Dict("error"=>string(e))))
    end
end

function register_unified_routes()
    @info "🚀 Registering unified investigation routes"
    @post "/api/v1/investigate" unified_investigate_handler
    # New canonical alias (explicit "full")
    @post "/api/investigation/full" unified_investigate_handler
    # Removed duplicate status/results routes (handled by FrontendHandlers) to avoid warnings
    # Aliases with deprecation notice
    @post "/api/v1/wallet/investigate" req -> unified_investigate_handler(req; deprecated=true)
    @post "/api/real-ai/investigate" req -> unified_investigate_handler(req; deprecated=true)
end

__init__() = register_unified_routes()

end # module
