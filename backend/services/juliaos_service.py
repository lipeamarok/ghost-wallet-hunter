"""
JuliaOS Integration Service

This service provides a bridge between the Ghost Wallet Hunter Python backend
and the JuliaOS Julia-based agent system for advanced blockchain analysis.

Uses HTTP client to connect to JuliaOS service at https://juliaos-core.onrender.com
"""

import logging
import asyncio
import httpx
from typing import Dict, List, Optional, Any
from dataclasses import dataclass

# Try relative import first, fallback to absolute
try:
    from ..config.settings import settings
except ImportError:
    # Fallback for direct execution
    import sys
    from pathlib import Path
    sys.path.append(str(Path(__file__).parent.parent))
    from config.settings import settings

logger = logging.getLogger(__name__)

@dataclass
class JuliaOSAgentSummary:
    """Represents a JuliaOS agent summary"""
    id: str
    name: str
    description: str
    state: str
    blueprint: Optional[Dict[str, Any]] = None

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'JuliaOSAgentSummary':
        """Convert dict response to our dataclass"""
        return cls(
            id=data.get('id', ''),
            name=data.get('name', ''),
            description=data.get('description', ''),
            state=data.get('state', 'unknown'),
            blueprint=data.get('blueprint')
        )

@dataclass
class JuliaOSToolSummary:
    """Represents a JuliaOS tool summary"""
    name: str
    description: str

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'JuliaOSToolSummary':
        """Convert dict response to our dataclass"""
        return cls(
            name=data.get('name', ''),
            description=data.get('description', '')
        )

@dataclass
class JuliaOSStrategy:
    """Represents a JuliaOS strategy"""
    name: str

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'JuliaOSStrategy':
        """Convert dict response to our dataclass"""
        return cls(name=data.get('name', ''))

class JuliaOSService:
    """Service for interacting with JuliaOS backend using HTTP client"""

    def __init__(self):
        base_url = settings.get_juliaos_url()
        # Ensure the base URL includes the API prefix
        if not base_url.endswith('/api/v1'):
            base_url = f"{base_url}/api/v1"
        self.base_url = base_url
        self.client = httpx.AsyncClient(timeout=30.0)

    async def close(self):
        """Close HTTP client"""
        await self.client.aclose()

    async def health_check(self) -> bool:
        """Check if JuliaOS backend is healthy"""
        try:
            response = await self.client.get(f"{self.base_url}/health")
            return response.status_code == 200
        except Exception as e:
            logger.error(f"JuliaOS health check failed: {e}")
            return False

    async def list_agents(self) -> List[JuliaOSAgentSummary]:
        """List all agents in JuliaOS"""
        try:
            response = await self.client.get(f"{self.base_url}/agents")
            if response.status_code == 200:
                agents_data = response.json()
                return [
                    JuliaOSAgentSummary.from_dict(agent)
                    for agent in agents_data
                ]
            else:
                logger.error(f"Failed to list agents: {response.status_code}")
                return []
        except Exception as e:
            logger.error(f"Error listing agents: {e}")
            return []

    async def list_tools(self) -> List[JuliaOSToolSummary]:
        """List all available tools in JuliaOS"""
        try:
            response = await self.client.get(f"{self.base_url}/tools")
            if response.status_code == 200:
                tools_data = response.json()
                return [
                    JuliaOSToolSummary.from_dict(tool)
                    for tool in tools_data
                ]
            else:
                logger.error(f"Failed to list tools: {response.status_code}")
                return []
        except Exception as e:
            logger.error(f"Error listing tools: {e}")
            return []

    async def list_strategies(self) -> List[JuliaOSStrategy]:
        """List all available strategies in JuliaOS"""
        try:
            response = await self.client.get(f"{self.base_url}/strategies")
            if response.status_code == 200:
                strategies_data = response.json()
                return [
                    JuliaOSStrategy.from_dict(strategy)
                    for strategy in strategies_data
                ]
            else:
                logger.error(f"Failed to list strategies: {response.status_code}")
                return []
        except Exception as e:
            logger.error(f"Error listing strategies: {e}")
            return []

    async def create_detective_agent(
        self,
        agent_id: str,
        name: str,
        description: str,
        strategy_name: str = "plan_execute",
        tools: Optional[List[str]] = None
    ) -> Optional[JuliaOSAgentSummary]:
        """Create a new detective agent in JuliaOS"""
        try:
            if tools is None:
                tools = ["llm_chat", "scrape_article_text", "ping"]

            payload = {
                "id": agent_id,
                "name": name,
                "description": description,
                "blueprint": {
                    "tools": [{"name": tool, "config": {}} for tool in tools],
                    "strategy": {"name": strategy_name, "config": {}},
                    "trigger": {"type": "webhook", "params": {}}
                }
            }

            response = await self.client.post(
                f"{self.base_url}/agents",
                json=payload
            )

            if response.status_code == 201:
                agent_data = response.json()
                return JuliaOSAgentSummary.from_dict(agent_data)
            else:
                logger.error(f"Failed to create agent: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            logger.error(f"Error creating detective agent: {e}")
            return None

    async def get_agent(self, agent_id: str) -> Optional[JuliaOSAgentSummary]:
        """Get a specific agent by ID"""
        try:
            response = await self.client.get(f"{self.base_url}/agents/{agent_id}")
            if response.status_code == 200:
                agent_data = response.json()
                return JuliaOSAgentSummary.from_dict(agent_data)
            else:
                logger.error(f"Agent {agent_id} not found: {response.status_code}")
                return None
        except Exception as e:
            logger.error(f"Error getting agent: {e}")
            return None

    async def delete_agent(self, agent_id: str) -> bool:
        """Delete an agent"""
        try:
            response = await self.client.delete(f"{self.base_url}/agents/{agent_id}")
            return response.status_code == 204
        except Exception as e:
            logger.error(f"Error deleting agent: {e}")
            return False

    async def trigger_agent_webhook(self, agent_id: str, payload: Dict[str, Any]) -> bool:
        """Trigger an agent via webhook"""
        try:
            response = await self.client.post(
                f"{self.base_url}/agents/{agent_id}/trigger",
                json=payload
            )
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Error triggering agent webhook: {e}")
            return False

    async def get_agent_logs(self, agent_id: str) -> Optional[Dict[str, Any]]:
        """Get agent logs"""
        try:
            response = await self.client.get(f"{self.base_url}/agents/{agent_id}/logs")
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"Failed to get agent logs: {response.status_code}")
                return None
        except Exception as e:
            logger.error(f"Error getting agent logs: {e}")
            return None

    async def get_agent_output(self, agent_id: str) -> Optional[Dict[str, Any]]:
        """Get agent output"""
        try:
            response = await self.client.get(f"{self.base_url}/agents/{agent_id}/output")
            if response.status_code == 200:
                return response.json()
            else:
                # Fallback to logs if output endpoint doesn't exist
                return await self.get_agent_logs(agent_id)
        except Exception as e:
            logger.error(f"Error getting agent output: {e}")
            return None

    async def set_agent_state(self, agent_id: str, state: str) -> bool:
        """Set agent state"""
        try:
            payload = {"state": state}
            response = await self.client.patch(
                f"{self.base_url}/agents/{agent_id}/state",
                json=payload
            )
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Error setting agent state: {e}")
            return False

# Global service instance
_juliaos_service: Optional[JuliaOSService] = None

def get_juliaos_service() -> JuliaOSService:
    """Get or create the global JuliaOS service instance"""
    global _juliaos_service
    if _juliaos_service is None:
        _juliaos_service = JuliaOSService()
    return _juliaos_service

async def cleanup_juliaos_service():
    """Cleanup the global JuliaOS service instance"""
    global _juliaos_service
    if _juliaos_service:
        await _juliaos_service.close()
        _juliaos_service = None
