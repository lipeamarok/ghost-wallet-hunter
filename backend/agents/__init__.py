"""
Ghost Wallet Hunter - Legendary Detective Squad Agents

This package contains the legendary detective squad powered by real AI.
Each detective demonstrates autonomous decision-making using real OpenAI/Grok APIs.
"""

# Import the legendary detective squad
from .detective_squad import DetectiveSquadManager
from .poirot_agent import PoirotAgent
from .marple_agent import MarpleAgent
from .spade_agent import SpadeAgent
from .marlowe_agent import MarloweAgent
from .dupin_agent import DupinAgent
from .shadow_agent import ShadowAgent
from .raven_agent import RavenAgent
from .shared_models import RiskLevel, WalletCluster, AnalysisResult

# Export all legendary agents
__all__ = [
    "DetectiveSquadManager",
    "PoirotAgent",
    "MarpleAgent",
    "SpadeAgent",
    "MarloweAgent",
    "DupinAgent",
    "ShadowAgent",
    "RavenAgent",
    "RiskLevel",
    "WalletCluster",
    "AnalysisResult"
]

# Legendary Detective Squad Registry
AVAILABLE_AGENTS = {
    "detective_squad": DetectiveSquadManager,
    "poirot": PoirotAgent,
    "marple": MarpleAgent,
    "spade": SpadeAgent,
    "marlowe": MarloweAgent,
    "dupin": DupinAgent,
    "shadow": ShadowAgent,
    "raven": RavenAgent
}

# Legendary Detective Capabilities
AGENT_CAPABILITIES = {
    "DetectiveSquadManager": [
        "legendary_squad_coordination",
        "multi_detective_consensus",
        "comprehensive_investigation",
        "real_ai_powered_analysis"
    ],
    "PoirotAgent": [
        "methodical_transaction_analysis",
        "behavioral_pattern_detection",
        "psychological_profiling",
        "evidence_chain_building"
    ],
    "MarpleAgent": [
        "pattern_recognition",
        "anomaly_detection",
        "village_wisdom_analysis",
        "wash_trading_detection"
    ],
    "SpadeAgent": [
        "risk_assessment",
        "threat_classification",
        "direct_evaluation",
        "action_recommendations"
    ],
    "MarloweAgent": [
        "bridge_tracking",
        "mixer_detection",
        "cross_chain_analysis",
        "obfuscation_pattern_tracing"
    ],
    "DupinAgent": [
        "compliance_analysis",
        "aml_screening",
        "sanctions_checking",
        "regulatory_assessment"
    ],
    "ShadowAgent": [
        "network_cluster_analysis",
        "hidden_relationship_mapping",
        "criminal_organization_detection",
        "coordination_pattern_analysis"
    ],
    "RavenAgent": [
        "explanation_synthesis",
        "clear_communication",
        "multi_audience_adaptation",
        "truth_distillation"
    ]
}

def get_agent_by_name(agent_name: str):
    """Get legendary detective agent class by name."""
    return AVAILABLE_AGENTS.get(agent_name)

def list_available_agents():
    """List all available legendary detectives and their capabilities."""
    return {
        name: {
            "class": agent_class.__name__,
            "capabilities": AGENT_CAPABILITIES.get(agent_class.__name__, [])
        }
        for name, agent_class in AVAILABLE_AGENTS.items()
    }
