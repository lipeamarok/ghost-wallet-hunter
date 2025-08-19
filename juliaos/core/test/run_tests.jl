# Ghost Wallet Hunter - Unified Test Runner
# Usage:
#   julia --project=juliaos/core juliaos/core/test/run_tests.jl [smoke|full]
# Default mode: smoke (fast critical path)

using Dates

# Ensure the juliaos/core project is active so that `using JuliaOS` in nested tests works
try
    import Pkg
    project_root = abspath(joinpath(@__DIR__, ".."))  # juliaos/core
    # Always activate explicitly (simpler & robust across Pkg versions)
    Pkg.activate(project_root; io=devnull)
    # Ensure the JuliaOS module is loaded into Main so references like Main.JuliaOS.* work
    try
        @info "Loading JuliaOS module for test environment"
        using JuliaOS
        @info "JuliaOS module loaded via package mechanism" path=try pathof(JuliaOS) catch; "(no path)" end
    catch e2
        @warn "Primary using JuliaOS failed; attempting manual fallback include" error=e2
        try
            # Fallback: ensure project root is on LOAD_PATH and include source directly
            project_root ∈ Base.LOAD_PATH || push!(Base.LOAD_PATH, project_root)
            src_file = joinpath(project_root, "src", "JuliaOS.jl")
            if isfile(src_file)
                @info "Including JuliaOS source manually" src=src_file
                include(src_file)
                # After include, module is available as .JuliaOS relative to Main
                if isdefined(Main, :JuliaOS)
                    @eval using .JuliaOS
                    @info "JuliaOS module loaded via manual include fallback" path=try pathof(JuliaOS) catch; "(no path)" end
                else
                    @error "Manual include did not define JuliaOS module" src=src_file
                end
            else
                @error "JuliaOS source file not found for manual include" looked_for=src_file
            end
        catch e3
            @error "Fallback manual include for JuliaOS failed" error=e3
        end
    end
catch e
    @warn "Could not ensure project activation" error=e
end

# Detect optional JSON3 availability (avoid const in try scope which causes error)
HAS_JSON3 = false
try
    import JSON3
    global HAS_JSON3 = true
catch
    @warn "JSON3 not available; JSON report disabled"
end

struct TestResult
    file::String
    ok::Bool
    seconds::Float64
    error::Union{Nothing,Any}
end

# NOTE: Para evitar o erro "module expression not at top level", não executamos mais os arquivos de teste
# dentro de uma função. O loop de inclusão agora está em escopo global (script), garantindo que quaisquer
# declarações de `module` dentro dos arquivos incluídos ocorram no nível superior de Main.

function _run_category(label::String, dir::String, files::Vector{String})
    println("\n==> Running $(label) tests ($(length(files)) files)")
    debug = get(ENV, "TEST_RUNNER_DEBUG", "0") == "1"
    results = TestResult[]
    for rel in files
        path = joinpath(dir, rel)
        print("  • $rel ... ")
        debug && println("[debug: path=$(path)]")
        t0 = time(); err = nothing; ok = true
        try
            # include em escopo global: Base.include(Main, path) garante módulo top-level
            Base.include(Main, path)
        catch e
            ok = false
            err = e
        end
        dt = time() - t0
        push!(results, TestResult(rel, ok, dt, err))
        println(ok ? "OK ($(round(dt; digits=2))s)" : "FAIL ($(round(dt; digits=2))s) -> $(err)")
        if !ok && get(ENV, "TEST_FAST_FAIL", "0") == "1"
            println("⛔ Fast-fail engaged after failure in $rel")
            return results
        end
    end
    return results
end

function summarize(all::Vector{TestResult}; label="TOTAL")
    total = length(all)
    passed = count(r->r.ok, all)
    failed = total - passed
    times = [r.seconds for r in all]
    p95 = isempty(times) ? 0.0 : local_quantile(times, 0.95)
    p99 = isempty(times) ? 0.0 : local_quantile(times, 0.99)
    println("\n===== SUMMARY: $label =====")
    println("Files: $total  Passed: $passed  Failed: $failed")
    println("Durations p95=$(round(p95; digits=3))s p99=$(round(p99; digits=3))s max=$(round(maximum(times); digits=3))s")
    return (; total, passed, failed, p95, p99)
end

# Simple quantile (no dependency) for small vectors (renamed to avoid clashing with Statistics.quantile)
function local_quantile(v::Vector{Float64}, q::Float64)
    isempty(v) && return 0.0
    s = sort(v)
    idx = clamp(Int(ceil(q * length(s))), 1, length(s))
    return s[idx]
end

mode = length(ARGS) > 0 ? lowercase(ARGS[1]) : "smoke"

root = abspath(joinpath(@__DIR__, "unit"))

analysis_dir   = joinpath(root, "analysis")
agents_dir     = joinpath(root, "agents")
api_dir        = joinpath(root, "api")
tools_dir      = joinpath(root, "tools")
blockchain_dir = joinpath(root, "blockchain")
mcp_dir        = joinpath(root, "mcp")

analysis_files_full = [
    "test_analysis_core.jl","test_graph_builder.jl","test_taint_propagation.jl","test_entity_clustering.jl",
    "test_risk_engine.jl","test_explainability.jl","test_flow_attribution.jl","test_influence_analysis.jl",
    "test_f7_realtime_scoring.jl"
]
analysis_files_smoke = ["test_analysis_core.jl","test_graph_builder.jl","test_explainability.jl"]

_collect(dir) = [f for f in readdir(dir) if endswith(f, ".jl") && f != "runtests.jl"]
agent_files = _collect(agents_dir)
api_files   = _collect(api_dir)
tools_files = _collect(tools_dir)
blockchain_files = _collect(blockchain_dir)
mcp_files = _collect(mcp_dir)

results = TestResult[]
start_time = time()
println("🚀 Ghost Wallet Hunter - Running $(mode) test suite @ $(Dates.format(Dates.now(), dateformat"yyyy-mm-dd HH:MM:SS"))")

# Order: analysis -> tools -> agents -> api -> blockchain -> mcp
analysis_results   = _run_category("Analysis", analysis_dir, mode == "smoke" ? analysis_files_smoke : analysis_files_full)
tools_results      = _run_category("Tools", tools_dir, mode == "smoke" ? ["test_blacklist_checker.jl","test_risk_assessment.jl"] : tools_files)
agents_results     = _run_category("Agents", agents_dir, mode == "smoke" ? first.(Iterators.partition(sort(agent_files), 2)) : agent_files)
api_results        = _run_category("API", api_dir, mode == "smoke" ? ["test_frontend_handlers.jl","test_metrics_handlers.jl"] : api_files)
blockchain_results = _run_category("Blockchain", blockchain_dir, blockchain_files)
mcp_results        = _run_category("MCP", mcp_dir, mode == "smoke" ? ["test_mcp_server.jl"] : mcp_files)

push!(results, analysis_results...)
push!(results, tools_results...)
push!(results, agents_results...)
push!(results, api_results...)
push!(results, blockchain_results...)
push!(results, mcp_results...)

summary = summarize(results; label=uppercase(mode))
wall = time() - start_time
println("⏱️ Wall time: $(round(wall/60; digits=2)) min")

if HAS_JSON3
    pretty = get(ENV, "TEST_REPORT_PRETTY", "0") == "1"
    function _write_json(path, data)
        open(path, "w") do io
            if pretty
                JSON3.write(io, data; allow_inf=true, indent=2)
            else
                JSON3.write(io, data; allow_inf=true)
            end
        end
    end
    # Base per-file report
    report = Dict(
        "mode" => mode,
        "generated_at" => Dates.format(Dates.now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS"),
        "wall_seconds" => wall,
        "summary" => Dict(k=>getfield(summary,k) for k in fieldnames(typeof(summary))),
        "categories" => Dict(
            "analysis"=>Dict("total"=>length(analysis_results),"passed"=>count(r->r.ok,analysis_results)),
            "tools"=>Dict("total"=>length(tools_results),"passed"=>count(r->r.ok,tools_results)),
            "agents"=>Dict("total"=>length(agents_results),"passed"=>count(r->r.ok,agents_results)),
            "api"=>Dict("total"=>length(api_results),"passed"=>count(r->r.ok,api_results)),
            "blockchain"=>Dict("total"=>length(blockchain_results),"passed"=>count(r->r.ok,blockchain_results)),
            "mcp"=>Dict("total"=>length(mcp_results),"passed"=>count(r->r.ok,mcp_results))
        ),
        "files" => [Dict(
            "file"=>r.file,
            "ok"=>r.ok,
            "seconds"=>r.seconds,
            "error"=> (r.ok ? nothing : string(r.error))
        ) for r in results]
    )
    out_dir = joinpath(@__DIR__, "..", "reports")
    mkpath(out_dir)
    timestamp = Dates.format(Dates.now(UTC), dateformat"yyyymmdd_HHMMSS")
    out_file = joinpath(out_dir, "test_report_$(mode)_$(timestamp).json")
    _write_json(out_file, report)
    println("📝 JSON report saved: $(out_file)")

    # Unified aggregated report only for full mode
    if mode == "full"
        try
            # Attempt to collect analysis sub-reports (they reside under unit/analysis/results)
            analysis_results_dir = joinpath(analysis_dir, "results")
            sub_reports = []
            if isdir(analysis_results_dir)
                for f in readdir(analysis_results_dir)
                    endswith(f, ".json") || continue
                    path = joinpath(analysis_results_dir, f)
                    try
                        raw = read(path, String)
                        parsed = JSON3.read(raw)
                        push!(sub_reports, Dict("file"=>f, "data"=>parsed))
                    catch e
                        push!(sub_reports, Dict("file"=>f, "error"=>string(e)))
                    end
                end
            end
            # Sanitizer to convert any Date/DateTime to string recursively
            function _sanitize(x)
                if x isa Date || x isa DateTime
                    return Dates.format(x, dateformat"yyyy-mm-ddTHH:MM:SS")
                elseif x isa AbstractVector
                    return [_sanitize(v) for v in x]
                elseif x isa AbstractDict
                    out = Dict{Any,Any}()
                    for (k,v) in x
                        out[k] = _sanitize(v)
                    end
                    return out
                else
                    return x
                end
            end
            git_sha = try
                readchomp(`git -C $(abspath(joinpath(@__DIR__, ".."))) rev-parse --short HEAD`)
            catch; "unknown" end
            unified = Dict(
                "type" => "unified_test_suite_report",
                "runner_version" => 2,
                "generated_at" => Dates.format(Dates.now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS"),
                "wall_seconds" => wall,
                "overall" => report["summary"],
                "categories" => report["categories"],
                "files" => report["files"],
                "analysis_sub_reports" => sub_reports,
                "environment" => Dict(
                    "julia_threads" => Threads.nthreads(),
                    "working_dir" => pwd(),
                    "git_sha" => git_sha,
                )
            ) |> _sanitize
            unified_file = joinpath(out_dir, "unified_full_report_$(timestamp).json")
            tmp_file = unified_file * ".tmp"
            _write_json(tmp_file, unified)
            try mv(tmp_file, unified_file; force=true) catch; cp(tmp_file, unified_file; force=true) end
            println("🧩 Unified FULL report saved: $(unified_file)")
        catch e
            unified_file = joinpath(out_dir, "unified_full_report_$(timestamp).json")
            fallback = Dict(
                "type"=>"unified_test_suite_report",
                "error"=>"failed_to_generate_unified",
                "exception"=>string(e),
                "generated_at"=>Dates.format(Dates.now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS"),
                "note"=>"Partial data only. Check runner for serialization issues.",
                "overall"=>report["summary"],
            )
            open(unified_file, "w") do io; JSON3.write(io, fallback); end
            @warn "Unified report generation failed" exception=e file=unified_file
        end
    end
end

failed = any(r->!r.ok, results)
failed && error("Some test files failed. See above summary.")
