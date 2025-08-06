"""
A2A Client for Backend Integration - FASE 2 CORRETA
====================================================

Cliente A2A conforme especificado no guia de implementação.
Implementa exatamente os métodos requeridos.
"""

import asyncio
import httpx
import json
import logging
from typing import Dict, List, Optional, Any, Union
from datetime import datetime, timezone

logger = logging.getLogger(__name__)


class GhostA2AClient:
    """
    CLIENTE A2A PARA BACKEND - CONFORME GUIA
    ========================================

    Cliente para comunicação do backend com servidor A2A.
    Substitui agentes locais por chamadas A2A reais.
    """

    def __init__(self, a2a_url: str = "http://127.0.0.1:9100"):
        self.a2a_url = a2a_url.rstrip('/')
        self.session = None

    async def __aenter__(self):
        self.session = httpx.AsyncClient(timeout=120.0)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.aclose()

    async def health_check(self) -> Dict[str, Any]:
        """Verifica se A2A server está funcionando"""
        try:
            if not self.session:
                self.session = httpx.AsyncClient(timeout=30.0)

            response = await self.session.get(f"{self.a2a_url}/health")
            response.raise_for_status()

            return response.json()

        except Exception as e:
            logger.error(f"A2A health check failed: {str(e)}")
            raise ConnectionError(f"Cannot connect to A2A server: {str(e)}")

    async def investigate_wallet_swarm(self, wallet_address: str) -> Dict[str, Any]:
        """
        INVESTIGAÇÃO COORDENADA SWARM - Método específico do guia
        Todos os detetives trabalham em equipe via A2A Protocol
        """
        try:
            if not self.session:
                self.session = httpx.AsyncClient(timeout=120.0)

            response = await self.session.post(
                f"{self.a2a_url}/swarm/investigate",
                json={"wallet_address": wallet_address}
            )
            response.raise_for_status()

            result = response.json()
            return {
                "success": True,
                "investigation_id": result.get("investigation_id"),
                "agents_involved": result.get("agents_involved", []),
                "investigation_steps": result.get("investigation_steps", []),
                "final_report": result.get("final_report", {}),
                "confidence_score": result.get("confidence_score", 0.0),
                "risk_assessment": result.get("risk_assessment", "UNKNOWN"),
                "total_duration": result.get("total_duration", 0.0)
            }

        except Exception as e:
            logger.error(f"A2A swarm investigation failed: {str(e)}")
            return {"success": False, "error": str(e)}

    async def investigate_wallet_individual(self, detective_id: str, wallet_address: str) -> Dict[str, Any]:
        """
        INVESTIGAÇÃO INDIVIDUAL - Método específico do guia
        Detetive específico via A2A Protocol
        """
        try:
            if not self.session:
                self.session = httpx.AsyncClient(timeout=60.0)

            response = await self.session.post(
                f"{self.a2a_url}/investigate/{detective_id}",
                json={"wallet_address": wallet_address}
            )
            response.raise_for_status()

            result = response.json()
            return {
                "success": True,
                "agent_name": result.get("agent_name", detective_id),
                "specialty": result.get("specialty", "Detective Analysis"),
                "investigation": result.get("analysis_results", {}),
                "specialized_analysis": result.get("specialized_analysis", {}),
                "timestamp": result.get("timestamp")
            }

        except Exception as e:
            logger.error(f"A2A individual investigation failed: {str(e)}")
            return {"success": False, "error": str(e)}

    async def list_agents(self) -> Dict[str, Any]:
        """
        LISTA AGENTES - Método específico do guia
        Busca agentes diretamente do A2A Server
        """
        try:
            if not self.session:
                self.session = httpx.AsyncClient(timeout=30.0)

            # Usar endpoint disponível no A2A server
            response = await self.session.get(f"{self.a2a_url}/agents")
            response.raise_for_status()

            result = response.json()

            # Formatação conforme especificado no guia
            return {
                "agents": result.get("available_agents", []),
                "total": len(result.get("available_agents", [])),
                "success": True
            }

        except Exception as e:
            logger.error(f"A2A list agents failed: {str(e)}")
            return {"agents": [], "total": 0, "error": str(e)}


# Global instance for easy import
a2a_client = GhostA2AClient()
