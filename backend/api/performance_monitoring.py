"""
Ghost Wallet Hunter - Performance and JuliaOS Status API

Endpoints para monitoramento de performance e verificação do status do JuliaOS.
"""

from fastapi import APIRouter, HTTPException
from typing import Dict, Any
import logging
from datetime import datetime

from services.performance_service import get_performance_service
from services.juliaos_service import get_juliaos_client, JuliaOSAPIError

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/performance", tags=["Performance Monitoring"])


@router.get("/status")
async def get_performance_status():
    """Get overall system performance status."""
    try:
        perf_service = await get_performance_service()

        # Get performance stats
        cache_stats = perf_service.get_cache_stats()
        performance_report = perf_service.get_performance_report()

        return {
            "status": "operational",
            "timestamp": datetime.now().isoformat(),
            "cache_performance": cache_stats,
            "analysis_performance": performance_report,
            "optimization_status": {
                "cache_enabled": True,
                "parallel_execution": True,
                "performance_monitoring": True
            }
        }

    except Exception as e:
        logger.error(f"Performance status error: {e}")
        raise HTTPException(status_code=500, detail=f"Performance status failed: {e}")


@router.get("/juliaos/status")
async def get_juliaos_status():
    """Check JuliaOS integration status."""
    try:
        logger.info("🔍 Checking JuliaOS status...")

        juliaos_client = await get_juliaos_client()

        # Test JuliaOS connection
        try:
            status_result = await juliaos_client.get_status()

            # Test analysis capability
            test_data = {
                "wallet_address": "test_wallet_123",
                "transactions": [],
                "test": True
            }

            analysis_result = await juliaos_client.analyze_transaction_with_llm(test_data)

            juliaos_status = {
                "connection": "connected",
                "status": status_result.get("status", "unknown"),
                "version": status_result.get("version", "unknown"),
                "message": status_result.get("message", "JuliaOS operational"),
                "analysis_capability": "functional" if "error" not in analysis_result else "limited",
                "last_test": datetime.now().isoformat()
            }

            # Determine if we're using real JuliaOS or fallback
            if analysis_result.get("analysis_method") == "local_fallback":
                juliaos_status["warning"] = "Using fallback analysis - JuliaOS not fully operational"
                juliaos_status["real_juliaos"] = False
            else:
                juliaos_status["real_juliaos"] = True

            logger.info(f"✅ JuliaOS Status: {juliaos_status['connection']} - {juliaos_status['status']}")

        except JuliaOSAPIError as e:
            juliaos_status = {
                "connection": "failed",
                "status": "unavailable",
                "error": str(e),
                "fallback_mode": True,
                "real_juliaos": False,
                "last_test": datetime.now().isoformat(),
                "message": "JuliaOS unavailable - using fallback analysis"
            }

            logger.warning(f"⚠️ JuliaOS unavailable: {e}")

        except Exception as e:
            juliaos_status = {
                "connection": "error",
                "status": "error",
                "error": str(e),
                "real_juliaos": False,
                "last_test": datetime.now().isoformat(),
                "message": "JuliaOS connection error"
            }

            logger.error(f"❌ JuliaOS error: {e}")

        return {
            "juliaos_integration": juliaos_status,
            "recommendations": _generate_juliaos_recommendations(juliaos_status)
        }

    except Exception as e:
        logger.error(f"JuliaOS status check error: {e}")
        raise HTTPException(status_code=500, detail=f"JuliaOS status check failed: {e}")


@router.get("/cache/stats")
async def get_cache_statistics():
    """Get detailed cache performance statistics."""
    try:
        perf_service = await get_performance_service()
        cache_stats = perf_service.get_cache_stats()

        return {
            "cache_statistics": cache_stats,
            "cache_health": "excellent" if cache_stats.get("hit_rate_percent", 0) > 70 else
                           "good" if cache_stats.get("hit_rate_percent", 0) > 50 else "poor",
            "recommendations": _generate_cache_recommendations(cache_stats)
        }

    except Exception as e:
        logger.error(f"Cache stats error: {e}")
        raise HTTPException(status_code=500, detail=f"Cache stats failed: {e}")


@router.post("/cache/cleanup")
async def cleanup_cache():
    """Manually trigger cache cleanup."""
    try:
        perf_service = await get_performance_service()
        cleanup_result = await perf_service.cleanup_cache()

        return {
            "status": "success",
            "cleanup_result": cleanup_result,
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"Cache cleanup error: {e}")
        raise HTTPException(status_code=500, detail=f"Cache cleanup failed: {e}")


@router.get("/analysis/timing")
async def get_analysis_timing_report():
    """Get detailed analysis timing and performance report."""
    try:
        perf_service = await get_performance_service()
        performance_report = perf_service.get_performance_report()

        return {
            "timing_analysis": performance_report,
            "performance_grade": _calculate_performance_grade(performance_report),
            "optimization_suggestions": _generate_optimization_suggestions(performance_report)
        }

    except Exception as e:
        logger.error(f"Timing report error: {e}")
        raise HTTPException(status_code=500, detail=f"Timing report failed: {e}")


@router.get("/health")
async def performance_health_check():
    """Comprehensive performance health check."""
    try:
        perf_service = await get_performance_service()

        # Get all metrics
        cache_stats = perf_service.get_cache_stats()
        performance_report = perf_service.get_performance_report()

        # Check JuliaOS
        juliaos_client = await get_juliaos_client()
        juliaos_status = "unknown"
        try:
            status_result = await juliaos_client.get_status()
            juliaos_status = "operational" if status_result.get("status") != "mock" else "fallback"
        except:
            juliaos_status = "unavailable"

        # Calculate overall health score
        health_score = _calculate_health_score(cache_stats, performance_report, juliaos_status)

        return {
            "overall_health": health_score,
            "components": {
                "cache_system": "healthy" if cache_stats.get("hit_rate_percent", 0) > 40 else "degraded",
                "analysis_performance": "healthy" if performance_report.get("overall_stats", {}).get("avg_time_seconds", 999) < 180 else "degraded",
                "juliaos_integration": juliaos_status
            },
            "system_ready": health_score["score"] > 70,
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"Health check error: {e}")
        raise HTTPException(status_code=500, detail=f"Health check failed: {e}")


def _generate_juliaos_recommendations(status: Dict) -> list:
    """Generate recommendations based on JuliaOS status."""
    recommendations = []

    if not status.get("real_juliaos", False):
        recommendations.append("JuliaOS is not operational - running in fallback mode")
        recommendations.append("Check JuliaOS server configuration and connectivity")
        recommendations.append("Verify JuliaOS API endpoints are accessible")

    if status.get("connection") == "failed":
        recommendations.append("JuliaOS connection failed - check network connectivity")
        recommendations.append("Verify JuliaOS server is running on expected port")

    if status.get("analysis_capability") == "limited":
        recommendations.append("JuliaOS analysis capability is limited")
        recommendations.append("Check JuliaOS AI model configuration")

    if not recommendations:
        recommendations.append("JuliaOS is fully operational - no issues detected")

    return recommendations


def _generate_cache_recommendations(stats: Dict) -> list:
    """Generate cache optimization recommendations."""
    recommendations = []
    hit_rate = stats.get("hit_rate_percent", 0)

    if hit_rate < 30:
        recommendations.append("Cache hit rate is low - consider increasing TTL")
        recommendations.append("Review cache key strategy for better reuse")
    elif hit_rate < 50:
        recommendations.append("Cache performance is moderate - optimize cache keys")
    else:
        recommendations.append("Cache performance is good")

    if stats.get("total_entries", 0) > 1000:
        recommendations.append("Large cache size detected - consider implementing LRU eviction")

    return recommendations


def _generate_optimization_suggestions(report: Dict) -> list:
    """Generate performance optimization suggestions."""
    suggestions = []

    overall_stats = report.get("overall_stats", {})
    avg_time = overall_stats.get("avg_time_seconds", 0)

    if avg_time > 300:  # 5 minutes
        suggestions.append("CRITICAL: Analysis time too high for production use")
        suggestions.append("Implement request timeouts and async processing")
        suggestions.append("Consider breaking down analysis into smaller chunks")
    elif avg_time > 120:  # 2 minutes
        suggestions.append("Analysis time is high - implement more aggressive caching")
        suggestions.append("Optimize database queries and API calls")

    slow_count = overall_stats.get("slow_analyses_count", 0)
    if slow_count > 0:
        suggestions.append(f"Found {slow_count} slow analyses - investigate bottlenecks")

    return suggestions


def _calculate_performance_grade(report: Dict) -> str:
    """Calculate performance grade based on metrics."""
    overall_stats = report.get("overall_stats", {})
    avg_time = overall_stats.get("avg_time_seconds", 999)

    if avg_time < 60:
        return "A"
    elif avg_time < 120:
        return "B"
    elif avg_time < 180:
        return "C"
    elif avg_time < 300:
        return "D"
    else:
        return "F"


def _calculate_health_score(cache_stats: Dict, performance_report: Dict, juliaos_status: str) -> Dict:
    """Calculate overall system health score."""
    score = 0
    max_score = 100

    # Cache health (30 points)
    hit_rate = cache_stats.get("hit_rate_percent", 0)
    cache_score = min(hit_rate / 2, 30)  # Max 30 points
    score += cache_score

    # Performance health (40 points)
    overall_stats = performance_report.get("overall_stats", {})
    avg_time = overall_stats.get("avg_time_seconds", 999)
    if avg_time < 60:
        perf_score = 40
    elif avg_time < 120:
        perf_score = 30
    elif avg_time < 180:
        perf_score = 20
    elif avg_time < 300:
        perf_score = 10
    else:
        perf_score = 0
    score += perf_score

    # JuliaOS health (30 points)
    if juliaos_status == "operational":
        juliaos_score = 30
    elif juliaos_status == "fallback":
        juliaos_score = 15
    else:
        juliaos_score = 0
    score += juliaos_score

    return {
        "score": score,
        "grade": "A" if score > 85 else "B" if score > 70 else "C" if score > 55 else "D" if score > 40 else "F",
        "components": {
            "cache_score": cache_score,
            "performance_score": perf_score,
            "juliaos_score": juliaos_score
        }
    }
