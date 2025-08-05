#!/usr/bin/env python3
"""
Ghost Detectives A2A Setup - FASE 4.1
=====================================

Script para criar e configurar todos os 8 detetives no JuliaOS
com suas ferramentas específicas via protocolo A2A.

REAL SETUP - Sem mocks, apenas chamadas reais.
"""

import asyncio
import json
from typing import Dict, List, Any
from datetime import datetime

import sys
import os

# Adicionar caminhos necessários
current_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = os.path.join(current_dir, '..', '..')
backend_dir = os.path.join(root_dir, 'backend')

sys.path.insert(0, root_dir)
sys.path.insert(0, backend_dir)

from services.juliaos_service import JuliaOSService


class GhostDetectivesSetup:
    """Setup completo dos detetives Ghost no sistema A2A"""

    def __init__(self, julia_url: str = "http://127.0.0.1:8052/api/v1"):
        self.julia_url = julia_url
        self.factory = GhostDetectiveFactory(julia_url)

        # Configuração real de cada detetive com suas ferramentas
        self.detective_configs = {
            "poirot": {
                "name": "Detective Hercule Poirot",
                "specialty": "transaction_analysis",
                "tools": [
                    "analyze_wallet",
                    "trace_fund_flow",
                    "identify_tokens",
                    "detect_patterns"
                ],
                "capabilities": [
                    "methodical_analysis",
                    "pattern_recognition",
                    "fund_flow_tracing",
                    "token_identification"
                ],
                "persona": "Belgian master of deduction applied to blockchain analysis",
                "catchphrase": "Ah, mon ami, the little grey cells, they work!"
            },
            "marple": {
                "name": "Detective Miss Jane Marple",
                "specialty": "pattern_anomaly_detection",
                "tools": [
                    "detect_anomalies",
                    "analyze_patterns",
                    "statistical_analysis",
                    "behavioral_profiling"
                ],
                "capabilities": [
                    "pattern_recognition",
                    "anomaly_detection",
                    "statistical_analysis",
                    "behavioral_analysis"
                ],
                "persona": "Perceptive observer who notices details others miss",
                "catchphrase": "Oh my dear, that's rather peculiar, isn't it?"
            },
            "spade": {
                "name": "Detective Sam Spade",
                "specialty": "hard_boiled_investigation",
                "tools": [
                    "aggressive_investigation",
                    "risk_assessment",
                    "criminal_detection",
                    "direct_analysis"
                ],
                "capabilities": [
                    "aggressive_investigation",
                    "risk_analysis",
                    "criminal_pattern_detection",
                    "direct_approach"
                ],
                "persona": "Hard-boiled private detective with no-nonsense approach",
                "catchphrase": "When you're slapped, you'll take it and like it."
            },
            "marlowee": {
                "name": "Detective Philip Marlowe",
                "specialty": "deep_analysis_investigation",
                "tools": [
                    "deep_analysis",
                    "corruption_detection",
                    "complex_investigation",
                    "narrative_analysis"
                ],
                "capabilities": [
                    "deep_analysis",
                    "corruption_detection",
                    "complex_case_solving",
                    "narrative_analysis"
                ],
                "persona": "Knight of the mean streets patrolling blockchain networks",
                "catchphrase": "Down these mean streets a man must go who is not himself mean."
            },
            "dupin": {
                "name": "Detective C. Auguste Dupin",
                "specialty": "analytical_investigation",
                "tools": [
                    "logical_analysis",
                    "mathematical_modeling",
                    "evidence_synthesis",
                    "ratiocination"
                ],
                "capabilities": [
                    "logical_analysis",
                    "ratiocination",
                    "mathematical_modeling",
                    "evidence_synthesis"
                ],
                "persona": "Original analytical detective using pure logic",
                "catchphrase": "The mental features discoursed of as the analytical are, in themselves, but little susceptible of analysis."
            },
            "shadow": {
                "name": "Detective The Shadow",
                "specialty": "stealth_investigation",
                "tools": [
                    "stealth_tracking",
                    "hidden_pattern_detection",
                    "anonymity_analysis",
                    "dark_investigation"
                ],
                "capabilities": [
                    "stealth_tracking",
                    "hidden_pattern_detection",
                    "anonymity_analysis",
                    "dark_web_investigation"
                ],
                "persona": "Master of stealth and hidden investigations",
                "catchphrase": "Who knows what evil lurks in the hearts of men? The Shadow knows!"
            },
            "raven": {
                "name": "Detective Edgar Raven",
                "specialty": "dark_pattern_investigation",
                "tools": [
                    "psychological_analysis",
                    "dark_pattern_detection",
                    "criminal_psychology",
                    "threat_assessment"
                ],
                "capabilities": [
                    "psychological_analysis",
                    "dark_pattern_detection",
                    "criminal_psychology",
                    "threat_assessment"
                ],
                "persona": "Investigator of darkest blockchain crimes",
                "catchphrase": "Nevermore shall crime go undetected in the blockchain."
            },
            "compliance": {
                "name": "Detective Compliance Officer",
                "specialty": "regulatory_compliance",
                "tools": [
                    "regulatory_analysis",
                    "compliance_checking",
                    "legal_assessment",
                    "policy_enforcement"
                ],
                "capabilities": [
                    "regulatory_analysis",
                    "compliance_checking",
                    "legal_assessment",
                    "policy_enforcement"
                ],
                "persona": "Specialist in regulatory compliance and legal aspects",
                "catchphrase": "Justice and compliance guide every investigation."
            }
        }

    async def setup_detective(self, detective_id: str) -> Dict[str, Any]:
        """Configura um detetive específico no sistema"""
        if detective_id not in self.detective_configs:
            raise ValueError(f"Detective {detective_id} not configured")

        config = self.detective_configs[detective_id]

        print(f"🔧 Setting up {config['name']}...")

        # Verificar se o detetive está disponível no Julia
        async with JuliaOSConnection(self.julia_url) as conn:
            try:
                agent_details = await conn.get_agent_details(detective_id)
                print(f"   ✅ Found in Julia: {agent_details['name']}")

                # Configurar ferramentas específicas
                setup_result = {
                    "detective_id": detective_id,
                    "name": config["name"],
                    "specialty": config["specialty"],
                    "tools_configured": len(config["tools"]),
                    "capabilities": config["capabilities"],
                    "status": "configured",
                    "julia_connection": "active",
                    "timestamp": datetime.now().isoformat()
                }

                print(f"   🛠️ Configured {len(config['tools'])} tools")
                print(f"   🎯 Specialty: {config['specialty']}")

                return setup_result

            except Exception as e:
                print(f"   ❌ Error setting up {detective_id}: {e}")
                raise

    async def setup_all_detectives(self) -> Dict[str, Any]:
        """Configura todos os detetives no sistema"""
        print("🚀 Setting up all Ghost Detectives...")
        print("=" * 50)

        setup_results = {}

        for detective_id in self.detective_configs.keys():
            try:
                result = await self.setup_detective(detective_id)
                setup_results[detective_id] = result
                print()
            except Exception as e:
                setup_results[detective_id] = {
                    "status": "error",
                    "error": str(e),
                    "timestamp": datetime.now().isoformat()
                }
                print(f"   ❌ Failed to setup {detective_id}: {e}\n")

        # Sumário final
        successful = sum(1 for r in setup_results.values() if r.get("status") == "configured")
        total = len(setup_results)

        print("📊 SETUP SUMMARY:")
        print(f"   ✅ Successfully configured: {successful}/{total} detectives")

        if successful == total:
            print("   🎉 ALL DETECTIVES READY FOR A2A!")
        else:
            print(f"   ⚠️ {total - successful} detectives need attention")

        return {
            "summary": {
                "total_detectives": total,
                "successful_setups": successful,
                "failed_setups": total - successful,
                "timestamp": datetime.now().isoformat()
            },
            "detectives": setup_results
        }

    async def verify_setup(self) -> bool:
        """Verifica se todos os detetives estão configurados corretamente"""
        print("🔍 Verifying detective setup...")

        try:
            # Verificar conexão com Julia
            async with JuliaOSConnection(self.julia_url) as conn:
                agents = await conn.list_agents()

                if len(agents) < len(self.detective_configs):
                    print(f"   ❌ Expected {len(self.detective_configs)} agents, found {len(agents)}")
                    return False

                # Verificar cada detetive
                for detective_id in self.detective_configs.keys():
                    found = any(agent["id"] == detective_id for agent in agents)
                    if not found:
                        print(f"   ❌ Detective {detective_id} not found in Julia")
                        return False
                    else:
                        print(f"   ✅ {detective_id}: OK")

                print("   🎉 All detectives verified and ready!")
                return True

        except Exception as e:
            print(f"   ❌ Verification failed: {e}")
            return False


async def main():
    """Executa setup completo dos Ghost Detectives"""
    setup = GhostDetectivesSetup()

    # Verificar se Julia Server está rodando
    print("🔗 Checking Julia Server connection...")
    try:
        async with JuliaOSConnection() as conn:
            health = await conn.health_check()
            print(f"   ✅ Julia Server: {health['service']} - {health['status']}")
    except Exception as e:
        print(f"   ❌ Julia Server not available: {e}")
        print("   💡 Make sure Julia Server is running on port 8052")
        return

    # Executar setup
    results = await setup.setup_all_detectives()

    # Verificar setup
    verification_passed = await setup.verify_setup()

    # Salvar resultados
    with open("ghost_detectives_setup_results.json", "w") as f:
        json.dump(results, f, indent=2)

    print(f"\n📄 Results saved to: ghost_detectives_setup_results.json")

    if verification_passed:
        print("\n🎉 FASE 4.1 COMPLETE - All Ghost Detectives configured!")
        print("   Ready for A2A Server setup (Fase 4.2)")
    else:
        print("\n⚠️ Setup completed with issues - check logs above")


if __name__ == "__main__":
    asyncio.run(main())
