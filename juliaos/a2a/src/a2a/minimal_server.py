#!/usr/bin/env python3
"""
A2A Protocol Server - Split Service Version
==========================================

Lightweight A2A server that connects to remote Julia service.
"""

import os
import httpx
import uvicorn
from starlette.applications import Starlette
from starlette.routing import Route
from starlette.responses import JSONResponse

# Configuration
JULIA_HOST = os.getenv("JULIA_HOST", "http://127.0.0.1:8052")

async def health_check(request):
    """Health check with Julia connectivity test"""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            julia_response = await client.get(f"{JULIA_HOST}/health")
            julia_healthy = julia_response.status_code == 200
    except:
        julia_healthy = False

    return JSONResponse({
        "status": "healthy",
        "service": "Ghost A2A Server",
        "version": "1.0.0",
        "julia_connection": "connected" if julia_healthy else "disconnected",
        "julia_host": JULIA_HOST
    })

async def list_agents(request):
    """List agents from Julia server"""
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            julia_response = await client.get(f"{JULIA_HOST}/api/v1/agents")
            if julia_response.status_code == 200:
                julia_data = julia_response.json()
                return JSONResponse({
                    "success": True,
                    "agents": julia_data.get("agents", []),
                    "total": len(julia_data.get("agents", [])),
                    "source": "julia"
                })
    except Exception as e:
        pass

    # Fallback mock response
    return JSONResponse({
        "success": True,
        "agents": [
            {"id": "poirot", "name": "Hercule Poirot", "status": "active", "specialty": "transaction_analysis"},
            {"id": "marple", "name": "Miss Marple", "status": "active", "specialty": "pattern_detection"},
            {"id": "spade", "name": "Sam Spade", "status": "active", "specialty": "risk_assessment"}
        ],
        "total": 3,
        "source": "fallback"
    })

async def investigate_wallet(request):
    """Proxy wallet investigation to Julia server"""
    try:
        wallet_address = request.path_params.get("wallet_address")

        async with httpx.AsyncClient(timeout=30.0) as client:
            julia_response = await client.post(
                f"{JULIA_HOST}/api/v1/investigate",
                json={"wallet_address": wallet_address}
            )
            if julia_response.status_code == 200:
                return JSONResponse(julia_response.json())
    except Exception as e:
        pass

    # Fallback response
    return JSONResponse({
        "success": False,
        "error": "Julia server unavailable",
        "fallback": True
    })

# Create app with A2A routes
app = Starlette(routes=[
    Route("/health", health_check),
    Route("/agents", list_agents),
    Route("/investigate/{wallet_address}", investigate_wallet),
])

if __name__ == "__main__":
    # Get configuration from environment
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("A2A_PORT", "9100"))

    print(f"🚀 Starting A2A Protocol Server")
    print(f"Host: {host}:{port}")
    print(f"Julia Backend: {JULIA_HOST}")
    print("Routes: /health, /agents, /investigate/{wallet_address}")

    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info"
    )
