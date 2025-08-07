"""
JuliaOS Integration Service for Ghost Wallet Hunter Detective Squad

This service bridges the Python detective squad with JuliaOS backend,
enabling real swarm intelligence and enhanced performance through
the JuliaOS agent framework.
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
    Integration service that connects Python detective squad with JuliaOS backend
    for enhanced swarm intelligence and parallel processing capabilities.
    """

    def __init__(self, juliaos_url: str = "http://localhost:10000"):
        self.juliaos_url = juliaos_url
        self.client = None
        self.available_tools = []
        self.detective_swarm_available = False

    async def initialize(self) -> bool:
        """Initialize connection to JuliaOS backend"""
        try:
            self.client = httpx.AsyncClient(timeout=30.0)

            # Test connection using JuliaOS health endpoint
            response = await self.client.get(f"{self.juliaos_url}/health")
            if response.status_code == 200:
                logger.info("🚀 JuliaOS backend connection established!")

                # Check available tools
                await self.refresh_available_tools()
                return True
            else:
                logger.warning(f"⚠️ JuliaOS backend responded with status {response.status_code}")
                return False

        except Exception as e:
            logger.warning(f"⚠️ Failed to connect to JuliaOS backend: {e}")
            return False

    async def refresh_available_tools(self) -> List[str]:
        """Refresh list of available detectives from Julia"""
        try:
            response = await self.client.get(f"{self.juliaos_url}/api/v1/agents")
            if response.status_code == 200:
                agents_data = response.json()
                self.available_tools = [agent.get("name", "") for agent in agents_data.get("agents", [])]

                # All detectives are available if Julia is responding
                self.detective_swarm_available = len(self.available_tools) > 0

                logger.info(f"�️ Julia detectives available: {len(self.available_tools)}")
                if self.detective_swarm_available:
                    logger.info("🕵️‍♂️ Detective squad ready for investigations!")

                return self.available_tools
            else:
                logger.warning("Failed to fetch detectives from Julia")
                return []

        except Exception as e:
            logger.error(f"Error refreshing JuliaOS tools: {e}")
            return []

    async def execute_detective_swarm(self, wallet_address: str, investigation_data: Dict, selected_detectives: List[str] = None) -> Dict:
        """
        Execute detective investigation using Julia server.
        This provides enhanced performance and real detective analysis.
        """
        try:
            if not self.detective_swarm_available:
                raise Exception("Detective squad not available in Julia server")

            # Prepare investigation request for Julia
            investigation_request = {
                "wallet_address": wallet_address,
                "agent_type": selected_detectives[0] if selected_detectives else "poirot",
                "investigation_data": investigation_data
            }

            logger.info(f"🕵️‍♂️ Starting Julia detective investigation for {wallet_address}")

            # Execute investigation via Julia API
            response = await self.client.post(
                f"{self.juliaos_url}/api/v1/investigate",
                json=investigation_request,
                timeout=60.0
            )

            if response.status_code == 200:
                result = response.json()
                logger.info("✅ Julia detective investigation completed successfully!")

                # Enhance result with metadata
                result["integration_method"] = "julia_native"
                result["performance_mode"] = "enhanced"
                result["execution_timestamp"] = datetime.now().isoformat()

                return result
            else:
                logger.error(f"Julia detective investigation failed with status {response.status_code}")
                return {"error": f"Julia execution failed: {response.status_code}", "status": "failed"}

        except Exception as e:
            logger.error(f"Error executing Julia detective investigation: {e}")
            return {"error": str(e), "status": "failed"}

    async def execute_individual_detective(self, detective_type: str, wallet_address: str, investigation_data: Dict) -> Dict:
        """Execute individual detective analysis via Julia"""
        try:
            config = {
                "wallet_address": wallet_address,
                "agent_type": detective_type,
                "investigation_data": investigation_data
            }

            response = await self.client.post(
                f"{self.juliaos_url}/api/v1/investigate",
                json=config,
                timeout=30.0
            )

            if response.status_code == 200:
                return response.json()
            else:
                return {"error": f"Detective execution failed: {response.status_code}", "status": "failed"}

        except Exception as e:
            logger.error(f"Error executing individual detective {detective_type}: {e}")
            return {"error": str(e), "status": "failed"}

    async def execute_ghost_wallet_strategy(self, wallet_address: str) -> Dict:
        """
        Execute Ghost Wallet Hunter investigation strategy via Julia.
        Uses the main investigation endpoint.
        """
        try:
            strategy_config = {
                "wallet_address": wallet_address,
                "agent_type": "comprehensive",  # Use comprehensive analysis
                "investigation_data": {
                    "investigation_depth": "comprehensive",
                    "enable_ai_analysis": True,
                    "detective_squad": ["poirot", "marple", "spade", "marlowe", "dupin", "shadow", "raven"],
                    "max_connections": 50,
                    "risk_threshold": 0.7
                }
            }

            logger.info(f"🎯 Executing Ghost Wallet Hunter strategy for {wallet_address}")

            response = await self.client.post(
                f"{self.juliaos_url}/api/v1/investigate",
                json=strategy_config,
                timeout=120.0
            )

            if response.status_code == 200:
                result = response.json()
                logger.info("✅ Ghost Wallet Hunter strategy completed successfully!")
                return result
            else:
                logger.error(f"Strategy execution failed with status {response.status_code}")
                return {"error": f"Strategy failed: {response.status_code}", "status": "failed"}

        except Exception as e:
            logger.error(f"Error executing Ghost Wallet Hunter strategy: {e}")
            return {"error": str(e), "status": "failed"}

    async def execute_fallback_investigation(self, wallet_address: str) -> Dict:
        """
        Fallback investigation using individual tools when strategy is not available.
        """
        try:
            logger.info("🔄 Executing fallback investigation using individual tools")

            investigation_data = {}

            # Step 1: Wallet analysis
            if "analyze_wallet" in self.available_tools:
                wallet_config = {"wallet_address": wallet_address}
                response = await self.client.post(
                    f"{self.juliaos_url}/tools/analyze_wallet/execute",
                    json=wallet_config,
                    timeout=30.0
                )
                if response.status_code == 200:
                    investigation_data["wallet_analysis"] = response.json()

            # Step 2: Blacklist check
            if "check_blacklist" in self.available_tools:
                blacklist_config = {"wallet_address": wallet_address}
                response = await self.client.post(
                    f"{self.juliaos_url}/tools/check_blacklist/execute",
                    json=blacklist_config,
                    timeout=15.0
                )
                if response.status_code == 200:
                    investigation_data["blacklist_status"] = response.json()

            # Step 3: Risk assessment
            if "risk_assessment" in self.available_tools:
                risk_config = {"wallet_address": wallet_address}
                response = await self.client.post(
                    f"{self.juliaos_url}/tools/risk_assessment/execute",
                    json=risk_config,
                    timeout=30.0
                )
                if response.status_code == 200:
                    investigation_data["risk_assessment"] = response.json()

            # Step 4: Detective swarm (if available)
            if self.detective_swarm_available:
                swarm_result = await self.execute_detective_swarm(wallet_address, investigation_data)
                investigation_data["detective_swarm"] = swarm_result

            return {
                "wallet_address": wallet_address,
                "investigation_method": "fallback_individual_tools",
                "investigation_data": investigation_data,
                "status": "completed",
                "timestamp": datetime.now().isoformat()
            }

        except Exception as e:
            logger.error(f"Error in fallback investigation: {e}")
            return {"error": str(e), "status": "failed"}

    async def get_available_detectives(self) -> List[Dict]:
        """Get list of available detectives from JuliaOS"""
        try:
            if not self.detective_swarm_available:
                return []

            # This would ideally query the detective registry
            # For now, return the standard squad
            detectives = [
                {"id": "poirot", "name": "Hercule Poirot", "specialty": "Transaction Analysis & Behavioral Patterns"},
                {"id": "marple", "name": "Miss Jane Marple", "specialty": "Pattern & Anomaly Detection"},
                {"id": "spade", "name": "Sam Spade", "specialty": "Risk Assessment & Threat Classification"},
                {"id": "marlowe", "name": "Philip Marlowe", "specialty": "Bridge & Mixer Tracking"},
                {"id": "dupin", "name": "Auguste Dupin", "specialty": "Compliance & AML Analysis"},
                {"id": "shadow", "name": "The Shadow", "specialty": "Network Cluster Analysis"},
                {"id": "raven", "name": "Raven", "specialty": "LLM Explanation & Communication"}
            ]

            return detectives

        except Exception as e:
            logger.error(f"Error getting available detectives: {e}")
            return []

    async def health_check(self) -> Dict:
        """Check health of JuliaOS integration"""
        try:
            if not self.client:
                return {"status": "not_initialized", "available": False}

            response = await self.client.get(f"{self.juliaos_url}/health")

            if response.status_code == 200:
                health_data = response.json()
                return {
                    "status": "healthy",
                    "available": True,
                    "juliaos_status": health_data,
                    "available_tools": len(self.available_tools),
                    "detective_swarm_available": self.detective_swarm_available
                }
            else:
                return {"status": "unhealthy", "available": False, "status_code": response.status_code}

        except Exception as e:
            return {"status": "error", "available": False, "error": str(e)}

    async def close(self):
        """Close the HTTP client"""
        if self.client:
            await self.client.aclose()


# Singleton instance for the integration service
_juliaos_integration = None


async def get_juliaos_detective_integration() -> JuliaOSDetectiveIntegration:
    """Get or create the JuliaOS detective integration singleton"""
    global _juliaos_integration

    if _juliaos_integration is None:
        _juliaos_integration = JuliaOSDetectiveIntegration()
        await _juliaos_integration.initialize()

    return _juliaos_integration


async def execute_enhanced_investigation(wallet_address: str, use_swarm: bool = True) -> Dict:
    """
    Execute enhanced investigation using JuliaOS integration.

    Args:
        wallet_address: The wallet address to investigate
        use_swarm: Whether to use swarm intelligence (True) or individual analysis (False)

    Returns:
        Dict containing the investigation results
    """
    try:
        integration = await get_juliaos_detective_integration()

        if use_swarm and integration.detective_swarm_available:
            logger.info("🚀 Using JuliaOS swarm intelligence for enhanced investigation")
            return await integration.execute_ghost_wallet_strategy(wallet_address)
        else:
            logger.info("🔄 Using fallback investigation method")
            return await integration.execute_fallback_investigation(wallet_address)

    except Exception as e:
        logger.error(f"Error in enhanced investigation: {e}")
        return {
            "error": str(e),
            "status": "failed",
            "fallback_recommended": True
        }


# Integration testing functions
async def test_juliaos_integration() -> Dict:
    """Test the JuliaOS integration"""
    try:
        integration = await get_juliaos_detective_integration()
        health = await integration.health_check()

        if health["available"]:
            # Test with a sample wallet
            test_result = await integration.execute_enhanced_investigation(
                "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
            )

            return {
                "integration_status": "success",
                "health": health,
                "test_execution": "completed" if "error" not in test_result else "failed",
                "available_detectives": len(await integration.get_available_detectives())
            }
        else:
            return {
                "integration_status": "failed",
                "health": health,
                "reason": "JuliaOS backend not available"
            }

    except Exception as e:
        return {
            "integration_status": "error",
            "error": str(e)
        }
