"""
Ghost Detective Factory - FASE 3
================================

Factory para criar instâncias específicas dos agentes detetives
Bridge Python ↔ Julia com factory pattern.
"""

import asyncio
from typing import Dict, List, Any, Optional
from juliaos_connection import JuliaOSConnection, JuliaOSAgent


class GhostDetectiveFactory:
    """
    Factory para criar agentes detetives específicos
    """

    def __init__(self, julia_url: str = "http://127.0.0.1:8052/api/v1"):
        self.julia_url = julia_url
        self._agents_cache: Dict[str, Dict[str, Any]] = {}

    async def _get_connection(self) -> JuliaOSConnection:
        """Cria conexão com Julia Server"""
        return JuliaOSConnection(self.julia_url)

    async def _load_agents(self) -> Dict[str, Dict[str, Any]]:
        """Carrega todos os agentes disponíveis"""
        if not self._agents_cache:
            async with await self._get_connection() as conn:
                agents_list = await conn.list_agents()
                self._agents_cache = {agent["id"]: agent for agent in agents_list}
        return self._agents_cache

    async def create_poirot_agent(self) -> JuliaOSAgent:
        """🕵️ Cria Detective Hercule Poirot - Transaction Analysis"""
        agents = await self._load_agents()
        if "poirot" not in agents:
            raise ValueError("Poirot agent not available in Julia Server")

        async with await self._get_connection() as conn:
            return JuliaOSAgent(agents["poirot"], conn)

    async def create_marple_agent(self) -> JuliaOSAgent:
        """👵 Cria Detective Miss Marple - Pattern & Anomaly Detection"""
        agents = await self._load_agents()
        if "marple" not in agents:
            raise ValueError("Marple agent not available in Julia Server")

        async with await self._get_connection() as conn:
            return JuliaOSAgent(agents["marple"], conn)

    async def create_spade_agent(self) -> JuliaOSAgent:
        """🔫 Cria Detective Sam Spade - Hard-boiled Investigation"""
        agents = await self._load_agents()
        if "spade" not in agents:
            raise ValueError("Spade agent not available in Julia Server")

        async with await self._get_connection() as conn:
            return JuliaOSAgent(agents["spade"], conn)

    async def create_marlowe_agent(self) -> JuliaOSAgent:
        """🏴‍☠️ Cria Detective Philip Marlowe - Deep Analysis"""
        agents = await self._load_agents()
        if "marlowee" not in agents:
            raise ValueError("Marlowe agent not available in Julia Server")

        async with await self._get_connection() as conn:
            return JuliaOSAgent(agents["marlowee"], conn)

    async def create_dupin_agent(self) -> JuliaOSAgent:
        """🧠 Cria Detective C. Auguste Dupin - Analytical Investigation"""
        agents = await self._load_agents()
        if "dupin" not in agents:
            raise ValueError("Dupin agent not available in Julia Server")

        async with await self._get_connection() as conn:
            return JuliaOSAgent(agents["dupin"], conn)

    async def create_shadow_agent(self) -> JuliaOSAgent:
        """🌫️ Cria Detective The Shadow - Stealth Investigation"""
        agents = await self._load_agents()
        if "shadow" not in agents:
            raise ValueError("Shadow agent not available in Julia Server")

        async with await self._get_connection() as conn:
            return JuliaOSAgent(agents["shadow"], conn)

    async def create_raven_agent(self) -> JuliaOSAgent:
        """🐦‍⬛ Cria Detective Edgar Raven - Dark Pattern Investigation"""
        agents = await self._load_agents()
        if "raven" not in agents:
            raise ValueError("Raven agent not available in Julia Server")

        async with await self._get_connection() as conn:
            return JuliaOSAgent(agents["raven"], conn)

    async def create_compliance_agent(self) -> JuliaOSAgent:
        """⚖️ Cria Detective Compliance Officer - Regulatory Compliance"""
        agents = await self._load_agents()
        if "compliance" not in agents:
            raise ValueError("Compliance agent not available in Julia Server")

        async with await self._get_connection() as conn:
            return JuliaOSAgent(agents["compliance"], conn)

    async def create_agent_by_id(self, agent_id: str) -> JuliaOSAgent:
        """Cria agente por ID específico"""
        agents = await self._load_agents()
        if agent_id not in agents:
            raise ValueError(f"Agent {agent_id} not available in Julia Server")

        async with await self._get_connection() as conn:
            return JuliaOSAgent(agents[agent_id], conn)

    async def list_available_agents(self) -> List[Dict[str, Any]]:
        """Lista todos os agentes disponíveis"""
        agents = await self._load_agents()
        return list(agents.values())

    async def create_detective_squad(self) -> List[JuliaOSAgent]:
        """Cria toda a squad de detetives"""
        agents = await self._load_agents()
        squad = []

        async with await self._get_connection() as conn:
            for agent_data in agents.values():
                squad.append(JuliaOSAgent(agent_data, conn))

        return squad


# Função de teste para demonstrar uso
async def test_ghost_detective_factory():
    """Testa a Ghost Detective Factory"""
    print("🏭 Testing Ghost Detective Factory...")

    factory = GhostDetectiveFactory()

    # Listar agentes disponíveis
    agents = await factory.list_available_agents()
    print(f"🕵️ Available agents: {len(agents)}")

    # Criar agentes específicos
    print("\n🔧 Creating specific detectives...")

    try:
        poirot = await factory.create_poirot_agent()
        print(f"✅ Created: {poirot}")

        marple = await factory.create_marple_agent()
        print(f"✅ Created: {marple}")

        spade = await factory.create_spade_agent()
        print(f"✅ Created: {spade}")

        # Criar squad completa
        print("\n🚔 Creating full detective squad...")
        squad = await factory.create_detective_squad()
        print(f"✅ Detective Squad created: {len(squad)} detectives")

        for detective in squad:
            print(f"  • {detective.name} - {detective.specialty}")

        print("\n🎉 FASE 3.2 COMPLETE - Ghost Detective Factory working!")

    except Exception as e:
        print(f"❌ Error: {e}")


if __name__ == "__main__":
    asyncio.run(test_ghost_detective_factory())
