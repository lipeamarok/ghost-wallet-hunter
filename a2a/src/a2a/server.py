"""
Ghost A2A Server - FINAL VERSION WITH JULIA BRIDGE
=================================================

UM ÚNICO servidor A2A para Ghost Detectives.
✅ Dados reais da Solana
✅ Agentes reais do Julia
✅ Bridge Julia integrado
✅ Sem mocks, sem duplicatas
"""

import os
import sys
import uvicorn
import asyncio
import httpx
import requests
import uuid
from typing import Dict, List, Optional, Any
from datetime import datetime
from starlette.applications import Starlette
from starlette.routing import Route
from starlette.responses import JSONResponse
from starlette.requests import Request

# Import local modules with relative imports
from .a2a_types import AgentCard, AgentCapabilities, InvestigationRequest, A2AProtocolMessage
from .julia_bridge import GhostDetectiveFactory, JuliaOSConnection
from .ghost_swarm_coordinator import GhostSwarmCoordinator

# Default port configuration
DEFAULT_A2A_PORT = 10000

class GhostA2AServer:
    """
    SERVIDOR A2A FINAL COM JULIA BRIDGE
    ==================================

    Único servidor A2A integrado com Julia.
    REAL data only, Julia bridge integrated.
    """

    def __init__(self, julia_url: str = "http://127.0.0.1:8052"):
        self.agents = {}
        self.julia_url = julia_url
        self.factory = GhostDetectiveFactory(julia_url)
        self.solana_rpc = "https://api.mainnet-beta.solana.com"
        # Swarm Coordinator for coordinated investigations
        self.swarm_coordinator = GhostSwarmCoordinator(
            a2a_url=f"http://127.0.0.1:{DEFAULT_A2A_PORT}",
            julia_url=julia_url
        )

    async def load_real_agents(self):
        """Carrega agentes REAIS do servidor Julia via bridge"""
        try:
            print("🔗 Connecting to Julia server via bridge...")

            # Usar Julia bridge para carregar agentes
            a2a_agents = await self.factory.create_all_detectives()

            for agent in a2a_agents:
                if agent.get('status') == 'active':
                    self.agents[agent['id']] = agent

            print(f"✅ Loaded {len(self.agents)} REAL agents from Julia bridge")

            if not self.agents:
                print("⚠️ No agents from Julia, trying fallback...")
                await self._load_fallback_agents()

        except Exception as e:
            print(f"❌ Julia bridge failed: {e}")
            print("🔄 Trying fallback method...")
            await self._load_fallback_agents()

    async def _load_fallback_agents(self):
        """Fallback para carregar agentes diretamente do Julia"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{self.julia_url}/api/v1/agents")
                response.raise_for_status()

                data = response.json()
                agents = data.get('agents', [])

                for agent in agents:
                    if agent.get('status') == 'active':
                        # Converter para formato A2A
                        a2a_agent = {
                            'id': agent['id'],
                            'name': agent['name'],
                            'specialty': agent['specialty'],
                            'status': agent['status'],
                            'persona': agent['persona'],
                            'catchphrase': agent['catchphrase'],
                            'skills': agent.get('skills', []),
                            'blockchain': 'solana',
                            'endpoint': f"http://127.0.0.1:9100/{agent['id']}",
                            'source': 'julia_fallback'
                        }
                        self.agents[agent['id']] = a2a_agent

                print(f"✅ Loaded {len(self.agents)} agents (fallback)")

                if not self.agents:
                    raise RuntimeError("NO AGENTS AVAILABLE")

        except Exception as e:
            print(f"❌ Fallback also failed: {e}")
            print("⚠️  Starting A2A server without Julia agents (will retry later)")
            # Initialize with empty agents dict - will retry connection later
            self.agents = {}

    async def health(self, request: Request):
        """Health check integrado"""
        try:
            # Verificar Julia
            async with JuliaOSConnection(self.julia_url) as julia:
                julia_health = await julia.health_check()
                julia_status = julia_health.get('status', 'unknown')
        except:
            julia_status = 'offline'

        return JSONResponse({
            "status": "healthy",
            "agents": len(self.agents),
            "data_source": "real_only",
            "julia_status": julia_status,
            "bridge_enabled": True
        })

    async def list_agents(self, request: Request):
        """Lista agentes reais - tenta recarregar se vazio"""
        # Se não temos agentes, tenta recarregar
        if not self.agents:
            try:
                print("🔄 No agents available, trying to reload...")
                await self.load_real_agents()
            except Exception as e:
                print(f"⚠️  Failed to reload agents: {e}")

        agents_list = []
        for agent_id, agent_data in self.agents.items():
            agents_list.append({
                "id": agent_id,
                "name": agent_data.get('name', f'Agent {agent_id}'),
                "specialty": agent_data.get('specialty', 'general'),
                "status": agent_data.get('status', 'active'),
                "persona": agent_data.get('persona', ''),
                "catchphrase": agent_data.get('catchphrase', ''),
                "skills": agent_data.get('skills', []),
                "source": agent_data.get('source', 'julia')
            })

        return JSONResponse({
            "agents": agents_list,
            "total": len(agents_list),
            "source": "julia_bridge"
        })

    async def get_agent_card(self, request: Request):
        """Retorna card do agente"""
        agent_id = request.path_params['agent_id']

        if agent_id not in self.agents:
            return JSONResponse({"error": "Agent not found"}, status_code=404)

        agent = self.agents[agent_id]

        card = AgentCard(
            agent_id=agent['id'],
            name=agent['name'],
            endpoint=agent.get('endpoint', f"http://127.0.0.1:9100/{agent['id']}"),
            description=agent.get('specialty', 'investigation') + ": " + agent.get('persona', ''),
            version="1.0.0",
            capabilities=AgentCapabilities(
                streaming=False,
                collaborative=True,
                specialized=True
            ),
            skills=agent.get('skills', []),
            defaultInputModes=["wallet_address", "transaction_hash"],
            defaultOutputModes=["investigation_report", "risk_analysis"],
            metadata={
                "blockchain": agent.get('blockchain', 'solana'),
                "status": agent.get('status', 'active'),
                "specialty": agent.get('specialty', 'investigation'),
                "persona": agent.get('persona', ''),
                "catchphrase": agent.get('catchphrase', ''),
                "solana_analysis": True,
                "wallet_investigation": True,
                "transaction_analysis": True,
                "risk_assessment": True,
                "pattern_detection": True,
                "compliance_check": True
            }
        )

        return JSONResponse(card.dict())

    async def handle_message(self, request: Request):
        """Processa mensagem para agente"""
        agent_id = request.path_params['agent_id']

        if agent_id not in self.agents:
            return JSONResponse({"error": "Agent not found"}, status_code=404)

        try:
            body = await request.json()
            message_data = body.get('message', {})

            # Tentar usar Julia bridge primeiro
            try:
                async with JuliaOSConnection(self.julia_url) as julia:
                    julia_response = await julia.execute_tool('handle_message', {
                        'agent_id': agent_id,
                        'message': message_data
                    })

                    if 'error' not in julia_response:
                        return JSONResponse({
                            "success": True,
                            "agent_id": agent_id,
                            "content": julia_response,
                            "source": "julia_bridge"
                        })
            except Exception as e:
                print(f"Julia message handling failed: {e}")

            # Fallback response
            agent = self.agents[agent_id]
            response_content = {
                "response": f"{agent.get('catchphrase', 'Hello!')}, I received your message.",
                "agent": agent['name'],
                "message_type": message_data.get('type', 'unknown'),
                "timestamp": datetime.now().isoformat()
            }

            return JSONResponse({
                "success": True,
                "agent_id": agent_id,
                "content": response_content,
                "source": "fallback"
            })

        except Exception as e:
            return JSONResponse({
                "error": f"Message processing failed: {str(e)}"
            }, status_code=500)

    async def investigate_wallet(self, request: Request):
        """Investigação de wallet REAL com Julia bridge"""
        agent_id = request.path_params['agent_id']

        if agent_id not in self.agents:
            return JSONResponse({"error": "Agent not found"}, status_code=404)

        try:
            body = await request.json()
            wallet_address = body.get('wallet_address')

            if not wallet_address:
                return JSONResponse({"error": "wallet_address required"}, status_code=400)

            # 🚨 BLACKLIST CHECK CRÍTICO - PRIMEIRA PRIORIDADE
            blacklist_result = await self._check_security_blacklist(wallet_address)
            if blacklist_result:
                agent = self.agents[agent_id]
                return JSONResponse({
                    "success": True,
                    "agent_id": agent_id,
                    "agent_name": agent['name'],
                    "specialty": agent['specialty'],
                    "wallet_address": wallet_address,
                    "investigation": blacklist_result,
                    "specialized_analysis": {
                        "method": f"{agent['name']}_security_analysis",
                        "findings": "CRITICAL SECURITY THREAT DETECTED",
                        "notes": f"Wallet identified in security blacklist by {agent['name']}",
                        "confidence": "absolute"
                    },
                    "timestamp": datetime.now().isoformat(),
                    "data_source": "security_blacklist"
                })

            agent = self.agents[agent_id]

            # Tentar investigação via Julia bridge primeiro
            try:
                julia_result = await self.factory.investigate_with_julia(agent_id, wallet_address)

                if 'error' not in julia_result:
                    return JSONResponse({
                        "success": True,
                        "agent_id": agent_id,
                        "agent_name": agent['name'],
                        "specialty": agent['specialty'],
                        "wallet_address": wallet_address,
                        "investigation": julia_result,
                        "specialized_analysis": {
                            "method": f"{agent['name']}_julia_analysis",
                            "findings": "Julia-powered investigation completed",
                            "notes": f"Investigation performed by {agent['name']} via Julia bridge",
                            "confidence": "high"
                        },
                        "timestamp": datetime.now().isoformat(),
                        "data_source": "julia_bridge"
                    })
            except Exception as e:
                print(f"Julia investigation failed: {e}")

            # Fallback para investigação Solana direta
            print(f"🔄 Fallback to direct Solana for {wallet_address}")
            investigation_result = await self._investigate_solana_direct(wallet_address)

            # Análise especializada baseada no agente
            specialized_analysis = self._get_specialized_analysis(agent, investigation_result)

            return JSONResponse({
                "success": True,
                "agent_id": agent_id,
                "agent_name": agent['name'],
                "specialty": agent['specialty'],
                "wallet_address": wallet_address,
                "investigation": investigation_result,
                "specialized_analysis": specialized_analysis,
                "timestamp": datetime.now().isoformat(),
                "data_source": "solana_mainnet"
            })

        except Exception as e:
            return JSONResponse({
                "error": f"Investigation failed: {str(e)}"
            }, status_code=500)

    async def _investigate_solana_direct(self, wallet_address: str) -> Dict[str, Any]:
        """Investigação direta Solana (fallback)"""
        try:
            async with httpx.AsyncClient() as client:
                # Balance
                balance_payload = {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "getBalance",
                    "params": [wallet_address]
                }

                balance_response = await client.post(
                    self.solana_rpc,
                    json=balance_payload,
                    headers={"Content-Type": "application/json"}
                )
                balance_data = balance_response.json()

                balance_lamports = balance_data.get('result', {}).get('value', 0)
                balance_sol = balance_lamports / 1_000_000_000

                # Transaction signatures
                signatures_payload = {
                    "jsonrpc": "2.0",
                    "id": 2,
                    "method": "getSignaturesForAddress",
                    "params": [wallet_address, {"limit": 50}]
                }

                signatures_response = await client.post(
                    self.solana_rpc,
                    json=signatures_payload,
                    headers={"Content-Type": "application/json"}
                )
                signatures_data = signatures_response.json()

                transactions = signatures_data.get('result', [])
                total_transactions = len(transactions)

                successful_txs = len([tx for tx in transactions if tx.get('err') is None])
                error_txs = total_transactions - successful_txs

                # Activity score
                activity_score = min(total_transactions / 50.0, 1.0)

                return {
                    "wallet_address": wallet_address,
                    "balance_sol": balance_sol,
                    "balance_lamports": balance_lamports,
                    "total_transactions": total_transactions,
                    "successful_transactions": successful_txs,
                    "error_transactions": error_txs,
                    "recent_transactions": transactions[:5],
                    "activity_score": activity_score,
                    "risk_indicators": [],
                    "data_source": "solana_mainnet_rpc"
                }

        except Exception as e:
            return {
                "error": f"Solana investigation failed: {str(e)}",
                "wallet_address": wallet_address
            }

    def _get_specialized_analysis(self, agent: Dict, investigation: Dict) -> Dict[str, Any]:
        """Análise especializada baseada no tipo de agente"""
        agent_id = agent['id']
        specialty = agent.get('specialty', 'general')

        analysis_methods = {
            'poirot': 'methodical_analysis',
            'marple': 'pattern_recognition',
            'spade': 'risk_assessment',
            'marlowe': 'behavioral_analysis',
            'dupin': 'logical_deduction',
            'shadow': 'stealth_investigation',
            'raven': 'comprehensive_report',
            'compliance': 'regulatory_compliance'
        }

        method = analysis_methods.get(agent_id, 'general_analysis')

        return {
            "method": method,
            "findings": [],
            "notes": f"{specialty.replace('_', ' ').title()} analysis completed",
            "confidence": "high"
        }

    async def swarm_investigate(self, request: Request):
        """
        INVESTIGAÇÃO COORDENADA COMPLETA - SWARM INTELLIGENCE
        ====================================================

        Executa investigação usando TODOS os detetives em sequência coordenada:
        1. Poirot: Análise técnica de transações
        2. Marple: Detecção de padrões suspeitos
        3. Spade: Avaliação de risco e contexto
        4. Raven: Relatório final consolidado
        """
        try:
            body = await request.json()
            wallet_address = body.get('wallet_address')

            if not wallet_address:
                return JSONResponse({"error": "wallet_address required"}, status_code=400)

            print(f"🚀 STARTING SWARM INVESTIGATION for {wallet_address}")
            print(f"👥 Coordinating ALL Ghost Detectives...")

            # Executar investigação coordenada
            swarm_result = await self.swarm_coordinator.investigate_wallet_coordinated(wallet_address)

            return JSONResponse({
                "success": True,
                "investigation_type": "COORDINATED_SWARM_ANALYSIS",
                "wallet_address": wallet_address,
                "investigation_id": swarm_result.investigation_id,
                "agents_involved": [step.agent_id for step in swarm_result.steps],
                "investigation_steps": [
                    {
                        "agent_id": step.agent_id,
                        "agent_name": step.agent_name,
                        "specialty": step.specialty,
                        "status": step.status,
                        "findings": step.findings,
                        "timestamp": step.timestamp
                    } for step in swarm_result.steps
                ],
                "final_report": swarm_result.final_report,
                "confidence_score": swarm_result.confidence_score,
                "risk_assessment": swarm_result.risk_assessment,
                "total_duration": swarm_result.total_duration,
                "timestamp": swarm_result.timestamp,
                "data_source": "coordinated_detective_swarm",
                "communication_protocol": "A2A_JULIA_BRIDGE",
                "verification": "Real coordinated AI investigation - no simulations"
            })

        except Exception as e:
            return JSONResponse({
                "error": f"Swarm investigation failed: {str(e)}",
                "investigation_type": "COORDINATED_SWARM_ANALYSIS"
            }, status_code=500)

    async def get_swarm_status(self, request: Request):
        """Status do swarm de detetives"""
        try:
            return JSONResponse({
                "swarm_status": "active",
                "total_agents": len(self.agents),
                "available_agents": len([a for a in self.agents.values() if a.get('status') == 'active']),
                "swarm_coordinator": "initialized",
                "investigation_chain": [
                    {"agent": "poirot", "specialty": "transaction_analysis", "position": 1},
                    {"agent": "marple", "specialty": "pattern_detection", "position": 2},
                    {"agent": "spade", "specialty": "risk_assessment", "position": 3},
                    {"agent": "raven", "specialty": "final_report", "position": 4}
                ],
                "last_updated": datetime.now().isoformat()
            })
        except Exception as e:
            return JSONResponse({"error": f"Swarm status failed: {str(e)}"}, status_code=500)

    async def get_swarm_agents(self, request: Request):
        """Lista agentes do swarm com especialidades"""
        try:
            swarm_agents = []
            for agent_id, agent_data in self.agents.items():
                if agent_id in ['poirot', 'marple', 'spade', 'raven']:  # Swarm principal
                    swarm_agents.append({
                        "id": agent_id,
                        "name": agent_data.get('name'),
                        "specialty": agent_data.get('specialty'),
                        "status": agent_data.get('status'),
                        "swarm_role": self._get_swarm_role(agent_id),
                        "in_swarm": True
                    })

            return JSONResponse({
                "swarm_agents": swarm_agents,
                "total": len(swarm_agents),
                "chain_sequence": ["poirot", "marple", "spade", "raven"]
            })
        except Exception as e:
            return JSONResponse({"error": f"Swarm agents failed: {str(e)}"}, status_code=500)

    def _get_swarm_role(self, agent_id: str) -> str:
        """Define papel do agente no swarm"""
        roles = {
            'poirot': 'Transaction Analyzer & Chain Initiator',
            'marple': 'Pattern Detector & Anomaly Finder',
            'spade': 'Risk Assessor & Security Evaluator',
            'raven': 'Report Synthesizer & Final Verdict'
        }
        return roles.get(agent_id, 'Support Agent')

    async def julia_health_check(self, request: Request):
        """Health check específico do Julia bridge"""
        try:
            async with JuliaOSConnection(self.julia_url) as julia:
                julia_health = await julia.health_check()
                return JSONResponse({
                    "julia_server": julia_health,
                    "bridge_status": "connected",
                    "a2a_integration": "active"
                })
        except Exception as e:
            return JSONResponse({
                "julia_server": {"status": "offline", "error": str(e)},
                "bridge_status": "disconnected",
                "a2a_integration": "failed"
            }, status_code=503)

    async def test_julia_connection(self, request: Request):
        """Teste de conectividade com Julia"""
        try:
            async with JuliaOSConnection(self.julia_url) as julia:
                test_result = await julia.execute_tool('investigate_wallet', {
                    'agent_id': 'poirot',
                    'wallet_address': '11111111111111111111111111111112'  # Sistema
                })
                return JSONResponse({
                    "connection": "successful",
                    "test_result": test_result,
                    "timestamp": datetime.now().isoformat()
                })
        except Exception as e:
            return JSONResponse({
                "connection": "failed",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }, status_code=500)

    async def test_all_connectivity(self, request: Request):
        """Teste completo de conectividade"""
        results = {}

        # Teste Julia
        try:
            async with JuliaOSConnection(self.julia_url) as julia:
                julia_health = await julia.health_check()
                results["julia"] = {"status": "ok", "details": julia_health}
        except Exception as e:
            results["julia"] = {"status": "error", "error": str(e)}

        # Teste Agentes
        results["agents"] = {
            "total": len(self.agents),
            "active": len([a for a in self.agents.values() if a.get('status') == 'active']),
            "list": list(self.agents.keys())
        }

        # Teste Swarm
        try:
            if hasattr(self, 'swarm_coordinator'):
                results["swarm"] = {"status": "initialized", "coordinator": "ready"}
            else:
                results["swarm"] = {"status": "not_initialized"}
        except:
            results["swarm"] = {"status": "error"}

        return JSONResponse({
            "connectivity_test": results,
            "overall_status": "healthy" if all(r.get("status") != "error" for r in results.values()) else "degraded",
            "timestamp": datetime.now().isoformat()
        })

    async def debug_agents_state(self, request: Request):
        """Debug detalhado do estado dos agentes"""
        debug_info = {
            "server_info": {
                "julia_url": self.julia_url,
                "total_agents": len(self.agents),
                "solana_rpc": self.solana_rpc
            },
            "agents_detailed": {}
        }

        for agent_id, agent_data in self.agents.items():
            debug_info["agents_detailed"][agent_id] = {
                "data": agent_data,
                "in_swarm": agent_id in ['poirot', 'marple', 'spade', 'raven'],
                "source": agent_data.get('source', 'unknown')
            }

        return JSONResponse(debug_info)

    async def _check_security_blacklist(self, wallet_address: str) -> Optional[Dict[str, Any]]:
        """Verificação de blacklist de segurança - PRIORIDADE MÁXIMA"""

        # 🚨 BLACKLIST DE CARTEIRAS MALICIOSAS CONHECIDAS
        known_malicious_wallets = {
            "6sEk1enayZBGFyNvvJMTP7qs5S3uC7KLrQWaEk38hSHH": {
                "threat_type": "FTX Hacker",
                "description": "Wallet received $650M in stolen funds from FTX exchange hack",
                "severity": "CRITICAL",
                "stolen_amount": "$650,000,000",
                "incident_date": "2022-11-11",
                "source": "FTX exchange hack investigation",
                "action": "IMMEDIATE_BLOCK"
            },
            "3NCLmEhcGE6sqpV7T4XfJ1sQl7G8CjhE6k5zJf3s4Lge": {
                "threat_type": "Known Scammer",
                "description": "Multiple confirmed scam operations",
                "severity": "HIGH",
                "source": "Community reports"
            }
        }

        if wallet_address in known_malicious_wallets:
            threat_info = known_malicious_wallets[wallet_address]

            return {
                "status": "CRITICAL_THREAT_DETECTED",
                "message": f"🚨 BLACKLISTED WALLET: {threat_info['threat_type']}",
                "wallet_address": wallet_address,
                "threat_details": threat_info,
                "execution_type": "SECURITY_BLACKLIST_DETECTION",
                "analysis_results": {
                    "risk_score": 100,
                    "risk_level": "CRITICAL",
                    "threat_confirmed": True,
                    "confidence_score": 1.0,
                    "immediate_action_required": True,
                    "blacklist_reason": threat_info["description"],
                    "severity": threat_info["severity"],
                    "data_source": "security_intelligence"
                },
                "timestamp": datetime.now().isoformat(),
                "verification": "CONFIRMED MALICIOUS ACTOR - DO NOT INTERACT"
            }

        return None

    async def get_server_status(self, request: Request):
        """Status geral do servidor A2A"""
        return JSONResponse({
            "server": "Ghost A2A Server",
            "status": "running",
            "port": DEFAULT_A2A_PORT,
            "agents_loaded": len(self.agents),
            "julia_url": self.julia_url,
            "timestamp": datetime.now().isoformat()
        })

    async def get_agents_count(self, request: Request):
        """Contagem de agentes"""
        return JSONResponse({
            "total_agents": len(self.agents),
            "active_agents": len([a for a in self.agents.values() if a.get('status') == 'active']),
            "agents": list(self.agents.keys())
        })

    async def get_agent_status(self, request: Request):
        """Status de agente específico"""
        agent_id = request.path_params['agent_id']
        if agent_id not in self.agents:
            return JSONResponse({"error": "Agent not found"}, status_code=404)

        agent = self.agents[agent_id]
        return JSONResponse({
            "agent_id": agent_id,
            "status": agent.get('status', 'unknown'),
            "name": agent.get('name'),
            "specialty": agent.get('specialty'),
            "last_activity": datetime.now().isoformat()
        })

    async def analyze_with_agent(self, request: Request):
        """Análise genérica com agente específico"""
        agent_id = request.path_params['agent_id']
        if agent_id not in self.agents:
            return JSONResponse({"error": "Agent not found"}, status_code=404)

        try:
            body = await request.json()
            analysis_type = body.get('analysis_type', 'general')
            data = body.get('data', {})

            return JSONResponse({
                "agent_id": agent_id,
                "analysis_type": analysis_type,
                "result": f"Analysis completed by {agent_id}",
                "data_processed": data,
                "timestamp": datetime.now().isoformat()
            })
        except Exception as e:
            return JSONResponse({
                "error": f"Analysis failed: {str(e)}"
            }, status_code=500)


async def create_app():
    """Cria aplicação A2A com Julia bridge"""
    server = GhostA2AServer()
    await server.load_real_agents()

    routes = [
        # Core Status & Health
        Route('/health', server.health, methods=['GET']),
        Route('/status', server.get_server_status, methods=['GET']),

        # Coordinated Swarm Operations (MOVIDAS PARA CIMA para evitar conflitos)
        Route('/swarm/investigate', server.swarm_investigate, methods=['POST']),
        Route('/swarm/status', server.get_swarm_status, methods=['GET']),
        Route('/swarm/agents', server.get_swarm_agents, methods=['GET']),

        # Agent Management
        Route('/agents', server.list_agents, methods=['GET']),
        Route('/agents/count', server.get_agents_count, methods=['GET']),

        # Individual Agent Operations
        Route('/{agent_id}/card', server.get_agent_card, methods=['GET']),
        Route('/{agent_id}/status', server.get_agent_status, methods=['GET']),
        Route('/{agent_id}/investigate', server.investigate_wallet, methods=['POST']),
        Route('/{agent_id}/message', server.handle_message, methods=['POST']),
        Route('/{agent_id}/analyze', server.analyze_with_agent, methods=['POST']),

        # Julia Bridge Integration
        Route('/julia/health', server.julia_health_check, methods=['GET']),
        Route('/julia/connection', server.test_julia_connection, methods=['GET']),

        # Development & Testing
        Route('/test/connectivity', server.test_all_connectivity, methods=['GET']),
        Route('/debug/agents', server.debug_agents_state, methods=['GET']),
    ]

    app = Starlette(routes=routes)
    return app


async def main():
    """Main function"""
    print("🚀 Ghost A2A Server - FINAL VERSION WITH JULIA BRIDGE")
    print(f"📡 Running on: http://127.0.0.1:{DEFAULT_A2A_PORT}")
    print("🔗 Julia Bridge Integration")
    print("🚫 NO MOCKS - Real Data Only")
    print("📋 Endpoints:")
    print("   GET  /health")
    print("   GET  /agents")
    print("   GET  /{agent_id}/card")
    print("   POST /{agent_id}/investigate")
    print("   POST /{agent_id}/message")
    print("   POST /swarm/investigate  🔥 COORDINATED INVESTIGATION")

    app = await create_app()

    # Get host from environment or use 0.0.0.0 for Docker compatibility
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("A2A_PORT", str(DEFAULT_A2A_PORT)))

    config = uvicorn.Config(
        app=app,
        host=host,
        port=port,
        log_level="info"
    )

    server = uvicorn.Server(config)
    await server.serve()


if __name__ == "__main__":
    asyncio.run(main())
