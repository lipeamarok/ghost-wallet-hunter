"""
Julia Bridge - FASE 3: BRIDGE PYTHON ↔ JULIA
============================================

Bridge para comunicação entre Python A2A e servidor Julia.
Conecta agentes A2A com detetives Julia reais.
"""

import asyncio
import httpx
import json
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime

logger = logging.getLogger(__name__)


class JuliaOSConnection:
    """Conexão com servidor Julia Ghost Wallet Hunter"""

    def __init__(self, julia_url: str = "http://127.0.0.1:8052"):
        self.julia_url = julia_url.rstrip('/')
        self.session = None
        self._agents_cache = None
        self._cache_timestamp = None

    async def __aenter__(self):
        self.session = httpx.AsyncClient(timeout=30.0)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.aclose()

    async def health_check(self) -> Dict[str, Any]:
        """Verifica se servidor Julia está funcionando"""
        try:
            if not self.session:
                self.session = httpx.AsyncClient(timeout=30.0)

            response = await self.session.get(f"{self.julia_url}/health")
            response.raise_for_status()

            data = response.json()
            logger.info(f"Julia server health: {data['status']}")
            return data

        except Exception as e:
            logger.error(f"Julia health check failed: {str(e)}")
            raise ConnectionError(f"Cannot connect to Julia server: {str(e)}")

    async def list_agents(self, force_refresh: bool = False) -> List[Dict[str, Any]]:
        """Lista agentes do servidor Julia"""
        try:
            # Cache por 5 minutos
            now = datetime.now()
            if (not force_refresh and
                self._agents_cache and
                self._cache_timestamp and
                (now - self._cache_timestamp).total_seconds() < 300):
                logger.debug("Using cached agents list")
                return self._agents_cache

            if not self.session:
                self.session = httpx.AsyncClient(timeout=30.0)

            response = await self.session.get(f"{self.julia_url}/api/v1/agents")
            response.raise_for_status()

            data = response.json()
            agents = data.get('agents', [])

            # Update cache
            self._agents_cache = agents
            self._cache_timestamp = now

            logger.info(f"Retrieved {len(agents)} agents from Julia")
            return agents

        except Exception as e:
            logger.error(f"Failed to list Julia agents: {str(e)}")
            raise

    async def get_agent_by_id(self, agent_id: str) -> Optional[Dict[str, Any]]:
        """Busca agente específico por ID"""
        agents = await self.list_agents()
        for agent in agents:
            if agent.get('id') == agent_id:
                return agent
        return None

    async def execute_tool(self, tool_name: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Executa ferramenta no servidor Julia"""
        try:
            if not self.session:
                self.session = httpx.AsyncClient(timeout=30.0)

            url = f"{self.julia_url}/api/v1/tools/{tool_name}"
            response = await self.session.post(url, json=parameters)
            response.raise_for_status()

            return response.json()

        except Exception as e:
            logger.error(f"Failed to execute tool {tool_name}: {str(e)}")
            raise


class GhostDetectiveFactory:
    """Factory para criar agentes Ghost Detectives conectados com Julia"""

    def __init__(self, julia_url: str = "http://127.0.0.1:8052"):
        self.julia_url = julia_url
        self._connection = None

    async def get_connection(self) -> JuliaOSConnection:
        """Obtém conexão reutilizável com Julia"""
        if not self._connection:
            self._connection = JuliaOSConnection(self.julia_url)
        return self._connection

    async def create_detective_agent(self, agent_id: str) -> Dict[str, Any]:
        """Cria agente A2A conectado com detetive Julia"""
        async with JuliaOSConnection(self.julia_url) as julia_conn:
            # Verificar se Julia está funcionando
            await julia_conn.health_check()

            # Buscar agente no Julia
            julia_agent = await julia_conn.get_agent_by_id(agent_id)
            if not julia_agent:
                raise ValueError(f"Agent {agent_id} not found in Julia server")

            # Criar agente A2A com dados Julia
            a2a_agent = {
                'id': julia_agent['id'],
                'name': julia_agent['name'],
                'specialty': julia_agent['specialty'],
                'status': julia_agent['status'],
                'persona': julia_agent['persona'],
                'catchphrase': julia_agent['catchphrase'],
                'skills': julia_agent.get('skills', []),
                'blockchain': 'solana',
                'endpoint': f"http://127.0.0.1:9100/{julia_agent['id']}",
                'source': 'julia_server',
                'julia_url': self.julia_url
            }

            logger.info(f"Created A2A agent for Julia detective: {agent_id}")
            return a2a_agent

    async def create_all_detectives(self) -> List[Dict[str, Any]]:
        """Cria todos os agentes A2A baseados nos detetives Julia"""
        async with JuliaOSConnection(self.julia_url) as julia_conn:
            # Verificar conexão
            await julia_conn.health_check()

            # Listar todos os agentes Julia
            julia_agents = await julia_conn.list_agents()

            # Criar agentes A2A
            a2a_agents = []
            for julia_agent in julia_agents:
                a2a_agent = await self.create_detective_agent(julia_agent['id'])
                a2a_agents.append(a2a_agent)

            logger.info(f"Created {len(a2a_agents)} A2A agents from Julia detectives")
            return a2a_agents

    async def investigate_with_julia(self, agent_id: str, wallet_address: str) -> Dict[str, Any]:
        """Executa investigação usando detetive Julia"""
        try:
            async with JuliaOSConnection(self.julia_url) as julia_conn:
                # Verificar se agente existe
                agent = await julia_conn.get_agent_by_id(agent_id)
                if not agent:
                    raise ValueError(f"Agent {agent_id} not found")

                # Executar investigação via Julia tools
                investigation_params = {
                    'wallet_address': wallet_address,
                    'agent_id': agent_id,
                    'blockchain': 'solana'
                }

                # Nota: Assumindo que Julia tem ferramenta de investigação
                # Adaptar conforme API real do Julia
                result = await julia_conn.execute_tool('investigate_wallet', investigation_params)

                logger.info(f"Julia investigation completed for {wallet_address} by {agent_id}")
                return result

        except Exception as e:
            logger.error(f"Julia investigation failed: {str(e)}")
            # Fallback para investigação local se Julia falhar
            return {
                'error': f"Julia investigation failed: {str(e)}",
                'fallback': 'local_investigation',
                'agent_id': agent_id,
                'wallet_address': wallet_address
            }


# Instância global para reutilização
ghost_factory = GhostDetectiveFactory()


async def test_julia_bridge():
    """Teste do bridge Julia"""
    print("🔗 Testing Julia Bridge...")

    try:
        # Teste 1: Conexão
        async with JuliaOSConnection() as julia:
            health = await julia.health_check()
            print(f"✅ Julia Health: {health['status']}")

            # Teste 2: Listar agentes
            agents = await julia.list_agents()
            print(f"✅ Found {len(agents)} Julia agents")

            for agent in agents[:3]:  # Primeiros 3
                print(f"   🕵️ {agent['name']} ({agent['id']})")

        # Teste 3: Factory
        factory = GhostDetectiveFactory()
        a2a_agents = await factory.create_all_detectives()
        print(f"✅ Created {len(a2a_agents)} A2A agents")

        # Teste 4: Agente específico
        poirot = await factory.create_detective_agent('poirot')
        print(f"✅ Created Poirot A2A agent: {poirot['name']}")

        print("🎉 Julia Bridge working perfectly!")
        return True

    except Exception as e:
        print(f"❌ Julia Bridge test failed: {str(e)}")
        return False


if __name__ == "__main__":
    asyncio.run(test_julia_bridge())
