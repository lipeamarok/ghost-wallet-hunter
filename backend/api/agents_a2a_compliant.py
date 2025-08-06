"""
Ghost Wallet Hunter - Agents API (A2A Protocol Compliant)
=========================================================

Main endpoints for coordinated blockchain investigations via Agent-to-Agent Protocol.
Provides real-time wallet analysis through distributed detective agents.

Features:
- Legendary Squad coordinated investigations
- Individual detective analysis
- Real-time A2A communication with JuliaOS backend
- Comprehensive blockchain data analysis
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
import logging

# A2A Client for JuliaOS integration
from services.a2a_client import a2a_client

# Router and logging setup
router = APIRouter()
logger = logging.getLogger(__name__)


class LegendarySquadRequest(BaseModel):
    """Request model for coordinated multi-agent investigation"""
    wallet_address: str
    investigation_type: str = "comprehensive"
    detective_preferences: Optional[List[str]] = None
    include_context: bool = True

class DetectiveAnalysisRequest(BaseModel):
    """Request model for individual detective analysis"""
    wallet_address: str
    detective: str
    analysis_parameters: Optional[Dict[str, Any]] = None

@router.post("/legendary-squad/investigate")
async def investigate_with_legendary_squad(request: LegendarySquadRequest):
    """
    Coordinated Multi-Agent Blockchain Investigation
    ===============================================

    Deploys the full legendary detective squad for comprehensive wallet analysis.
    All detectives work collaboratively via A2A Protocol with JuliaOS backend.

    Returns:
        Comprehensive investigation report with risk assessment and detailed findings
    """
    try:
        logger.info(f"🚀 Legendary Squad Investigation initiated: {request.wallet_address}")

        # Execute coordinated A2A swarm investigation
        swarm_result = await a2a_client.investigate_wallet_swarm(request.wallet_address)

        if not swarm_result.get('success'):
            raise HTTPException(
                status_code=500,
                detail=f"Investigation failed: {swarm_result.get('error', 'Unknown error')}"
            )

        # Transform A2A results to standardized backend format
        return {
            "investigation_type": "A2A_COORDINATED_SWARM",
            "wallet_address": request.wallet_address,
            "investigation_id": swarm_result.get('investigation_id'),
            "agents_involved": swarm_result.get('agents_involved', []),
            "investigation_steps": swarm_result.get('investigation_steps', []),
            "final_report": swarm_result.get('final_report', {}),
            "confidence_score": swarm_result.get('confidence_score', 0.0),
            "risk_assessment": swarm_result.get('risk_assessment', 'UNKNOWN'),
            "total_duration": swarm_result.get('total_duration', 0.0),
            "data_source": "A2A_JULIAOS_INTEGRATION",
            "verification": "Real blockchain data via A2A + JuliaOS",
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"❌ Legendary Squad investigation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/detective/{detective_id}/analyze")
async def analyze_with_specific_detective(detective_id: str, request: DetectiveAnalysisRequest):
    """
    Individual Detective Blockchain Analysis
    =======================================

    Deploy a specific detective for specialized wallet analysis.
    Each detective has unique capabilities and analysis approaches.

    Args:
        detective_id: Detective identifier (poirot, marple, spade, raven)
        request: Analysis parameters and wallet address

    Returns:
        Specialized analysis report from the selected detective
    """
    try:
        logger.info(f"🕵️ Individual Detective Analysis: {detective_id} -> {request.wallet_address}")

        # Execute individual A2A agent investigation
        result = await a2a_client.investigate_wallet_individual(detective_id, request.wallet_address)

        if not result.get('success'):
            raise HTTPException(
                status_code=500,
                detail=f"Detective {detective_id} analysis failed: {result.get('error', 'Unknown error')}"
            )

        return {
            "detective_id": detective_id,
            "detective_name": result.get('agent_name'),
            "specialty": result.get('specialty'),
            "wallet_address": request.wallet_address,
            "investigation_result": result.get('investigation', {}),
            "specialized_analysis": result.get('specialized_analysis', {}),
            "data_source": "A2A_JULIAOS_SINGLE_AGENT",
            "timestamp": result.get('timestamp'),
            "verification": "Real blockchain data via A2A + JuliaOS"
        }

    except Exception as e:
        logger.error(f"❌ Detective {detective_id} analysis failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/available")
async def list_available_detectives():
    """
    Available Detective Agents Directory
    ===================================

    Retrieves the complete roster of available detective agents from the A2A network.
    Each detective has specialized capabilities for different types of blockchain analysis.

    Returns:
        List of available detectives with their specialties and current status
    """
    try:
        agents_result = await a2a_client.list_agents()

        return {
            "detectives": agents_result.get('agents', []),
            "total_count": agents_result.get('total', 0),
            "data_source": "A2A_JULIAOS_BRIDGE",
            "verification": "Real-time agent status via A2A + JuliaOS",
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"❌ Failed to retrieve available detectives: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/health")
async def a2a_system_health():
    """
    A2A System Health Check
    ======================

    Comprehensive health status of the Agent-to-Agent network and JuliaOS backend.
    Monitors connectivity, agent availability, and system performance metrics.

    Returns:
        Complete system health report including all connected services
    """
    try:
        health_result = await a2a_client.health_check()

        return {
            "a2a_system": health_result,
            "integration_status": "A2A + JuliaOS Operational",
            "architecture": "Distributed Agent Network",
            "data_source": "Real Blockchain Data Only",
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"❌ A2A system health check failed: {str(e)}")
        return {
            "a2a_system": {"status": "error", "error": str(e)},
            "integration_status": "A2A Connection Failed",
            "timestamp": datetime.now().isoformat()
        }

# End of Agents API - Production Ready
# All detective coordination handled via A2A Protocol with JuliaOS backend
# No legacy Python agent duplicates - Clean architecture implementation
