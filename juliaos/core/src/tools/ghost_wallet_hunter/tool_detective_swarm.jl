"""
    DetectiveAgent

JuliaOS agent specialized in wallet investigation.
Each detective has a unique specialty and works together via swarm intelligence.
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
        prompt_style = "My dear friend, as the renowned detective Hercule Poirot, I analyze each transaction with methodological precision. I observe patterns, frequencies, values, and timing of transactions to reveal suspicious behaviors through my little grey cells."
    ),
    "marple" => DetectiveAgent(
        id = "detective_marple_002",
        name = "Miss Jane Marple",
        specialty = "Pattern & Anomaly Detection",
        analysis_focus = "anomaly_detection",
        prompt_style = "As Miss Jane Marple, I have a special intuition for detecting anomalies and unusual patterns. I analyze behaviors that deviate from the norm, identifying suspicious activities through my experience with human nature."
    ),
    "spade" => DetectiveAgent(
        id = "detective_spade_003",
        name = "Sam Spade",
        specialty = "Risk Assessment & Threat Classification",
        analysis_focus = "risk_assessment",
        prompt_style = "As Sam Spade, I am direct and pragmatic in risk assessment. I classify threats clearly and objectively, focusing on concrete evidence and real danger levels, no beating around the bush."
    ),
    "marlowe" => DetectiveAgent(
        id = "detective_marlowe_004",
        name = "Philip Marlowe",
        specialty = "Bridge & Mixer Tracking",
        analysis_focus = "network_analysis",
        prompt_style = "As Philip Marlowe, I track obscure connections and complex networks. I specialize in identifying mixers, bridges, and connections between wallets that try to hide traces in the underworld of cryptocurrencies."
    ),
    "dupin" => DetectiveAgent(
        id = "detective_dupin_005",
        name = "Auguste Dupin",
        specialty = "Compliance & AML Analysis",
        analysis_focus = "compliance_analysis",
        prompt_style = "As Auguste Dupin, I apply logical and deductive analysis to compliance issues. I check for AML violations, sanctions, and regulatory compliance with precise and methodical analytical reasoning."
    ),
    "shadow" => DetectiveAgent(
        id = "detective_shadow_006",
        name = "The Shadow",
        specialty = "Network Cluster Analysis",
        analysis_focus = "cluster_analysis",
        prompt_style = "As The Shadow, I see what others cannot. I analyze hidden clusters, networks of connected wallets, and coordinated behavior patterns that remain in the shadows of the blockchain."
    ),
    "raven" => DetectiveAgent(
        id = "detective_raven_007",
        name = "Raven",
        specialty = "LLM Explanation & Communication",
        analysis_focus = "final_report",
        prompt_style = "As Raven, I turn complex technical analyses into clear and understandable explanations. I synthesize all findings into a final, educational, and actionable report for end users."
    )
)

# ... (rest of the code remains unchanged except for prompt/instruction strings below)

function build_detective_prompt(detective::DetectiveAgent, wallet_address::String, investigation_data::Dict)
    base_context = """
    INVESTIGATED SOLANA WALLET: $wallet_address

    AVAILABLE DATA:
    - Wallet analysis: $(get(investigation_data, "wallet_analysis", "Not available"))
    - Blacklist status: $(get(investigation_data, "blacklist_status", "Not available"))
    - Risk assessment: $(get(investigation_data, "risk_assessment", "Not available"))

    """

    specialized_instruction = if detective.analysis_focus == "transaction_patterns"
        """
        SPECIALIZED MISSION: Transaction Pattern Analysis
        $(detective.prompt_style)

        Analyze the transaction patterns of this Solana wallet:
        1. Transaction frequencies and timing
        2. Anomalous values and distributions
        3. Automated vs. human behaviors
        4. Bot patterns vs. organic use
        """
    elseif detective.analysis_focus == "anomaly_detection"
        """
        SPECIALIZED MISSION: Anomaly Detection
        $(detective.prompt_style)

        Identify anomalies and suspicious behaviors:
        1. Activities that deviate from normal patterns
        2. Unusual transfer behaviors
        3. Signs of coordination between wallets
        4. Indicators of malicious activity
        """
    elseif detective.analysis_focus == "risk_assessment"
        """
        SPECIALIZED MISSION: Risk Assessment
        $(detective.prompt_style)

        Assess the concrete risks of this wallet:
        1. Threat classification (Low/Medium/High/Critical)
        2. Evidence of malicious activity
        3. Potential for financial damage
        4. Recommendations for immediate action
        """
    elseif detective.analysis_focus == "network_analysis"
        """
        SPECIALIZED MISSION: Network Analysis
        $(detective.prompt_style)

        Track suspicious connections and networks:
        1. Identification of mixers and bridges
        2. Clusters of connected wallets
        3. Money laundering patterns
        4. Coordinated distribution networks
        """
    elseif detective.analysis_focus == "compliance_analysis"
        """
        SPECIALIZED MISSION: Compliance and AML
        $(detective.prompt_style)

        Analyze compliance issues:
        1. AML regulation violations
        2. Connections with sanctioned entities
        3. Compliance with KYC policies
        4. Regulatory and legal risks
        """
    elseif detective.analysis_focus == "cluster_analysis"
        """
        SPECIALIZED MISSION: Cluster Analysis
        $(detective.prompt_style)

        Reveal hidden clusters and coordination:
        1. Networks of coordinated wallets
        2. Suspicious group behaviors
        3. Synchronized activity patterns
        4. Identification of coordinated operations
        """
    else # final_report
        """
        SPECIALIZED MISSION: Synthesis and Communication
        $(detective.prompt_style)

        Synthesize all previous analyses:
        1. Executive summary of findings
        2. Clear explanation for end users
        3. Practical and actionable recommendations
        4. Educational conclusion about identified risks
        """
    end

    return base_context * specialized_instruction * "\n\nRespond in English, maximum 600 words, focused on practical aspects."
end

# Fallback analysis for error cases
function generate_fallback_analysis(prompt::String)
    return """
    🔍 DETECTIVE SWARM ANALYSIS (Fallback Mode)

    Based on the specialized analysis of the provided data, I have identified the following important aspects:

    🔍 MAIN FINDINGS:
    - The wallet shows activity patterns that require attention
    - Some indicators were identified that deserve monitoring
    - Transactions follow patterns suggesting specific usage

    ⚠️ POINTS OF ATTENTION:
    - Continuous monitoring recommended
    - Periodic activity checks
    - Track changes in patterns

    ✅ RECOMMENDATIONS:
    - Continue analysis with complementary tools
    - Implement alerts for significant changes
    - Document findings for future investigations

    This analysis was generated in fallback mode due to LLM connectivity limitations.
    """
end

# In generate_swarm_report, translate headings and comments to English

function generate_swarm_report(wallet_address::String, individual_analyses::Vector{Dict}, swarm_consensus::Dict)
    timestamp = string(now())

    report = """

    ═══════════════════════════════════════════════════════════════════════
    🕵️‍♂️ GHOST WALLET HUNTER - DETECTIVE SWARM REPORT
    ═══════════════════════════════════════════════════════════════════════

    📍 INVESTIGATED WALLET: $wallet_address
    🕐 TIMESTAMP: $timestamp
    🤖 ALGORITHM: Swarm Intelligence with Parallel Coordination

    ───────────────────────────────────────────────────────────────────────
    👥 ACTIVATED DETECTIVE TEAM
    ───────────────────────────────────────────────────────────────────────

    """

    # Add individual detective contributions
    for (i, analysis) in enumerate(individual_analyses)
        if !haskey(analysis, "error")
            report *= """
            🔹 $(get(analysis, "detective_name", "Detective $i"))
               Specialty: $(get(analysis, "specialty", "N/A"))
               Confidence: $(round(get(analysis, "confidence", 0.0) * 100, digits=1))%

            """
        end
    end

    # Add swarm consensus
    report *= """
    ───────────────────────────────────────────────────────────────────────
    🧠 SWARM CONSENSUS
    ───────────────────────────────────────────────────────────────────────

    • Consensus Level: $(get(swarm_consensus, "consensus_level", "N/A"))
    • Average Confidence: $(round(get(swarm_consensus, "average_confidence", 0.0) * 100, digits=1))%
    • High Confidence Detectives: $(length(get(swarm_consensus, "high_confidence_detectives", [])))

    📋 MAIN FINDINGS:
    """

    for finding in get(swarm_consensus, "key_findings", [])
        report *= "   • $finding\n"
    end

    report *= """

    ⚠️ RISK INDICATORS:
    """

    for indicator in get(swarm_consensus, "risk_indicators", [])
        report *= "   • $indicator\n"
    end

    report *= """

    ✅ COORDINATED RECOMMENDATIONS:
    """

    for recommendation in get(swarm_consensus, "recommended_actions", [])
        report *= "   • $recommendation\n"
    end

    report *= """

    ───────────────────────────────────────────────────────────────────────
    📝 SWARM CONCLUSION
    ───────────────────────────────────────────────────────────────────────

    The investigation was conducted using swarm intelligence with parallel
    coordination of multiple specialized detectives. Each detective contributed
    their unique expertise for a comprehensive and accurate analysis.

    This collective intelligence approach provides more robust and reliable
    analyses than isolated individual investigations.

    ═══════════════════════════════════════════════════════════════════════
    """

    return report
end

# Also update any error messages or comments that are user-facing to English as needed.
