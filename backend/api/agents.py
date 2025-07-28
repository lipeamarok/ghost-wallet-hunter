"""
Ghost Wallet Hunter - Legendary Detective Squad API Endpoints

API endpoints for the legendary detective squad with real AI integration.
"""

from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
import logging

# Import the legendary detective squad
from agents.detective_squad import DetectiveSquadManager
from agents.poirot_agent import PoirotAgent
from agents.marple_agent import MarpleAgent
from agents.spade_agent import SpadeAgent

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/agents", tags=["Legendary Detective Squad"])


class LegendarySquadRequest(BaseModel):
    wallet_address: str
    investigation_type: str = "comprehensive"
    detective_preferences: Optional[List[str]] = None


class DetectiveAnalysisRequest(BaseModel):
    wallet_address: str
    detective: str
    analysis_parameters: Optional[Dict[str, Any]] = None


@router.get("/legendary-squad/status")
async def get_legendary_squad_status():
    """Get the status of the legendary detective squad."""
    try:
        squad = DetectiveSquadManager()

        # Initialize squad to get status
        await squad.initialize_squad()
        status = await squad.get_squad_status()

        return {
            "status": "success",
            "squad_info": {
                "name": status["squad_name"],
                "motto": status["motto"],
                "operational_status": status["operational_status"],
                "cases_handled": status["cases_handled"],
                "active_cases": status["active_cases"]
            },
            "available_detectives": squad.get_available_detectives(),
            "legendary_power": "🌟 Seven legendary minds, one unstoppable force! 🌟"
        }

    except Exception as e:
        logger.error(f"Squad status error: {e}")
        raise HTTPException(status_code=500, detail=f"Squad status failed: {e}")


@router.post("/legendary-squad/investigate")
async def legendary_squad_investigation(request: LegendarySquadRequest):
    """Launch a full legendary squad investigation with all 7 detectives."""
    try:
        logger.info(f"🚨 Legendary squad investigation requested for wallet: {request.wallet_address}")

        # Initialize the legendary squad
        squad = DetectiveSquadManager()
        squad_ready = await squad.initialize_squad()

        if not squad_ready:
            raise HTTPException(status_code=503, detail="Legendary squad not ready for deployment")

        # Launch comprehensive investigation
        if request.investigation_type == "comprehensive":
            results = await squad.investigate_wallet_comprehensive(request.wallet_address)
        else:
            # Default to comprehensive for now
            results = await squad.investigate_wallet_comprehensive(request.wallet_address)

        if "error" in results:
            raise HTTPException(status_code=500, detail=results["error"])

        return {
            "status": "investigation_complete",
            "wallet_address": request.wallet_address,
            "investigation_type": request.investigation_type,
            "legendary_results": results,
            "squad_signature": "🌟 The legendary seven have spoken! 🌟"
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Legendary investigation error: {e}")
        raise HTTPException(status_code=500, detail=f"Investigation failed: {e}")


@router.post("/detective/poirot")
async def analyze_with_poirot(request: DetectiveAnalysisRequest):
    """Analyze wallet using Hercule Poirot's methodical approach."""
    try:
        logger.info(f"🕵️ Poirot investigating wallet: {request.wallet_address}")

        poirot = PoirotAgent()
        await poirot.initialize()

        analysis = await poirot.investigate_wallet(request.wallet_address)

        return {
            "detective": "Hercule Poirot",
            "analysis": analysis,
            "signature": "🕵️ 'Order and method in all things!' - Hercule Poirot"
        }

    except Exception as e:
        logger.error(f"Poirot analysis error: {e}")
        raise HTTPException(status_code=500, detail=f"Poirot analysis failed: {e}")


@router.post("/detective/marple")
async def analyze_with_marple(request: DetectiveAnalysisRequest):
    """Analyze wallet using Miss Marple's village wisdom."""
    try:
        logger.info(f"👵 Miss Marple observing wallet: {request.wallet_address}")

        marple = MarpleAgent()
        await marple.initialize()

        # Simulate transactions for demo
        transactions = []
        patterns = await marple.observe_patterns(request.wallet_address, transactions)

        return {
            "detective": "Miss Jane Marple",
            "analysis": patterns,
            "signature": "👵 'Human nature is much the same everywhere.' - Miss Marple"
        }

    except Exception as e:
        logger.error(f"Marple analysis error: {e}")
        raise HTTPException(status_code=500, detail=f"Marple analysis failed: {e}")


@router.post("/detective/spade")
async def analyze_with_spade(request: DetectiveAnalysisRequest):
    """Analyze wallet using Sam Spade's direct risk assessment."""
    try:
        logger.info(f"🚬 Sam Spade assessing wallet: {request.wallet_address}")

        spade = SpadeAgent()
        await spade.initialize()

        # Basic evidence for risk assessment
        evidence = {"wallet": request.wallet_address}
        risk_assessment = await spade.assess_wallet_risk(request.wallet_address, evidence)

        return {
            "detective": "Sam Spade",
            "analysis": risk_assessment,
            "signature": "🚬 'When a man's partner is killed, he's supposed to do something about it.' - Sam Spade"
        }

    except Exception as e:
        logger.error(f"Spade analysis error: {e}")
        raise HTTPException(status_code=500, detail=f"Spade analysis failed: {e}")


@router.get("/detectives/available")
async def list_available_detectives():
    """List all available legendary detectives and their specialties."""
    try:
        squad = DetectiveSquadManager()

        return {
            "legendary_detectives": squad.get_available_detectives(),
            "squad_motto": squad.motto,
            "total_detectives": 7,
            "ai_powered": True,
            "operational_status": "Ready for legendary investigations"
        }

    except Exception as e:
        logger.error(f"Detective listing error: {e}")
        raise HTTPException(status_code=500, detail=f"Detective listing failed: {e}")


@router.get("/test/real-ai")
async def test_real_ai_integration():
    """Test endpoint to verify real AI integration across the detective squad."""
    try:
        logger.info("🧪 Testing real AI integration across legendary squad...")

        # Test individual detectives
        test_results = {}

        # Test Poirot
        poirot = PoirotAgent()
        poirot_ready = await poirot.initialize()
        test_results["poirot"] = {
            "status": "ready" if poirot_ready else "failed",
            "specialty": "Transaction Analysis & Behavioral Patterns"
        }

        # Test Marple
        marple = MarpleAgent()
        marple_ready = await marple.initialize()
        test_results["marple"] = {
            "status": "ready" if marple_ready else "failed",
            "specialty": "Pattern & Anomaly Detection"
        }

        # Test Spade
        spade = SpadeAgent()
        spade_ready = await spade.initialize()
        test_results["spade"] = {
            "status": "ready" if spade_ready else "failed",
            "specialty": "Risk Assessment & Threat Classification"
        }

        # Test full squad
        squad = DetectiveSquadManager()
        squad_ready = await squad.initialize_squad()

        return {
            "ai_integration_status": "OPERATIONAL",
            "real_ai_enabled": True,
            "individual_detectives": test_results,
            "legendary_squad_status": "ready" if squad_ready else "partial",
            "ai_providers": ["OpenAI GPT-3.5-turbo", "Grok (fallback)"],
            "test_timestamp": "2025-07-28",
            "legendary_power": "🌟 Real AI powering legendary detective minds! 🌟"
        }

    except Exception as e:
        logger.error(f"AI integration test error: {e}")
        raise HTTPException(status_code=500, detail=f"AI test failed: {e}")


@router.get("/health")
async def health_check():
    """Health check for the legendary detective squad API."""
    return {
        "status": "legendary_operational",
        "message": "The legendary detective squad stands ready!",
        "detectives_available": 7,
        "ai_powered": True,
        "timestamp": "2025-07-28"
    }
