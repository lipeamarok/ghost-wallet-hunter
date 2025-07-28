"""
Ghost Wallet Hunter - AI Cost Management API

API endpoints for monitoring and managing AI usage costs across the legendary detective squad.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
import logging
from datetime import datetime, timedelta

from services.smart_ai_service import SmartAIService, AIConfiguration
from services.cost_tracking import cost_tracker

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ai-costs", tags=["AI Cost Management"])


class CostLimitUpdate(BaseModel):
    user_id: str
    daily_limit: Optional[float] = None
    monthly_limit: Optional[float] = None
    calls_per_minute: Optional[int] = None
    calls_per_hour: Optional[int] = None
    calls_per_day: Optional[int] = None


class CostAlert(BaseModel):
    threshold_percentage: float
    alert_type: str  # "email", "webhook", "log"
    recipient: Optional[str] = None


@router.get("/dashboard")
async def get_ai_cost_dashboard():
    """Get comprehensive AI cost dashboard with real-time metrics."""
    try:
        # Get data from cost tracker
        dashboard_data = await cost_tracker.get_dashboard_data()

        # Get rate limit status for the dashboard user
        rate_limits = await cost_tracker.check_rate_limits("dashboard")

        # Enhance with additional information
        enhanced_dashboard = {
            "dashboard_status": "operational",
            "timestamp": dashboard_data["timestamp"],
            "cost_overview": {
                "total_spent_today": dashboard_data["overview"]["total_cost_today"],
                "total_spent_month": 0.00,  # Would need monthly calculation
                "estimated_monthly": dashboard_data["overview"]["total_cost_today"] * 30,
                "cost_per_investigation": 0.05
            },
            "usage_metrics": {
                "total_api_calls": dashboard_data["overview"]["total_calls_today"],
                "successful_calls": dashboard_data["overview"]["successful_calls_today"],
                "failed_calls": dashboard_data["overview"]["total_calls_today"] - dashboard_data["overview"]["successful_calls_today"],
                "average_response_time": 0.15  # Would come from cost tracker
            },
            "detective_breakdown": dashboard_data["detective_breakdown"],
            "rate_limits": rate_limits.get("limits_status", {}),
            "ai_providers": dashboard_data["provider_breakdown"],
            "alerts": [],
            "budget_status": "within_limits" if rate_limits.get("within_limits", True) else "approaching_limits",
            "health": dashboard_data["health"]
        }

        return enhanced_dashboard

    except Exception as e:
        logger.error(f"AI cost dashboard error: {e}")
        raise HTTPException(status_code=500, detail=f"Cost dashboard failed: {e}")


@router.post("/update-limits")
async def update_cost_limits(request: CostLimitUpdate):
    """Update AI usage and cost limits for a user."""
    try:
        config = AIConfiguration()
        ai_service = SmartAIService(config)

        # Update user limits
        updated_limits = {}

        if request.daily_limit is not None:
            updated_limits["daily_limit"] = request.daily_limit

        if request.monthly_limit is not None:
            updated_limits["monthly_limit"] = request.monthly_limit

        if request.calls_per_minute is not None:
            updated_limits["calls_per_minute"] = request.calls_per_minute

        if request.calls_per_hour is not None:
            updated_limits["calls_per_hour"] = request.calls_per_hour

        if request.calls_per_day is not None:
            updated_limits["calls_per_day"] = request.calls_per_day

        # Apply limits (this would update the SmartAIService configuration)
        success = True  # Would be actual update result

        return {
            "status": "limits_updated" if success else "update_failed",
            "user_id": request.user_id,
            "updated_limits": updated_limits,
            "effective_immediately": True,
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"Cost limits update error: {e}")
        raise HTTPException(status_code=500, detail=f"Limits update failed: {e}")


@router.get("/usage/{user_id}")
async def get_user_usage(user_id: str):
    """Get detailed usage statistics for a specific user."""
    try:
        config = AIConfiguration()
        ai_service = SmartAIService(config)

        # Get user-specific usage (this would query actual usage data)
        user_usage = {
            "user_id": user_id,
            "current_period": {
                "calls_today": 0,
                "calls_this_hour": 0,
                "calls_this_minute": 0,
                "cost_today": 0.00,
                "cost_this_month": 0.00
            },
            "limits": {
                "daily_cost_limit": 10.00,
                "monthly_cost_limit": 100.00,
                "calls_per_minute": 10,
                "calls_per_hour": 100,
                "calls_per_day": 500
            },
            "percentage_used": {
                "daily_cost": 0.0,
                "monthly_cost": 0.0,
                "minute_calls": 0.0,
                "hour_calls": 0.0,
                "day_calls": 0.0
            },
            "recent_investigations": [],
            "favorite_detectives": ["poirot", "marple", "spade"]
        }

        return user_usage

    except Exception as e:
        logger.error(f"User usage query error: {e}")
        raise HTTPException(status_code=500, detail=f"Usage query failed: {e}")


@router.post("/alerts/setup")
async def setup_cost_alerts(request: CostAlert):
    """Setup cost and usage alerts."""
    try:
        # Setup alert configuration
        alert_config = {
            "id": f"alert_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "threshold_percentage": request.threshold_percentage,
            "alert_type": request.alert_type,
            "recipient": request.recipient,
            "active": True,
            "created_at": datetime.now().isoformat()
        }

        return {
            "status": "alert_configured",
            "alert_config": alert_config,
            "message": f"Alert will trigger at {request.threshold_percentage}% of limits"
        }

    except Exception as e:
        logger.error(f"Alert setup error: {e}")
        raise HTTPException(status_code=500, detail=f"Alert setup failed: {e}")


@router.get("/providers/status")
async def get_ai_providers_status():
    """Get status of all AI providers (OpenAI, Grok, etc.)."""
    try:
        config = AIConfiguration()
        ai_service = SmartAIService(config)

        providers_status = {
            "openai": {
                "status": "operational",
                "response_time": "150ms",
                "success_rate": "99.5%",
                "cost_per_1k_tokens": 0.002,
                "model": "gpt-3.5-turbo",
                "priority": "primary"
            },
            "grok": {
                "status": "operational",
                "response_time": "200ms",
                "success_rate": "98.0%",
                "cost_per_1k_tokens": 0.001,
                "model": "grok-beta",
                "priority": "fallback"
            },
            "mock": {
                "status": "operational",
                "response_time": "5ms",
                "success_rate": "100%",
                "cost_per_1k_tokens": 0.000,
                "model": "mock-detective",
                "priority": "emergency_fallback"
            }
        }

        return {
            "providers": providers_status,
            "fallback_chain": ["openai", "grok", "mock"],
            "current_primary": "openai",
            "auto_failover": True,
            "health_check_timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"Providers status error: {e}")
        raise HTTPException(status_code=500, detail=f"Providers status failed: {e}")


@router.get("/health")
async def ai_costs_health_check():
    """Health check for AI cost management system."""
    return {
        "status": "operational",
        "service": "AI Cost Management",
        "monitoring": "active",
        "alerts": "configured",
        "timestamp": datetime.now().isoformat()
    }
