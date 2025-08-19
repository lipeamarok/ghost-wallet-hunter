# 🛠️ Test Helpers - Ghost Wallet Hunter
# Criado: 12/08/2025
# Status: 🟡 IN PROGRESS
# Propósito: Utilitários para testes SEM MOCKS - apenas dados reais

"""
Utilitários para setup e criação de dados de teste.
IMPORTANTE: SEM MOCKS - todas as funções trabalham com dados reais ou
criam estruturas baseadas em dados reais de blockchain.
"""

using Dates, JSON3, HTTP
include("solana_helpers.jl")
include("../fixtures/real_wallets.jl")

# =============================================================================
# 📋 CONFIGURAÇÕES DE TESTE
# =============================================================================

"""
Cria configuração de teste para análise de wallet com RPC real
"""
function create_real_test_config(;
    rpc_url::String=SOLANA_MAINNET_RPC,
    max_transactions::Int=100,
    analysis_depth::String="standard",
    include_ai_analysis::Bool=false,
    rate_limit_delay::Float64=0.1)

    return Dict(
        "solana_rpc_url" => rpc_url,
        "max_transactions" => max_transactions,
        "analysis_depth" => analysis_depth,
        "include_ai_analysis" => include_ai_analysis,
        "rate_limit_delay" => rate_limit_delay,
        "test_mode" => true,
        "created_at" => now(),
        "config_type" => "real_test_config"
    )
end

"""
Configuração específica para testes de performance
"""
function create_performance_test_config()
    return create_real_test_config(
        max_transactions=500,
        analysis_depth="deep",
        rate_limit_delay=0.05  # Mais agressivo para performance tests
    )
end

"""
Configuração conservadora para testes básicos
"""
function create_basic_test_config()
    return create_real_test_config(
        max_transactions=50,
        analysis_depth="basic",
        rate_limit_delay=0.2  # Mais conservador
    )
end

# =============================================================================
# 📊 DADOS DE TESTE REAIS
# =============================================================================

"""
Carrega dados reais de um wallet específico
"""
function load_real_wallet_data(wallet_key::String)
    all_wallets = get_all_real_wallets()

    if !haskey(all_wallets, wallet_key)
        @error "Wallet key '$wallet_key' not found in real wallet database"
        return nothing
    end

    address = all_wallets[wallet_key]
    profile = get_expected_profile(wallet_key)

    # Buscar dados reais
    @info "Loading real data for wallet: $wallet_key ($address)"

    account_info = get_account_info(address)
    balance_info = get_sol_balance(address)
    tx_data = fetch_real_transactions(address, limit=50)

    return Dict(
        "wallet_key" => wallet_key,
        "address" => address,
        "expected_profile" => profile,
        "account_info" => account_info,
        "balance_info" => balance_info,
        "transaction_data" => tx_data,
        "loaded_at" => now()
    )
end

"""
Carrega dados de múltiplos wallets para testes comparativos
"""
function load_wallet_test_set(wallet_keys::Vector{String})
    results = Dict()

    for key in wallet_keys
        @info "Loading test set wallet: $key"
        data = load_real_wallet_data(key)
        if !isnothing(data)
            results[key] = data
        end
        sleep(0.1)  # Rate limiting
    end

    return results
end

"""
Carrega conjunto de wallets por categoria para testes
"""
function load_category_test_set(category::String)
    category_wallets = get_wallets_by_category(category)
    wallet_keys = collect(keys(category_wallets))

    @info "Loading $category category test set: $(length(wallet_keys)) wallets"
    return load_wallet_test_set(wallet_keys)
end

# =============================================================================
# 🧪 GERADORES DE CENÁRIOS DE TESTE
# =============================================================================

"""
Cria cenário de teste baseado em dados reais de whale
"""
function create_whale_test_scenario()
    whale_data = load_real_wallet_data("whale_1")

    if isnothing(whale_data)
        @error "Could not load whale test data"
        return nothing
    end

    return Dict(
        "scenario_type" => "whale_analysis",
        "description" => "High-volume individual wallet analysis",
        "wallet_data" => whale_data,
        "expected_risk_range" => (0.3, 0.7),
        "test_criteria" => [
            "High transaction volume",
            "Complex transaction patterns",
            "Multiple counterparties",
            "Risk score in expected range"
        ],
        "created_at" => now()
    )
end

"""
Cria cenário de teste com CEX wallet
"""
function create_cex_test_scenario()
    cex_data = load_real_wallet_data("binance_hot_1")

    if isnothing(cex_data)
        @error "Could not load CEX test data"
        return nothing
    end

    return Dict(
        "scenario_type" => "cex_analysis",
        "description" => "Centralized exchange hot wallet analysis",
        "wallet_data" => cex_data,
        "expected_risk_range" => (0.2, 0.4),
        "test_criteria" => [
            "Very high transaction volume",
            "Regular deposit/withdrawal patterns",
            "Multiple small transactions",
            "CEX categorization"
        ],
        "created_at" => now()
    )
end

"""
Cria cenário comparativo entre diferentes tipos de wallet
"""
function create_comparative_test_scenario()
    wallets = [
        ("wrapped_sol", "token_mint"),
        ("binance_hot_1", "cex_hot"),
        ("raydium_amm_v4", "defi_protocol"),
        ("whale_1", "individual_whale")
    ]

    scenario_data = Dict()

    for (wallet_key, expected_type) in wallets
        data = load_real_wallet_data(wallet_key)
        if !isnothing(data)
            scenario_data[wallet_key] = Dict(
                "data" => data,
                "expected_type" => expected_type
            )
        end
    end

    return Dict(
        "scenario_type" => "comparative_analysis",
        "description" => "Compare risk assessment across different wallet types",
        "wallets" => scenario_data,
        "test_criteria" => [
            "Correct wallet categorization",
            "Risk scores reflect wallet types",
            "Consistent analysis methodology",
            "Reasonable confidence levels"
        ],
        "created_at" => now()
    )
end

# =============================================================================
# 📈 PERFORMANCE TESTING HELPERS
# =============================================================================

"""
Executa benchmark de função com dados reais
"""
function benchmark_real_function(func::Function, args...;
                                warm_up::Bool=true,
                                iterations::Int=1)

    if warm_up
        @info "Warming up function..."
        try
            func(args...)
        catch e
            @warn "Warm-up failed" exception=e
        end
    end

    times = Float64[]
    memory_usage = Int64[]

    for i in 1:iterations
        @info "Benchmark iteration $i/$iterations"

        # Measure memory before
        GC.gc()  # Force garbage collection
        memory_before = Base.gc_live_bytes()

        # Measure execution time
        execution_time = @elapsed begin
            result = func(args...)
        end

        # Measure memory after
        GC.gc()
        memory_after = Base.gc_live_bytes()
        memory_delta = memory_after - memory_before

        push!(times, execution_time)
        push!(memory_usage, memory_delta)

        @info "Iteration $i completed: $(execution_time)s, $(memory_delta) bytes"
    end

    return Dict(
        "iterations" => iterations,
        "execution_times" => times,
        "avg_execution_time" => mean(times),
        "min_execution_time" => minimum(times),
        "max_execution_time" => maximum(times),
        "memory_usage" => memory_usage,
        "avg_memory_usage" => mean(memory_usage),
        "timestamp" => now()
    )
end

"""
Benchmark de investigação completa com wallet real
"""
function benchmark_real_investigation(wallet_key::String, detective_type::String="poirot")
    wallet_data = load_real_wallet_data(wallet_key)

    if isnothing(wallet_data)
        @error "Could not load wallet data for benchmark"
        return nothing
    end

    address = wallet_data["address"]

    @info "Benchmarking investigation: $detective_type -> $wallet_key ($address)"

    # TODO: Esta função será implementada quando tivermos os detective agents prontos
    # Por enquanto, vamos simular com análise de dados

    benchmark_func = () -> begin
        # Simulate investigation workflow
        config = create_performance_test_config()

        # Fetch real data
        account_info = get_account_info(address)
        balance_info = get_sol_balance(address)
        tx_data = fetch_real_transactions(address, limit=100, include_details=true)

        # Simulate analysis (will be replaced with real detective analysis)
        analysis_result = Dict(
            "address" => address,
            "account_info" => account_info,
            "balance_info" => balance_info,
            "transaction_analysis" => tx_data,
            "detective_type" => detective_type,
            "analysis_timestamp" => now()
        )

        return analysis_result
    end

    benchmark_result = benchmark_real_function(benchmark_func, iterations=1)

    return merge(benchmark_result, Dict(
        "wallet_key" => wallet_key,
        "address" => address,
        "detective_type" => detective_type,
        "test_type" => "real_investigation_benchmark"
    ))
end

# =============================================================================
# 📄 RESULT LOGGING E STORAGE
# =============================================================================

"""
Salva resultado de teste em JSON
"""
function save_test_result(result::Dict, test_name::String, category::String="general")
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
    filename = "$(test_name)_$(timestamp).json"

    # Determinar diretório baseado na categoria
    base_dir = "c:\\ghost-wallet-hunter\\juliaos\\core\\test"
    result_dir = ""

    if category == "analysis"
        result_dir = joinpath(base_dir, "unit", "analysis", "results")
    elseif category == "agents"
        result_dir = joinpath(base_dir, "unit", "agents", "results")
    elseif category == "integration"
        result_dir = joinpath(base_dir, "integration", "results")
    elseif category == "regression"
        result_dir = joinpath(base_dir, "regression", "results")
    else
        result_dir = joinpath(base_dir, "results")
    end

    # Criar diretório se não existir
    if !isdir(result_dir)
        mkpath(result_dir)
    end

    filepath = joinpath(result_dir, filename)

    # Adicionar metadata
    result_with_metadata = merge(result, Dict(
        "test_name" => test_name,
        "category" => category,
        "saved_at" => now(),
        "julia_version" => VERSION,
        "hostname" => gethostname()
    ))

    try
        open(filepath, "w") do file
            JSON3.pretty(file, result_with_metadata)
        end

        @info "Test result saved: $filepath"
        return filepath
    catch e
        @error "Failed to save test result" exception=e
        return nothing
    end
end

"""
Carrega resultado de teste salvo
"""
function load_test_result(filepath::String)
    try
        content = read(filepath, String)
        return JSON3.read(content)
    catch e
        @error "Failed to load test result from $filepath" exception=e
        return nothing
    end
end

"""
Lista todos os resultados salvos por categoria
"""
function list_saved_results(category::String="all")
    base_dir = "c:\\ghost-wallet-hunter\\juliaos\\core\\test"

    if category == "all"
        search_dirs = [
            joinpath(base_dir, "unit", "analysis", "results"),
            joinpath(base_dir, "unit", "agents", "results"),
            joinpath(base_dir, "integration", "results"),
            joinpath(base_dir, "regression", "results")
        ]
    else
        if category == "analysis"
            search_dirs = [joinpath(base_dir, "unit", "analysis", "results")]
        elseif category == "agents"
            search_dirs = [joinpath(base_dir, "unit", "agents", "results")]
        elseif category == "integration"
            search_dirs = [joinpath(base_dir, "integration", "results")]
        elseif category == "regression"
            search_dirs = [joinpath(base_dir, "regression", "results")]
        else
            search_dirs = [joinpath(base_dir, "results")]
        end
    end

    all_files = []
    for dir in search_dirs
        if isdir(dir)
            files = filter(f -> endswith(f, ".json"), readdir(dir))
            for file in files
                push!(all_files, joinpath(dir, file))
            end
        end
    end

    return all_files
end

# =============================================================================
# 🔍 TEST VALIDATION HELPERS
# =============================================================================

"""
Valida se resultado de teste está dentro de expectativas
"""
function validate_test_result(result::Dict, expected_profile::Union{Dict,Nothing}=nothing)
    validations = Dict{String,Bool}()

    # Validações básicas
    validations["has_success_field"] = haskey(result, "success")
    validations["has_timestamp"] = haskey(result, "timestamp") || haskey(result, "created_at")

    if haskey(result, "success") && result["success"]
        validations["successful_execution"] = true
    else
        validations["successful_execution"] = false
    end

    # Validações específicas se temos perfil esperado
    if !isnothing(expected_profile)
        if haskey(result, "risk_score") && haskey(expected_profile, "risk_range")
            risk_score = result["risk_score"]
            risk_range = expected_profile["risk_range"]

            validations["risk_score_in_range"] = (risk_range[1] <= risk_score <= risk_range[2])
        end

        if haskey(result, "category") && haskey(expected_profile, "category")
            validations["correct_category"] = (result["category"] == expected_profile["category"])
        end
    end

    all_passed = all(values(validations))

    return Dict(
        "all_validations_passed" => all_passed,
        "individual_validations" => validations,
        "validation_timestamp" => now()
    )
end

"""
Gera relatório de execução de teste
"""
function generate_test_report(test_name::String, results::Vector{Dict})
    total_tests = length(results)
    successful_tests = count(r -> get(r, "success", false), results)
    success_rate = successful_tests / total_tests

    # Calcular estatísticas de tempo se disponível
    execution_times = [get(r, "execution_time", 0.0) for r in results if haskey(r, "execution_time")]

    report = Dict(
        "test_name" => test_name,
        "total_tests" => total_tests,
        "successful_tests" => successful_tests,
        "failed_tests" => total_tests - successful_tests,
        "success_rate" => success_rate,
        "generated_at" => now()
    )

    if !isempty(execution_times)
        report["performance_stats"] = Dict(
            "avg_execution_time" => mean(execution_times),
            "min_execution_time" => minimum(execution_times),
            "max_execution_time" => maximum(execution_times),
            "total_execution_time" => sum(execution_times)
        )
    end

    return report
end

# =============================================================================
# 🚀 INITIALIZATION
# =============================================================================

@info "Test Helpers loaded - Real data utilities ready"

# Validar conectividade na inicialização
@info "Validating test environment..."

try
    # Test RPC connectivity
    rpc_test = test_rpc_connection()
    if rpc_test["success"]
        @info "✅ RPC connectivity validated"
    else
        @warn "⚠️ RPC connectivity issues detected"
    end

    # Validate wallet database
    wallet_stats = get_wallet_stats()
    @info "✅ Wallet database loaded" wallet_stats

    @info "🚀 Test environment ready for real data testing!"

catch e
    @error "❌ Test environment validation failed" exception=e
end
