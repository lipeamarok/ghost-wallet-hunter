"""
JuliaOS Connection Bridge - FASE 3
==================================

Cliente Python para comunicação direta com Julia Server (8052)
Bridge Python ↔ Julia sem simulações.
"""

import asyncio
import httpx
import json
from typing import Dict, List, Any, Optional
from datetime import datetime


class JuliaOSConnection:
    """
    Conexão Python com Julia Server
    """

    def __init__(self, base_url: str = "http://127.0.0.1:8052/api/v1"):
        self.base_url = base_url.rstrip('/')
        self.session = None

    async def __aenter__(self):
        self.session = httpx.AsyncClient(timeout=30.0)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.aclose()

    async def health_check(self) -> Dict[str, Any]:
        """Verifica saúde do Julia Server"""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url.replace('/api/v1', '')}/health")
            response.raise_for_status()
            return response.json()

    async def list_agents(self) -> List[Dict[str, Any]]:
        """Lista todos os agentes detetives disponíveis"""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url}/agents")
            response.raise_for_status()
            data = response.json()
            return data.get("agents", [])

    async def get_agent_details(self, agent_id: str) -> Dict[str, Any]:
        """Obtém detalhes específicos de um agente"""
        agents = await self.list_agents()
        for agent in agents:
            if agent.get("id") == agent_id:
                return agent
        raise ValueError(f"Agent {agent_id} not found")

    async def execute_tool(self, tool_name: str, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Executa uma ferramenta no Julia Server"""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/tools/{tool_name}",
                json=params or {}
            )
            response.raise_for_status()
            return response.json()

    async def test_connection(self) -> Dict[str, Any]:
        """Testa conexão básica com Julia Server"""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url}/test/hello")
            response.raise_for_status()
            return response.json()


# Classe para compatibilidade com código existente
class JuliaOSAgent:
    """Representa um agente Julia no lado Python"""

    def __init__(self, agent_data: Dict[str, Any], connection: JuliaOSConnection):
        self.id = agent_data.get("id")
        self.name = agent_data.get("name")
        self.specialty = agent_data.get("specialty")
        self.status = agent_data.get("status")
        self.persona = agent_data.get("persona", "")
        self.catchphrase = agent_data.get("catchphrase", "")
        self._connection = connection

    def __repr__(self):
        return f"JuliaOSAgent(id='{self.id}', name='{self.name}', specialty='{self.specialty}')"

    async def execute_investigation(self, wallet_address: str) -> Dict[str, Any]:
        """Executa investigação usando este agente específico"""
        # TODO: Implementar chamada específica para o agente
        return await self._connection.execute_tool(
            f"detective_{self.id}_investigate",
            {"wallet_address": wallet_address}
        )


# Função de conveniência para teste rápido
async def test_juliaos_connection():
    """Testa conexão básica com Julia Server"""
    print("🔗 Testing JuliaOS Connection...")

    async with JuliaOSConnection() as conn:
        # Health check
        health = await conn.health_check()
        print(f"✅ Julia Server: {health.get('service')} - {health.get('status')}")

        # List agents
        agents = await conn.list_agents()
        print(f"🕵️ Available agents: {len(agents)}")

        for agent in agents:
            print(f"  • {agent.get('name')} ({agent.get('id')}) - {agent.get('specialty')}")

        # Test connection
        test_result = await conn.test_connection()
        print(f"💬 Test message: {test_result.get('message')}")

        return agents


if __name__ == "__main__":
    # Teste direto
    asyncio.run(test_juliaos_connection())
