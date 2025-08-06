# backend/api/real_ai_investigation.py
"""
Real AI Investigation API

Professional endpoint that connects real blockchain data with AI agents
for comprehensive wallet investigation and risk assessment.

This module provides advanced investigation capabilities by combining:
- Real-time Solana blockchain data collection
- AI-powered analysis using Julia agents
- Professional reporting and risk scoring
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Dict, List, Any, Optional
import logging
from datetime import datetime

from ..services.julia_detective_integration import execute_julia_investigation
from ..services.solana_service import SolanaService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/real-ai", tags=["Real AI Investigation"])

class WalletInvestigationRequest(BaseModel):
    """Request model for comprehensive wallet investigation."""
    wallet_address: str
    investigation_type: str = "comprehensive"
    max_transactions: int = 50
    include_network_analysis: bool = True

class InvestigationResponse(BaseModel):
    """Response model for completed wallet investigation."""
    case_id: str
    status: str
    wallet_address: str
    investigation_type: str
    timestamp: str
    agents_used: List[str]
    blockchain_data: Dict[str, Any]
    ai_analysis: Dict[str, Any]
    confidence_level: float
    recommendations: List[str]

@router.post("/investigate", response_model=Dict[str, Any])
async def investigate_wallet_with_real_ai(
    request: WalletInvestigationRequest
) -> Dict[str, Any]:
    """
    COMPREHENSIVE wallet investigation with REAL AI

    This endpoint provides professional-grade wallet investigation by:
    1. Collecting REAL data from Solana blockchain
    2. Analyzing with REAL AI agents (Julia + OpenAI GPT-4)
    3. Returning complete professional investigation report
    """
    case_id = f"REAL_AI_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    logger.info(f"🚀 REAL INVESTIGATION STARTED: {case_id} - Wallet: {request.wallet_address}")

    try:
        # Phase 1: Collect REAL blockchain data
        logger.info("📊 Phase 1: Collecting REAL Solana blockchain data...")

        solana_service = SolanaService()

        # Collect comprehensive data
        transactions = await solana_service.get_wallet_transactions(
            request.wallet_address,
            limit=request.max_transactions
        )

        token_accounts = await solana_service.get_token_accounts(request.wallet_address)

        wallet_analysis = {
            "transactions": transactions,
            "token_accounts": token_accounts,
            "transaction_count": len(transactions),
            "token_accounts_count": len(token_accounts)
        }

        if not transactions and not token_accounts:
            raise HTTPException(
                status_code=400,
                detail="Unable to retrieve wallet data - wallet may not exist or be invalid"
            )

        # Collect connected wallets if requested (simplified for now)
        connected_wallets = []
        if request.include_network_analysis and transactions:
            # Extract unique addresses from transactions for network analysis
            unique_addresses = set()
            for tx in transactions[:10]:  # Limit to first 10 transactions
                if isinstance(tx, dict) and 'account' in tx:
                    unique_addresses.add(tx['account'])
            connected_wallets = list(unique_addresses)[:15]

        logger.info(f"✅ Data collected: {len(transactions)} transactions, {len(connected_wallets)} connected wallets")

        # Phase 2: Analysis with REAL AI (Julia agents + OpenAI GPT-4)
        logger.info("🤖 Phase 2: Analysis with REAL AI (Julia agents + OpenAI GPT-4)...")

        # Execute Julia detective investigation
        ai_investigation = await execute_julia_investigation(
            wallet_address=request.wallet_address,
            detective_type="poirot"  # Use Poirot as default detective
        )

        if ai_investigation.get("error"):
            raise HTTPException(
                status_code=500,
                detail=f"AI analysis error: {ai_investigation['error']}"
            )

        logger.info("✅ AI analysis completed successfully")

        # Phase 3: Compile final result
        logger.info("📋 Phase 3: Compiling final result...")

        # Extract recommendations from AI analysis
        recommendations = extract_recommendations(ai_investigation)

        # Calculate final risk score
        risk_score = calculate_risk_score(wallet_analysis, ai_investigation)

        # Final investigation result
        final_result = {
            "case_id": case_id,
            "status": "completed",
            "wallet_address": request.wallet_address,
            "investigation_type": request.investigation_type,
            "timestamp": datetime.now().isoformat(),

            # REAL blockchain data
            "blockchain_data": {
                "transactions": wallet_analysis.get("transactions", [])[:10],  # First 10 for response
                "connected_wallets": connected_wallets,
                "total_transactions": len(wallet_analysis.get("transactions", [])),
                "analysis_timestamp": datetime.now().isoformat()
            },

            # REAL AI analysis
            "ai_analysis": {
                "agents_used": ai_investigation.get("agents_used", []),
                "detective_reports": ai_investigation.get("detective_reports", {}),
                "final_synthesis": ai_investigation.get("final_synthesis", {}),
                "confidence_level": ai_investigation.get("confidence_level", 0.0)
            },

            # Consolidated assessment
            "risk_assessment": {
                "overall_risk_score": risk_score,
                "risk_level": get_risk_level(risk_score),
                "key_concerns": extract_key_concerns(wallet_analysis, ai_investigation)
            },

            # Actionable recommendations
            "recommendations": recommendations,

            # Metadata
            "metadata": {
                "investigation_duration_seconds": 0,  # Calculate if needed
                "data_sources": ["solana_mainnet", "openai_gpt4", "juliaos_agents"],
                "analysis_completeness": calculate_completeness(wallet_analysis, ai_investigation),
                "confidence_level": ai_investigation.get("confidence_level", 0.0)
            }
        }

        logger.info(f"🎉 REAL INVESTIGATION COMPLETED: {case_id}")
        logger.info(f"📊 Risk Score: {risk_score:.2f}, Level: {get_risk_level(risk_score)}")
        logger.info(f"🎯 Confidence: {ai_investigation.get('confidence_level', 0.0):.2f}")

        return final_result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error in real investigation {case_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal investigation error: {str(e)}"
        )

@router.get("/health")
async def check_real_ai_health():
    """Check health of real AI systems"""
    try:
        # Check Julia integration
        from ..services.julia_detective_integration import test_julia_integration
        julia_health = await test_julia_integration()

        solana_service = SolanaService()
        # Simple connectivity test for blockchain
        test_valid = await solana_service.validate_wallet_address("11111111111111111111111111111112")
        blockchain_health = {"status": "healthy" if test_valid else "unhealthy"}

        return {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "services": {
                "juliaos_ai": julia_health,
                "blockchain_data": blockchain_health
            }
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

@router.get("/agent-status")
async def get_ai_agent_status():
    """Status of Julia AI agents"""
    try:
        from ..services.julia_detective_integration import get_julia_detective_integration
        julia_service = await get_julia_detective_integration()
        agents = await julia_service.get_detective_list()
        return {
            "agents_found": len(agents),
            "agents": agents,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {"error": str(e)}

def extract_recommendations(ai_investigation: Dict[str, Any]) -> List[str]:
    """Extract recommendations from AI analysis"""
    recommendations = []

    # Extract from individual reports
    reports = ai_investigation.get("detective_reports", {})

    # Spade recommendations (Risk Assessment)
    spade_report = reports.get("spade", {})
    if isinstance(spade_report, dict) and "recommendations" in spade_report:
        recommendations.extend(spade_report["recommendations"])

    # Final synthesis recommendations (Raven)
    synthesis = ai_investigation.get("final_synthesis", {})
    if isinstance(synthesis, dict) and "recommendations" in synthesis:
        recommendations.extend(synthesis["recommendations"])

    # Default recommendations based on patterns
    if not recommendations:
        recommendations = [
            "Continue monitoring wallet activity",
            "Review transaction patterns for anomalies",
            "Consider additional compliance checks if needed"
        ]

    return recommendations[:5]  # Limit to 5 recommendations

def calculate_risk_score(blockchain_data: Dict[str, Any], ai_analysis: Dict[str, Any]) -> float:
    """Calculate final risk score (0.0 to 1.0)"""
    risk_score = 0.0

    # Factors based on blockchain data
    transaction_count = blockchain_data.get("transaction_count", 0)
    token_accounts_count = blockchain_data.get("token_accounts_count", 0)

    # High activity indicators
    if transaction_count > 100:
        risk_score += 0.2
    elif transaction_count > 50:
        risk_score += 0.1

    # Token diversity
    if token_accounts_count > 20:
        risk_score += 0.15

    # AI analysis factors
    confidence = ai_analysis.get("confidence_level", 0.5)
    if confidence < 0.3:
        risk_score += 0.2  # Low confidence increases risk

    # Check for error in AI analysis
    if ai_analysis.get("error"):
        risk_score += 0.3

    # Normalize between 0.0 and 1.0
    return min(1.0, max(0.0, risk_score))

def get_risk_level(risk_score: float) -> str:
    """Convert numeric score to risk level"""
    if risk_score < 0.2:
        return "LOW"
    elif risk_score < 0.5:
        return "MEDIUM"
    elif risk_score < 0.8:
        return "HIGH"
    else:
        return "CRITICAL"

def extract_key_concerns(blockchain_data: Dict[str, Any], ai_analysis: Dict[str, Any]) -> List[str]:
    """Extract key concerns identified"""
    concerns = []

    # Concerns based on blockchain data
    transaction_count = blockchain_data.get("transaction_count", 0)
    token_accounts_count = blockchain_data.get("token_accounts_count", 0)

    if transaction_count > 100:
        concerns.append("Very high transaction volume detected")

    if token_accounts_count > 20:
        concerns.append("High number of different tokens")

    if transaction_count == 0:
        concerns.append("No transaction history found")

    # AI analysis concerns
    reports = ai_analysis.get("detective_reports", {})

    # Marple (pattern detection)
    marple_report = reports.get("marple", {})
    if isinstance(marple_report, dict) and "anomalies" in marple_report:
        concerns.append("Anomalous behavioral patterns detected")

    # Spade (risk assessment)
    spade_report = reports.get("spade", {})
    if isinstance(spade_report, dict) and "threat_level" in spade_report:
        threat_level = spade_report.get("threat_level", "UNKNOWN")
        if threat_level in ["HIGH", "CRITICAL"]:
            concerns.append(f"Risk assessment indicates {threat_level} threat level")

    return concerns[:5]  # Limit to 5 main concerns

def calculate_completeness(blockchain_data: Dict[str, Any], ai_analysis: Dict[str, Any]) -> float:
    """Calculate analysis completeness (0.0 to 1.0)"""
    completeness_score = 0.0

    # Check collected blockchain data
    if blockchain_data.get("transaction_count", 0) >= 0:
        completeness_score += 0.3
    if blockchain_data.get("token_accounts_count", 0) >= 0:
        completeness_score += 0.2

    # Check AI analyses performed
    reports = ai_analysis.get("detective_reports", {})
    expected_agents = ["poirot", "marple", "spade", "shadow", "raven"]

    for agent in expected_agents:
        if agent in reports and not reports[agent].get("error"):
            completeness_score += 0.1

    return min(1.0, completeness_score)
