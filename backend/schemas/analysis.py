"""
Analysis Schemas

Pydantic models for wallet analysis requests and responses.
"""

from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum


class RiskLevel(str, Enum):
    """Risk level enumeration."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class WalletCluster(BaseModel):
    """Wallet cluster information."""
    wallet_address: str = Field(..., description="Wallet address")
    risk_score: float = Field(..., ge=0.0, le=1.0, description="Risk score (0-1)")
    risk_level: RiskLevel = Field(..., description="Risk level assessment")
    connections: int = Field(..., ge=0, description="Number of connections")
    total_volume_sol: float = Field(..., ge=0.0, description="Total volume in SOL")
    last_activity: Optional[datetime] = Field(None, description="Last transaction timestamp")
    patterns: List[str] = Field(default_factory=list, description="Detected patterns")

    @validator('risk_level', pre=True, always=True)
    @classmethod
    def determine_risk_level(cls, v, values):
        """Automatically determine risk level from risk score."""
        if values and 'risk_score' in values:
            score = values['risk_score']
            if score < 0.3:
                return RiskLevel.LOW
            elif score < 0.7:
                return RiskLevel.MEDIUM
            else:
                return RiskLevel.HIGH
        return v


class TransactionInfo(BaseModel):
    """Transaction information."""
    signature: str = Field(..., description="Transaction signature")
    from_address: str = Field(..., description="Sender address")
    to_address: str = Field(..., description="Recipient address")
    amount_sol: float = Field(..., description="Amount in SOL")
    timestamp: datetime = Field(..., description="Transaction timestamp")
    block_height: int = Field(..., description="Block height")


class AnalysisRequest(BaseModel):
    """Request model for wallet analysis."""
    wallet_address: str = Field(..., description="Solana wallet address to analyze")
    depth: Optional[int] = Field(default=2, ge=1, le=5, description="Analysis depth")
    include_explanation: Optional[bool] = Field(default=True, description="Include AI explanation")
    max_clusters: Optional[int] = Field(default=50, ge=1, le=100, description="Maximum clusters to return")


class AnalysisMetadata(BaseModel):
    """Analysis metadata and statistics with AI insights."""
    analysis_duration_ms: float = Field(..., description="Analysis duration in milliseconds")
    transactions_analyzed: int = Field(..., description="Number of transactions analyzed")
    wallets_scanned: int = Field(..., description="Number of wallets scanned")
    depth_reached: int = Field(..., description="Maximum depth reached")
    patterns_detected: List[str] = Field(default_factory=list, description="All patterns detected")
    ai_insights: Optional[str] = Field(None, description="JuliaOS AI-generated insights")
    analysis_method: Optional[str] = Field(None, description="Analysis method used")


class AnalysisResponse(BaseModel):
    """Response model for wallet analysis."""
    wallet_address: str = Field(..., description="Analyzed wallet address")
    clusters: List[WalletCluster] = Field(..., description="Detected wallet clusters")
    risk_score: float = Field(..., ge=0.0, le=1.0, description="Overall risk score")
    risk_level: RiskLevel = Field(..., description="Overall risk level")
    total_connections: int = Field(..., description="Total number of connections found")
    explanation: Optional[str] = Field(None, description="AI-generated explanation")
    analysis_timestamp: datetime = Field(..., description="When the analysis was performed")
    metadata: AnalysisMetadata = Field(..., description="Analysis metadata")

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class QuickAnalysisResponse(BaseModel):
    """Quick analysis response model."""
    wallet_address: str = Field(..., description="Analyzed wallet address")
    risk_score: float = Field(..., ge=0.0, le=1.0, description="Risk score")
    risk_level: RiskLevel = Field(..., description="Risk level")
    cluster_count: int = Field(..., description="Number of clusters detected")
    total_connections: int = Field(..., description="Total connections")
    analysis_timestamp: datetime = Field(..., description="Analysis timestamp")

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
