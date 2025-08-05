#!/usr/bin/env python3
"""
Ghost A2A Server - FASE 4.2 (Simplificado)
============================================

Servidor A2A específico para Ghost Detectives
Expõe todos os detetives via protocolo A2A para comunicação real.

REAL A2A SERVER - Sem mocks, apenas chamadas reais.
"""

import asyncio
import json
import logging
import httpx
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Models para A2A Protocol
class A2AMessage(BaseModel):
    """Mensagem padrão do protocolo A2A"""
    from_agent: str
    to_agent: str
    message_type: str
    content: Dict[str, Any]
    timestamp: str
    message_id: str


class A2AResponse(BaseModel):
    """Resposta padrão do protocolo A2A"""
    success: bool
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    timestamp: str
    agent_id: str


class InvestigationRequest(BaseModel):
    """Request para investigação blockchain"""
    target_wallet: str
    investigation_type: str
    detective_id: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None


class SimpleJuliaOSConnection:
    """Conexão simples com Julia Server"""

    def __init__(self, julia_url: str = "http://127.0.0.1:8052"):
        self.julia_url = julia_url

    async def health_check(self) -> Dict[str, Any]:
        """Verifica se Julia Server está rodando"""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.julia_url}/health")
            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"Health check failed: {response.status_code}")

    async def list_agents(self) -> List[Dict[str, Any]]:
        """Lista todos os agentes"""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.julia_url}/api/v1/agents")
            if response.status_code == 200:
                data = response.json()
                return data.get("agents", [])
            else:
                raise Exception(f"List agents failed: {response.status_code}")

    async def get_agent_details(self, agent_id: str) -> Dict[str, Any]:
        """Obtém detalhes de um agente específico"""
        agents = await self.list_agents()
        for agent in agents:
            if agent.get("id") == agent_id:
                return agent
        raise Exception(f"Agent {agent_id} not found")


class GhostA2AServer:
    """Servidor A2A para Ghost Detectives"""

    def __init__(self, julia_url: str = "http://127.0.0.1:8052"):
        self.julia_url = julia_url
        self.julia_conn = SimpleJuliaOSConnection(julia_url)
        self.active_investigations: Dict[str, Dict[str, Any]] = {}

        # FastAPI app
        self.app = FastAPI(
            title="Ghost Detectives A2A Server",
            description="Agent-to-Agent protocol server for Ghost Detectives",
            version="1.0.0"
        )

        # CORS
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

        self._setup_routes()

    def _setup_routes(self):
        """Configura todas as rotas A2A"""

        @self.app.get("/")
        async def root():
            return {
                "service": "Ghost Detectives A2A Server",
                "version": "1.0.0",
                "status": "active",
                "protocol": "A2A v1.0",
                "julia_backend": self.julia_url,
                "timestamp": datetime.now().isoformat()
            }

        @self.app.get("/health")
        async def health_check():
            """Health check do servidor A2A"""
            try:
                # Verificar conexão com Julia
                julia_health = await self.julia_conn.health_check()
                agents = await self.julia_conn.list_agents()

                return {
                    "status": "healthy",
                    "julia_connection": julia_health["status"],
                    "detectives_count": len(agents),
                    "timestamp": datetime.now().isoformat()
                }
            except Exception as e:
                logger.error(f"Health check failed: {e}")
                raise HTTPException(status_code=503, detail=f"Julia connection failed: {e}")

        @self.app.get("/a2a/agents")
        async def list_agents():
            """Lista todos os agentes disponíveis via A2A"""
            try:
                julia_agents = await self.julia_conn.list_agents()

                agents_list = []
                for agent in julia_agents:
                    agents_list.append({
                        "id": agent["id"],
                        "name": agent["name"],
                        "type": "ghost_detective",
                        "specialty": agent.get("specialty", "investigation"),
                        "status": "active",
                        "a2a_endpoint": f"/a2a/agents/{agent['id']}",
                        "capabilities": agent.get("capabilities", []),
                        "protocol_version": "A2A v1.0"
                    })

                return {
                    "success": True,
                    "agents": agents_list,
                    "total_count": len(agents_list),
                    "timestamp": datetime.now().isoformat()
                }

            except Exception as e:
                logger.error(f"Error listing agents: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.get("/a2a/agents/{agent_id}")
        async def get_agent_details(agent_id: str):
            """Obtém detalhes de um agente específico"""
            try:
                agent = await self.julia_conn.get_agent_details(agent_id)

                return {
                    "success": True,
                    "agent": {
                        "id": agent["id"],
                        "name": agent["name"],
                        "specialty": agent.get("specialty", "investigation"),
                        "persona": agent.get("persona", ""),
                        "catchphrase": agent.get("catchphrase", ""),
                        "capabilities": agent.get("capabilities", []),
                        "tools": agent.get("tools", []),
                        "status": "active",
                        "a2a_protocol": "v1.0",
                        "last_seen": datetime.now().isoformat()
                    },
                    "timestamp": datetime.now().isoformat()
                }

            except Exception as e:
                logger.error(f"Error getting agent {agent_id}: {e}")
                raise HTTPException(status_code=404, detail=f"Agent {agent_id} not found")

        @self.app.post("/a2a/message")
        async def send_a2a_message(message: A2AMessage):
            """Envia mensagem via protocolo A2A"""
            try:
                logger.info(f"A2A Message: {message.from_agent} -> {message.to_agent}")

                # Verificar se o agente de destino existe
                try:
                    target_agent = await self.julia_conn.get_agent_details(message.to_agent)
                except:
                    raise HTTPException(status_code=404, detail=f"Target agent {message.to_agent} not found")

                # Processar mensagem baseado no tipo
                response_data = await self._process_a2a_message(message, target_agent)

                return A2AResponse(
                    success=True,
                    data=response_data,
                    timestamp=datetime.now().isoformat(),
                    agent_id=message.to_agent
                )

            except Exception as e:
                logger.error(f"Error processing A2A message: {e}")
                return A2AResponse(
                    success=False,
                    error=str(e),
                    timestamp=datetime.now().isoformat(),
                    agent_id=message.to_agent
                )

        @self.app.post("/a2a/investigation")
        async def start_investigation(request: InvestigationRequest):
            """Inicia investigação via A2A"""
            try:
                # Selecionar detetive apropriado
                detective_id = request.detective_id or "poirot"  # Default para Poirot

                # Verificar se detetive existe
                detective = await self.julia_conn.get_agent_details(detective_id)

                # Criar investigação
                investigation_id = f"inv_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{detective_id}"

                investigation = {
                    "id": investigation_id,
                    "detective_id": detective_id,
                    "detective_name": detective["name"],
                    "target_wallet": request.target_wallet,
                    "investigation_type": request.investigation_type,
                    "parameters": request.parameters or {},
                    "status": "started",
                    "created_at": datetime.now().isoformat(),
                    "a2a_protocol": "v1.0"
                }

                self.active_investigations[investigation_id] = investigation

                logger.info(f"Started investigation {investigation_id} with {detective_id}")

                return {
                    "success": True,
                    "investigation": investigation,
                    "message": f"Investigation started with {detective['name']}",
                    "timestamp": datetime.now().isoformat()
                }

            except Exception as e:
                logger.error(f"Error starting investigation: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.get("/a2a/investigations")
        async def list_investigations():
            """Lista todas as investigações ativas"""
            return {
                "success": True,
                "investigations": list(self.active_investigations.values()),
                "total_count": len(self.active_investigations),
                "timestamp": datetime.now().isoformat()
            }

        @self.app.get("/a2a/investigations/{investigation_id}")
        async def get_investigation(investigation_id: str):
            """Obtém detalhes de uma investigação específica"""
            if investigation_id not in self.active_investigations:
                raise HTTPException(status_code=404, detail="Investigation not found")

            return {
                "success": True,
                "investigation": self.active_investigations[investigation_id],
                "timestamp": datetime.now().isoformat()
            }

    async def _process_a2a_message(self, message: A2AMessage, target_agent: Dict[str, Any]) -> Dict[str, Any]:
        """Processa mensagem A2A baseado no tipo"""
        message_type = message.message_type

        if message_type == "ping":
            return {"response": "pong", "agent_status": "active"}

        elif message_type == "investigation_request":
            return {
                "response": "investigation_accepted",
                "detective": target_agent["name"],
                "specialty": target_agent.get("specialty", "investigation"),
                "ready": True
            }

        elif message_type == "status_check":
            return {
                "agent_status": "active",
                "agent_name": target_agent["name"],
                "capabilities": target_agent.get("capabilities", []),
                "last_activity": datetime.now().isoformat()
            }

        else:
            return {
                "response": "message_received",
                "message_type": message_type,
                "processed_at": datetime.now().isoformat()
            }

    async def initialize_detectives(self):
        """Inicializa conexão com todos os detetives"""
        logger.info("Initializing Ghost Detectives...")

        try:
            agents = await self.julia_conn.list_agents()
            logger.info(f"Found {len(agents)} detectives:")

            for agent in agents:
                logger.info(f"  🕵️ {agent['name']} ({agent['id']})")

            logger.info("All detectives initialized successfully!")

        except Exception as e:
            logger.error(f"Failed to initialize detectives: {e}")
            raise


# Instância global do servidor
ghost_a2a_server = GhostA2AServer()


async def startup_event():
    """Evento de inicialização do servidor"""
    await ghost_a2a_server.initialize_detectives()


# Configurar evento de startup
ghost_a2a_server.app.add_event_handler("startup", startup_event)


def main():
    """Executa o servidor A2A"""
    print("🚀 Starting Ghost Detectives A2A Server...")
    print("=" * 50)
    print("Protocol: A2A v1.0")
    print("Port: 8003")
    print("Julia Backend: http://127.0.0.1:8052")
    print("=" * 50)

    uvicorn.run(
        "ghost_server_simple:ghost_a2a_server.app",
        host="0.0.0.0",
        port=8003,
        reload=False,
        log_level="info"
    )


if __name__ == "__main__":
    main()
