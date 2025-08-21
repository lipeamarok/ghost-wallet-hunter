#!/usr/bin/env julia

# 🔥 GHOST WALLET HUNTER - JULIAOS MAIN ENTRY POINT (cleaned)

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using Base.Threads: nthreads
using Dates

# ----------------------------
# Thread Optimization Module
# ----------------------------
module ThreadOptimizer
using Base.Threads
const MIN_COMPUTE_DEFAULT = 4
const MIN_INTERACTIVE_DEFAULT = 1
function ensure_threads(; auto::Bool=true)
    thread_spec = get(ENV, "JULIA_NUM_THREADS", "")
    compute_threads = nthreads()
    has_interactive = occursin(",", thread_spec)
    min_compute = try parse(Int, get(ENV, "JULIAOS_MIN_COMPUTE_THREADS", string(MIN_COMPUTE_DEFAULT))) catch; MIN_COMPUTE_DEFAULT end
    min_interactive = try parse(Int, get(ENV, "JULIAOS_MIN_INTERACTIVE_THREADS", string(MIN_INTERACTIVE_DEFAULT))) catch; MIN_INTERACTIVE_DEFAULT end
    if compute_threads >= min_compute && (has_interactive || min_interactive == 0)
        recommended_spec = has_interactive ? thread_spec : (isempty(thread_spec) ? string(compute_threads) : thread_spec)
        return (status=:ok, current=compute_threads, interactive=has_interactive, recommended=recommended_spec, restarted=false)
    end
    cores = Sys.CPU_THREADS
    rec_compute = max(min_compute, min(cores - 1, cores))
    rec_interactive = min_interactive
    recommended_spec = rec_interactive > 0 ? "$(rec_compute),$(rec_interactive)" : string(rec_compute)
    if auto || get(ENV, "JULIAOS_AUTO_RETHREAD", "0") == "1"
        @info "Suboptimal thread configuration detected" current_threads=compute_threads interactive_pool=has_interactive recommended_command="julia --threads=$(recommended_spec) src/main.jl" cpu_cores=cores auto_rethread=true
    else
        @warn "Suboptimal thread configuration detected" current_threads=compute_threads interactive_pool=has_interactive recommended_command="julia --threads=$(recommended_spec) src/main.jl" cpu_cores=cores auto_rethread=false
    end
    if auto || get(ENV, "JULIAOS_AUTO_RETHREAD", "0") == "1"
        if get(ENV, "JULIAOS_THREAD_RESTARTED", "0") == "1"
            return (status=:skipped, current=compute_threads, interactive=has_interactive, recommended=recommended_spec, restarted=false)
        end
        if isempty(thread_spec) || thread_spec != recommended_spec
            @info "Re-launching with optimized threads" recommended_spec
            new_env = copy(ENV)
            new_env["JULIA_NUM_THREADS"] = recommended_spec
            new_env["JULIAOS_THREAD_RESTARTED"] = "1"
            cmd = Base.julia_cmd()
            push!(cmd.exec, "--project=$(abspath(joinpath(@__DIR__, "..")))")
            push!(cmd.exec, joinpath(@__DIR__, "main.jl"))
            if PROGRAM_FILE == @__FILE__
                append!(cmd.exec, ARGS)
            end
            run(setenv(cmd, new_env))
            exit(0)
        end
    end
    return (status=:warned, current=compute_threads, interactive=has_interactive, recommended=recommended_spec, restarted=false)
end
end # module

using .ThreadOptimizer: ensure_threads

# ----------------------------
# Early .env loader
# ----------------------------
function _early_load_env()
    env_path = abspath(joinpath(@__DIR__, "..", ".env"))
    isfile(env_path) || return
    for line in eachline(env_path)
        s = strip(line); isempty(s) && continue; startswith(s, "#") && continue
        m = match(r"^([A-Za-z0-9_]+)=(.*)$", line); m === nothing && continue
        key, val = m.captures; val = strip(val)
        if startswith(val, '"') && endswith(val,'"') && length(val) > 1
            val = val[2:end-1]
        end
        if !haskey(ENV, key) && !isempty(val)
            ENV[key] = val
        end
    end
end
_early_load_env()

# ----------------------------
# Blacklist cache helpers
# ----------------------------
const BLACKLIST_CACHE_FILE = abspath(joinpath(@__DIR__, "..", "data", "blacklist_cache.json"))
const BLACKLIST_CACHE_TTL_S = 3600

# Optional JSON3 availability (do not hard fail if missing)
const _HAS_JSON3 = let ok = false
    try
        @eval import JSON3
        ok = true
    catch
        @info "JSON3.jl not available; blacklist cache disabled"
    end
    ok
end

blacklist_cache_valid() = _HAS_JSON3 && isfile(BLACKLIST_CACHE_FILE) && (time() - stat(BLACKLIST_CACHE_FILE).mtime <= BLACKLIST_CACHE_TTL_S)

function load_blacklist_cache()
    _HAS_JSON3 || return nothing
    try
        JSON3.read(read(BLACKLIST_CACHE_FILE, String))
    catch
        nothing
    end
end

function save_blacklist_cache(addresses::Vector{String})
    _HAS_JSON3 || return
    try
        mkpath(dirname(BLACKLIST_CACHE_FILE))
        write(BLACKLIST_CACHE_FILE, JSON3.write(Dict(
            "saved_at" => Dates.format(Dates.now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
            "count" => length(addresses),
            "addresses" => addresses
        )))
    catch
        # silent
    end
end

# ----------------------------
# Main entry logic
# ----------------------------
function main()
    t0 = time()
    auto_flag = !haskey(ENV, "JULIA_NUM_THREADS") || isempty(get(ENV, "JULIA_NUM_THREADS", ""))
    tinfo = ensure_threads(auto=auto_flag)
    if !isdefined(Main, :JuliaOS)
        include("JuliaOS.jl")
    end
    # Thread config log
    spec = get(ENV, "JULIA_NUM_THREADS", "(unset)")
    has_interactive = occursin(",", spec)
    compute = nthreads(); interactive = 0; total = compute
    if has_interactive
        parts = split(spec, ","); if length(parts)==2; try
            compute = parse(Int, parts[1]); interactive = parse(Int, parts[2]); total = compute + interactive
        catch; end; end
    end
    @info "[Threads] configuration" status=tinfo.status spec=spec compute_threads=compute interactive_threads=interactive total_threads=total recommended=tinfo.recommended cpu_cores=Sys.CPU_THREADS auto_rethread=auto_flag
    if tinfo.status != :ok && !has_interactive
        @info "Suggested command" cmd="julia --threads=$(tinfo.recommended) src/main.jl"
    end

    if length(ARGS) == 0
        @info "🚀 Starting Ghost Wallet Hunter Server"
        host = get(ENV, "JULIAOS_HOST", "0.0.0.0")
        port = try parse(Int, get(ENV, "JULIAOS_PORT", "10000")) catch; 10000 end
        @info "📡 Host: $(host)  Port: $(port)"
        @info "🔗 A2A_ENABLED=$(get(ENV, "A2A_ENABLED", "false"))  A2A_PORT=$(get(ENV, "A2A_PORT", "9100"))  A2A_INTEGRATED=$(get(ENV, "A2A_INTEGRATED", "true"))"
        # Optional cache prime
        if blacklist_cache_valid()
            cached = load_blacklist_cache()
            if cached !== nothing && haskey(cached, "addresses") && isdefined(JuliaOS, :BlacklistChecker)
                try
                    JuliaOS.BlacklistChecker._PRIME_FROM_CACHE!(cached["addresses"])
                    @info "Blacklist pre-primed from cache" cached_count=cached["count"]
                catch; end
            end
        end
        Base.invokelatest(JuliaOS.start_server, host, port)
        @info "Bootstrap complete" total_seconds=round(time()-t0; digits=2) thread_spec=spec startup_threads=nthreads()
    elseif "--health" in ARGS
        health = Base.invokelatest(JuliaOS.get_health)
        println("✅ Health Status: $(get(health, "status", "unknown")) ")
        println("🕵️  Detectives: $(get(health, "detectives_available", "n/a")) ")
        println("🕒 Timestamp: $(get(health, "timestamp", "n/a")) ")
    elseif "--investigate" in ARGS
        if length(ARGS) < 2
            println("❌ Usage: julia src/main.jl --investigate <wallet_address>")
            return
        end
        wallet_address = ARGS[2]
        detective_type = length(ARGS) > 2 ? ARGS[3] : "poirot"
        @info "🔎 Starting investigation..." wallet=wallet_address detective=detective_type
        result = Base.invokelatest(JuliaOS.investigate_wallet, wallet_address, detective_type)
        if haskey(result, "error")
            println("❌ $(get(result, "error", "")) ")
        else
            println("✅ Investigation completed")
            println(result)
        end
    else
        println("❌ Unknown arguments. Available options:")
        println("  julia src/main.jl                    # Start server")
        println("  julia src/main.jl --health           # Health check")
        println("  julia src/main.jl --investigate <wallet> [detective]")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end