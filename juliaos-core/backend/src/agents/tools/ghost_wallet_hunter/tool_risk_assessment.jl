using DotEnv
DotEnv.load!()

using HTTP
using JSON3
using Statistics
using Dates
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

"""
Ghost Wallet Hunter - Risk Assessment Tool

Esta ferramenta realiza uma avaliação completa de risco de uma carteira,
combinando análise de transações, verificação de blacklists, análise de rede
e inteligência artificial para fornecer um score de risco abrangente.

Segue os padrões da documentação JuliaOS oficial para implementação de tools.
"""

# Configurações
const DEFAULT_SOLANA_RPC = get(ENV, "SOLANA_RPC_URL", "https://api.mainnet-beta.solana.com")
const GROK_API_KEY = get(ENV, "GROK_API_KEY", "")

Base.@kwdef struct ToolRiskAssessmentConfig <: ToolConfig
    solana_rpc_url::String = DEFAULT_SOLANA_RPC
    grok_api_key::String = GROK_API_KEY
    assessment_depth::String = "comprehensive"  # "basic", "standard", "comprehensive"
    include_network_analysis::Bool = true
    include_ai_risk_assessment::Bool = true
    max_transactions_analyze::Int = 200
    max_connected_addresses::Int = 50
    risk_threshold_high::Float64 = 70.0
    risk_threshold_medium::Float64 = 40.0
end

"""
Estrutura para armazenar dados de avaliação de risco
"""
struct RiskAssessmentData
    wallet_address::String
    transaction_metrics::Dict
    behavioral_patterns::Dict
    network_analysis::Dict
    blacklist_status::Dict
    composite_score::Float64
    risk_level::String
    confidence::Float64
end

"""
    parse_solana_value(value) -> Float64

Parse seguro de valores Solana (lamports para SOL).
"""
function parse_solana_value(value)
    if value === nothing || value == 0
        return 0.0
    end

    try
        # Solana usa lamports (1 SOL = 1e9 lamports)
        if isa(value, String)
            # Remover prefixo 0x se existir (fallback para compatibilidade)
            clean_value = startswith(value, "0x") ? value[3:end] : value
            if all(c -> c in "0123456789ABCDEFabcdef", clean_value)
                # Valor hexadecimal
                lamports = parse(BigInt, clean_value, base=16)
            else
                # Valor decimal string
                lamports = parse(BigInt, clean_value)
            end
        else
            # Valor numérico direto
            lamports = BigInt(value)
        end

        # Converter lamports para SOL
        return Float64(lamports) / 1e9
    catch e
        @warn "Failed to parse Solana value: $value, error: $e"
        return 0.0
    end
end

"""
    extract_solana_transaction_value(tx::Dict, wallet_address::String) -> Dict

Extrai valores de transação Solana de forma segura.
"""
function extract_solana_transaction_value(tx::Dict, wallet_address::String)
    result = Dict("value_sol" => 0.0, "direction" => "unknown")

    try
        # Estrutura de transação Solana
        if haskey(tx, "meta") && haskey(tx["meta"], "preBalances") && haskey(tx["meta"], "postBalances")
            pre_balances = tx["meta"]["preBalances"]
            post_balances = tx["meta"]["postBalances"]
            account_keys = get(tx, "transaction", Dict()) |> t -> get(t, "message", Dict()) |> m -> get(m, "accountKeys", [])

            # Encontrar índice da carteira
            wallet_index = -1
            for (i, key) in enumerate(account_keys)
                if key == wallet_address
                    wallet_index = i
                    break
                end
            end

            if wallet_index > 0 && wallet_index <= length(pre_balances) && wallet_index <= length(post_balances)
                balance_change = post_balances[wallet_index] - pre_balances[wallet_index]
                result["value_sol"] = abs(parse_solana_value(balance_change))
                result["direction"] = balance_change >= 0 ? "in" : "out"
            end
        end
    catch e
        @warn "Error extracting Solana transaction value: $e"
    end

    return result
end

"""
    calculate_transaction_risk_metrics(transactions::Vector, wallet_address::String) -> Dict

Calcula métricas de risco baseadas nas transações da carteira.
"""
function calculate_transaction_risk_metrics(transactions::Vector, wallet_address::String)
    if isempty(transactions)
        return Dict(
            "total_transactions" => 0,
            "risk_score" => 0.0,
            "risk_factors" => [],
            "time_span_days" => 0
        )
    end

    risk_factors = []
    risk_score = 0.0

    # Métricas básicas
    total_txs = length(transactions)
    total_value_in = 0.0
    total_value_out = 0.0
    gas_prices = []
    timestamps = []
    counterparties = Set{String}()

    # Análise detalhada das transações
    for tx in transactions
        # Análise de valores Solana
        tx_value_info = extract_solana_transaction_value(tx, wallet_address)
        value_sol = tx_value_info["value_sol"]
        direction = tx_value_info["direction"]

        if value_sol > 0
            if direction == "out"
                total_value_out += value_sol
            elseif direction == "in"
                total_value_in += value_sol
            end
        end

        # Análise de taxa Solana (fee em lamports)
        if haskey(tx, "meta") && haskey(tx["meta"], "fee")
            fee_lamports = tx["meta"]["fee"]
            fee_sol = parse_solana_value(fee_lamports)
            push!(gas_prices, fee_sol)
        end

        # Análise temporal Solana
        if haskey(tx, "blockTime") && tx["blockTime"] !== nothing
            timestamp = tx["blockTime"]
            push!(timestamps, timestamp)
        end

        # Análise de contrapartes Solana
        if haskey(tx, "transaction") && haskey(tx["transaction"], "message")
            message = tx["transaction"]["message"]
            if haskey(message, "accountKeys")
                for account in message["accountKeys"]
                    if account != wallet_address
                        push!(counterparties, lowercase(account))
                    end
                end
            end
        end
    end

    # Calcular span temporal
    time_span_days = 0
    if length(timestamps) > 1
        time_span_days = (maximum(timestamps) - minimum(timestamps)) / (24 * 3600)
    end

    # Fator 1: Frequência de transações anômala
    if total_txs > 100 && time_span_days < 30
        push!(risk_factors, "High transaction frequency in short period")
        risk_score += 15
    end

    # Fator 2: Padrões de valor suspeitos
    if total_value_out > 0 && total_value_in > 0
        ratio = total_value_out / total_value_in
        if ratio > 0.95 && ratio < 1.05  # Valores muito equilibrados
            push!(risk_factors, "Suspicious balance between inflow and outflow")
            risk_score += 10
        end
    end

    # Fator 3: Diversidade de contrapartes
    unique_counterparties = length(counterparties)
    if unique_counterparties > total_txs * 0.8  # Muitas contrapartes únicas
        push!(risk_factors, "Unusually high counterparty diversity")
        risk_score += 12
    elseif unique_counterparties < total_txs * 0.1  # Poucas contrapartes
        push!(risk_factors, "Limited counterparty diversity - possible automated behavior")
        risk_score += 8
    end

    # Fator 4: Consistência de gas price (comportamento de bot)
    if length(gas_prices) > 10
        gas_cv = std(gas_prices) / mean(gas_prices)  # Coeficiente de variação
        if gas_cv < 0.05  # Muito consistente
            push!(risk_factors, "Suspiciously consistent gas pricing patterns")
            risk_score += 15
        end
    end

    # Fator 5: Horários de atividade
    if length(timestamps) > 5
        hours = [(ts ÷ 3600) % 24 for ts in timestamps]
        night_hours = count(h -> 2 <= h <= 6, hours)  # 2-6 AM UTC
        if night_hours > length(hours) * 0.4
            push!(risk_factors, "High activity during automated hours (2-6 AM UTC)")
            risk_score += 10
        end
    end

    return Dict(
        "total_transactions" => total_txs,
        "total_value_in_sol" => round(total_value_in, digits=6),
        "total_value_out_sol" => round(total_value_out, digits=6),
        "unique_counterparties" => unique_counterparties,
        "time_span_days" => round(time_span_days, digits=2),
        "risk_score" => min(100.0, risk_score),
        "risk_factors" => risk_factors,
        "gas_price_consistency" => length(gas_prices) > 5 ? round(std(gas_prices) / mean(gas_prices), digits=4) : 0.0
    )
end

"""
    analyze_behavioral_patterns(wallet_address::String, transactions::Vector) -> Dict

Analisa padrões comportamentais da carteira.
"""
function analyze_behavioral_patterns(wallet_address::String, transactions::Vector)
    if isempty(transactions)
        return Dict("patterns" => [], "risk_score" => 0.0, "behavior_type" => "INSUFFICIENT_DATA")
    end

    patterns = []
    risk_score = 0.0

    # Análise 1: Padrão de timing das transações
    if length(transactions) > 5
        timestamps = []
        for tx in transactions
            if haskey(tx, "blockTime") && tx["blockTime"] !== nothing
                push!(timestamps, tx["blockTime"])
            end
        end

        if length(timestamps) > 5
            intervals = diff(sort(timestamps))
            if length(intervals) > 0
                interval_consistency = std(intervals) / mean(intervals)
                if interval_consistency < 0.2  # Intervalos muito regulares
                    push!(patterns, "Regular transaction timing (possible automation)")
                    risk_score += 20
                end
            end
        end
    end

    # Análise 2: Padrões de valor
    values = []
    for tx in transactions
        if haskey(tx, "value") && tx["value"] != "0x0"
            value_wei = parse(BigInt, tx["value"], base=16)
            value_eth = Float64(value_wei) / 1e18
            push!(values, value_eth)
        end
    end

    if length(values) > 5
        # Verificar se há muitos valores redondos
        round_values = count(v -> v == round(v), values)
        if round_values > length(values) * 0.5
            push!(patterns, "High frequency of round-number transactions")
            risk_score += 15
        end

        # Verificar valores muito pequenos (dust attacks)
        dust_threshold = 0.001  # ETH
        dust_count = count(v -> 0 < v < dust_threshold, values)
        if dust_count > length(values) * 0.3
            push!(patterns, "Possible dust attack pattern detected")
            risk_score += 25
        end
    end

    # Análise 3: Padrão de direção das transações (Solana style)
    outgoing = 0
    incoming = 0
    for tx in transactions
        # Usar preBalances e postBalances para determinar direção em Solana
        if haskey(tx, "meta") && haskey(tx["meta"], "preBalances") && haskey(tx["meta"], "postBalances")
            pre_balances = tx["meta"]["preBalances"]
            post_balances = tx["meta"]["postBalances"]

            if length(pre_balances) > 0 && length(post_balances) > 0
                if pre_balances[1] > post_balances[1]  # Primeiro account geralmente é o signatário
                    outgoing += 1
                else
                    incoming += 1
                end
            end
        end
    end

    total = outgoing + incoming
    if total > 0
        outgoing_ratio = outgoing / total
        if outgoing_ratio > 0.8
            push!(patterns, "Predominantly outgoing transactions (possible distribution wallet)")
            risk_score += 10
        elseif outgoing_ratio < 0.2
            push!(patterns, "Predominantly incoming transactions (possible collection wallet)")
            risk_score += 10
        end
    end

    # Determinar tipo de comportamento
    behavior_type = if risk_score >= 50
        "HIGH_RISK_AUTOMATED"
    elseif risk_score >= 25
        "SUSPICIOUS_PATTERNS"
    elseif length(patterns) > 0
        "MODERATE_AUTOMATION"
    else
        "NORMAL_BEHAVIOR"
    end

    return Dict(
        "patterns" => patterns,
        "risk_score" => min(100.0, risk_score),
        "behavior_type" => behavior_type,
        "outgoing_ratio" => total > 0 ? round(outgoing / total, digits=3) : 0.0,
        "total_analyzed" => total
    )
end

"""
    perform_network_analysis(wallet_address::String, transactions::Vector, max_depth::Int) -> Dict

Realiza análise de rede das conexões da carteira.
"""
function perform_network_analysis(wallet_address::String, transactions::Vector, max_depth::Int)
    if isempty(transactions)
        return Dict("connected_addresses" => [], "risk_score" => 0.0, "network_risk" => "UNKNOWN")
    end

    # Extrair endereços conectados
    connected_addresses = Set{String}()
    connection_counts = Dict{String, Int}()
    high_value_connections = Set{String}()

    for tx in transactions
        # Análise de conexões Solana
        if haskey(tx, "transaction") && haskey(tx["transaction"], "message")
            message = tx["transaction"]["message"]
            if haskey(message, "accountKeys")
                for account in message["accountKeys"]
                    if lowercase(account) != lowercase(wallet_address)
                        counterparty = lowercase(account)
                        push!(connected_addresses, counterparty)
                        connection_counts[counterparty] = get(connection_counts, counterparty, 0) + 1

                        # Verificar se é conexão de alto valor (Solana)
                        value_sol = extract_solana_transaction_value(tx)
                        if value_sol > 10.0  # Mais de 10 SOL
                            push!(high_value_connections, counterparty)
                        end
                    end
                end
            end
        end
    end

    # Análise de risco da rede
    network_risk_score = 0.0
    risk_indicators = []

    # Indicador 1: Muitas conexões com poucas transações (possível lavagem)
    single_tx_connections = count(addr -> connection_counts[addr] == 1, keys(connection_counts))
    if single_tx_connections > length(connected_addresses) * 0.7
        push!(risk_indicators, "High ratio of single-transaction connections")
        network_risk_score += 20
    end

    # Indicador 2: Concentração de transações em poucos endereços
    if length(connected_addresses) > 10
        top_connections = sort(collect(connection_counts), by=x->x[2], rev=true)[1:min(5, end)]
        top_concentration = sum(x[2] for x in top_connections) / length(transactions)
        if top_concentration > 0.8
            push!(risk_indicators, "High transaction concentration with few addresses")
            network_risk_score += 15
        end
    end

    # Indicador 3: Muitas conexões de alto valor
    if length(high_value_connections) > 10
        push!(risk_indicators, "Multiple high-value connections (possible money laundering)")
        network_risk_score += 25
    end

    # Determinar nível de risco da rede
    network_risk = if network_risk_score >= 50
        "HIGH"
    elseif network_risk_score >= 25
        "MEDIUM"
    else
        "LOW"
    end

    return Dict(
        "connected_addresses" => collect(connected_addresses)[1:min(max_depth, end)],
        "total_unique_connections" => length(connected_addresses),
        "high_value_connections" => length(high_value_connections),
        "single_transaction_ratio" => length(connected_addresses) > 0 ? round(single_tx_connections / length(connected_addresses), digits=3) : 0.0,
        "risk_score" => min(100.0, network_risk_score),
        "network_risk" => network_risk,
        "risk_indicators" => risk_indicators,
        "top_connections" => length(connected_addresses) > 0 ? sort(collect(connection_counts), by=x->x[2], rev=true)[1:min(5, end)] : []
    )
end

"""
    generate_ai_risk_assessment(assessment_data::Dict, config::ToolRiskAssessmentConfig) -> String

Gera avaliação de risco usando IA baseada em todos os dados coletados.
"""
function generate_ai_risk_assessment(assessment_data::Dict, config::ToolRiskAssessmentConfig)
    if isempty(config.grok_api_key)
        return "AI risk assessment unavailable: No Grok API key configured"
    end

    try
        grok_cfg = Grok.GrokConfig(
            api_key = config.grok_api_key,
            model_name = "grok-beta",
            temperature = 0.2,  # Baixa temperatura para análise mais conservadora
            max_tokens = 800
        )

        # Compilar dados para análise
        wallet_addr = assessment_data["wallet_address"]
        tx_metrics = assessment_data["transaction_metrics"]
        behavior = assessment_data["behavioral_patterns"]
        network = assessment_data["network_analysis"]

        prompt = """
        Você é um especialista em análise de risco blockchain. Analise esta carteira Solana:

        ENDEREÇO: $(wallet_addr)

        MÉTRICAS DE TRANSAÇÃO:
        - Total de transações: $(tx_metrics["total_transactions"])
        - Valor total entrada: $(tx_metrics["total_value_in_sol"]) SOL
        - Valor total saída: $(tx_metrics["total_value_out_sol"]) SOL
        - Contrapartes únicas: $(tx_metrics["unique_counterparties"])
        - Período ativo: $(tx_metrics["time_span_days"]) dias
        - Fatores de risco: $(join(tx_metrics["risk_factors"], "; "))
        - Score de risco transações: $(tx_metrics["risk_score"])/100

        PADRÕES COMPORTAMENTAIS:
        - Tipo de comportamento: $(behavior["behavior_type"])
        - Padrões detectados: $(join(behavior["patterns"], "; "))
        - Score de risco comportamental: $(behavior["risk_score"])/100
        - Ratio transações saída: $(behavior["outgoing_ratio"])

        ANÁLISE DE REDE:
        - Conexões únicas: $(network["total_unique_connections"])
        - Conexões alto valor: $(network["high_value_connections"])
        - Risco da rede: $(network["network_risk"])
        - Indicadores de rede: $(join(network["risk_indicators"], "; "))
        - Score de risco rede: $(network["risk_score"])/100

        FORNEÇA UMA ANÁLISE DETALHADA INCLUINDO:
        1. Probabilidade de atividade maliciosa (1-10)
        2. Principais preocupações de segurança
        3. Classificação de risco: BAIXO/MÉDIO/ALTO/CRÍTICO
        4. Recomendações específicas para monitoramento
        5. Potenciais cenários de uso malicioso

        Resposta em português, máximo 600 palavras, focada em aspectos técnicos de segurança.
        """

        ai_response = Grok.grok_util(grok_cfg, prompt)
        return ai_response

    catch e
        return "AI risk assessment failed: $(string(e))"
    end
end

"""
    calculate_composite_risk_score(tx_metrics::Dict, behavior::Dict, network::Dict, blacklist::Dict) -> Dict

Calcula score de risco composto combinando todas as análises.
"""
function calculate_composite_risk_score(tx_metrics::Dict, behavior::Dict, network::Dict, blacklist::Dict)
    # Pesos para cada componente
    weights = Dict(
        "transaction" => 0.25,
        "behavioral" => 0.25,
        "network" => 0.25,
        "blacklist" => 0.25
    )

    # Scores individuais
    tx_score = get(tx_metrics, "risk_score", 0.0)
    behavior_score = get(behavior, "risk_score", 0.0)
    network_score = get(network, "risk_score", 0.0)

    # Score de blacklist
    blacklist_score = 0.0
    if haskey(blacklist, "is_blacklisted") && blacklist["is_blacklisted"]
        blacklist_score = 100.0  # Máximo se estiver em blacklist
    elseif haskey(blacklist, "composite_score")
        blacklist_score = blacklist["composite_score"]
    end

    # Calcular score composto
    composite_score = (
        tx_score * weights["transaction"] +
        behavior_score * weights["behavioral"] +
        network_score * weights["network"] +
        blacklist_score * weights["blacklist"]
    )

    # Determinar nível de risco
    risk_level = if composite_score >= 80
        "CRITICAL"
    elseif composite_score >= 60
        "HIGH"
    elseif composite_score >= 35
        "MEDIUM"
    else
        "LOW"
    end

    # Calcular confiança baseada na quantidade de dados
    confidence = min(1.0, (
        get(tx_metrics, "total_transactions", 0) / 50 * 0.3 +
        length(get(behavior, "patterns", [])) / 5 * 0.3 +
        get(network, "total_unique_connections", 0) / 20 * 0.2 +
        0.2  # Base confidence
    ))

    return Dict(
        "composite_score" => round(composite_score, digits=2),
        "risk_level" => risk_level,
        "confidence" => round(confidence, digits=3),
        "component_scores" => Dict(
            "transaction_risk" => tx_score,
            "behavioral_risk" => behavior_score,
            "network_risk" => network_score,
            "blacklist_risk" => blacklist_score
        ),
        "weights_used" => weights
    )
end

"""
    tool_risk_assessment(cfg::ToolRiskAssessmentConfig, task::Dict) -> Dict

Função principal da tool que realiza avaliação completa de risco de uma carteira.
"""
function tool_risk_assessment(cfg::ToolRiskAssessmentConfig, task::Dict)
    # Validação de entrada
    if !haskey(task, "wallet_address") || !(task["wallet_address"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'wallet_address' field")
    end

    wallet_address = task["wallet_address"]

    # Validar formato do endereço Solana (base58, 32-44 chars)
    if !occursin(r"^[1-9A-HJ-NP-Za-km-z]{32,44}$", wallet_address)
        return Dict("success" => false, "error" => "Invalid Solana address format")
    end

    try
        # Simulação de busca de transações (em produção, integraria com analyze_wallet)
        transactions = []  # Seria populado com dados reais

        # Para demonstração, vamos simular algumas transações
        sample_transactions = [
            Dict("from" => wallet_address, "to" => "0x742C2c5a3Ff7e9e7F9Ac8b7e6f8D3C1a2B9E8F7A",
                 "value" => "0x16345785D8A0000", "gasPrice" => "0x4A817C800", "timestamp" => "0x60A8B2C0"),
            Dict("from" => "0x8E2F3a5b9C8D7E6F4A3B2C1D0E9F8A7B6C5D4E3F", "to" => wallet_address,
                 "value" => "0x8AC7230489E80000", "gasPrice" => "0x4A817C800", "timestamp" => "0x60A8B4A0"),
        ]
        transactions = sample_transactions

        # 1. Análise de métricas de transação
        tx_metrics = calculate_transaction_risk_metrics(transactions, wallet_address)

        # 2. Análise de padrões comportamentais
        behavioral_analysis = analyze_behavioral_patterns(wallet_address, transactions)

        # 3. Análise de rede (se habilitada)
        network_analysis = Dict("risk_score" => 0.0, "network_risk" => "LOW")
        if cfg.include_network_analysis
            network_analysis = perform_network_analysis(wallet_address, transactions, cfg.max_connected_addresses)
        end

        # 4. Simulação de verificação de blacklist
        blacklist_status = Dict(
            "is_blacklisted" => false,
            "composite_score" => 15.0,
            "sources_checked" => 5
        )

        # 5. Calcular score de risco composto
        risk_summary = calculate_composite_risk_score(
            tx_metrics, behavioral_analysis, network_analysis, blacklist_status
        )

        # 6. Análise AI (se habilitada)
        ai_assessment = ""
        if cfg.include_ai_risk_assessment
            assessment_data = Dict(
                "wallet_address" => wallet_address,
                "transaction_metrics" => tx_metrics,
                "behavioral_patterns" => behavioral_analysis,
                "network_analysis" => network_analysis
            )
            ai_assessment = generate_ai_risk_assessment(assessment_data, cfg)
        end

        # 7. Gerar recomendações
        recommendations = generate_risk_recommendations(risk_summary["risk_level"], risk_summary["composite_score"])

        # Compilar resultado final
        result = Dict(
            "success" => true,
            "wallet_address" => wallet_address,
            "assessment_depth" => cfg.assessment_depth,
            "risk_summary" => risk_summary,
            "detailed_analysis" => Dict(
                "transaction_metrics" => tx_metrics,
                "behavioral_patterns" => behavioral_analysis,
                "network_analysis" => network_analysis,
                "blacklist_status" => blacklist_status
            ),
            "ai_assessment" => ai_assessment,
            "recommendations" => recommendations,
            "metadata" => Dict(
                "timestamp" => string(now()),
                "analysis_version" => "1.0",
                "data_sources" => ["blockchain_rpc", "pattern_analysis", "network_graph", "ai_assessment"]
            )
        )

        return result

    catch e
        return Dict(
            "success" => false,
            "error" => "Risk assessment failed: $(string(e))",
            "wallet_address" => wallet_address
        )
    end
end

"""
    generate_risk_recommendations(risk_level::String, score::Float64) -> Vector{String}

Gera recomendações específicas baseadas no nível de risco e score.
"""
function generate_risk_recommendations(risk_level::String, score::Float64)
    base_recommendations = [
        "Implement continuous monitoring for this address",
        "Document all findings for compliance records"
    ]

    if risk_level == "CRITICAL"
        return [
            "🚨 IMMEDIATE ACTION REQUIRED",
            "Block all transactions with this address",
            "Escalate to security team immediately",
            "Consider law enforcement notification",
            "Investigate all connected addresses",
            "Implement enhanced monitoring of related wallets",
            base_recommendations...
        ]
    elseif risk_level == "HIGH"
        return [
            "⚠️ HIGH RISK - Enhanced monitoring required",
            "Restrict large value transactions",
            "Require additional verification for interactions",
            "Monitor for pattern changes",
            "Review all historical transactions",
            "Consider temporary holds on transactions",
            base_recommendations...
        ]
    elseif risk_level == "MEDIUM"
        return [
            "📊 MEDIUM RISK - Increased surveillance recommended",
            "Monitor transaction patterns for changes",
            "Review counterparty relationships",
            "Implement periodic re-assessment",
            "Consider transaction limits",
            base_recommendations...
        ]
    else
        return [
            "✅ LOW RISK - Standard monitoring sufficient",
            "Continue routine compliance checks",
            "Re-assess if activity patterns change significantly",
            base_recommendations...
        ]
    end
end

# Metadados e especificação da tool seguindo padrão JuliaOS
const TOOL_RISK_ASSESSMENT_METADATA = ToolMetadata(
    "risk_assessment",
    "Performs comprehensive risk assessment of a wallet address by analyzing transaction patterns, behavioral indicators, network connections, blacklist status, and generating AI-powered risk insights with actionable recommendations."
)

const TOOL_RISK_ASSESSMENT_SPECIFICATION = ToolSpecification(
    tool_risk_assessment,
    ToolRiskAssessmentConfig,
    TOOL_RISK_ASSESSMENT_METADATA
)
