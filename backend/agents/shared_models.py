"""
Shared models and mock services for JuliaOS agents.

This module contains common classes and mock services used across all agents
to avoid code duplication and import issues.
"""

import asyncio
from typing import Dict, List, Any, Optional
from datetime import datetime


class RiskLevel:
    """Risk level enumeration."""
    def __init__(self, level: str):
        self.level = level.upper()


class WalletCluster:
    """Wallet cluster data structure."""
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)


class AnalysisResult:
    """Analysis result data structure."""
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)


class MockJuliaOSService:
    """Mock JuliaOS service for demonstration purposes."""

    async def initialize_agent(self, agent_name: str, capabilities: List[str]):
        """Initialize an agent with JuliaOS."""
        return f"mock_agent_{agent_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    async def create_agent(self, agent_name: str, agent_type: str, capabilities: List[str]):
        """Create a new agent."""
        return f"agent_{agent_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    async def create_swarm(self, swarm_name: str, coordinator_agent: str, max_agents: int):
        """Create a new swarm."""
        return f"swarm_{swarm_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    async def add_agent_to_swarm(self, swarm_id: str, agent_name: str, agent_role: str):
        """Add agent to swarm."""
        return True

    async def distribute_swarm_tasks(self, swarm_id: str, tasks: Dict):
        """Distribute tasks to swarm agents."""
        return True

    async def agent_use_llm(self, agent_name: str, prompt: str, context: Optional[Dict] = None):
        """Simulate agent.useLLM() call."""
        # Simulate processing delay
        await asyncio.sleep(0.1)

        # Return appropriate response based on prompt content
        if "strategy" in prompt.lower():
            return {
                "optimal_depth": 15,
                "analysis_focus": ["transaction_patterns", "risk_indicators"],
                "recommended_algorithms": ["clustering", "pattern_matching"]
            }
        elif "pattern" in prompt.lower():
            return {
                "patterns": [
                    {"type": "round_amounts", "confidence": 0.8, "instances": 5},
                    {"type": "timing_correlation", "confidence": 0.7, "instances": 3}
                ],
                "confidence": 0.75
            }
        elif "risk" in prompt.lower():
            return {
                "risk_score": 0.6,
                "risk_level": "MEDIUM",
                "key_factors": ["frequent_small_transactions", "round_amounts"],
                "confidence": 0.8
            }
        elif "compliance" in prompt.lower():
            return {
                "compliance_status": "requires_review",
                "aml_flags": ["structuring_pattern"],
                "sanctions_hit": False,
                "confidence": 0.85
            }
        elif "explanation" in prompt.lower():
            return {
                "explanation": "This wallet shows moderate risk patterns with some suspicious transaction clustering behavior."
            }
        elif "consensus" in prompt.lower() or "integrate" in prompt.lower():
            return {
                "consensus": "Multi-agent analysis completed",
                "confidence": 0.82,
                "integrated_assessment": "MEDIUM risk level with enhanced monitoring required"
            }

        return {
            "response": "Analysis completed using autonomous agent intelligence",
            "confidence": 0.8
        }

    async def health_check(self):
        """Check service health."""
        return True


class MockSolanaService:
    """Mock Solana service for demonstration purposes."""

    async def get_wallet_transactions(self, wallet_address: str, limit: int = 10):
        """Get mock transaction data."""
        transactions = []
        for i in range(min(limit, 15)):
            transactions.append({
                "signature": f"mock_tx_{i}_{wallet_address[:8]}",
                "amount": 1000 if i % 3 == 0 else 150.5,  # Some round amounts
                "timestamp": f"2024-{7+i//10:02d}-{15+i:02d}T10:30:00Z",
                "type": "transfer",
                "counterparty": f"wallet_{i % 5}"  # Some repeated counterparties
            })
        return transactions
