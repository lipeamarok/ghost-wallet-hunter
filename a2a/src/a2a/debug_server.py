#!/usr/bin/env python3
"""
Debug A2A Server Startup
========================

Script simples para capturar erros de importação e startup.
"""

import sys
import traceback
import os

print("🔍 Debug A2A Server Startup")
print("=" * 40)
print(f"Python version: {sys.version}")
print(f"Python path: {sys.path}")
print(f"Current directory: {os.getcwd()}")
print(f"Environment: {dict(os.environ)}")
print("=" * 40)

try:
    print("📦 Testing basic imports...")
    import uvicorn
    print("✅ uvicorn imported")

    import asyncio
    print("✅ asyncio imported")

    import httpx
    print("✅ httpx imported")

    from starlette.applications import Starlette
    print("✅ starlette imported")

    print("\n📦 Testing relative imports...")
    from .a2a_types import AgentCard
    print("✅ a2a_types imported")

    from .julia_bridge import JuliaOSConnection
    print("✅ julia_bridge imported")

    from .ghost_swarm_coordinator import GhostSwarmCoordinator
    print("✅ ghost_swarm_coordinator imported")

    print("\n🚀 Testing server creation...")
    from .server import create_app, main
    print("✅ server module imported")

    print("\n🚀 Starting main server...")
    asyncio.run(main())

except Exception as e:
    print(f"\n❌ ERROR: {e}")
    print("\n🔍 Full traceback:")
    traceback.print_exc()
    print("\n" + "=" * 40)
    sys.exit(1)
