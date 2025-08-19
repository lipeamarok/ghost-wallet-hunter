module ProviderPool

using Dates, HTTP, JSON3, Logging, Statistics

export SolanaEndpoint, SolanaProviderPool, next_endpoint, record_success!, record_failure!, warmup_endpoints!, rpc_request, init_solana_pool, get_balance, get_signatures_for_address, get_transaction, SOLANA_POOL

mutable struct SolanaEndpoint
    url::String
    score::Float64
    last_fail::Union{Nothing,DateTime}
    consecutive_failures::Int
end

mutable struct SolanaProviderPool
    endpoints::Vector{SolanaEndpoint}
    cursor::Int
end

SolanaProviderPool(urls::Vector{String}) = SolanaProviderPool([SolanaEndpoint(u, 1.0, nothing, 0) for u in urls], 1)

function next_endpoint(pool::SolanaProviderPool)
    n = length(pool.endpoints)
    for i in 1:n
        idx = (pool.cursor - 1 + i) % n + 1
        ep = pool.endpoints[idx]
        if ep.score > 0.15
            pool.cursor = idx % n + 1
            return ep
        end
    end
    # Get the endpoint with the highest score directly
    max_score_idx = argmax([e.score for e in pool.endpoints])
    pool.endpoints[max_score_idx]
end

function record_success!(pool::SolanaProviderPool, ep::SolanaEndpoint; latency_ms::Float64=50.0)
    ep.score = clamp(ep.score + 0.05 - (latency_ms/3000), 0.0, 2.0)
    ep.consecutive_failures = 0
    ep
end

function record_failure!(pool::SolanaProviderPool, ep::SolanaEndpoint)
    ep.consecutive_failures += 1
    ep.score = max(0.0, ep.score - 0.2*ep.consecutive_failures)
    ep
end

function _rpc_ping(url::String)
    body = JSON3.write((jsonrpc="2.0", id=1, method="getHealth", params=[]))
    try
        r = HTTP.request("POST", url; body=body, headers=Dict("Content-Type"=>"application/json"), readtimeout=3, connecttimeout=2)
        return r.status == 200
    catch
        return false
    end
end

function warmup_endpoints!(pool::SolanaProviderPool)
    for ep in pool.endpoints
        ok = _rpc_ping(ep.url)
        ok || record_failure!(pool, ep)
    end
    pool
end

const SOLANA_POOL = Ref{Union{Nothing,SolanaProviderPool}}(nothing)

function init_solana_pool()
    urls = String[]
    if !isempty(get(ENV, "HELIUS_RPC_HTTPS", "")); push!(urls, ENV["HELIUS_RPC_HTTPS"]); end
    if haskey(ENV, "SOLANA_EXTRA_RPCS")
        append!(urls, [strip(u) for u in split(ENV["SOLANA_EXTRA_RPCS"], ",") if !isempty(strip(u))])
    end
    append!(urls, [
        get(ENV, "SOLANA_RPC_URL", "https://api.mainnet-beta.solana.com"),
        "https://solana-api.projectserum.com",
        "https://rpc.ankr.com/solana"
    ])
    pool = SolanaProviderPool(unique(urls))
    warmup_endpoints!(pool)
    SOLANA_POOL[] = pool
    @info "Solana provider pool initialized" endpoints=length(pool.endpoints)
    return pool
end

const _MAX_READ_TIMEOUT = try parse(Int, get(ENV, "SOLANA_PROVIDER_READ_TIMEOUT_S", "10")) catch; 10 end
const _CONNECT_TIMEOUT = try parse(Int, get(ENV, "SOLANA_PROVIDER_CONNECT_TIMEOUT_S", "4")) catch; 4 end
const _BASE_BACKOFF = try parse(Float64, get(ENV, "SOLANA_PROVIDER_BASE_BACKOFF_S", "0.08")) catch; 0.08 end
const _JITTER = try parse(Float64, get(ENV, "SOLANA_PROVIDER_JITTER_S", "0.04")) catch; 0.04 end
const _RATE_LIMIT_SLEEP = try parse(Float64, get(ENV, "SOLANA_PROVIDER_RATELIMIT_SLEEP_S", "0.35")) catch; 0.35 end
const _LAT_HISTORY = Ref{Vector{Float64}}(Float64[])

function _record_latency(ms)
    h = _LAT_HISTORY[]; push!(h, ms); length(h) > 200 && deleteat!(h, 1:length(h)-200)
end

function rpc_request(method::String, params::Vector{Any}; id::Int=1, retries::Int=3)
    isnothing(SOLANA_POOL[]) && init_solana_pool()
    pool = SOLANA_POOL[]
    payload = JSON3.write((jsonrpc="2.0", id=id, method=method, params=params))
    last_err = nothing
    for attempt in 1:retries
        ep = next_endpoint(pool)
        t0 = time()
        try
            resp = HTTP.request("POST", ep.url; body=payload, headers=Dict("Content-Type"=>"application/json"), readtimeout=_MAX_READ_TIMEOUT, connecttimeout=_CONNECT_TIMEOUT)
            latency = (time()-t0)*1000
            if resp.status == 200
                record_success!(pool, ep; latency_ms=latency)
                data = JSON3.read(String(resp.body))
                if haskey(data, :error)
                    last_err = data[:error]
                else
                    _record_latency(latency)
                    # Return full shape for compatibility; some callers expect :result only
                    return Dict(
                        "jsonrpc"=>get(data, :jsonrpc, "2.0"),
                        "id"=>get(data, :id, id),
                        "result"=>get(data, :result, nothing),
                        "_meta"=>Dict(
                            "endpoint"=>ep.url,
                            "latency_ms"=>latency,
                            "attempt"=>attempt,
                            "avg_latency_ms"=> (isempty(_LAT_HISTORY[]) ? latency : mean(_LAT_HISTORY[]))
                        )
                    )
                end
            else
                record_failure!(pool, ep)
                last_err = resp.status
                if resp.status in (429, 503)
                    sleep(_RATE_LIMIT_SLEEP)
                end
            end
        catch e
            record_failure!(pool, ep)
            last_err = e
            sleep(_BASE_BACKOFF * 2.0^(attempt-1) + rand()*_JITTER)
        end
    end
    return Dict(
        "jsonrpc"=>"2.0",
        "id"=>id,
        "result"=>nothing,
        "error"=>Dict("message"=>string(last_err)),
        "_meta"=>Dict("failed"=>true, "attempts"=>retries)
    )
end

get_signatures_for_address(addr::String; limit::Int=25) = begin
    resp = rpc_request("getSignaturesForAddress", Any[addr, (; limit=limit)])
    haskey(resp, "result") ? resp["result"] : Any[]
end
get_transaction(signature::String) = begin
    resp = rpc_request("getTransaction", Any[signature, Dict("encoding"=>"json", "maxSupportedTransactionVersion"=>0)])
    haskey(resp, "result") ? resp["result"] : nothing
end
get_balance(addr::String) = begin
    resp = rpc_request("getBalance", Any[addr])
    if haskey(resp, "result") && haskey(resp["result"], :value)
        return resp["result"][:value] / 1_000_000_000
    elseif haskey(resp, "result") && haskey(resp["result"], "value")
        return resp["result"]["value"] / 1_000_000_000
    else
        return 0.0
    end
end

end # module ProviderPool
