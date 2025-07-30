"""
Ghost Wallet Hunter - Compliance Utilities

Módulo utilitário centralizado para lógica de compliance, AML e sanções,
evitando duplicidade entre agentes.
"""

import asyncio
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import json

from services.smart_ai_service import get_ai_service

logger = logging.getLogger(__name__)


class ComplianceUtils:
    """
    Utilitários centralizados para compliance, AML e sanções.
    Evita duplicidade de lógica entre agentes.
    """

    def __init__(self):
        self.ai_service = get_ai_service()

        # Frameworks de compliance comuns
        self.aml_frameworks = [
            "FATF Recommendations", "EU AML Directives", "US Bank Secrecy Act",
            "UK Money Laundering Regulations", "MiCA Regulation", "Travel Rule"
        ]

        self.sanctions_lists = [
            "OFAC SDN List", "EU Consolidated List", "UN Security Council List",
            "HMT Sanctions List", "DFAT Sanctions", "SECO Sanctions"
        ]

        self.regulatory_frameworks = [
            "FATF_Crypto_Standards", "EU_MiCA", "US_FinCEN_Guidance"
        ]

    async def perform_aml_analysis(self, wallet_address: str, agent_id: str, agent_style: str = "neutral") -> Dict:
        """
        Análise AML centralizada que pode ser usada por diferentes agentes.

        Args:
            wallet_address: Endereço da wallet para análise
            agent_id: ID do agente que está fazendo a chamada
            agent_style: Estilo do agente ("analytical", "direct", "methodical", "neutral")
        """
        try:
            # Base prompt comum
            base_aml_analysis = {
                "layering_schemes": "Transaction patterns typical of layering schemes",
                "structuring": "Rapid movement of funds (structuring)",
                "suspicious_amounts": "Round number transactions (suspicious amounts)",
                "micro_transactions": "High-frequency micro-transactions",
                "risky_connections": "Connections to known risky addresses"
            }

            # Personalização por estilo do agente
            style_prompts = {
                "analytical": f"C. Auguste Dupin here, applying analytical reasoning to AML investigation of wallet {wallet_address}.",
                "direct": f"Listen here, partner. I need a straight AML assessment on wallet {wallet_address}.",
                "methodical": f"Hercule Poirot conducting methodical AML analysis of wallet {wallet_address}.",
                "neutral": f"Performing AML compliance analysis for wallet {wallet_address}."
            }

            aml_prompt = f"""
            {style_prompts.get(agent_style, style_prompts["neutral"])}

            Analyze for potential money laundering indicators:
            1. {base_aml_analysis["layering_schemes"]}
            2. {base_aml_analysis["structuring"]}
            3. {base_aml_analysis["suspicious_amounts"]}
            4. {base_aml_analysis["micro_transactions"]}
            5. {base_aml_analysis["risky_connections"]}

            Provide assessment with:
            - Risk level (LOW/MEDIUM/HIGH/CRITICAL)
            - Specific AML red flags identified
            - Confidence score (0-1)
            - Recommended actions

            Frameworks applied: {', '.join(self.aml_frameworks)}
            """

            aml_analysis = await self.ai_service.analyze_with_ai(
                prompt=aml_prompt,
                user_id=agent_id,
                context={
                    "analysis_type": "aml_screening",
                    "wallet": wallet_address,
                    "frameworks": self.aml_frameworks
                },
                analysis_type="compliance"
            )

            # Add common metadata
            aml_analysis["screening_date"] = datetime.now().isoformat()
            aml_analysis["frameworks_applied"] = self.aml_frameworks
            aml_analysis["screening_agent"] = agent_id

            return aml_analysis

        except Exception as e:
            logger.error(f"❌ AML analysis failed: {e}")
            return {"error": "AML analysis failed", "details": str(e)}

    async def perform_sanctions_screening(self, wallet_address: str, agent_id: str, agent_style: str = "neutral") -> Dict:
        """
        Screening de sanções centralizado.
        """
        try:
            style_prompts = {
                "analytical": f"Dupin conducting sanctions screening with methodical precision for wallet {wallet_address}.",
                "direct": f"Spade here. Need sanctions check on wallet {wallet_address} - any hits?",
                "methodical": f"Poirot performing systematic sanctions verification for wallet {wallet_address}.",
                "neutral": f"Conducting sanctions screening for wallet {wallet_address}."
            }

            sanctions_prompt = f"""
            {style_prompts.get(agent_style, style_prompts["neutral"])}

            Screen against global sanctions lists:
            1. OFAC SDN (Specially Designated Nationals) connections
            2. EU Consolidated List matches
            3. UN Security Council sanctions
            4. Country-based sanctions (Iran, North Korea, etc.)
            5. Sectoral sanctions in crypto/finance

            Decision criteria:
            - Direct hits = BLOCK immediately
            - Indirect connections = FLAG for review
            - Jurisdictional risks = MONITOR closely

            Screening lists: {', '.join(self.sanctions_lists)}
            """

            sanctions_analysis = await self.ai_service.analyze_with_ai(
                prompt=sanctions_prompt,
                user_id=agent_id,
                context={
                    "analysis_type": "sanctions_screening",
                    "wallet": wallet_address,
                    "sanctions_lists": self.sanctions_lists
                },
                analysis_type="compliance"
            )

            # Add common metadata
            sanctions_analysis["screening_lists"] = self.sanctions_lists
            sanctions_analysis["last_updated"] = datetime.now().isoformat()
            sanctions_analysis["screening_agent"] = agent_id

            return sanctions_analysis

        except Exception as e:
            logger.error(f"❌ Sanctions screening failed: {e}")
            return {"error": "Sanctions screening failed", "details": str(e)}

    async def perform_regulatory_assessment(self, wallet_address: str, agent_id: str, agent_style: str = "neutral") -> Dict:
        """
        Avaliação regulatória centralizada.
        """
        try:
            style_prompts = {
                "analytical": f"Dupin applying analytical reasoning to regulatory compliance assessment for wallet {wallet_address}.",
                "direct": f"Regulatory check on wallet {wallet_address} - what's the compliance status?",
                "methodical": f"Poirot conducting thorough regulatory review of wallet {wallet_address}.",
                "neutral": f"Assessing regulatory compliance for wallet {wallet_address}."
            }

            regulatory_prompt = f"""
            {style_prompts.get(agent_style, style_prompts["neutral"])}

            Evaluate against current crypto regulations:
            1. Travel Rule compliance (transactions >$1000)
            2. KYC/CDD requirements based on activity
            3. Jurisdictional regulatory risks
            4. DeFi protocol compliance
            5. Tax reporting obligations

            Consider recent regulations:
            - EU MiCA framework
            - US FinCEN guidance
            - FATF crypto standards

            Frameworks: {', '.join(self.regulatory_frameworks)}
            """

            regulatory_analysis = await self.ai_service.analyze_with_ai(
                prompt=regulatory_prompt,
                user_id=agent_id,
                context={
                    "analysis_type": "regulatory_assessment",
                    "wallet": wallet_address,
                    "frameworks": self.regulatory_frameworks
                },
                analysis_type="compliance"
            )

            # Add common metadata
            regulatory_analysis["applicable_frameworks"] = self.regulatory_frameworks
            regulatory_analysis["assessment_date"] = datetime.now().isoformat()
            regulatory_analysis["assessing_agent"] = agent_id

            return regulatory_analysis

        except Exception as e:
            logger.error(f"❌ Regulatory assessment failed: {e}")
            return {"error": "Regulatory assessment failed", "details": str(e)}

    async def calculate_compliance_score(self, aml_analysis: Dict, sanctions_check: Dict,
                                       regulatory_assessment: Dict, agent_id: str) -> Dict:
        """
        Cálculo de score de compliance centralizado.
        """
        try:
            scoring_prompt = f"""
            Calculate overall compliance score based on:

            AML Analysis: {json.dumps(aml_analysis, indent=2)}
            Sanctions Check: {json.dumps(sanctions_check, indent=2)}
            Regulatory Assessment: {json.dumps(regulatory_assessment, indent=2)}

            Calculate:
            1. Overall compliance score (0-100)
            2. Risk category (LOW/MEDIUM/HIGH/CRITICAL)
            3. Key compliance concerns
            4. Immediate actions required
            5. Monitoring recommendations

            Use weighted scoring:
            - Sanctions hits: -50 points
            - High AML risk: -30 points
            - Regulatory violations: -20 points
            - Base score: 100 points
            """

            compliance_score = await self.ai_service.analyze_with_ai(
                prompt=scoring_prompt,
                user_id=agent_id,
                context={
                    "analysis_type": "compliance_scoring",
                    "inputs": [aml_analysis, sanctions_check, regulatory_assessment]
                },
                analysis_type="compliance"
            )

            return compliance_score

        except Exception as e:
            logger.error(f"❌ Compliance scoring failed: {e}")
            return {"score": 0, "category": "UNKNOWN", "error": str(e)}

    async def generate_compliance_report(self, wallet_address: str, aml_analysis: Dict,
                                       sanctions_check: Dict, regulatory_assessment: Dict,
                                       compliance_score: Dict, agent_id: str, agent_name: str) -> Dict:
        """
        Geração de relatório de compliance centralizada.
        """
        try:
            report_prompt = f"""
            Generate a comprehensive compliance report for wallet {wallet_address}.

            Include:
            1. Executive Summary
            2. Key Findings
            3. Risk Assessment
            4. Compliance Status
            5. Recommended Actions
            6. Monitoring Requirements

            Base report on:
            - AML Analysis: {aml_analysis}
            - Sanctions Check: {sanctions_check}
            - Regulatory Assessment: {regulatory_assessment}
            - Compliance Score: {compliance_score}

            Format as structured compliance report.
            """

            final_report = await self.ai_service.analyze_with_ai(
                prompt=report_prompt,
                user_id=agent_id,
                context={
                    "analysis_type": "compliance_report",
                    "wallet": wallet_address,
                    "all_analyses": [aml_analysis, sanctions_check, regulatory_assessment, compliance_score]
                },
                analysis_type="compliance"
            )

            # Add report metadata
            final_report.update({
                "report_id": f"COMP_{wallet_address}_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                "generated_by": agent_name,
                "generated_at": datetime.now().isoformat(),
                "wallet_address": wallet_address,
                "compliance_framework": "Ghost_Wallet_Hunter_Compliance_v1.0",
                "report_type": "compliance_analysis"
            })

            return final_report

        except Exception as e:
            logger.error(f"❌ Compliance report generation failed: {e}")
            return {"error": "Report generation failed", "details": str(e)}


# Instância global para reutilização
compliance_utils = ComplianceUtils()
