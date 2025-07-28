"""
Fast Demo Investigation Endpoint

Returns immediate results for demonstration purposes while the real
investigation can happen in the background.
"""

from fastapi import APIRouter
from pydantic import BaseModel
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["Demo Investigation"])


class QuickDemoRequest(BaseModel):
    wallet_address: str


@router.post("/wallet/investigate/demo")
async def demo_investigation(request: QuickDemoRequest):
    """
    🎯 DEMO INVESTIGATION - Immediate results for production demonstration

    Returns realistic sample results instantly for UI testing and demos.
    """
    try:
        logger.info(f"🎯 Demo investigation launched: {request.wallet_address}")

        # Sample realistic investigation results
        demo_results = {
            "success": True,
            "investigation_id": f"DEMO_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "wallet_address": request.wallet_address,
            "investigation_type": "comprehensive_demo",

            "risk_assessment": {
                "risk_score": 0.72,
                "risk_level": "HIGH",
                "confidence": 0.89,
                "reasoning": "Multiple suspicious patterns detected including round-number transactions and rapid transfer sequences"
            },

            "detective_findings": {
                "poirot": {
                    "specialist": "Transaction Analysis & Behavioral Patterns",
                    "findings": [
                        "Frequent round-number transactions (100, 500, 1000 SOL)",
                        "Consistent transaction timing patterns suggest automation",
                        "High frequency micro-transactions mixed with large transfers"
                    ],
                    "risk_indicators": ["round_amounts", "timing_correlation", "mixed_patterns"],
                    "confidence": 0.85
                },

                "marple": {
                    "specialist": "Pattern & Anomaly Detection",
                    "findings": [
                        "Detected wash trading patterns across 3 associated wallets",
                        "Unusual clustering behavior with synchronized movements",
                        "Price manipulation indicators in DeFi interactions"
                    ],
                    "anomalies": ["wash_trading", "cluster_behavior", "price_manipulation"],
                    "confidence": 0.91
                },

                "spade": {
                    "specialist": "Risk Assessment & Threat Classification",
                    "findings": [
                        "High-risk classification due to multiple red flags",
                        "Potential money laundering through DeFi protocols",
                        "Recommended for enhanced monitoring and reporting"
                    ],
                    "threat_level": "HIGH",
                    "actions": ["enhanced_monitoring", "compliance_report", "investigation_priority"],
                    "confidence": 0.88
                },

                "marlowe": {
                    "specialist": "Bridge & Mixer Tracking",
                    "findings": [
                        "Bridge activity detected: Wormhole, Portal",
                        "Cross-chain obfuscation attempts identified",
                        "Potential use of privacy protocols"
                    ],
                    "bridge_usage": ["wormhole", "portal"],
                    "obfuscation_score": 0.76
                },

                "dupin": {
                    "specialist": "Compliance & AML Analysis",
                    "findings": [
                        "AML risk score: HIGH (7.2/10)",
                        "No direct sanctions matches found",
                        "Requires enhanced due diligence"
                    ],
                    "aml_score": 7.2,
                    "sanctions_status": "clear",
                    "compliance_level": "enhanced_monitoring_required"
                },

                "shadow": {
                    "specialist": "Network Cluster Analysis",
                    "findings": [
                        "Part of larger wallet cluster (15+ wallets)",
                        "Coordinated movement patterns detected",
                        "Potential sybil attack preparation"
                    ],
                    "cluster_size": 15,
                    "coordination_score": 0.83
                },

                "raven": {
                    "specialist": "AI Analysis & Communication",
                    "narrative": """
Based on comprehensive analysis by our legendary detective squad, this wallet exhibits
multiple concerning patterns consistent with sophisticated financial manipulation activities.

🔍 KEY FINDINGS:
• HIGH RISK wallet with 72% risk score
• Evidence of wash trading and price manipulation
• Part of coordinated wallet cluster (15+ wallets)
• Cross-chain obfuscation attempts detected
• Automated transaction patterns suggest bot activity

⚠️ RECOMMENDATIONS:
• Immediate enhanced monitoring
• Compliance reporting required
• Consider transaction restrictions
• Flag for regulatory review

The convergence of evidence from all seven detectives strongly suggests this wallet
is involved in systematic market manipulation and potential money laundering activities.
                    """
                }
            },

            "metadata": {
                "investigation_duration": "2.3 seconds",
                "detectives_deployed": 7,
                "total_patterns_analyzed": 156,
                "ai_confidence": 0.89,
                "risk_factors_identified": 12
            },

            "timestamp": datetime.now().isoformat(),
            "legendary_squad_signature": "🕵️ Seven legendary minds have analyzed the evidence! 🕵️",
            "note": "Demo results - Real investigation available via /api/v1/wallet/investigate"
        }

        return demo_results

    except Exception as e:
        logger.error(f"❌ Demo investigation failed: {e}")
        return {
            "success": False,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }


@router.get("/wallet/investigate/demo/health")
async def demo_health():
    """Demo endpoint health check."""
    return {
        "status": "healthy",
        "demo_mode": "active",
        "timestamp": datetime.now().isoformat(),
        "message": "Demo investigation ready for instant results"
    }
