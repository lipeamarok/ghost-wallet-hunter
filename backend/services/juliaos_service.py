# Ghost Wallet Hunter - JuliaOS Integration
"""
JuliaOS wrapper for Ghost Wallet Hunter.
Provides AI-powered transaction analysis using JuliaOS framework.
"""

import asyncio
import json
from typing import Dict, Any, List, Optional
import structlog
import httpx

logger = structlog.get_logger(__name__)

class JuliaOSAPIError(Exception):
    """Exception raised for JuliaOS API errors."""
    def __init__(self, status_code: int, error_message: str, response_data: Optional[Dict[str, Any]] = None):
        self.status_code = status_code
        self.error_message = error_message
        self.response_data = response_data
        super().__init__(f"JuliaOS API Error {status_code}: {error_message}")

class JuliaOSAgentClient:
    """
    JuliaOS Agent Client for Ghost Wallet Hunter.
    Handles AI-powered transaction analysis using JuliaOS agents.
    """
    
    def __init__(self, base_url: str = "http://localhost:8080/api/v1", timeout: float = 30.0):
        """
        Initialize JuliaOS client.
        
        Args:
            base_url: JuliaOS backend URL
            timeout: Request timeout in seconds
        """
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self._client = httpx.AsyncClient(base_url=self.base_url, timeout=self.timeout)
        
    async def close(self):
        """Close the HTTP client."""
        await self._client.aclose()
        
    async def __aenter__(self):
        """Async context manager entry."""
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self.close()
        
    async def _request(self, method: str, endpoint: str, 
                      params: Optional[Dict[str, Any]] = None, 
                      data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Make HTTP request to JuliaOS API.
        
        Args:
            method: HTTP method
            endpoint: API endpoint
            params: Query parameters
            data: JSON data
            
        Returns:
            API response as dictionary
            
        Raises:
            JuliaOSAPIError: If API request fails
        """
        try:
            url = f"{self.base_url}/{endpoint.lstrip('/')}"
            response = await self._client.request(
                method=method,
                url=url,
                params=params,
                json=data
            )
            response.raise_for_status()
            
            if not response.content:
                return {}
            return response.json()
            
        except httpx.HTTPStatusError as e:
            error_message = f"HTTP error: {e.response.status_code} - {e.response.reason_phrase}"
            response_data = None
            try:
                response_data = e.response.json()
                if "error" in response_data:
                    error_message = response_data["error"]
                elif "message" in response_data:
                    error_message = response_data["message"]
            except:
                pass
            raise JuliaOSAPIError(e.response.status_code, error_message, response_data)
            
        except httpx.RequestError as e:
            raise JuliaOSAPIError(503, f"Request failed: {e}")
            
        except json.JSONDecodeError as e:
            raise JuliaOSAPIError(500, f"Invalid JSON response: {e}")
    
    async def get_status(self) -> Dict[str, Any]:
        """
        Get JuliaOS backend status.
        
        Returns:
            Status information
        """
        try:
            return await self._request("GET", "/status")
        except JuliaOSAPIError:
            # Return mock status if JuliaOS is not available
            logger.warning("JuliaOS backend not available, using mock mode")
            return {
                "status": "mock",
                "message": "JuliaOS running in mock mode",
                "version": "0.1.0"
            }
    
    async def analyze_transaction_with_llm(self, transaction_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze transaction using JuliaOS LLM capabilities.
        
        Args:
            transaction_data: Transaction data to analyze
            
        Returns:
            Analysis results with AI insights
        """
        try:
            analysis_payload = {
                "task": "transaction_analysis",
                "data": transaction_data,
                "analysis_type": "suspicious_pattern_detection",
                "llm_provider": "openai",
                "model": "gpt-4"
            }
            
            result = await self._request("POST", "/agents/analyze", data=analysis_payload)
            return result
            
        except JuliaOSAPIError as e:
            logger.warning(f"JuliaOS analysis failed: {e}, using fallback analysis")
            # Fallback to local analysis
            return await self._fallback_analysis(transaction_data)
    
    async def _fallback_analysis(self, transaction_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Fallback analysis when JuliaOS is unavailable.
        
        Args:
            transaction_data: Transaction data
            
        Returns:
            Basic analysis results
        """
        # Basic pattern detection
        suspicious_patterns = []
        
        amount = transaction_data.get("amount", 0)
        if amount > 1000000:  # Large transaction
            suspicious_patterns.append("large_amount")
            
        # Check for multiple recipients
        if len(transaction_data.get("recipients", [])) > 5:
            suspicious_patterns.append("multiple_recipients")
            
        # Check for round amounts (potential structuring)
        if amount % 10000 == 0:
            suspicious_patterns.append("round_amount")
        
        risk_score = len(suspicious_patterns) * 25
        risk_level = "low"
        if risk_score >= 75:
            risk_level = "high"
        elif risk_score >= 50:
            risk_level = "medium"
            
        return {
            "status": "completed",
            "risk_score": min(risk_score, 100),
            "risk_level": risk_level,
            "suspicious_patterns": suspicious_patterns,
            "ai_insights": "Fallback analysis - JuliaOS unavailable",
            "analysis_method": "local_fallback",
            "timestamp": transaction_data.get("timestamp"),
            "recommendation": f"Transaction flagged as {risk_level} risk based on pattern analysis"
        }
    
    async def create_compliance_agent(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a specialized compliance agent for transaction monitoring.
        
        Args:
            config: Agent configuration
            
        Returns:
            Agent creation result
        """
        try:
            agent_config = {
                "name": "Ghost Wallet Compliance Agent",
                "type": "compliance_monitor",
                "capabilities": [
                    "transaction_analysis",
                    "pattern_detection",
                    "risk_assessment",
                    "regulatory_compliance"
                ],
                "config": config
            }
            
            result = await self._request("POST", "/agents", data=agent_config)
            return result
            
        except JuliaOSAPIError as e:
            logger.warning(f"Agent creation failed: {e}, using mock agent")
            return {
                "agent_id": "mock_compliance_agent_001",
                "status": "created",
                "name": "Ghost Wallet Compliance Agent (Mock)",
                "type": "compliance_monitor",
                "message": "Mock agent created - JuliaOS unavailable"
            }
    
    async def execute_agent_task(self, agent_id: str, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a task using a JuliaOS agent.
        
        Args:
            agent_id: Agent identifier
            task: Task configuration
            
        Returns:
            Task execution result
        """
        try:
            result = await self._request(
                "POST", 
                f"/agents/{agent_id}/tasks", 
                data=task
            )
            return result
            
        except JuliaOSAPIError as e:
            logger.warning(f"Agent task execution failed: {e}")
            return {
                "task_id": f"mock_task_{agent_id}",
                "status": "completed",
                "result": "Mock task execution - JuliaOS unavailable",
                "agent_id": agent_id
            }
    
    async def get_blockchain_insights(self, network: str, address: str) -> Dict[str, Any]:
        """
        Get blockchain insights using JuliaOS blockchain client.
        
        Args:
            network: Blockchain network (e.g., 'solana', 'ethereum')
            address: Wallet address to analyze
            
        Returns:
            Blockchain analysis insights
        """
        try:
            blockchain_data = {
                "network": network,
                "address": address,
                "analysis_depth": "comprehensive"
            }
            
            result = await self._request("POST", "/blockchain/insights", data=blockchain_data)
            return result
            
        except JuliaOSAPIError as e:
            logger.warning(f"Blockchain insights failed: {e}")
            return {
                "network": network,
                "address": address,
                "insights": "Mock insights - JuliaOS unavailable",
                "risk_indicators": [],
                "transaction_patterns": [],
                "compliance_status": "unknown"
            }

# Global JuliaOS client instance
_juliaos_client: Optional[JuliaOSAgentClient] = None

async def get_juliaos_client() -> JuliaOSAgentClient:
    """
    Get or create global JuliaOS client instance.
    
    Returns:
        JuliaOS client instance
    """
    global _juliaos_client
    if _juliaos_client is None:
        _juliaos_client = JuliaOSAgentClient()
    return _juliaos_client

async def close_juliaos_client():
    """Close global JuliaOS client."""
    global _juliaos_client
    if _juliaos_client is not None:
        await _juliaos_client.close()
        _juliaos_client = None
