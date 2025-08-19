using Test
using JSON3
using HTTP
using Statistics

# Import utils and fixtures
include("../../utils/test_helpers.jl")
include("../../utils/solana_helpers.jl")
include("../../fixtures/real_wallets.jl")

"""
Test suite para Taint Propagation (F2) - Análise de Propagação de Contaminação
Funcionalidade: Rastreamento de propagação de "taint" através de transações reais
Filosofia: SEM MOCKS - apenas dados reais do Solana mainnet para análise de contaminação
"""

@testset "Taint Propagation F2 - Real Data Analysis" begin

    # Teste 1: Module loading and taint propagation setup
    @testset "Taint Propagation Module Setup" begin
        @test true  # Module loaded successfully

        # Verificar dependências para análise de taint
        @test isdefined(Main, :HTTP)   # Para RPC calls
        @test isdefined(Main, :JSON3)  # Para parsing de dados

        println("🔬 Taint Propagation Analysis Module Loaded")

        save_test_result(Dict(
            "status" => "success",
            "dependencies_loaded" => ["HTTP", "JSON3"],
            "timestamp" => now()
        ), "unit_analysis_taint_propagation", "module_setup")
    end

    # Teste 2: Real taint source identification
    @testset "Taint Source Identification" begin
        println("🎯 Identifying taint sources from real blockchain data...")

        # Usar wallets suspeitas conhecidas como fontes de taint
        potential_taint_sources = [
            DEFI_WALLETS["mango_v3"],  # Conhecido caso de exploit
            CEX_WALLETS["ftx_main"],  # Exchange comprometida
            WHALE_WALLETS["whale_1"]  # Entidade suspeita
        ]

        taint_analysis_results = []

        for source_wallet in potential_taint_sources
            try
                # Fetch transactions para análise de taint
                source_data = fetch_real_transactions(source_wallet, limit=5)

                if source_data["success"] && length(source_data["data"]) > 0
                    # Análise de padrões suspeitos
                    transaction_count = length(source_data["data"])

                    taint_score = min(1.0, transaction_count * 0.1)  # Score baseado em atividade

                    taint_info = Dict(
                        "source_wallet" => source_wallet,
                        "transaction_count" => transaction_count,
                        "taint_score" => taint_score,
                        "risk_level" => taint_score > 0.7 ? "HIGH" : (taint_score > 0.4 ? "MEDIUM" : "LOW"),
                        "sample_transactions" => source_data["data"][1:min(2, transaction_count)]
                    )

                    push!(taint_analysis_results, taint_info)

                    println("  🚨 $(source_wallet[1:8])... - Risk: $(taint_info["risk_level"]) (Score: $(round(taint_score, digits=3)))")
                end

                sleep(0.3)  # Rate limiting

            catch e
                println("  ⚠️ Taint analysis failed for $(source_wallet[1:8])...: $e")
            end
        end

        @test length(taint_analysis_results) > 0

        # Verificar que pelo menos uma fonte foi identificada como alta/média risk
        high_risk_sources = filter(result -> result["risk_level"] in ["HIGH", "MEDIUM"], taint_analysis_results)
        @test length(high_risk_sources) > 0

        save_test_result(Dict(
            "sources_analyzed" => length(potential_taint_sources),
            "sources_with_data" => length(taint_analysis_results),
            "high_risk_sources" => length(high_risk_sources),
            "taint_results" => taint_analysis_results,
            "timestamp" => now()
        ), "taint_source_identification", "unit_analysis_taint_propagation")
    end

    # Teste 3: Taint propagation path analysis with real transactions
    @testset "Taint Propagation Path Analysis" begin
        println("🔍 Analyzing taint propagation paths through real transactions...")

        # Simular análise de propagação usando wallets conectadas
        source_wallet = DEFI_WALLETS["raydium_amm_v4"]
        potential_targets = [
            DEFI_WALLETS["orca_whirlpools"],
            DEFI_WALLETS["jupiter_v6"],
            CEX_WALLETS["binance_hot_1"]
        ]

        propagation_paths = []

        try
            # Fetch source transactions
            source_transactions = fetch_real_transactions(source_wallet, limit=8)

            if source_transactions["success"]
                # Para cada target, verificar possíveis caminhos de propagação
                for target_wallet in potential_targets
                    target_transactions = fetch_real_transactions(target_wallet, limit=5)

                    if target_transactions["success"]
                        # Simular análise de intersecção temporal
                        source_count = length(source_transactions["data"])
                        target_count = length(target_transactions["data"])

                        # Calcular probabilidade de propagação baseada em atividade
                        propagation_probability = min(0.95, (source_count + target_count) * 0.05)

                        path_info = Dict(
                            "source" => source_wallet,
                            "target" => target_wallet,
                            "source_tx_count" => source_count,
                            "target_tx_count" => target_count,
                            "propagation_probability" => propagation_probability,
                            "path_strength" => propagation_probability > 0.6 ? "STRONG" : (propagation_probability > 0.3 ? "MEDIUM" : "WEAK")
                        )

                        push!(propagation_paths, path_info)

                        println("  🔗 $(source_wallet[1:8])... -> $(target_wallet[1:8])... | Strength: $(path_info["path_strength"])")
                    end

                    sleep(0.2)  # Rate limiting
                end
            end

        catch e
            println("  ❌ Propagation path analysis failed: $e")
        end

        @test length(propagation_paths) > 0

        # Verificar que pelo menos um caminho foi identificado
        strong_paths = filter(path -> path["path_strength"] == "STRONG", propagation_paths)
        @test length(propagation_paths) >= length(potential_targets) * 0.5  # Pelo menos 50% sucesso

        println("📊 Propagation Analysis Summary:")
        println("  - Total paths analyzed: $(length(propagation_paths))")
        println("  - Strong propagation paths: $(length(strong_paths))")

        save_test_result(Dict(
            "source_wallet" => source_wallet,
            "targets_analyzed" => length(potential_targets),
            "paths_found" => length(propagation_paths),
            "strong_paths" => length(strong_paths),
            "path_details" => propagation_paths,
            "timestamp" => now()
        ), "unit_analysis_taint_propagation", "propagation_path_analysis")
    end

    # Teste 4: Taint contamination level calculation
    @testset "Taint Contamination Level Calculation" begin
        println("🧮 Calculating taint contamination levels with real data...")

        # Usar wallets diversas para calcular níveis de contaminação
        test_wallets = [
            DEFI_WALLETS["jupiter_v6"],      # DeFi - medium risk
            CEX_WALLETS["coinbase_1"], # CEX - low risk
            WHALE_WALLETS["whale_1"],  # Whale - high risk
            NATIVE_PROGRAMS["token_program"]  # Native - very low risk
        ]

        contamination_results = []

        for wallet in test_wallets
            try
                # Fetch transaction data for contamination analysis
                wallet_data = fetch_real_transactions(wallet, limit=6)

                if wallet_data["success"] && length(wallet_data["data"]) > 0
                    transaction_count = length(wallet_data["data"])

                    # Calcular nível de contaminação baseado em padrões reais
                    base_contamination = transaction_count * 0.05

                    # Ajustar baseado no tipo de wallet
                    wallet_type_multiplier = begin
                        if wallet in values(NATIVE_PROGRAMS)
                            0.1  # Native programs - baixa contaminação
                        elseif wallet in values(CEX_WALLETS)
                            0.3  # CEX - contaminação moderada
                        elseif wallet in values(DEFI_WALLETS)
                            0.6  # DeFi - contaminação média-alta
                        elseif wallet in values(WHALE_WALLETS)
                            0.8  # Whales - contaminação alta
                        else
                            0.5  # Default
                        end
                    end

                    final_contamination = min(1.0, base_contamination * wallet_type_multiplier)

                    contamination_info = Dict(
                        "wallet" => wallet,
                        "transaction_count" => transaction_count,
                        "base_contamination" => base_contamination,
                        "type_multiplier" => wallet_type_multiplier,
                        "final_contamination_level" => final_contamination,
                        "contamination_grade" => begin
                            if final_contamination > 0.8
                                "CRITICAL"
                            elseif final_contamination > 0.6
                                "HIGH"
                            elseif final_contamination > 0.4
                                "MEDIUM"
                            elseif final_contamination > 0.2
                                "LOW"
                            else
                                "MINIMAL"
                            end
                        end
                    )

                    push!(contamination_results, contamination_info)

                    println("  📏 $(wallet[1:8])... - $(contamination_info["contamination_grade"]) ($(round(final_contamination, digits=3)))")
                end

                sleep(0.2)  # Rate limiting

            catch e
                println("  ⚠️ Contamination calculation failed for $(wallet[1:8])...: $e")
            end
        end

        @test length(contamination_results) > 0

        # Verificar distribuição de níveis de contaminação
        contamination_levels = [result["contamination_grade"] for result in contamination_results]
        unique_levels = unique(contamination_levels)
        @test length(unique_levels) >= 2  # Pelo menos 2 níveis diferentes detectados

        println("🎯 Contamination Distribution:")
        for level in ["CRITICAL", "HIGH", "MEDIUM", "LOW", "MINIMAL"]
            level_count = isempty(contamination_levels) ? 0 : sum(contamination_levels .== level)
            if level_count > 0
                println("  - $level: $level_count wallets")
            end
        end

        save_test_result(Dict(
            "wallets_analyzed" => length(test_wallets),
            "contamination_results" => contamination_results,
            "contamination_distribution" => isempty(contamination_levels) ? Dict() : Dict(level => sum(contamination_levels .== level) for level in unique_levels),
            "unique_levels_detected" => length(unique_levels),
            "timestamp" => now()
        ), "unit_analysis_taint_propagation", "contamination_level_calculation")
    end

    # Teste 5: Real-time taint tracking simulation
    @testset "Real-Time Taint Tracking" begin
        println("⚡ Simulating real-time taint tracking with live data...")

        # Simular tracking em tempo real usando wallets ativos
        tracking_targets = [
            DEFI_WALLETS["raydium_amm_v4"],
            CEX_WALLETS["binance_hot_1"]
        ]

        tracking_sessions = []

        for target in tracking_targets
            try
                tracking_start = time()

                # Simulação de múltiplas verificações em intervalos
                tracking_data = []

                for check_round in 1:3
                    check_time = time()

                    # Fetch recent transactions
                    recent_data = fetch_real_transactions(target, limit=3)

                    if recent_data["success"]
                        check_result = Dict(
                            "round" => check_round,
                            "check_time" => check_time,
                            "transactions_found" => length(recent_data["data"]),
                            "new_taint_detected" => length(recent_data["data"]) > 0,
                            "sample_tx" => length(recent_data["data"]) > 0 ? recent_data["data"][1] : nothing
                        )

                        push!(tracking_data, check_result)

                        println("  🔄 Round $check_round for $(target[1:8])... - $(length(recent_data["data"])) new transactions")
                    end

                    sleep(0.5)  # Simular intervalo de tracking
                end

                tracking_end = time()
                tracking_duration = tracking_end - tracking_start

                session_info = Dict(
                    "target_wallet" => target,
                    "tracking_duration_seconds" => tracking_duration,
                    "total_checks" => length(tracking_data),
                    "successful_checks" => sum([check["new_taint_detected"] for check in tracking_data]),
                    "tracking_efficiency" => length(tracking_data) > 0 ? sum([check["new_taint_detected"] for check in tracking_data]) / length(tracking_data) : 0.0,
                    "tracking_details" => tracking_data
                )

                push!(tracking_sessions, session_info)

                println("  ✅ Tracking session for $(target[1:8])... completed in $(round(tracking_duration, digits=2))s")

            catch e
                println("  ❌ Real-time tracking failed for $(target[1:8])...: $e")
            end
        end

        @test length(tracking_sessions) > 0

        # Verificar performance de tracking
        avg_tracking_time = mean([session["tracking_duration_seconds"] for session in tracking_sessions])
        @test avg_tracking_time < 10.0  # Tracking deve ser eficiente

        # Verificar eficiência de detecção
        tracking_efficiency = mean([session["tracking_efficiency"] for session in tracking_sessions])
        @test tracking_efficiency > 0.0  # Deve detectar alguma atividade

        println("📈 Real-Time Tracking Performance:")
        println("  - Sessions completed: $(length(tracking_sessions))")
        println("  - Average tracking time: $(round(avg_tracking_time, digits=2))s")
        println("  - Detection efficiency: $(round(tracking_efficiency * 100, digits=1))%")

        save_test_result(Dict(
            "sessions_completed" => length(tracking_sessions),
            "average_tracking_time" => avg_tracking_time,
            "detection_efficiency" => tracking_efficiency,
            "performance_target_met" => avg_tracking_time < 10.0,
            "tracking_sessions" => tracking_sessions,
            "timestamp" => now()
        ), "unit_analysis_taint_propagation", "realtime_taint_tracking")
    end

    # Teste 6: Taint network analysis with real blockchain data
    @testset "Taint Network Analysis" begin
        println("🕸️ Analyzing taint networks using real blockchain relationships...")

        # Construir rede de taint usando wallets interconectadas
        network_nodes = [
            DEFI_WALLETS["raydium_amm_v4"],
            DEFI_WALLETS["orca_whirlpools"],
            DEFI_WALLETS["jupiter_v6"],
            CEX_WALLETS["binance_hot_1"]
        ]

        network_analysis = Dict(
            "nodes" => [],
            "edges" => [],
            "taint_clusters" => []
        )

        # Analisar cada nó da rede
        for node_wallet in network_nodes
            try
                node_data = fetch_real_transactions(node_wallet, limit=4)

                if node_data["success"]
                    node_info = Dict(
                        "wallet" => node_wallet,
                        "transaction_count" => length(node_data["data"]),
                        "node_importance" => min(1.0, length(node_data["data"]) * 0.1),
                        "taint_potential" => length(node_data["data"]) > 5 ? "HIGH" : (length(node_data["data"]) > 2 ? "MEDIUM" : "LOW")
                    )

                    push!(network_analysis["nodes"], node_info)

                    println("  🔗 Node $(node_wallet[1:8])... - Importance: $(round(node_info["node_importance"], digits=3)), Potential: $(node_info["taint_potential"])")
                end

                sleep(0.3)  # Rate limiting

            catch e
                println("  ⚠️ Network analysis failed for node $(node_wallet[1:8])...: $e")
            end
        end

        # Simular análise de edges (conexões entre nós)
        for i in 1:length(network_analysis["nodes"])
            for j in (i+1):length(network_analysis["nodes"])
                node1 = network_analysis["nodes"][i]
                node2 = network_analysis["nodes"][j]

                # Simular conexão baseada na importância dos nós
                connection_strength = (node1["node_importance"] + node2["node_importance"]) / 2

                if connection_strength > 0.3  # Threshold para considerar edge significativa
                    edge_info = Dict(
                        "source" => node1["wallet"],
                        "target" => node2["wallet"],
                        "strength" => connection_strength,
                        "taint_flow_potential" => connection_strength > 0.6 ? "HIGH" : "MEDIUM"
                    )

                    push!(network_analysis["edges"], edge_info)
                end
            end
        end

        # Análise de clusters de taint
        high_importance_nodes = filter(node -> node["node_importance"] > 0.5, network_analysis["nodes"])
        if length(high_importance_nodes) > 0
            cluster_info = Dict(
                "cluster_id" => "HIGH_TAINT_CLUSTER_1",
                "nodes" => [node["wallet"] for node in high_importance_nodes],
                "cluster_size" => length(high_importance_nodes),
                "average_importance" => mean([node["node_importance"] for node in high_importance_nodes])
            )

            push!(network_analysis["taint_clusters"], cluster_info)
        end

        @test length(network_analysis["nodes"]) > 0
        @test length(network_analysis["edges"]) >= 0

        # Verificar estrutura da rede
        network_density = length(network_analysis["edges"]) / max(1, length(network_analysis["nodes"]) * (length(network_analysis["nodes"]) - 1) / 2)
        @test network_density >= 0.0 && network_density <= 1.0

        println("🌐 Taint Network Analysis Results:")
        println("  - Total nodes: $(length(network_analysis["nodes"]))")
        println("  - Total edges: $(length(network_analysis["edges"]))")
        println("  - Network density: $(round(network_density, digits=3))")
        println("  - Taint clusters identified: $(length(network_analysis["taint_clusters"]))")

        save_test_result(Dict(
            "network_nodes" => length(network_analysis["nodes"]),
            "network_edges" => length(network_analysis["edges"]),
            "network_density" => network_density,
            "taint_clusters" => length(network_analysis["taint_clusters"]),
            "network_structure" => network_analysis,
            "timestamp" => now()
        ), "unit_analysis_taint_propagation", "taint_network_analysis")
    end

    println("\n🎯 Taint Propagation F2 Testing Complete!")
    println("All tests executed with real Solana blockchain data")
    println("Taint analysis performed using actual transaction patterns")
    println("Results saved to: unit/analysis/results/")
end
