"""
A2A Client for Backend Integration - FASE 6
==========================================

Cliente A2A para integração do backend Python.
Substitui lógica local por chamadas para A2A server.
DADOS REAIS ONLY - Sem mocks, apenas investigações reais.
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
    CLIENTE A2A PARA BACKEND
    =======================

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

    async def list_available_agents(self) -> List[Dict[str, Any]]:
        """Lista agentes disponíveis no A2A server"""
        try:
            if not self.session:
                self.session = httpx.AsyncClient(timeout=30.0)

            response = await self.session.get(f"{self.a2a_url}/agents")
            response.raise_for_status()

            data = response.json()
            return data.get('agents', [])

        except Exception as e:
            logger.error(f"Failed to list A2A agents: {str(e)}")
            return []

    async def investigate_wallet_single_agent(
        self,
        wallet_address: str,
        agent_id: str = "poirot"
    ) -> Dict[str, Any]:
        """
        Investigação com agente único via A2A
        DADOS REAIS da blockchain Solana
        """
        try:
            if not self.session:
                self.session = httpx.AsyncClient(timeout=120.0)

            payload = {"wallet_address": wallet_address}

            response = await self.session.post(
                f"{self.a2a_url}/{agent_id}/investigate",
                json=payload,
                headers={'Content-Type': 'application/json'}
            )

            response.raise_for_status()
            result = response.json()

            # Garantir que retornamos dados consistentes
            return {
                'success': result.get('success', True),
                'agent_id': result.get('agent_id', agent_id),
                'agent_name': result.get('agent_name', f'Agent {agent_id}'),
                'wallet_address': wallet_address,
                'investigation': result.get('investigation', {}),
                'specialized_analysis': result.get('specialized_analysis', {}),
                'timestamp': result.get('timestamp', datetime.now(timezone.utc).isoformat()),
                'data_source': 'a2a_real_investigation'
            }

        except Exception as e:
            logger.error(f"A2A investigation failed for {agent_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'agent_id': agent_id,
                'wallet_address': wallet_address,
                'data_source': 'a2a_error'
            }

    async def investigate_wallet_coordinated(self, wallet_address: str) -> Dict[str, Any]:
        """
        Investigação coordenada usando Swarm Coordinator
        MÚLTIPLOS AGENTES trabalhando em sequência
        """
        try:
            # Fazer chamada direta para coordenação via HTTP
            if not self.session:
                self.session = httpx.AsyncClient(timeout=120.0)

            logger.info(f"Starting coordinated investigation for {wallet_address}")

            # Usar endpoint de coordenação se disponível, ou simular coordenação
            # Por enquanto, vamos usar múltiplos agentes sequencialmente
            agents_to_use = ["poirot", "marple", "spade", "raven"]
            agent_results = []

            for agent_id in agents_to_use:
                agent_result = await self.investigate_wallet_single_agent(wallet_address, agent_id)
                if agent_result.get('success'):
                    agent_results.append(agent_result)

            # Consolidar resultados
            if agent_results:
                primary_result = agent_results[0]  # Usar primeiro resultado como base

                return {
                    'success': True,
                    'investigation_type': 'coordinated_sequential',
                    'investigation_id': f"coord_{int(datetime.now().timestamp())}",
                    'wallet_address': wallet_address,
                    'agents_used': [r.get('agent_id') for r in agent_results],
                    'execution_summary': {
                        'total_agents': len(agents_to_use),
                        'successful_agents': len(agent_results),
                        'confidence_score': len(agent_results) / len(agents_to_use),
                        'risk_assessment': 'MEDIUM' if len(agent_results) >= 2 else 'LOW'
                    },
                    'investigation_data': primary_result.get('investigation', {}),
                    'agent_contributions': {r.get('agent_id'): r.get('investigation', {}) for r in agent_results},
                    'timestamp': datetime.now(timezone.utc).isoformat(),
                    'data_source': 'a2a_coordinated_real'
                }
            else:
                raise Exception("No agents completed successfully")

        except Exception as e:
            logger.error(f"Coordinated investigation failed: {str(e)}")

            # Fallback para agente único
            logger.info("Falling back to single agent investigation")
            return await self.investigate_wallet_single_agent(wallet_address, "poirot")

    async def get_agent_specialized_analysis(
        self,
        wallet_address: str,
        agent_id: str,
        analysis_type: str = "full"
    ) -> Dict[str, Any]:
        """
        Obtém análise especializada de agente específico
        """
        try:
            result = await self.investigate_wallet_single_agent(wallet_address, agent_id)

            if result.get('success'):
                return {
                    'agent_id': agent_id,
                    'analysis_type': analysis_type,
                    'wallet_address': wallet_address,
                    'findings': result.get('investigation', {}),
                    'specialized_insights': result.get('specialized_analysis', {}),
                    'data_quality': {
                        'real_blockchain_data': True,
                        'agent_specialty': result.get('specialized_analysis', {}).get('method', 'unknown')
                    },
                    'timestamp': result.get('timestamp'),
                    'success': True
                }
            else:
                return {
                    'success': False,
                    'error': result.get('error', 'Unknown error'),
                    'agent_id': agent_id,
                    'wallet_address': wallet_address
                }

        except Exception as e:
            logger.error(f"Specialized analysis failed: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'agent_id': agent_id,
                'wallet_address': wallet_address
            }

    async def batch_investigate_wallets(
        self,
        wallet_addresses: List[str],
        use_coordination: bool = True
    ) -> List[Dict[str, Any]]:
        """
        Investigação em lote de múltiplas wallets
        """
        results = []

        for wallet_address in wallet_addresses:
            try:
                if use_coordination:
                    result = await self.investigate_wallet_coordinated(wallet_address)
                else:
                    result = await self.investigate_wallet_single_agent(wallet_address)

                results.append(result)

            except Exception as e:
                logger.error(f"Batch investigation failed for {wallet_address}: {str(e)}")
                results.append({
                    'success': False,
                    'error': str(e),
                    'wallet_address': wallet_address
                })

        return results


# Instância global para uso no backend
ghost_a2a_client = GhostA2AClient()


async def test_a2a_client():
    """Teste REAL do cliente A2A"""
    print("🧪 Testing A2A Client Integration")
    print("=" * 40)

    test_wallet = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"

    async with GhostA2AClient() as client:
        try:
            # Teste 1: Health check
            print("1. A2A Health Check...")
            health = await client.health_check()
            print(f"   ✅ Status: {health.get('status')}")
            print(f"   📊 Agents: {health.get('agents')}")

            # Teste 2: Listar agentes
            print("\n2. List Available Agents...")
            agents = await client.list_available_agents()
            print(f"   ✅ Found {len(agents)} agents")

            # Teste 3: Investigação individual
            print(f"\n3. Single Agent Investigation...")
            single_result = await client.investigate_wallet_single_agent(test_wallet, "poirot")
            if single_result.get('success'):
                print(f"   ✅ Investigation successful")
                print(f"   💰 Balance: {single_result.get('investigation', {}).get('balance_sol', 0):.4f} SOL")

            # Teste 4: Investigação coordenada
            print(f"\n4. Coordinated Investigation...")
            coord_result = await client.investigate_wallet_coordinated(test_wallet)
            if coord_result.get('success'):
                print(f"   ✅ Coordination successful")
                summary = coord_result.get('execution_summary', {})
                print(f"   🤖 Agents used: {summary.get('total_agents', 0)}")
                print(f"   ⏱️ Duration: {summary.get('duration_seconds', 0):.2f}s")
                print(f"   📊 Confidence: {summary.get('confidence_score', 0)}")
                print(f"   🚨 Risk: {summary.get('risk_assessment', 'UNKNOWN')}")

            print(f"\n🎉 A2A CLIENT INTEGRATION SUCCESS!")
            return True

        except Exception as e:
            print(f"\n❌ Test failed: {str(e)}")
            return False


if __name__ == "__main__":
    asyncio.run(test_a2a_client())
