"""
Ghost A2A Client - Cliente para comunicação com agentes via protocolo A2A
Substitui todas as importações diretas de agentes Python eliminados

Seguindo a arquitetura: 1 detetive = 1 definição = 1 local (A2A + JuliaOS)
"""

import aiohttp
import asyncio
import os
from typing import Dict, List, Any, Optional, Union
from datetime import datetime
import json
import logging

# Configuração de logging
logger = logging.getLogger(__name__)

class GhostA2AClient:
    """Cliente para comunicação com os Ghost Detectives via A2A Protocol"""

    def __init__(self, a2a_host: str = None, a2a_port: int = None):
        # Use environment variables with fallbacks
        a2a_host = a2a_host or os.getenv("A2A_HOST", "localhost")
        a2a_port = a2a_port or int(os.getenv("A2A_PORT", "9100"))
        
        # Handle HTTPS URLs from environment
        if a2a_host.startswith(("http://", "https://")):
            self.base_url = a2a_host
        else:
            protocol = "https" if a2a_port == 443 else "http"
            self.base_url = f"{protocol}://{a2a_host}:{a2a_port}" if a2a_port not in [80, 443] else f"{protocol}://{a2a_host}"
            
        self.session = None
        logger.info(f"🔗 GhostA2AClient configured for: {self.base_url}")

    async def _get_session(self):
        """Obtém ou cria uma sessão HTTP"""
        if self.session is None:
            self.session = aiohttp.ClientSession()
        return self.session

    async def close(self):
        """Fecha a sessão HTTP"""
        if self.session:
            await self.session.close()
            self.session = None

    async def _call_agent(self, agent_name: str, wallet_address: str, extra_data: Optional[Dict] = None) -> Dict[str, Any]:
        """Chama um agente específico via A2A"""
        try:
            session = await self._get_session()

            payload = {
                "wallet_address": wallet_address,
                "extra_data": extra_data or {}
            }

            url = f"{self.base_url}/investigate/{agent_name}"

            timeout = aiohttp.ClientTimeout(total=30)
            async with session.post(url, json=payload, timeout=timeout) as response:
                if response.status == 200:
                    result = await response.json()
                    logger.info(f"Agent {agent_name} analysis completed for {wallet_address}")
                    return result
                else:
                    error_text = await response.text()
                    logger.error(f"Agent {agent_name} failed with status {response.status}: {error_text}")
                    return {
                        "status": "error",
                        "message": f"Agent call failed: {error_text}",
                        "risk_score": 0
                    }

        except Exception as e:
            logger.error(f"Exception calling agent {agent_name}: {str(e)}")
            return {
                "status": "error",
                "message": f"Connection error: {str(e)}",
                "risk_score": 0
            }

    # === MÉTODOS DOS AGENTES ESPECÍFICOS ===

    async def poirot_analyze(self, wallet_address: str, transaction_patterns: Optional[Dict] = None) -> Dict[str, Any]:
        """Análise do Detetive Poirot (Padrões de Transação)"""
        extra_data = {"transaction_patterns": transaction_patterns or {}}
        return await self._call_agent("poirot", wallet_address, extra_data)

    async def marple_analyze(self, wallet_address: str, social_connections: Optional[Dict] = None) -> Dict[str, Any]:
        """Análise da Detetive Marple (Conexões Sociais)"""
        extra_data = {"social_connections": social_connections or {}}
        return await self._call_agent("marple", wallet_address, extra_data)

    async def spade_analyze(self, wallet_address: str, financial_flows: Optional[Dict] = None) -> Dict[str, Any]:
        """Análise do Detetive Spade (Fluxos Financeiros)"""
        extra_data = {"financial_flows": financial_flows or {}}
        return await self._call_agent("spade", wallet_address, extra_data)

    async def raven_analyze(self, wallet_address: str, dark_patterns: Optional[Dict] = None) -> Dict[str, Any]:
        """Análise do Detetive Raven (Padrões Sombrios)"""
        extra_data = {"dark_patterns": dark_patterns or {}}
        return await self._call_agent("raven", wallet_address, extra_data)

    async def dupin_analyze(self, wallet_address: str, psychological_profile: Optional[Dict] = None) -> Dict[str, Any]:
        """Análise do Detetive Dupin (Perfil Psicológico)"""
        extra_data = {"psychological_profile": psychological_profile or {}}
        return await self._call_agent("dupin", wallet_address, extra_data)

    async def marlowe_analyze(self, wallet_address: str, noir_investigation: Optional[Dict] = None) -> Dict[str, Any]:
        """Análise do Detetive Marlowe (Investigação Noir)"""
        extra_data = {"noir_investigation": noir_investigation or {}}
        return await self._call_agent("marlowe", wallet_address, extra_data)

    async def shadow_analyze(self, wallet_address: str, stealth_patterns: Optional[Dict] = None) -> Dict[str, Any]:
        """Análise do Detetive Shadow (Padrões Stealth)"""
        extra_data = {"stealth_patterns": stealth_patterns or {}}
        return await self._call_agent("shadow", wallet_address, extra_data)

    async def compliance_analyze(self, wallet_address: str, regulatory_check: Optional[Dict] = None) -> Dict[str, Any]:
        """Análise do Agente de Compliance (Verificação Regulatória)"""
        extra_data = {"regulatory_check": regulatory_check or {}}
        return await self._call_agent("compliance", wallet_address, extra_data)

    # === INVESTIGAÇÃO COORDENADA ===

    async def swarm_investigate(self, wallet_address: str, investigation_depth: str = "standard") -> Dict[str, Any]:
        """Investigação coordenada usando todo o swarm de detetives"""
        try:
            session = await self._get_session()

            payload = {
                "wallet_address": wallet_address,
                "investigation_depth": investigation_depth
            }

            url = f"{self.base_url}/swarm/investigate"

            timeout = aiohttp.ClientTimeout(total=120)
            async with session.post(url, json=payload, timeout=timeout) as response:
                if response.status == 200:
                    result = await response.json()
                    logger.info(f"Swarm investigation completed for {wallet_address}")
                    return result
                else:
                    error_text = await response.text()
                    logger.error(f"Swarm investigation failed with status {response.status}: {error_text}")
                    return {
                        "status": "error",
                        "message": f"Swarm investigation failed: {error_text}",
                        "risk_score": 0
                    }

        except Exception as e:
            logger.error(f"Exception in swarm investigation: {str(e)}")
            return {
                "status": "error",
                "message": f"Swarm connection error: {str(e)}",
                "risk_score": 0
            }

    # === COMPATIBILIDADE COM CÓDIGO LEGACY ===

    class DetectiveSquadManager:
        """Wrapper de compatibilidade para DetectiveSquadManager"""

        def __init__(self, a2a_client):
            self.a2a_client = a2a_client

        async def investigate_wallet(self, wallet_address: str, investigation_type: str = "comprehensive"):
            """Investigação usando o swarm A2A"""
            return await self.a2a_client.swarm_investigate(wallet_address, investigation_type)

    class PoirotAgent:
        """Wrapper de compatibilidade para PoirotAgent"""

        def __init__(self, a2a_client):
            self.a2a_client = a2a_client

        async def analyze_wallet(self, wallet_address: str, transaction_data: Optional[Dict] = None):
            """Análise Poirot via A2A"""
            return await self.a2a_client.poirot_analyze(wallet_address, transaction_data)

    class MarpleAgent:
        """Wrapper de compatibilidade para MarpleAgent"""

        def __init__(self, a2a_client):
            self.a2a_client = a2a_client

        async def analyze_wallet(self, wallet_address: str, social_data: Optional[Dict] = None):
            """Análise Marple via A2A"""
            return await self.a2a_client.marple_analyze(wallet_address, social_data)

    class SpadeAgent:
        """Wrapper de compatibilidade para SpadeAgent"""

        def __init__(self, a2a_client):
            self.a2a_client = a2a_client

        async def analyze_wallet(self, wallet_address: str, financial_data: Optional[Dict] = None):
            """Análise Spade via A2A"""
            return await self.a2a_client.spade_analyze(wallet_address, financial_data)

    def get_detective_squad_manager(self):
        """Retorna wrapper compatível com DetectiveSquadManager"""
        return self.DetectiveSquadManager(self)

    def get_poirot_agent(self):
        """Retorna wrapper compatível com PoirotAgent"""
        return self.PoirotAgent(self)

    def get_marple_agent(self):
        """Retorna wrapper compatível com MarpleAgent"""
        return self.MarpleAgent(self)

    def get_spade_agent(self):
        """Retorna wrapper compatível com SpadeAgent"""
        return self.SpadeAgent(self)

# === MODELOS DE COMPATIBILIDADE ===

class RiskLevel:
    """Enum de compatibilidade para RiskLevel"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

    @staticmethod
    def from_score(score: float) -> str:
        """Converte score numérico para nível de risco"""
        if score >= 80:
            return RiskLevel.CRITICAL
        elif score >= 60:
            return RiskLevel.HIGH
        elif score >= 30:
            return RiskLevel.MEDIUM
        else:
            return RiskLevel.LOW

# === INSTÂNCIA GLOBAL ===

# Cliente global para uso em toda a aplicação
ghost_a2a_client = GhostA2AClient()

# Aliases de compatibilidade para importações legacy
DetectiveSquadManager = ghost_a2a_client.get_detective_squad_manager
PoirotAgent = ghost_a2a_client.get_poirot_agent
MarpleAgent = ghost_a2a_client.get_marple_agent
SpadeAgent = ghost_a2a_client.get_spade_agent
