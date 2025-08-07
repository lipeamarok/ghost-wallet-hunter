"""
JuliaOS Integration Service - SIMPLIFIED VERSION

This service bridges the Python backend with Julia detective server,
enabling real detective investigations through HTTP API calls.
"""

import asyncio
import logging
import json
import httpx
from typing import Dict, List, Any, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class JuliaOSDetectiveIntegration:
    """
    Simplified integration service that connects Python backend with Julia detective server.
    """

    def __init__(self, julia_url: Optional[str] = None):
        # Use environment variable first, fallback to localhost
        import os
        self.julia_url = (julia_url or
                         os.getenv('JULIAOS_BASE_URL') or
                         os.getenv('JULIA_URL') or
                         "http://localhost:10000").rstrip('/')
        self.client = None
        self.available_detectives = []
        self.is_connected = False

    async def initialize(self) -> bool:
        """Initialize connection to Julia detective server"""
        try:
            if self.client is None:
                self.client = httpx.AsyncClient(timeout=30.0)

            # Test connection using Julia health endpoint
            response = await self.client.get(f"{self.julia_url}/health")
            if response.status_code == 200:
                logger.info("🚀 Julia detective server connection established!")

                # Get available detectives
                await self.refresh_available_detectives()
                self.is_connected = True
                return True
            else:
                logger.warning(f"⚠️ Julia server responded with status {response.status_code}")
                return False

        except Exception as e:
            logger.warning(f"⚠️ Failed to connect to Julia server: {e}")
            return False

    async def refresh_available_detectives(self) -> List[str]:
        """Get list of available detectives from Julia"""
        try:
            if self.client is None:
                self.client = httpx.AsyncClient(timeout=30.0)

            response = await self.client.get(f"{self.julia_url}/api/v1/agents")
            if response.status_code == 200:
                agents_data = response.json()
                self.available_detectives = [agent.get("name", "") for agent in agents_data.get("agents", [])]

                logger.info(f"🕵️ Julia detectives available: {len(self.available_detectives)}")
                return self.available_detectives
            else:
                logger.warning("Failed to fetch detectives from Julia")
                return []

        except Exception as e:
            logger.error(f"Error refreshing Julia detectives: {e}")
            return []

    async def investigate_wallet(self, wallet_address: str, detective_type: str = "poirot") -> Dict:
        """
        Execute wallet investigation using Julia detective server.
        """
        try:
            if not self.is_connected:
                await self.initialize()

            if self.client is None:
                self.client = httpx.AsyncClient(timeout=30.0)

            # Prepare investigation request
            investigation_request = {
                "wallet_address": wallet_address,
                "agent_type": detective_type
            }

            logger.info(f"🕵️‍♂️ Starting Julia investigation: {detective_type} -> {wallet_address}")

            # Execute investigation via Julia API
            response = await self.client.post(
                f"{self.julia_url}/api/v1/investigate",
                json=investigation_request,
                timeout=60.0
            )

            if response.status_code == 200:
                result = response.json()
                logger.info("✅ Julia investigation completed successfully!")

                # Add metadata
                result["integration_method"] = "julia_native"
                result["detective_used"] = detective_type
                result["execution_timestamp"] = datetime.now().isoformat()

                return result
            else:
                logger.error(f"Julia investigation failed with status {response.status_code}")
                return {
                    "error": f"Julia investigation failed: {response.status_code}",
                    "status": "failed",
                    "wallet_address": wallet_address
                }

        except Exception as e:
            logger.error(f"Error executing Julia investigation: {e}")
            return {
                "error": str(e),
                "status": "failed",
                "wallet_address": wallet_address
            }

    async def get_detective_list(self) -> List[Dict[str, Any]]:
        """Get list of available detectives with their capabilities"""
        try:
            if self.client is None:
                self.client = httpx.AsyncClient(timeout=30.0)

            response = await self.client.get(f"{self.julia_url}/api/v1/agents")
            if response.status_code == 200:
                return response.json().get("agents", [])
            else:
                return []
        except Exception as e:
            logger.error(f"Error getting detective list: {e}")
            return []

    async def health_check(self) -> Dict[str, Any]:
        """Check if Julia server is healthy"""
        try:
            if self.client is None:
                self.client = httpx.AsyncClient(timeout=30.0)

            response = await self.client.get(f"{self.julia_url}/health")
            if response.status_code == 200:
                health_data = response.json()
                return {
                    "status": "healthy",
                    "julia_available": True,
                    "detectives_count": len(self.available_detectives),
                    "server_info": health_data
                }
            else:
                return {
                    "status": "unhealthy",
                    "julia_available": False,
                    "error": f"HTTP {response.status_code}"
                }
        except Exception as e:
            return {
                "status": "error",
                "julia_available": False,
                "error": str(e)
            }

    async def close(self):
        """Close the HTTP client"""
        if self.client:
            await self.client.aclose()


# Global instance management
_julia_integration = None

async def get_julia_detective_integration() -> JuliaOSDetectiveIntegration:
    """Get singleton instance of Julia integration"""
    global _julia_integration

    if _julia_integration is None:
        _julia_integration = JuliaOSDetectiveIntegration()
        await _julia_integration.initialize()

    return _julia_integration


async def execute_julia_investigation(wallet_address: str, detective_type: str = "poirot") -> Dict:
    """
    Execute investigation using Julia detective server.

    Args:
        wallet_address: The wallet address to investigate
        detective_type: Detective to use ("poirot", "marple", "spade", etc.)

    Returns:
        Dict containing the investigation results
    """
    try:
        integration = await get_julia_detective_integration()
        return await integration.investigate_wallet(wallet_address, detective_type)

    except Exception as e:
        logger.error(f"Error in Julia investigation: {e}")
        return {
            "error": str(e),
            "status": "failed",
            "wallet_address": wallet_address
        }


async def test_julia_integration() -> Dict:
    """Test the Julia integration"""
    try:
        integration = await get_julia_detective_integration()

        # Test health check
        health = await integration.health_check()

        if health["julia_available"]:
            # Test with sample wallet
            test_result = await integration.investigate_wallet(
                "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
                "poirot"
            )

            return {
                "integration_status": "success",
                "health": health,
                "test_execution": "completed" if "error" not in test_result else "failed",
                "available_detectives": len(integration.available_detectives),
                "test_result": test_result
            }
        else:
            return {
                "integration_status": "failed",
                "health": health,
                "reason": "Julia server not available"
            }

    except Exception as e:
        return {
            "integration_status": "error",
            "error": str(e)
        }
