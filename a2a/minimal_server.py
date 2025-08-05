#!/usr/bin/env python3
"""
MINIMAL A2A SERVER - Emergency Deploy Version
============================================
Standalone server without complex dependencies
"""

import os
import asyncio
import httpx
from datetime import datetime
from starlette.applications import Starlette
from starlette.routing import Route
from starlette.responses import JSONResponse
import uvicorn

# Default configuration
DEFAULT_A2A_PORT = 10000

async def health_check(request):
    """Health check endpoint"""
    return JSONResponse({
        "status": "healthy",
        "service": "a2a-minimal",
        "timestamp": datetime.now().isoformat(),
        "julia_host": os.getenv("JULIA_HOST", "not_configured")
    })

async def investigate_wallet(request):
    """Minimal wallet investigation"""
    try:
        body = await request.json()
        wallet_address = body.get("wallet_address", "unknown")

        # Try to call Julia service
        julia_host = os.getenv("JULIA_HOST", "http://localhost:8052")

        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.post(f"{julia_host}/analyze",
                                           json={"wallet": wallet_address})
                julia_result = response.json()
        except Exception as e:
            julia_result = {"error": str(e), "fallback": True}

        return JSONResponse({
            "wallet_address": wallet_address,
            "investigation_id": f"min_{int(datetime.now().timestamp())}",
            "status": "completed",
            "julia_analysis": julia_result,
            "timestamp": datetime.now().isoformat()
        })

    except Exception as e:
        return JSONResponse({
            "error": str(e),
            "status": "error"
        }, status_code=500)

# Routes
routes = [
    Route("/health", health_check, methods=["GET"]),
    Route("/investigate", investigate_wallet, methods=["POST"]),
]

app = Starlette(routes=routes)

if __name__ == "__main__":
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("A2A_PORT", str(DEFAULT_A2A_PORT)))

    print(f"🚀 Starting Minimal A2A Server on {host}:{port}")
    print(f"🔗 Julia Host: {os.getenv('JULIA_HOST', 'not_configured')}")

    uvicorn.run(app, host=host, port=port)
