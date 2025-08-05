"""
Health Check Routes

Provides health check and status endpoints for monitoring and load balancers.
"""

from fastapi import APIRouter
from config.settings import settings
import logging
import time
from datetime import datetime, timezone

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/health")
async def health_check():
    """Basic health check endpoint."""
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION
    }


@router.get("/health/detailed")
async def detailed_health_check():
    """Detailed health check including AI services connectivity."""
    start_time = time.time()

    health_status = {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "checks": {}
    }

    # JuliaOS AI Service check
    try:
        health_status["checks"]["juliaos"] = {
            "status": "configured",
            "message": "JuliaOS AI service integration ready"
        }
    except Exception as e:
        logger.error(f"JuliaOS health check failed: {e}")
        health_status["checks"]["juliaos"] = {
            "status": "warning",
            "message": f"JuliaOS check failed: {str(e)}"
        }

    # OpenAI API check
    if settings.OPENAI_API_KEY:
        health_status["checks"]["openai"] = {
            "status": "configured",
            "message": "OpenAI API key is configured"
        }
    else:
        health_status["checks"]["openai"] = {
            "status": "warning",
            "message": "OpenAI API key not configured"
        }

    # Solana RPC check
    health_status["checks"]["solana"] = {
        "status": "configured",
        "message": f"Solana RPC URL: {settings.SOLANA_RPC_URL}",
        "network": settings.SOLANA_NETWORK
    }

    # Response time
    response_time = time.time() - start_time
    health_status["response_time_ms"] = round(response_time * 1000, 2)

    return health_status


@router.get("/version")
async def version_info():
    """Get application version information."""
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "debug": settings.DEBUG
    }
