"""
Analysis Routes

Main analysis endpoints for wallet clustering and risk assessment.
"""

from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import logging
from datetime import datetime, UTC

from services.solana_service import SolanaService
from services.analysis_service import AnalysisService
from services.ai_service import AIService
from schemas.analysis import AnalysisRequest, AnalysisResponse, WalletCluster, AnalysisMetadata
from utils.validators import validate_solana_address

logger = logging.getLogger(__name__)
router = APIRouter()


class AnalysisRequestModel(BaseModel):
    """Request model for wallet analysis."""
    wallet_address: str = Field(..., description="Solana wallet address to analyze")
    depth: Optional[int] = Field(default=2, ge=1, le=5, description="Analysis depth (1-5)")
    include_explanation: Optional[bool] = Field(default=True, description="Include AI explanation")


class QuickAnalysisResponse(BaseModel):
    """Quick analysis response model."""
    wallet_address: str
    risk_score: float
    risk_level: str
    cluster_count: int
    total_connections: int
    analysis_timestamp: datetime


@router.post("/analyze", response_model=AnalysisResponse)
async def analyze_wallet(
    request: AnalysisRequestModel,
    background_tasks: BackgroundTasks
):
    """
    Analyze a Solana wallet for suspicious clustering patterns.

    This endpoint performs comprehensive wallet analysis including:
    - Transaction pattern analysis
    - Cluster detection
    - Risk assessment
    - AI-powered explanations
    """
    try:
        # Validate wallet address
        if not validate_solana_address(request.wallet_address):
            raise HTTPException(
                status_code=422,
                detail="Invalid Solana wallet address format"
            )

        logger.info(f"Starting analysis for wallet: {request.wallet_address}")

        # Initialize services
        solana_service = SolanaService()
        analysis_service = AnalysisService()
        ai_service = AIService() if request.include_explanation else None

        # Perform wallet analysis
        analysis_result = await analysis_service.analyze_wallet(
            wallet_address=request.wallet_address,
            depth=request.depth or 2  # Use default depth if None
        )

        # Generate AI explanation if requested
        explanation = None
        if request.include_explanation and ai_service:
            try:
                explanation = await ai_service.generate_explanation(
                    analysis_result=analysis_result,
                    wallet_address=request.wallet_address
                )
            except Exception as e:
                logger.warning(f"Failed to generate AI explanation: {e}")
                explanation = "Analysis completed successfully, but explanation generation failed."

        # Prepare response
        response = AnalysisResponse(
            wallet_address=request.wallet_address,
            clusters=analysis_result.clusters,
            risk_score=analysis_result.risk_score,
            risk_level=analysis_result.risk_level,
            total_connections=analysis_result.total_connections,
            explanation=explanation,
            analysis_timestamp=datetime.now(UTC),
            metadata=analysis_result.metadata or AnalysisMetadata(
                analysis_duration_ms=0.0,
                transactions_analyzed=0,
                wallets_scanned=0,
                depth_reached=1,
                patterns_detected=[],
                ai_insights="JuliaOS analysis unavailable",
                analysis_method="traditional"
            )
        )

        # Log analysis result in background
        background_tasks.add_task(
            log_analysis_result,
            request.wallet_address,
            analysis_result.risk_score
        )

        logger.info(f"Analysis completed for wallet: {request.wallet_address}")
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Analysis failed for wallet {request.wallet_address}: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Analysis failed. Please try again later."
        )


@router.get("/analyze/quick/{wallet_address}", response_model=QuickAnalysisResponse)
async def quick_analyze_wallet(wallet_address: str):
    """
    Perform a quick analysis of a wallet without detailed clustering.
    Useful for real-time risk assessment.
    """
    try:
        if not validate_solana_address(wallet_address):
            raise HTTPException(
                status_code=422,
                detail="Invalid Solana wallet address format"
            )

        # Initialize services
        analysis_service = AnalysisService()

        # Perform quick analysis
        quick_result = await analysis_service.quick_analyze_wallet(wallet_address)

        return QuickAnalysisResponse(
            wallet_address=wallet_address,
            risk_score=quick_result.risk_score,
            risk_level=quick_result.risk_level,
            cluster_count=len(quick_result.clusters),
            total_connections=quick_result.total_connections,
            analysis_timestamp=datetime.now(UTC)
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Quick analysis failed for wallet {wallet_address}: {e}")
        raise HTTPException(
            status_code=500,
            detail="Quick analysis failed. Please try again later."
        )


@router.get("/patterns")
async def get_known_patterns():
    """Get information about known suspicious patterns and detection criteria."""
    return {
        "patterns": {
            "simultaneous_transactions": {
                "description": "Multiple wallets transacting simultaneously",
                "threshold": "3+ mutual transactions within 48 hours",
                "risk_level": "medium"
            },
            "high_frequency_transfers": {
                "description": "Rapid repeated transfers between wallets",
                "threshold": "5+ transfers within 1 hour",
                "risk_level": "high"
            },
            "identical_amounts": {
                "description": "Identical transaction amounts across multiple wallets",
                "threshold": "3+ identical amounts within 24 hours",
                "risk_level": "medium"
            },
            "mixer_connections": {
                "description": "Connections to known mixing services",
                "threshold": "Direct or 1-hop connection to mixer",
                "risk_level": "high"
            }
        },
        "risk_scoring": {
            "low": "0.0 - 0.3",
            "medium": "0.3 - 0.7",
            "high": "0.7 - 1.0"
        }
    }


async def log_analysis_result(wallet_address: str, risk_score: float):
    """Background task to log analysis results for monitoring."""
    try:
        # Log analysis results for monitoring and analytics
        logger.info(f"Analysis completed - Wallet: {wallet_address}, Risk Score: {risk_score:.3f}")

        # In a production environment, this could send metrics to monitoring services
        # or write to a log aggregation service

    except Exception as e:
        logger.error(f"Failed to log analysis result: {e}")
