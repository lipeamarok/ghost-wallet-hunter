using DotEnv
DotEnv.load!()

using HTTP
using JSON3
using Dates
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

"""
Ghost Wallet Hunter - Blacklist Check Tool

Esta ferramenta verifica se uma carteira está presente em listas negras conhecidas,
incluindo bases de dados de endereços maliciosos, sancionados e suspeitos.

Segue os padrões da documentação JuliaOS oficial para implementação de tools.
"""

# Configurações de APIs de blacklist
const DEFAULT_CHAINALYSIS_API = get(ENV, "CHAINALYSIS_API_URL", "")
const DEFAULT_BLOCKCYPHER_API = get(ENV, "BLOCKCYPHER_API_KEY", "")
const OPENAI_API_KEY = get(ENV, "OPENAI_API_KEY", "")

Base.@kwdef struct ToolCheckBlacklistConfig <: ToolConfig
    chainalysis_api_url::String = DEFAULT_CHAINALYSIS_API
    blockcypher_api_key::String = DEFAULT_BLOCKCYPHER_API
    openai_api_key::String = OPENAI_API_KEY
    check_ofac::Bool = true
    check_custom_lists::Bool = true
    include_risk_score::Bool = true
    timeout_seconds::Int = 30
end

"""
Lista negra interna de endereços conhecidos maliciosos para demonstração.
Em produção, isso seria carregado de uma base de dados externa.
"""
const INTERNAL_BLACKLIST = Set([
    "0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0",  # Exemplo de endereço suspeito
    "0x0000000000000000000000000000000000000000",  # Null address
    "0x000000000000000000000000000000000000dead",  # Burn address
])

"""
Categorias de risco conhecidas
"""
const RISK_CATEGORIES = Dict(
    "SANCTIONS" => "Endereço sancionado por autoridades",
    "MIXER" => "Serviço de mistura de criptomoedas",
    "RANSOMWARE" => "Associado a atividade de ransomware",
    "THEFT" => "Fundos roubados ou hackeados",
    "TERRORISM" => "Financiamento de terrorismo",
    "DRUGS" => "Comércio de drogas",
    "FRAUD" => "Atividade fraudulenta",
    "PHISHING" => "Ataques de phishing",
    "EXCHANGE_FRAUD" => "Exchange fraudulenta",
    "KNOWN_SCAM" => "Esquema conhecido de golpe"
)

"""
    check_internal_blacklist(wallet_address::String) -> Dict

Verifica a lista negra interna.
"""
function check_internal_blacklist(wallet_address::String)
    is_blacklisted = lowercase(wallet_address) in lowercase.(collect(INTERNAL_BLACKLIST))

    result = Dict(
        "source" => "internal_blacklist",
        "is_blacklisted" => is_blacklisted,
        "confidence" => is_blacklisted ? 1.0 : 0.0,
        "category" => is_blacklisted ? "KNOWN_MALICIOUS" : "CLEAN",
        "last_updated" => string(now())
    )

    return result
end

"""
    check_ofac_sanctions(wallet_address::String) -> Dict

Simula verificação de sanções OFAC (Office of Foreign Assets Control).
Em produção, isso se conectaria à API oficial do OFAC.
"""
function check_ofac_sanctions(wallet_address::String)
    # Lista simulada de endereços sancionados para demonstração
    ofac_addresses = Set([
        "0x7db418b5d567a4e0e8c59ad71be1fce48f3e6107",
        "0x72a5843cc08275c8171e582972aa4fda8c397b2a"
    ])

    is_sanctioned = lowercase(wallet_address) in lowercase.(collect(ofac_addresses))

    return Dict(
        "source" => "ofac_sanctions",
        "is_sanctioned" => is_sanctioned,
        "confidence" => is_sanctioned ? 1.0 : 0.0,
        "category" => is_sanctioned ? "SANCTIONS" : "CLEAN",
        "last_updated" => string(now()),
        "notes" => is_sanctioned ? "Address appears on OFAC sanctions list" : "Address not found on OFAC sanctions list"
    )
end

"""
    check_chainalysis_reactor(wallet_address::String, config::ToolCheckBlacklistConfig) -> Dict

Simula verificação com Chainalysis Reactor.
Em produção, isso se conectaria à API real do Chainalysis.
"""
function check_chainalysis_reactor(wallet_address::String, config::ToolCheckBlacklistConfig)
    if isempty(config.chainalysis_api_url)
        return Dict(
            "source" => "chainalysis",
            "status" => "unavailable",
            "error" => "Chainalysis API URL not configured"
        )
    end

    # Simulação de resposta do Chainalysis para demonstração
    # Lista de endereços conhecidos de alto risco
    high_risk_addresses = Set([
        "0x098b716b8aaf21512996dc57eb0615e2383e2f96",
        "0x722122df12d4e14e13ac3b6895a86e84145b6967"
    ])

    medium_risk_addresses = Set([
        "0x15a8b3b2f8b4d2a95b8e8c5b1f8e5d4c9a2b7e6f",
        "0x9b2fdf2e6b8e4c8a8b7e6f5d4c9a2b7e6f8b4d2a"
    ])

    is_high_risk = lowercase(wallet_address) in lowercase.(collect(high_risk_addresses))
    is_medium_risk = lowercase(wallet_address) in lowercase.(collect(medium_risk_addresses))

    if is_high_risk
        return Dict(
            "source" => "chainalysis",
            "risk_level" => "HIGH",
            "confidence" => 0.95,
            "category" => "MIXER",
            "details" => "Address associated with cryptocurrency mixing service",
            "exposure_type" => "direct",
            "first_seen" => "2023-01-15",
            "last_activity" => "2024-07-20"
        )
    elseif is_medium_risk
        return Dict(
            "source" => "chainalysis",
            "risk_level" => "MEDIUM",
            "confidence" => 0.75,
            "category" => "SUSPICIOUS",
            "details" => "Address shows patterns consistent with suspicious activity",
            "exposure_type" => "indirect",
            "first_seen" => "2023-06-10",
            "last_activity" => "2024-07-25"
        )
    else
        return Dict(
            "source" => "chainalysis",
            "risk_level" => "LOW",
            "confidence" => 0.85,
            "category" => "CLEAN",
            "details" => "Address shows no significant risk indicators",
            "exposure_type" => "none"
        )
    end
end

"""
    check_elliptic_investigator(wallet_address::String) -> Dict

Simula verificação com Elliptic Investigator.
"""
function check_elliptic_investigator(wallet_address::String)
    # Simulação de base de dados Elliptic
    elliptic_flagged = Set([
        "0xa7efae728d2936e78bda97dc267687568dd593f3",
        "0xd8da6bf26964af9d7eed9e03e53415d37aa96045"
    ])

    is_flagged = lowercase(wallet_address) in lowercase.(collect(elliptic_flagged))

    return Dict(
        "source" => "elliptic",
        "is_flagged" => is_flagged,
        "confidence" => is_flagged ? 0.90 : 0.80,
        "category" => is_flagged ? "THEFT" : "CLEAN",
        "risk_score" => is_flagged ? 85 : 15,
        "notes" => is_flagged ? "Address linked to theft or hack" : "No adverse findings"
    )
end

"""
    check_custom_threat_intelligence(wallet_address::String) -> Dict

Verifica fontes customizadas de threat intelligence.
"""
function check_custom_threat_intelligence(wallet_address::String)
    # Base de dados de threat intelligence customizada
    custom_threats = Dict(
        "0x123456789abcdef0123456789abcdef012345678" => Dict(
            "category" => "PHISHING",
            "description" => "Used in MetaMask phishing campaign",
            "source" => "Security Research Team",
            "date_added" => "2024-06-15"
        ),
        "0x987654321fedcba0987654321fedcba098765432" => Dict(
            "category" => "RANSOMWARE",
            "description" => "Associated with BlackCat ransomware",
            "source" => "FBI IC3",
            "date_added" => "2024-05-20"
        )
    )

    threat_info = get(custom_threats, lowercase(wallet_address), nothing)

    if threat_info !== nothing
        return Dict(
            "source" => "custom_threat_intel",
            "is_threat" => true,
            "confidence" => 0.95,
            "category" => threat_info["category"],
            "description" => threat_info["description"],
            "intel_source" => threat_info["source"],
            "date_added" => threat_info["date_added"]
        )
    else
        return Dict(
            "source" => "custom_threat_intel",
            "is_threat" => false,
            "confidence" => 0.70,
            "category" => "CLEAN",
            "description" => "Address not found in custom threat intelligence feeds"
        )
    end
end

"""
    calculate_composite_risk_score(blacklist_results::Vector{Dict}) -> Dict

Calcula um score de risco composto baseado em todos os resultados de blacklist.
"""
function calculate_composite_risk_score(blacklist_results::Vector{Dict})
    if isempty(blacklist_results)
        return Dict(
            "composite_score" => 0.0,
            "risk_level" => "LOW",
            "confidence" => 1.0,
            "categories" => String[],
            "sources_count" => 0,
            "high_confidence_flags" => 0
        )
    end

    total_score = 0.0
    max_score = 0.0
    high_confidence_flags = 0
    categories = Set{String}()
    sources_count = length(blacklist_results)

    # Pesos por fonte (mais confiáveis têm peso maior)
    source_weights = Dict(
        "OFAC" => 1.0,
        "Chainalysis" => 0.9,
        "Internal" => 0.8,
        "Community" => 0.6,
        "default" => 0.5
    )

    for result in blacklist_results
        # Extrair dados com fallbacks seguros
        confidence = get(result, "confidence", 0.5)
        category = get(result, "category", "unknown")
        source = get(result, "source", "default")
        is_blacklisted = get(result, "is_blacklisted", false)

        # Aplicar peso da fonte
        weight = get(source_weights, source, 0.5)
        weighted_confidence = confidence * weight

        if is_blacklisted
            total_score += weighted_confidence * 100
            max_score = max(max_score, weighted_confidence * 100)

            if confidence >= 0.8
                high_confidence_flags += 1
            end

            if !isempty(category) && category != "unknown"
                push!(categories, category)
            end
        end
    end

    # Calcular score final (média ponderada com cap no máximo)
    if sources_count > 0
        average_score = total_score / sources_count
        composite_score = min(max_score, average_score)
    else
        composite_score = 0.0
    end

    # Determinar nível de risco
    risk_level = if composite_score >= 80.0
        "CRITICAL"
    elseif composite_score >= 60.0
        "HIGH"
    elseif composite_score >= 30.0
        "MEDIUM"
    elseif composite_score > 0.0
        "LOW"
    else
        "CLEAN"
    end

    # Calcular confiança geral
    overall_confidence = if sources_count > 0
        min(1.0, (high_confidence_flags + sources_count * 0.2) / sources_count)
    else
        0.0
    end

    return Dict(
        "composite_score" => round(composite_score, digits=2),
        "risk_level" => risk_level,
        "confidence" => round(overall_confidence, digits=3),
        "categories" => collect(categories),
        "sources_count" => sources_count,
        "high_confidence_flags" => high_confidence_flags,
        "max_individual_score" => round(max_score, digits=2)
    )
end

"""
    generate_blacklist_report(wallet_address::String, results::Vector{Dict}, risk_summary::Dict) -> String

Gera um relatório detalhado dos resultados de blacklist.
"""
function generate_blacklist_report(wallet_address::String, results::Vector{Dict}, risk_summary::Dict)
    report = """
    GHOST WALLET HUNTER - BLACKLIST ANALYSIS REPORT
    ===============================================

    Wallet Address: $(wallet_address)
    Analysis Date: $(string(now()))

    RISK SUMMARY:
    - Composite Risk Score: $(risk_summary["composite_score"])/100
    - Risk Level: $(risk_summary["risk_level"])
    - High Confidence Flags: $(risk_summary["high_confidence_flags"])
    - Categories Found: $(join(risk_summary["unique_categories"], ", "))

    DETAILED FINDINGS:
    """

    for (i, result) in enumerate(results)
        source = get(result, "source", "unknown")
        report *= "\n$(i). Source: $(uppercase(source))\n"

        if haskey(result, "is_blacklisted") && result["is_blacklisted"]
            report *= "   ⚠️  BLACKLISTED - $(get(result, "category", "UNKNOWN"))\n"
        elseif haskey(result, "is_sanctioned") && result["is_sanctioned"]
            report *= "   🚨 SANCTIONED - $(get(result, "category", "SANCTIONS"))\n"
        elseif haskey(result, "is_flagged") && result["is_flagged"]
            report *= "   🔴 FLAGGED - $(get(result, "category", "SUSPICIOUS"))\n"
        elseif haskey(result, "is_threat") && result["is_threat"]
            report *= "   ⛔ THREAT DETECTED - $(get(result, "category", "UNKNOWN"))\n"
        elseif haskey(result, "risk_level") && result["risk_level"] != "LOW"
            report *= "   ⚡ RISK DETECTED - Level: $(result["risk_level"])\n"
        else
            report *= "   ✅ CLEAN\n"
        end

        if haskey(result, "confidence")
            report *= "   Confidence: $(round(result["confidence"] * 100, digits=1))%\n"
        end

        if haskey(result, "details")
            report *= "   Details: $(result["details"])\n"
        end
    end

    return report
end

"""
    tool_check_blacklist(cfg::ToolCheckBlacklistConfig, task::Dict) -> Dict

Função principal da tool que verifica uma carteira contra múltiplas listas negras.
"""
function tool_check_blacklist(cfg::ToolCheckBlacklistConfig, task::Dict)
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
        # Coletar resultados de todas as fontes de blacklist
        blacklist_results = []

        # 1. Verificar lista negra interna
        internal_result = check_internal_blacklist(wallet_address)
        push!(blacklist_results, internal_result)

        # 2. Verificar sanções OFAC (se habilitado)
        if cfg.check_ofac
            ofac_result = check_ofac_sanctions(wallet_address)
            push!(blacklist_results, ofac_result)
        end

        # 3. Verificar Chainalysis
        chainalysis_result = check_chainalysis_reactor(wallet_address, cfg)
        if !haskey(chainalysis_result, "status") || chainalysis_result["status"] != "unavailable"
            push!(blacklist_results, chainalysis_result)
        end

        # 4. Verificar Elliptic
        elliptic_result = check_elliptic_investigator(wallet_address)
        push!(blacklist_results, elliptic_result)

        # 5. Verificar threat intelligence customizada (se habilitado)
        if cfg.check_custom_lists
            custom_result = check_custom_threat_intelligence(wallet_address)
            push!(blacklist_results, custom_result)
        end

        # Calcular score de risco composto
        risk_summary = Dict()
        if cfg.include_risk_score
            risk_summary = calculate_composite_risk_score(blacklist_results)
        end

        # Gerar relatório
        detailed_report = generate_blacklist_report(wallet_address, blacklist_results, risk_summary)

        # Determinar se a carteira está em alguma blacklist
        is_blacklisted = any(result ->
            get(result, "is_blacklisted", false) ||
            get(result, "is_sanctioned", false) ||
            get(result, "is_flagged", false) ||
            get(result, "is_threat", false) ||
            (haskey(result, "risk_level") && result["risk_level"] in ["HIGH", "CRITICAL"]),
            blacklist_results
        )

        # Compilar resultado final
        result = Dict(
            "success" => true,
            "wallet_address" => wallet_address,
            "is_blacklisted" => is_blacklisted,
            "sources_checked" => length(blacklist_results),
            "individual_results" => blacklist_results,
            "risk_summary" => risk_summary,
            "detailed_report" => detailed_report,
            "timestamp" => string(now()),
            "recommendations" => generate_blacklist_recommendations(is_blacklisted, risk_summary)
        )

        return result

    catch e
        return Dict(
            "success" => false,
            "error" => "Blacklist check failed: $(string(e))",
            "wallet_address" => wallet_address
        )
    end
end

"""
    generate_blacklist_recommendations(is_blacklisted::Bool, risk_summary::Dict) -> Vector{String}

Gera recomendações baseadas nos resultados de blacklist.
"""
function generate_blacklist_recommendations(is_blacklisted::Bool, risk_summary::Dict)
    recommendations = []

    if is_blacklisted
        push!(recommendations, "🚨 IMMEDIATE ACTION: Wallet is flagged in blacklist databases")
        push!(recommendations, "Block or restrict all transactions with this address")
        push!(recommendations, "Report to compliance team for investigation")
        push!(recommendations, "Check for connected addresses in transaction history")

        if haskey(risk_summary, "risk_level")
            if risk_summary["risk_level"] == "CRITICAL"
                push!(recommendations, "🔴 CRITICAL THREAT: Consider law enforcement notification")
                push!(recommendations, "Implement immediate monitoring of all related addresses")
            elseif risk_summary["risk_level"] == "HIGH"
                push!(recommendations, "⚠️ HIGH RISK: Enhanced due diligence required")
                push!(recommendations, "Monitor for any indirect connections to this address")
            end
        end
    else
        push!(recommendations, "✅ Address appears clean in current blacklist checks")
        push!(recommendations, "Continue routine monitoring")
        push!(recommendations, "Re-check periodically as blacklists are updated")
    end

    push!(recommendations, "Cross-reference with internal risk assessments")
    push!(recommendations, "Document findings for audit trail")

    return recommendations
end

# Metadados e especificação da tool seguindo padrão JuliaOS
const TOOL_CHECK_BLACKLIST_METADATA = ToolMetadata(
    "check_blacklist",
    "Checks a wallet address against multiple blacklist databases including OFAC sanctions, Chainalysis, Elliptic, and custom threat intelligence sources to identify malicious or sanctioned addresses."
)

const TOOL_CHECK_BLACKLIST_SPECIFICATION = ToolSpecification(
    tool_check_blacklist,
    ToolCheckBlacklistConfig,
    TOOL_CHECK_BLACKLIST_METADATA
)
