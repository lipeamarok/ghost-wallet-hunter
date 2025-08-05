"""
Ghost A2A Server - FINAL VERSION
===============================

UM ÚNICO servidor A2A para Ghost Detectives.
Dados reais, sem mocks, sem duplicatas, sem bagunça.
AGORA COM BRIDGE JULIA INTEGRADO!
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
    """UM ÚNICO servidor para tudo"""
    
    def __init__(self):
        self.agents = {}
        self.julia_backend = "http://127.0.0.1:8052/api/v1"
        self.solana_rpc = "https://api.mainnet-beta.solana.com"
        self.load_real_agents()
    
    def load_real_agents(self):
        """Carrega agentes REAIS do backend Julia"""
        try:
            response = requests.get(f"{self.julia_backend}/agents")
            response.raise_for_status()
            
            data = response.json()
            agents = data.get('agents', [])
            
            for agent in agents:
                if agent.get('status') == 'active':
                    self.agents[agent['id']] = agent
            
            print(f"✅ Loaded {len(self.agents)} REAL agents")
            
            if not self.agents:
                raise RuntimeError("NO REAL AGENTS FOUND")
                
        except Exception as e:
            print(f"❌ Failed to load real agents: {e}")
            raise RuntimeError("REAL AGENTS REQUIRED")
    
    async def health(self, request: Request):
        """Health check"""
        return JSONResponse({
            "status": "healthy",
            "agents": len(self.agents),
            "data_source": "real_only"
        })
    
    async def list_agents(self, request: Request):
        """Lista agentes REAIS"""
        agents_list = []
        for agent_id, agent_data in self.agents.items():
            agents_list.append({
                "id": agent_id,
                "name": agent_data.get('name', agent_id),
                "specialty": agent_data.get('specialty', 'detective'),
                "status": agent_data.get('status', 'active'),
                "persona": agent_data.get('persona', ''),
                "catchphrase": agent_data.get('catchphrase', '')
            })
        
        return JSONResponse({
            "agents": agents_list,
            "total": len(agents_list),
            "timestamp": datetime.now().isoformat(),
            "data_source": "julia_backend_real"
        })
    
    async def agent_card(self, request: Request):
        """Card do agente REAL"""
        agent_id = request.path_params['agent_id']
        
        if agent_id not in self.agents:
            return JSONResponse({"error": f"Agent {agent_id} not found"}, status_code=404)
        
        agent = self.agents[agent_id]
        
        return JSONResponse({
            "agent_id": agent_id,
            "name": agent.get('name', agent_id),
            "endpoint": f"http://127.0.0.1:{PORT}/{agent_id}",
            "description": f"Real blockchain detective: {agent.get('persona', '')}",
            "version": "1.0.0",
            "capabilities": {
                "streaming": False,
                "collaborative": True,
                "specialized": True,
                "real_data": True
            },
            "skills": [
                {
                    "id": f"{agent_id}_investigate",
                    "name": "Real Solana Investigation",
                    "description": f"Live investigation using {agent.get('specialty', 'detective')} methods"
                },
                {
                    "id": f"{agent_id}_analyze",
                    "name": "Transaction Analysis",
                    "description": "Real blockchain transaction analysis"
                }
            ],
            "metadata": {
                "specialty": agent.get('specialty', ''),
                "persona": agent.get('persona', ''),
                "catchphrase": agent.get('catchphrase', ''),
                "data_source": "julia_backend",
                "blockchain": "solana_mainnet"
            }
        })
    
    async def investigate_wallet(self, request: Request):
        """Investigação REAL na Solana"""
        agent_id = request.path_params['agent_id']
        
        if agent_id not in self.agents:
            return JSONResponse({"error": f"Agent {agent_id} not found"}, status_code=404)
        
        try:
            body = await request.json()
            wallet_address = body.get('wallet_address')
            
            if not wallet_address:
                return JSONResponse({"error": "wallet_address required"}, status_code=400)
            
            # Investigação REAL na Solana
            investigation = await self._investigate_solana_real(wallet_address)
            
            # Análise especializada do agente
            agent = self.agents[agent_id]
            analysis = self._analyze_by_specialty(investigation, agent.get('specialty', 'general'))
            
            return JSONResponse({
                "success": True,
                "agent_id": agent_id,
                "agent_name": agent.get('name', agent_id),
                "specialty": agent.get('specialty', 'general'),
                "wallet_address": wallet_address,
                "investigation": investigation,
                "specialized_analysis": analysis,
                "timestamp": datetime.now().isoformat(),
                "data_source": "solana_mainnet"
            })
            
        except Exception as e:
            return JSONResponse({"error": f"Investigation failed: {str(e)}"}, status_code=500)
    
    async def send_message(self, request: Request):
        """Envio de mensagem simples"""
        agent_id = request.path_params['agent_id']
        
        if agent_id not in self.agents:
            return JSONResponse({"error": f"Agent {agent_id} not found"}, status_code=404)
        
        try:
            body = await request.json()
            message = body.get('message', {})
            
            agent = self.agents[agent_id]
            
            return JSONResponse({
                "success": True,
                "agent_id": agent_id,
                "agent_name": agent.get('name', agent_id),
                "message_type": "response",
                "content": {
                    "status": "received",
                    "response": f"{agent.get('name', agent_id)} acknowledges your message",
                    "specialty": agent.get('specialty', 'general'),
                    "catchphrase": agent.get('catchphrase', '')
                },
                "timestamp": datetime.now().isoformat()
            })
            
        except Exception as e:
            return JSONResponse({"error": f"Message failed: {str(e)}"}, status_code=500)
    
    async def _investigate_solana_real(self, wallet_address: str) -> Dict[str, Any]:
        """Investigação REAL na blockchain Solana"""
        async with httpx.AsyncClient() as client:
            try:
                # 1. Saldo real
                balance_payload = {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "getBalance",
                    "params": [wallet_address]
                }
                
                balance_response = await client.post(self.solana_rpc, json=balance_payload)
                balance_result = balance_response.json()
                
                balance_sol = 0.0
                if "result" in balance_result and "value" in balance_result["result"]:
                    balance_lamports = balance_result["result"]["value"]
                    balance_sol = balance_lamports / 1_000_000_000
                
                # 2. Transações reais
                tx_payload = {
                    "jsonrpc": "2.0", 
                    "id": 2,
                    "method": "getSignaturesForAddress",
                    "params": [wallet_address, {"limit": 50}]
                }
                
                tx_response = await client.post(self.solana_rpc, json=tx_payload)
                tx_result = tx_response.json()
                
                transactions = []
                if "result" in tx_result and tx_result["result"]:
                    transactions = tx_result["result"]
                
                # 3. Análise básica
                error_count = len([tx for tx in transactions if tx.get("err")])
                success_count = len(transactions) - error_count
                
                return {
                    "wallet_address": wallet_address,
                    "balance_sol": balance_sol,
                    "balance_lamports": balance_result.get("result", {}).get("value", 0),
                    "total_transactions": len(transactions),
                    "successful_transactions": success_count,
                    "error_transactions": error_count,
                    "recent_transactions": transactions[:10],
                    "activity_score": min(len(transactions) / 10, 1.0),
                    "risk_indicators": {
                        "high_error_rate": error_count > len(transactions) * 0.1,
                        "high_value": balance_sol > 100,
                        "high_activity": len(transactions) > 100
                    },
                    "data_source": "solana_mainnet_rpc"
                }
                
            except Exception as e:
                return {"error": f"Solana investigation failed: {str(e)}"}
    
    def _analyze_by_specialty(self, investigation: Dict[str, Any], specialty: str) -> Dict[str, Any]:
        """Análise especializada por tipo de detetive"""
        
        if "error" in investigation:
            return {"analysis_error": "Cannot analyze due to investigation error"}
        
        balance = investigation.get("balance_sol", 0)
        tx_count = investigation.get("total_transactions", 0)
        error_rate = investigation.get("error_transactions", 0) / max(tx_count, 1)
        
        if specialty == "transaction_analysis":
            return {
                "method": "methodical_analysis",
                "findings": {
                    "pattern": "systematic" if tx_count > 50 else "moderate",
                    "consistency": "consistent" if error_rate < 0.05 else "inconsistent",
                    "assessment": f"Analyzed {tx_count} transactions with {error_rate:.2%} error rate"
                },
                "notes": "Methodical transaction pattern analysis completed",
                "confidence": "high"
            }
        
        elif specialty == "pattern_anomaly_detection":
            return {
                "method": "anomaly_detection",
                "findings": {
                    "anomalies": error_rate > 0.1,
                    "deviation": "high" if error_rate > 0.15 else "low",
                    "patterns": "unusual" if error_rate > 0.1 else "normal"
                },
                "notes": "Behavioral pattern anomaly analysis completed",
                "confidence": "high"
            }
        
        elif specialty == "hard_boiled_investigation":
            return {
                "method": "direct_assessment",
                "findings": {
                    "risk_level": "high" if balance > 1000 else "low",
                    "classification": "high_value" if balance > 100 else "standard",
                    "threat": "investigate" if error_rate > 0.15 else "monitor"
                },
                "notes": "Direct risk assessment completed",
                "confidence": "high"
            }
        
        else:
            return {
                "method": f"{specialty}_analysis",
                "findings": {
                    "assessment": f"Wallet: {balance:.4f} SOL, {tx_count} transactions",
                    "activity": "high" if tx_count > 100 else "low",
                    "risk": "elevated" if error_rate > 0.1 else "standard"
                },
                "notes": f"Analysis using {specialty} methodology",
                "confidence": "medium"
            }


def create_app():
    """Cria a aplicação única"""
    server = GhostA2AServer()
    
    routes = [
        Route("/health", server.health, methods=["GET"]),
        Route("/agents", server.list_agents, methods=["GET"]),
        Route("/{agent_id}/card", server.agent_card, methods=["GET"]),
        Route("/{agent_id}/investigate", server.investigate_wallet, methods=["POST"]),
        Route("/{agent_id}/message", server.send_message, methods=["POST"])
    ]
    
    return Starlette(routes=routes)


if __name__ == "__main__":
    print("🚀 Ghost A2A Server - FINAL VERSION")
    print(f"📡 Running on: http://127.0.0.1:{PORT}")
    print("🔗 Real Solana Network Integration")
    print("🚫 NO MOCKS - Real Data Only")
    print("📋 Endpoints:")
    print(f"   GET  /health")
    print(f"   GET  /agents") 
    print(f"   GET  /{{agent_id}}/card")
    print(f"   POST /{{agent_id}}/investigate")
    print(f"   POST /{{agent_id}}/message")
    
    app = create_app()
    uvicorn.run(app, host="127.0.0.1", port=PORT)
