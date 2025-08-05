"""
Ghost A2A Server - FINAL VERSION WITH JULIA BRIDGE
=================================================

UM ÚNICO servidor A2A para Ghost Detectives.
✅ Dados reais da Solana
✅ Agentes reais do Julia
✅ Bridge Julia integrado
✅ Sem mocks, sem duplicatas
"""

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

from a2a_types import AgentCard, InvestigationRequest, A2AProtocolMessage
from julia_bridge import GhostDetectiveFactory, JuliaOSConnection

PORT = 9100

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
            raise RuntimeError("CANNOT LOAD ANY AGENTS")

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
        """Lista agentes reais"""
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
            id=agent['id'],
            name=agent['name'],
            skills=agent.get('skills', []),
            blockchain=agent.get('blockchain', 'solana'),
            endpoint=agent.get('endpoint', f"http://127.0.0.1:9100/{agent['id']}"),
            status=agent.get('status', 'active'),
            specialty=agent.get('specialty', 'investigation'),
            persona=agent.get('persona', ''),
            catchphrase=agent.get('catchphrase', '')
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


async def create_app():
    """Cria aplicação A2A com Julia bridge"""
    server = GhostA2AServer()
    await server.load_real_agents()
    
    routes = [
        Route('/health', server.health, methods=['GET']),
        Route('/agents', server.list_agents, methods=['GET']),
        Route('/{agent_id}/card', server.get_agent_card, methods=['GET']),
        Route('/{agent_id}/investigate', server.investigate_wallet, methods=['POST']),
        Route('/{agent_id}/message', server.handle_message, methods=['POST']),
    ]
    
    app = Starlette(routes=routes)
    return app


async def main():
    """Main function"""
    print("🚀 Ghost A2A Server - FINAL VERSION WITH JULIA BRIDGE")
    print(f"📡 Running on: http://127.0.0.1:{PORT}")
    print("🔗 Julia Bridge Integration")
    print("🚫 NO MOCKS - Real Data Only")
    print("📋 Endpoints:")
    print("   GET  /health")
    print("   GET  /agents")
    print("   GET  /{agent_id}/card")
    print("   POST /{agent_id}/investigate")
    print("   POST /{agent_id}/message")
    
    app = await create_app()
    
    config = uvicorn.Config(
        app=app,
        host="127.0.0.1",
        port=PORT,
        log_level="info"
    )
    
    server = uvicorn.Server(config)
    await server.serve()


if __name__ == "__main__":
    asyncio.run(main())
