"""
Ghost Wallet Hunter - A2A Integration API Endpoints
Todas as investigações agora usam A2A + JuliaOS (sem duplicações)
"""

from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
import logging
from datetime import datetime

# NOVA IMPORTAÇÃO - A2A Client
from services.a2a_client import GhostA2AClient

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/agents", tags=["A2A Integrated Detective Squad"])

# Cliente A2A global
a2a_client = GhostA2AClient()

class LegendarySquadRequest(BaseModel):
    wallet_address: str
    investigation_type: str = "comprehensive"
    detective_preferences: Optional[List[str]] = None
    include_context: bool = True

class DetectiveAnalysisRequest(BaseModel):
    wallet_address: str
    detective: str
    analysis_parameters: Optional[Dict[str, Any]] = None

@router.post("/legendary-squad/investigate")
async def investigate_with_legendary_squad(request: LegendarySquadRequest):
    """
    INVESTIGAÇÃO COORDENADA - 100% A2A + JULIAOS
    Todos os detetives trabalham em equipe via A2A Protocol
    """
    try:
        logger.info(f"🚀 A2A Swarm Investigation: {request.wallet_address}")

        # NOVA IMPLEMENTAÇÃO: Usar A2A Swarm em vez de agentes Python
        swarm_result = await a2a_client.investigate_wallet_swarm(request.wallet_address)

        if not swarm_result.get('success'):
            raise HTTPException(
                status_code=500,
                detail=f"A2A Investigation failed: {swarm_result.get('error', 'Unknown error')}"
            )

        # Transformar resultado A2A para formato backend compatível
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
            "verification": "100% A2A + JuliaOS - No Python duplicates",
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"❌ A2A Swarm investigation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/detective/{detective_id}/analyze")
async def analyze_with_specific_detective(detective_id: str, request: DetectiveAnalysisRequest):
    """
    INVESTIGAÇÃO INDIVIDUAL - 100% A2A + JULIAOS
    Detetive específico via A2A Protocol
    """
    try:
        logger.info(f"🕵️ A2A Individual Investigation: {detective_id} -> {request.wallet_address}")

        # NOVA IMPLEMENTAÇÃO: Usar A2A individual em vez de agente Python
        result = await a2a_client.investigate_wallet_individual(detective_id, request.wallet_address)

        if not result.get('success'):
            raise HTTPException(
                status_code=500,
                detail=f"A2A Detective {detective_id} failed: {result.get('error', 'Unknown error')}"
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
            "verification": "100% A2A + JuliaOS - No Python duplicates"
        }

    except Exception as e:
        logger.error(f"❌ A2A Detective {detective_id} failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/available")
async def list_available_detectives():
    """
    LISTA DETETIVES - 100% A2A + JULIAOS
    Busca detetives diretamente do A2A Server
    """
    try:
        agents_result = await a2a_client.list_agents()

        return {
            "detectives": agents_result.get('agents', []),
            "total_count": agents_result.get('total', 0),
            "data_source": "A2A_JULIAOS_BRIDGE",
            "verification": "100% A2A + JuliaOS - No Python duplicates",
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"❌ A2A List agents failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/health")
async def a2a_system_health():
    """
    HEALTH CHECK - A2A + JULIAOS
    Verifica status completo do sistema
    """
    try:
        health_result = await a2a_client.health_check()

        return {
            "a2a_system": health_result,
            "integration_status": "100% A2A + JuliaOS",
            "python_duplicates": "ELIMINATED",
            "data_source": "REAL_BLOCKCHAIN_ONLY",
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"❌ A2A Health check failed: {str(e)}")
        return {
            "a2a_system": {"status": "error", "error": str(e)},
            "integration_status": "A2A Connection Failed",
            "timestamp": datetime.now().isoformat()
        }

# Remover TODOS os outros imports e classes relacionados aos agentes Python
# DELETAR: DetectiveSquadManager, PoirotAgent, MarpleAgent, etc.
