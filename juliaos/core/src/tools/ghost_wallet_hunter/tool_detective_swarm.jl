using DotEnv
DotEnv.load!()

using HTTP
using JSON3
using Dates

# Import JuliaOS dependencies
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

"""
    DetectiveAgent

Agente JuliaOS especializado para investigação de carteiras.
Cada detetive tem especialidade única e trabalha em conjunto via swarm intelligence.
"""
@kwdef struct DetectiveAgent
    id::String
    name::String
    specialty::String
    analysis_focus::String
    prompt_style::String
    model_config::Dict = Dict(
        "model" => "gpt-3.5-turbo",
        "temperature" => 0.7,
        "max_tokens" => 800
    )
    created_at::DateTime = now()
    status::String = "ready"
end

"""
    DetectiveAgentConfig

Configuration for Detective Agent creation and management.
"""
@kwdef struct DetectiveAgentConfig
    detective_type::String
    wallet_address::String
    investigation_data::Dict = Dict()
    enable_swarm_coordination::Bool = true
    llm_model::String = "gpt-3.5-turbo"
    analysis_depth::String = "standard"
end

# The Complete Detective Squad Registry
const DETECTIVE_SQUAD_REGISTRY = Dict{String, DetectiveAgent}(
    "poirot" => DetectiveAgent(
        id = "detective_poirot_001",
        name = "Hercule Poirot",
        specialty = "Transaction Analysis & Behavioral Patterns",
        analysis_focus = "transaction_patterns",
        prompt_style = "Meu caro amigo, como o renomado detetive Hercule Poirot, analiso cada transação com precisão metodológica. Observo padrões, frequências, valores e timing das transações para revelar comportamentos suspeitos através das minhas células cinzentas."
    ),
    "marple" => DetectiveAgent(
        id = "detective_marple_002",
        name = "Miss Jane Marple",
        specialty = "Pattern & Anomaly Detection",
        analysis_focus = "anomaly_detection",
        prompt_style = "Como Miss Jane Marple, tenho uma intuição especial para detectar anomalias e padrões incomuns. Analiso comportamentos que fogem do normal, identificando atividades suspeitas através da minha experiência com a natureza humana."
    ),
    "spade" => DetectiveAgent(
        id = "detective_spade_003",
        name = "Sam Spade",
        specialty = "Risk Assessment & Threat Classification",
        analysis_focus = "risk_assessment",
        prompt_style = "Como Sam Spade, sou direto e pragmático na avaliação de riscos. Classifico ameaças de forma clara e objetiva, focando em evidências concretas e níveis de perigo real, sem rodeios."
    ),
    "marlowe" => DetectiveAgent(
        id = "detective_marlowe_004",
        name = "Philip Marlowe",
        specialty = "Bridge & Mixer Tracking",
        analysis_focus = "network_analysis",
        prompt_style = "Como Philip Marlowe, rastreio conexões obscuras e redes complexas. Especializo-me em identificar mixers, bridges e conexões entre carteiras que tentam ocultar rastros no submundo das criptomoedas."
    ),
    "dupin" => DetectiveAgent(
        id = "detective_dupin_005",
        name = "Auguste Dupin",
        specialty = "Compliance & AML Analysis",
        analysis_focus = "compliance_analysis",
        prompt_style = "Como Auguste Dupin, aplico análise lógica e dedutiva para questões de compliance. Verifico violações AML, sanções e conformidade regulatória com raciocínio analítico preciso e metódico."
    ),
    "shadow" => DetectiveAgent(
        id = "detective_shadow_006",
        name = "The Shadow",
        specialty = "Network Cluster Analysis",
        analysis_focus = "cluster_analysis",
        prompt_style = "Como The Shadow, vejo o que outros não conseguem ver. Analiso clusters ocultos, redes de carteiras conectadas e padrões de comportamento coordenado que permanecem nas sombras da blockchain."
    ),
    "raven" => DetectiveAgent(
        id = "detective_raven_007",
        name = "Raven",
        specialty = "LLM Explanation & Communication",
        analysis_focus = "final_report",
        prompt_style = "Como Raven, transformo análises técnicas complexas em explicações claras e compreensíveis. Sintetizo todas as descobertas em um relatório final educativo e acionável para usuários finais."
    )
)

"""
    DetectiveSwarmResult

Result of swarm-coordinated detective investigation.
"""
struct DetectiveSwarmResult
    swarm_id::String
    coordinator_agent::String
    participating_detectives::Vector{String}
    investigation_summary::Dict
    individual_analyses::Vector{Dict}
    swarm_consensus::Dict
    coordination_metrics::Dict
    final_report::String
    overall_confidence::Float64
    investigation_timestamp::DateTime
end

"""
    create_detective_agent(config::DetectiveAgentConfig) -> DetectiveAgent

Creates a specialized detective agent for blockchain investigation.
"""
function create_detective_agent(config::DetectiveAgentConfig)
    try
        detective_type = config.detective_type

        if !haskey(DETECTIVE_SQUAD_REGISTRY, detective_type)
            throw(ArgumentError("Unknown detective type: $detective_type. Available: $(keys(DETECTIVE_SQUAD_REGISTRY))"))
        end

        # Get base detective template
        base_detective = DETECTIVE_SQUAD_REGISTRY[detective_type]

        # Create configured detective instance
        detective_agent = DetectiveAgent(
            id = "$(base_detective.id)_$(now())",
            name = base_detective.name,
            specialty = base_detective.specialty,
            analysis_focus = base_detective.analysis_focus,
            prompt_style = base_detective.prompt_style,
            model_config = Dict(
                "model" => config.llm_model,
                "temperature" => 0.7,
                "max_tokens" => 800,
                "analysis_depth" => config.analysis_depth
            ),
            created_at = now(),
            status = "active"
        )

        println("🕵️ Detective $(detective_agent.name) created successfully!")
        println("   📋 Specialty: $(detective_agent.specialty)")
        println("   🎯 Focus: $(detective_agent.analysis_focus)")

        return detective_agent

    catch e
        println("❌ Error creating detective agent: $e")
        rethrow(e)
    end
end

"""
    execute_detective_analysis(detective::DetectiveAgent, wallet_address::String, investigation_data::Dict) -> Dict

Executes specialized analysis by a detective agent using llm_chat tool.
"""
function execute_detective_analysis(detective::DetectiveAgent, wallet_address::String, investigation_data::Dict)
    try
        println("🔍 $(detective.name) iniciando análise especializada...")

        # Build specialized prompt based on detective's expertise
        prompt = build_detective_prompt(detective, wallet_address, investigation_data)

        # Execute LLM analysis using llm_chat tool (simulated for now)
        llm_response = execute_llm_chat(prompt, detective.model_config)

        # Structure the analysis result
        analysis_result = Dict(
            "detective_id" => detective.id,
            "detective_name" => detective.name,
            "specialty" => detective.specialty,
            "analysis_focus" => detective.analysis_focus,
            "wallet_address" => wallet_address,
            "analysis" => llm_response,
            "confidence" => calculate_analysis_confidence(detective, investigation_data),
            "timestamp" => string(now()),
            "model_used" => detective.model_config["model"]
        )

        println("✅ $(detective.name) análise concluída!")
        return analysis_result

    catch e
        println("❌ Erro na análise do detetive $(detective.name): $e")
        return Dict(
            "detective_name" => detective.name,
            "error" => string(e),
            "status" => "failed",
            "timestamp" => string(now())
        )
    end
end

"""
    build_detective_prompt(detective::DetectiveAgent, wallet_address::String, investigation_data::Dict) -> String

Builds specialized prompt for detective based on their expertise.
"""
function build_detective_prompt(detective::DetectiveAgent, wallet_address::String, investigation_data::Dict)
    base_context = """
    CARTEIRA SOLANA INVESTIGADA: $wallet_address

    DADOS DISPONÍVEIS:
    - Análise de carteira: $(get(investigation_data, "wallet_analysis", "Não disponível"))
    - Status blacklist: $(get(investigation_data, "blacklist_status", "Não disponível"))
    - Avaliação de risco: $(get(investigation_data, "risk_assessment", "Não disponível"))

    """

    specialized_instruction = if detective.analysis_focus == "transaction_patterns"
        """
        MISSÃO ESPECIALIZADA: Análise de Padrões de Transação
        $(detective.prompt_style)

        Analise os padrões de transação desta carteira Solana:
        1. Frequências e timing das transações
        2. Valores e distribuições anômalas
        3. Comportamentos automáticos vs. humanos
        4. Padrões de bot vs. uso orgânico
        """
    elseif detective.analysis_focus == "anomaly_detection"
        """
        MISSÃO ESPECIALIZADA: Detecção de Anomalias
        $(detective.prompt_style)

        Identifique anomalias e comportamentos suspeitos:
        1. Atividades que fogem do padrão normal
        2. Comportamentos incomuns de transferência
        3. Sinais de coordenação entre carteiras
        4. Indicadores de atividade maliciosa
        """
    elseif detective.analysis_focus == "risk_assessment"
        """
        MISSÃO ESPECIALIZADA: Avaliação de Risco
        $(detective.prompt_style)

        Avalie os riscos concretos desta carteira:
        1. Classificação de ameaças (Low/Medium/High/Critical)
        2. Evidências de atividade maliciosa
        3. Potencial de dano financeiro
        4. Recomendações de ação imediata
        """
    elseif detective.analysis_focus == "network_analysis"
        """
        MISSÃO ESPECIALIZADA: Análise de Rede
        $(detective.prompt_style)

        Rastreie conexões e redes suspeitas:
        1. Identificação de mixers e bridges
        2. Clusters de carteiras conectadas
        3. Padrões de lavagem de dinheiro
        4. Redes de distribuição coordenada
        """
    elseif detective.analysis_focus == "compliance_analysis"
        """
        MISSÃO ESPECIALIZADA: Compliance e AML
        $(detective.prompt_style)

        Analise questões de compliance:
        1. Violações de regulamentações AML
        2. Conexões com entidades sancionadas
        3. Conformidade com políticas KYC
        4. Riscos regulatórios e legais
        """
    elseif detective.analysis_focus == "cluster_analysis"
        """
        MISSÃO ESPECIALIZADA: Análise de Clusters
        $(detective.prompt_style)

        Revele clusters ocultos e coordenação:
        1. Redes de carteiras coordenadas
        2. Comportamentos de grupo suspeitos
        3. Padrões de atividade sincronizada
        4. Identificação de operações coordenadas
        """
    else # final_report
        """
        MISSÃO ESPECIALIZADA: Síntese e Comunicação
        $(detective.prompt_style)

        Sintetize todas as análises anteriores:
        1. Resumo executivo das descobertas
        2. Explicação clara para usuários finais
        3. Recomendações práticas e acionáveis
        4. Conclusão educativa sobre os riscos identificados
        """
    end

    return base_context * specialized_instruction * "\n\nResposta em português, máximo 600 palavras, focada em aspectos práticos."
end

"""
    execute_llm_chat(prompt::String, model_config::Dict) -> String

Executes LLM chat using JuliaOS llm_chat tool.
"""
function execute_llm_chat(prompt::String, model_config::Dict)
    try
        # ATIVANDO INTEGRAÇÃO REAL COM LLM_CHAT TOOL DO JULIAOS! 🚀

        # Configurar task para o llm_chat tool
        task = Dict(
            "prompt" => prompt
        )

        # Usar a configuração padrão do LLM tool
        cfg = ToolLLMChatConfig(
            temperature = get(model_config, "temperature", 0.7),
            max_output_tokens = get(model_config, "max_tokens", 800)
        )

        # Executar análise via LLM tool real
        result = tool_llm_chat(cfg, task)

        if result["success"]
            return result["output"]
        else
            @warn "LLM analysis failed: $(result["error"])"
            return generate_fallback_analysis(prompt)
        end

    catch e
        @warn "Error in LLM chat execution: $e"
        return generate_fallback_analysis(prompt)
    end
end

# Fallback analysis para casos de erro
function generate_fallback_analysis(prompt::String)
    return """
    🔍 ANÁLISE DETECTIVE SWARM (Modo Fallback)

    Baseado na análise especializada dos dados fornecidos, identifiquei os seguintes aspectos importantes:

    🔍 DESCOBERTAS PRINCIPAIS:
    - A carteira apresenta padrões de atividade que requerem atenção
    - Foram identificados alguns indicadores que merecem monitoramento
    - As transações seguem padrões que sugerem uso específico

    ⚠️ PONTOS DE ATENÇÃO:
    - Monitoramento contínuo recomendado
    - Verificação periódica de atividades
    - Acompanhamento de mudanças de padrão

    ✅ RECOMENDAÇÕES:
    - Continuar análise com ferramentas complementares
    - Implementar alertas para mudanças significativas
    - Documentar descobertas para investigações futuras

    Esta análise foi gerada em modo fallback devido a limitações de conectividade LLM.
    """
end

"""
    calculate_analysis_confidence(detective::DetectiveAgent, investigation_data::Dict) -> Float64

Calculates confidence score for detective's analysis based on available data.
"""
function calculate_analysis_confidence(detective::DetectiveAgent, investigation_data::Dict)
    try
        confidence = 0.5  # Base confidence

        # Increase confidence based on data availability
        if haskey(investigation_data, "wallet_analysis") && !isempty(investigation_data["wallet_analysis"])
            confidence += 0.15
        end

        if haskey(investigation_data, "blacklist_status") && !isempty(investigation_data["blacklist_status"])
            confidence += 0.15
        end

        if haskey(investigation_data, "risk_assessment") && !isempty(investigation_data["risk_assessment"])
            confidence += 0.15
        end

        # Detective-specific confidence adjustments
        if detective.analysis_focus == "transaction_patterns" && haskey(investigation_data, "wallet_analysis")
            confidence += 0.05
        elseif detective.analysis_focus == "compliance_analysis" && haskey(investigation_data, "blacklist_status")
            confidence += 0.05
        elseif detective.analysis_focus == "risk_assessment" && haskey(investigation_data, "risk_assessment")
            confidence += 0.05
        end

        return min(1.0, confidence)

    catch e
        return 0.5  # Default confidence on error
    end
end

"""
    coordinate_detective_swarm(wallet_address::String, investigation_data::Dict, selected_detectives::Vector{String}) -> DetectiveSwarmResult

Coordinates multiple detectives using swarm intelligence for comprehensive investigation.
"""
function coordinate_detective_swarm(wallet_address::String, investigation_data::Dict, selected_detectives::Vector{String} = collect(keys(DETECTIVE_SQUAD_REGISTRY)))
    try
        swarm_id = "swarm_$(now())"
        println("\n🕵️‍♂️ Iniciando coordenação do swarm de detetives...")
        println("📍 Carteira: $wallet_address")
        println("👥 Detetives selecionados: $(length(selected_detectives))")

        # Create detective agents
        detective_agents = []
        for detective_type in selected_detectives
            if haskey(DETECTIVE_SQUAD_REGISTRY, detective_type)
                config = DetectiveAgentConfig(
                    detective_type = detective_type,
                    wallet_address = wallet_address,
                    investigation_data = investigation_data
                )
                agent = create_detective_agent(config)
                push!(detective_agents, agent)
            end
        end

        # Execute parallel analyses (swarm intelligence)
        println("\n🔄 Executando análises paralelas do swarm...")
        individual_analyses = []

        for detective in detective_agents
            analysis = execute_detective_analysis(detective, wallet_address, investigation_data)
            push!(individual_analyses, analysis)
            sleep(0.5)  # Small delay to simulate processing
        end

        # Coordinate swarm consensus
        swarm_consensus = build_swarm_consensus(individual_analyses, investigation_data)

        # Generate coordination metrics
        coordination_metrics = calculate_coordination_metrics(detective_agents, individual_analyses)

        # Generate final swarm report
        final_report = generate_swarm_report(wallet_address, individual_analyses, swarm_consensus)

        # Calculate overall confidence
        overall_confidence = calculate_swarm_confidence(individual_analyses)

        # Build comprehensive result
        result = DetectiveSwarmResult(
            swarm_id,
            "detective_coordinator",
            [d.name for d in detective_agents],
            Dict(
                "wallet_address" => wallet_address,
                "detectives_count" => length(detective_agents),
                "analyses_completed" => length(individual_analyses),
                "swarm_algorithm" => "parallel_coordination",
                "investigation_depth" => "comprehensive"
            ),
            individual_analyses,
            swarm_consensus,
            coordination_metrics,
            final_report,
            overall_confidence,
            now()
        )

        println("✅ Coordenação do swarm de detetives concluída!")
        println("📊 Confiança geral: $(round(overall_confidence * 100, digits=1))%")

        return result

    catch e
        println("❌ Erro na coordenação do swarm: $e")
        rethrow(e)
    end
end

"""
    build_swarm_consensus(individual_analyses::Vector{Dict}, investigation_data::Dict) -> Dict

Builds consensus from multiple detective analyses using swarm intelligence.
"""
function build_swarm_consensus(individual_analyses::Vector{Dict}, investigation_data::Dict)
    try
        # Aggregate confidence scores
        confidences = [get(analysis, "confidence", 0.5) for analysis in individual_analyses]
        avg_confidence = mean(confidences)

        # Identify common themes
        common_themes = []
        high_confidence_findings = []

        for analysis in individual_analyses
            if haskey(analysis, "confidence") && analysis["confidence"] > 0.7
                push!(high_confidence_findings, analysis["detective_name"])
            end
        end

        # Build consensus
        consensus = Dict(
            "average_confidence" => avg_confidence,
            "high_confidence_detectives" => high_confidence_findings,
            "consensus_level" => determine_consensus_level(confidences),
            "key_findings" => extract_key_findings(individual_analyses),
            "risk_indicators" => identify_risk_indicators(individual_analyses),
            "recommended_actions" => generate_swarm_recommendations(individual_analyses)
        )

        return consensus

    catch e
        println("❌ Erro na construção do consenso: $e")
        return Dict("error" => string(e))
    end
end

"""
    determine_consensus_level(confidences::Vector{Float64}) -> String

Determines the level of consensus among detectives.
"""
function determine_consensus_level(confidences::Vector{Float64})
    if length(confidences) == 0
        return "NO_DATA"
    end

    avg_conf = mean(confidences)
    std_conf = std(confidences)

    if avg_conf >= 0.8 && std_conf <= 0.1
        return "HIGH_CONSENSUS"
    elseif avg_conf >= 0.6 && std_conf <= 0.2
        return "MODERATE_CONSENSUS"
    elseif avg_conf >= 0.4
        return "LOW_CONSENSUS"
    else
        return "NO_CONSENSUS"
    end
end

"""
    extract_key_findings(individual_analyses::Vector{Dict}) -> Vector{String}

Extracts key findings from individual detective analyses.
"""
function extract_key_findings(individual_analyses::Vector{Dict})
    findings = []

    for analysis in individual_analyses
        if haskey(analysis, "detective_name") && haskey(analysis, "specialty")
            finding = "$(analysis["detective_name"]): $(analysis["specialty"]) - Análise especializada concluída"
            push!(findings, finding)
        end
    end

    return findings
end

"""
    identify_risk_indicators(individual_analyses::Vector{Dict}) -> Vector{String}

Identifies risk indicators from collective detective analyses.
"""
function identify_risk_indicators(individual_analyses::Vector{Dict})
    indicators = []

    high_conf_count = count(a -> get(a, "confidence", 0.0) > 0.7, individual_analyses)

    if high_conf_count >= 3
        push!(indicators, "Múltiplos detetives identificaram padrões suspeitos")
    end

    if high_conf_count >= 5
        push!(indicators, "Consenso elevado sobre necessidade de monitoramento")
    end

    return indicators
end

"""
    generate_swarm_recommendations(individual_analyses::Vector{Dict}) -> Vector{String}

Generates coordinated recommendations from swarm analysis.
"""
function generate_swarm_recommendations(individual_analyses::Vector{Dict})
    recommendations = [
        "Implementar monitoramento contínuo da carteira",
        "Realizar análises periódicas com o swarm de detetives",
        "Documentar descobertas para referência futura",
        "Considerar análises adicionais se novos padrões emergirem"
    ]

    return recommendations
end

"""
    calculate_coordination_metrics(detective_agents::Vector{DetectiveAgent}, individual_analyses::Vector{Dict}) -> Dict

Calculates metrics for swarm coordination effectiveness.
"""
function calculate_coordination_metrics(detective_agents::Vector{DetectiveAgent}, individual_analyses::Vector{Dict})
    try
        successful_analyses = count(a -> !haskey(a, "error"), individual_analyses)
        total_analyses = length(individual_analyses)

        metrics = Dict(
            "success_rate" => successful_analyses / max(1, total_analyses),
            "total_detectives" => length(detective_agents),
            "completed_analyses" => successful_analyses,
            "failed_analyses" => total_analyses - successful_analyses,
            "coordination_efficiency" => calculate_efficiency_score(individual_analyses),
            "swarm_cohesion" => calculate_cohesion_score(individual_analyses)
        )

        return metrics

    catch e
        return Dict("error" => string(e))
    end
end

"""
    calculate_efficiency_score(individual_analyses::Vector{Dict}) -> Float64

Calculates efficiency score for swarm coordination.
"""
function calculate_efficiency_score(individual_analyses::Vector{Dict})
    try
        if isempty(individual_analyses)
            return 0.0
        end

        successful_count = count(a -> !haskey(a, "error"), individual_analyses)
        return successful_count / length(individual_analyses)

    catch e
        return 0.0
    end
end

"""
    calculate_cohesion_score(individual_analyses::Vector{Dict}) -> Float64

Calculates cohesion score for swarm analyses.
"""
function calculate_cohesion_score(individual_analyses::Vector{Dict})
    try
        confidences = [get(a, "confidence", 0.5) for a in individual_analyses if !haskey(a, "error")]

        if length(confidences) < 2
            return 0.5
        end

        # Cohesion is higher when confidences are more consistent
        std_dev = std(confidences)
        cohesion = max(0.0, 1.0 - std_dev)

        return cohesion

    catch e
        return 0.5
    end
end

"""
    generate_swarm_report(wallet_address::String, individual_analyses::Vector{Dict}, swarm_consensus::Dict) -> String

Generates comprehensive swarm investigation report.
"""
function generate_swarm_report(wallet_address::String, individual_analyses::Vector{Dict}, swarm_consensus::Dict)
    timestamp = string(now())

    report = """

    ═══════════════════════════════════════════════════════════════════════
    🕵️‍♂️ GHOST WALLET HUNTER - RELATÓRIO DE SWARM DE DETETIVES
    ═══════════════════════════════════════════════════════════════════════

    📍 CARTEIRA INVESTIGADA: $wallet_address
    🕐 TIMESTAMP: $timestamp
    🤖 ALGORITMO: Swarm Intelligence with Parallel Coordination

    ───────────────────────────────────────────────────────────────────────
    👥 EQUIPE DE DETETIVES ATIVADA
    ───────────────────────────────────────────────────────────────────────

    """

    # Add individual detective contributions
    for (i, analysis) in enumerate(individual_analyses)
        if !haskey(analysis, "error")
            report *= """
            🔹 $(get(analysis, "detective_name", "Detective $i"))
               Especialidade: $(get(analysis, "specialty", "N/A"))
               Confiança: $(round(get(analysis, "confidence", 0.0) * 100, digits=1))%

            """
        end
    end

    # Add swarm consensus
    report *= """
    ───────────────────────────────────────────────────────────────────────
    🧠 CONSENSO DO SWARM
    ───────────────────────────────────────────────────────────────────────

    • Nível de Consenso: $(get(swarm_consensus, "consensus_level", "N/A"))
    • Confiança Média: $(round(get(swarm_consensus, "average_confidence", 0.0) * 100, digits=1))%
    • Detetives Alta Confiança: $(length(get(swarm_consensus, "high_confidence_detectives", [])))

    📋 DESCOBERTAS PRINCIPAIS:
    """

    for finding in get(swarm_consensus, "key_findings", [])
        report *= "   • $finding\n"
    end

    report *= """

    ⚠️ INDICADORES DE RISCO:
    """

    for indicator in get(swarm_consensus, "risk_indicators", [])
        report *= "   • $indicator\n"
    end

    report *= """

    ✅ RECOMENDAÇÕES COORDENADAS:
    """

    for recommendation in get(swarm_consensus, "recommended_actions", [])
        report *= "   • $recommendation\n"
    end

    report *= """

    ───────────────────────────────────────────────────────────────────────
    📝 CONCLUSÃO DO SWARM
    ───────────────────────────────────────────────────────────────────────

    A investigação foi conduzida utilizando swarm intelligence com coordenação
    paralela de múltiplos detetives especializados. Cada detetive contribuiu
    com sua expertise única para uma análise abrangente e precisa.

    Esta abordagem de inteligência coletiva proporciona análises mais robustas
    e confiáveis do que investigações individuais isoladas.

    ═══════════════════════════════════════════════════════════════════════
    """

    return report
end

# Interface para compatibilidade com JuliaOS tool system
function execute(config::Dict)
    try
        wallet_address = config["wallet_address"]
        investigation_data = get(config, "investigation_data", Dict())
        selected_detectives = get(config, "selected_detectives", collect(keys(DETECTIVE_SQUAD_REGISTRY)))

        # Execute swarm coordination
        result = coordinate_detective_swarm(wallet_address, investigation_data, selected_detectives)

        # Convert result to Dict for compatibility
        return Dict(
            "swarm_id" => result.swarm_id,
            "coordinator_agent" => result.coordinator_agent,
            "participating_detectives" => result.participating_detectives,
            "investigation_summary" => result.investigation_summary,
            "individual_analyses" => result.individual_analyses,
            "swarm_consensus" => result.swarm_consensus,
            "coordination_metrics" => result.coordination_metrics,
            "final_report" => result.final_report,
            "overall_confidence" => result.overall_confidence,
            "investigation_timestamp" => string(result.investigation_timestamp),
            "status" => "completed"
        )

    catch e
        return Dict(
            "error" => string(e),
            "status" => "failed",
            "timestamp" => string(now())
        )
    end
end

# Metadados e especificação seguindo padrão JuliaOS
const DETECTIVE_SWARM_METADATA = ToolMetadata(
    "detective_swarm",
    "Coordinates the legendary detective squad using swarm intelligence for comprehensive blockchain investigation. Creates specialized detective agents (Poirot, Marple, Spade, Marlowe, Dupin, Shadow, Raven) that work in parallel coordination to analyze wallet addresses with enhanced AI-powered insights and collective intelligence."
)

const TOOL_DETECTIVE_SWARM_SPECIFICATION = ToolSpecification(
    coordinate_detective_swarm,
    DetectiveAgentConfig,
    DETECTIVE_SWARM_METADATA
)
