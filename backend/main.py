"""
Ghost Wallet Hunter - Main FastAPI Application

This is the main entry point for the Ghost Wallet Hunter backend API.
It provides endpoints for blockchain analysis, wallet clustering, and AI-powered explanations.
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from contextlib import asynccontextmanager
import logging
import sys
from pathlib import Path

# Add the backend directory to the Python path
sys.path.append(str(Path(__file__).parent))

from config.settings import settings
from api.routes import analysis, health
from utils.logging_config import setup_logging

# Setup logging
setup_logging()
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager for startup and shutdown events."""
    # Startup
    logger.info("Starting Ghost Wallet Hunter backend...")
    logger.info("AI-powered blockchain analysis ready")

    yield

    # Shutdown
    logger.info("Shutting down Ghost Wallet Hunter backend...")
    logger.info("Cleanup completed")


# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    description="AI-powered blockchain analysis tool for detecting suspicious wallet clusters on Solana",
    version=settings.APP_VERSION,
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=False,  # Mudança aqui - não precisamos de credentials
    allow_methods=settings.ALLOWED_METHODS,
    allow_headers=settings.ALLOWED_HEADERS,
    expose_headers=["*"],
)

# Add trusted host middleware for security
if not settings.DEBUG:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=["*.onrender.com", "localhost", "127.0.0.1"]
    )

# Include API routes
app.include_router(health.router, prefix="/api", tags=["health"])
app.include_router(analysis.router, prefix="/api", tags=["analysis"])

# Include JuliaOS Agents routes
try:
    from api.agents import router as agents_router
    app.include_router(agents_router, prefix="/api", tags=["agents"])
    logger.info("[OK] JuliaOS Agents routes registered successfully")
except ImportError as e:
    logger.warning(f"[WARNING] Could not import agents router: {e}")
except Exception as e:
    logger.error(f"[ERROR] Failed to register agents router: {e}")

# Include AI Cost Management routes
try:
    from api.ai_costs import router as ai_costs_router
    app.include_router(ai_costs_router, prefix="/api", tags=["ai-costs"])
    logger.info("[OK] AI Cost Management routes registered successfully")
except ImportError as e:
    logger.warning(f"[WARNING] Could not import AI costs router: {e}")
except Exception as e:
    logger.error(f"[ERROR] Failed to register AI costs router: {e}")

# Include Frontend API routes
try:
    from api.frontend_api import router as frontend_router
    app.include_router(frontend_router, tags=["frontend-api"])
    logger.info("[OK] Frontend API routes registered successfully")
except ImportError as e:
    logger.warning(f"[WARNING] Could not import frontend API router: {e}")
except Exception as e:
    logger.error(f"[ERROR] Failed to register frontend API router: {e}")


@app.get("/")
async def root():
    """Root endpoint with basic application information."""
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "description": "AI-powered blockchain analysis for Solana wallet clustering",
        "status": "operational",
        "docs": "/docs" if settings.DEBUG else None
    }


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler for unhandled errors."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return HTTPException(
        status_code=500,
        detail="Internal server error. Please try again later."
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower()
    )
