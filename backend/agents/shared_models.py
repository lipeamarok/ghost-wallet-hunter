"""
Shared models for JuliaOS agents.

This module contains common classes used across all agents
to avoid code duplication and import issues.
Real JuliaOS integration will replace mock services.
"""

import asyncio
from typing import Dict, List, Any, Optional
from datetime import datetime
from enum import Enum
from enum import Enum


class RiskLevel(Enum):
    """Risk level enumeration."""
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

    def __str__(self):
        return self.value

    def __repr__(self):
        return f"RiskLevel.{self.name}"


class WalletCluster:
    """Wallet cluster data structure."""
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)


class AnalysisResult:
    """Analysis result data structure."""
    def __init__(self, **kwargs):
        # Define expected attributes with defaults
        self.wallet_address: str = kwargs.get('wallet_address', '')
        self.clusters: List = kwargs.get('clusters', [])
        self.risk_score: float = kwargs.get('risk_score', 0.0)
        self.risk_level: RiskLevel = kwargs.get('risk_level', RiskLevel.LOW)
        self.total_connections: int = kwargs.get('total_connections', 0)
        self.explanation: str = kwargs.get('explanation', '')
        self.analysis_timestamp: Any = kwargs.get('analysis_timestamp', datetime.now())
        self.false_positive_prevention: Optional[Dict] = kwargs.get('false_positive_prevention', None)

        # Set any additional attributes from kwargs
        for key, value in kwargs.items():
            if not hasattr(self, key):
                setattr(self, key, value)


# Mock services removed - will be replaced by real JuliaOS integration
