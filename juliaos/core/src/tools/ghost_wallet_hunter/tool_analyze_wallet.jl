using DotEnv
DotEnv.load!()

using HTTP
using JSON3
using Dates
using Statistics
using ...CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

"""
Ghost Wallet Hunter - Wallet Analysis Tool

Esta ferramenta analisa uma carteira específica para detectar padrões suspeitos,
transações anômalas e comportamentos típicos de "ghost wallets".

Segue os padrões da documentação JuliaOS oficial para implementação de tools.
"""

# Configurações da API Solana com fallbacks
const DEFAULT_SOLANA_RPC = get(ENV, "SOLANA_RPC_URL", "https://api.mainnet-beta.solana.com")
const FALLBACK_SOLANA_RPCS = [
    "https://solana-api.projectserum.com",
    "https://rpc.ankr.com/solana",
    "https://api.mainnet-beta.solana.com"
]

# Use environment API keys
const OPENAI_API_KEY = get(ENV, "OPENAI_API_KEY", "")
const GROK_API_KEY = get(ENV, "GROK_API_KEY", "")

Base.@kwdef struct ToolAnalyzeWalletConfig <: ToolConfig
    solana_rpc_url::String = DEFAULT_SOLANA_RPC
    fallback_rpcs::Vector{String} = FALLBACK_SOLANA_RPCS
    openai_api_key::String = OPENAI_API_KEY
    grok_api_key::String = GROK_API_KEY
    analysis_depth::String = "standard"  # "basic", "standard", "deep"
    include_ai_analysis::Bool = false     # Desabilitar AI por enquanto
    max_transactions::Int = 1000          # Aumentar limite
    rate_limit_delay::Float64 = 0.5       # Segundos entre requests
    max_retries::Int = 3
end

"""
    make_solana_rpc_call(config::ToolAnalyzeWalletConfig, method::String, params::Vector) -> Dict

Faz chamada RPC Solana com fallback automático e rate limiting.
"""
function make_solana_rpc_call(config::ToolAnalyzeWalletConfig, method::String, params::Vector)
    rpcs_to_try = [config.solana_rpc_url; config.fallback_rpcs]

    for (attempt, rpc_url) in enumerate(rpcs_to_try)
        try
            # Rate limiting
            if attempt > 1
                sleep(config.rate_limit_delay * attempt)
            end

            response = HTTP.post(
                rpc_url,
                ["Content-Type" => "application/json"],
                JSON3.write(Dict(
                    "jsonrpc" => "2.0",
                    "method" => method,
                    "params" => params,
                    "id" => 1
                ));
                timeout = 30
            )

            if response.status == 200
                return JSON3.read(String(response.body))
            elseif response.status == 429 && attempt < length(rpcs_to_try)
                @warn "Rate limited on $rpc_url, trying next RPC..."
                continue
            else
                throw(ErrorException("HTTP $(response.status): $(String(response.body))"))
            end

        catch e
            if attempt == length(rpcs_to_try)
                rethrow(e)
            else
                @warn "RPC call failed on $rpc_url: $e, trying next..."
                continue
            end
        end
    end

    throw(ErrorException("All RPC endpoints failed"))
end

"""
    analyze_wallet_transactions(wallet_address::String, config::ToolAnalyzeWalletConfig, max_txs::Int) -> Dict

Analisa transações de uma carteira Solana com fallback robusto.
"""
function analyze_wallet_transactions(wallet_address::String, config::ToolAnalyzeWalletConfig, max_txs::Int)
    try
        # Buscar transações recentes da carteira usando Solana RPC com fallback
        signature_data = make_solana_rpc_call(
            config,
            "getSignaturesForAddress",
            [wallet_address, Dict("limit" => max_txs)]
        )

        if !haskey(signature_data, "result")
            return Dict("error" => "Failed to get transaction signatures", "success" => false)
        end

        signatures = signature_data["result"]
        transactions = []

        # Buscar detalhes de cada transação com rate limiting
        for (i, sig_info) in enumerate(signatures[1:min(end, max_txs)])
            if haskey(sig_info, "signature")
                # Rate limiting para evitar 429
                if i > 1 && i % 10 == 0
                    sleep(config.rate_limit_delay)
                end

                tx_data = make_solana_rpc_call(
                    config,
                    "getTransaction",
                    [sig_info["signature"], Dict("encoding" => "json", "maxSupportedTransactionVersion" => 0)]
                )

                if haskey(tx_data, "result") && tx_data["result"] !== nothing
                    push!(transactions, tx_data["result"])
                end
            end

            if length(transactions) >= max_txs
                break
            end
        end

        return Dict(
            "transactions" => transactions,
            "total_found" => length(transactions),
            "latest_block" => latest_block,
            "success" => true
        )

    catch e
        return Dict("error" => string(e), "success" => false)
    end
end

"""
    detect_ghost_patterns(transactions::Vector) -> Dict

Detecta padrões suspeitos típicos de ghost wallets nas transações.
"""
function detect_ghost_patterns(transactions::Vector)
    if isempty(transactions)
        return Dict("patterns" => [], "risk_score" => 0, "analysis" => "No transactions to analyze")
    end

    suspicious_patterns = []
    risk_score = 0

    # Padrão 1: Transações em horários suspeitos (automated behavior)
    automated_hours = 0
    for tx in transactions
        if haskey(tx, "timestamp")
            # Converter timestamp para hora
            timestamp = parse(Int, tx["timestamp"], base=16)
            hour = (timestamp ÷ 3600) % 24
            # Horários suspeitos: 2-6 AM UTC (bots)
            if 2 <= hour <= 6
                automated_hours += 1
            end
        end
    end

    if automated_hours > length(transactions) * 0.3  # Mais de 30% em horários suspeitos
        push!(suspicious_patterns, "High automated activity during suspicious hours")
        risk_score += 25
    end

    # Padrão 2: Valores redondos suspeitos
    round_values = 0
    for tx in transactions
        if haskey(tx, "value")
            value_wei = parse(BigInt, tx["value"], base=16)
            value_eth = value_wei / BigInt(10)^18
            # Valores exatamente redondos são suspeitos
            if value_eth == round(value_eth) && value_eth > 0
                round_values += 1
            end
        end
    end

    if round_values > length(transactions) * 0.4  # Mais de 40% valores redondos
        push!(suspicious_patterns, "Unusual frequency of round value transactions")
        risk_score += 20
    end

    # Padrão 3: Frequência alta de transações
    if length(transactions) > 50
        push!(suspicious_patterns, "High transaction frequency")
        risk_score += 15
    end

    # Padrão 4: Análise de gas price patterns
    gas_prices = []
    for tx in transactions
        if haskey(tx, "gasPrice")
            gas_price = parse(BigInt, tx["gasPrice"], base=16)
            push!(gas_prices, gas_price)
        end
    end

    if length(gas_prices) > 5
        # Verificar se gas prices são muito consistentes (bot behavior)
        gas_std = std(Float64.(gas_prices))
        gas_mean = mean(Float64.(gas_prices))
        if gas_std / gas_mean < 0.1  # Muito baixa variabilidade
            push!(suspicious_patterns, "Suspiciously consistent gas price patterns")
            risk_score += 20
        end
    end

    # Determinar nível de risco
    risk_level = if risk_score >= 60
        "HIGH"
    elseif risk_score >= 30
        "MEDIUM"
    else
        "LOW"
    end

    return Dict(
        "patterns" => suspicious_patterns,
        "risk_score" => risk_score,
        "risk_level" => risk_level,
        "analysis" => "Completed pattern analysis for $(length(transactions)) transactions"
    )
end

"""
    generate_ai_analysis(wallet_address::String, patterns::Dict, config::ToolAnalyzeWalletConfig) -> String

Gera análise AI usando OpenAI para interpretar os padrões detectados.
"""
function generate_ai_analysis(wallet_address::String, patterns::Dict, config::ToolAnalyzeWalletConfig)
    if isempty(config.openai_api_key)
        return "AI analysis unavailable: No OpenAI API key configured"
    end

    try
        openai_cfg = OpenAI.OpenAIConfig(
            api_key = config.openai_api_key,
            model_name = "gpt-3.5-turbo",
            temperature = 0.3,  # Lower temperature for analytical tasks
            max_tokens = 512
        )

        prompt = """
        Analise a seguinte carteira Ethereum para atividade suspeita de "ghost wallet":

        Endereço: $(wallet_address)
        Padrões detectados: $(patterns["patterns"])
        Score de risco: $(patterns["risk_score"])
        Nível de risco: $(patterns["risk_level"])

        Forneça uma análise concisa sobre:
        1. Probabilidade de ser uma ghost wallet (1-10)
        2. Principais indicadores de suspeita
        3. Recomendações de investigação adicional
        4. Classificação final: LEGÍTIMA, SUSPEITA ou GHOST_WALLET

        Resposta em português, máximo 300 palavras.
        """

        ai_response = OpenAI.openai_util(openai_cfg, prompt)
        return ai_response

    catch e
        return "AI analysis failed: $(string(e))"
    end
end

"""
    tool_analyze_wallet(cfg::ToolAnalyzeWalletConfig, task::Dict) -> Dict

Função principal da tool que analisa uma carteira para detectar atividade ghost wallet.
"""
function tool_analyze_wallet(cfg::ToolAnalyzeWalletConfig, task::Dict)
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
        # Passo 1: Analisar transações da carteira
        tx_analysis = analyze_wallet_transactions(wallet_address, cfg, cfg.max_transactions)

        if !tx_analysis["success"]
            return Dict(
                "success" => false,
                "error" => "Failed to analyze wallet transactions: $(tx_analysis["error"])",
                "wallet_address" => wallet_address
            )
        end

        # Passo 2: Detectar padrões suspeitos
        pattern_analysis = detect_ghost_patterns(tx_analysis["transactions"])

        # Passo 3: Análise AI (se habilitada)
        ai_analysis = ""
        if cfg.include_ai_analysis
            ai_analysis = generate_ai_analysis(wallet_address, pattern_analysis, cfg)
        end

        # Passo 4: Compilar resultado final
        result = Dict(
            "success" => true,
            "wallet_address" => wallet_address,
            "analysis_depth" => cfg.analysis_depth,
            "transaction_summary" => Dict(
                "total_transactions" => tx_analysis["total_found"],
                "latest_block_analyzed" => tx_analysis["latest_block"]
            ),
            "risk_assessment" => pattern_analysis,
            "ai_analysis" => ai_analysis,
            "timestamp" => string(now()),
            "recommendations" => generate_recommendations(pattern_analysis["risk_level"])
        )

        return result

    catch e
        return Dict(
            "success" => false,
            "error" => "Analysis failed: $(string(e))",
            "wallet_address" => wallet_address
        )
    end
end

"""
    generate_recommendations(risk_level::String) -> Vector{String}

Gera recomendações baseadas no nível de risco detectado.
"""
function generate_recommendations(risk_level::String)
    base_recommendations = [
        "Monitor wallet activity for changes in patterns",
        "Cross-reference with known blacklists"
    ]

    if risk_level == "HIGH"
        return [
            base_recommendations...,
            "IMMEDIATE ACTION: Flag wallet for manual review",
            "Check for connections to known malicious addresses",
            "Investigate source of funds and destination patterns",
            "Consider temporary monitoring or restrictions"
        ]
    elseif risk_level == "MEDIUM"
        return [
            base_recommendations...,
            "Conduct deeper transaction history analysis",
            "Monitor for escalation in suspicious patterns",
            "Verify legitimacy through additional data sources"
        ]
    else
        return [
            base_recommendations...,
            "Continue routine monitoring",
            "Wallet appears to have normal activity patterns"
        ]
    end
end

# Metadados e especificação da tool seguindo padrão JuliaOS
const TOOL_ANALYZE_WALLET_METADATA = ToolMetadata(
    "analyze_wallet",
    "Analyzes a specific wallet address to detect ghost wallet patterns, suspicious transactions, and risk indicators using blockchain data and AI analysis."
)

const TOOL_ANALYZE_WALLET_SPECIFICATION = ToolSpecification(
    tool_analyze_wallet,
    ToolAnalyzeWalletConfig,
    TOOL_ANALYZE_WALLET_METADATA
)
