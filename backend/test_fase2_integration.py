#!/usr/bin/env python3
"""
Test script for FASE 2 - JuliaOS Integration

Quick test to verify that the Python ↔ JuliaOS connection is working
after the FASE 2 modifications.
"""

import asyncio
import sys
import os

# Add backend to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

async def test_fase_2_integration():
    """Test FASE 2 integration between Python and JuliaOS"""
    print("🧪 TESTE FASE 2: Python ↔ JuliaOS Integration")
    print("=" * 50)

    try:
        # Test 1: Import DetectiveSquadManager
        print("📦 Test 1: Importing DetectiveSquadManager...")
        from agents.detective_squad import DetectiveSquadManager
        print("✅ DetectiveSquadManager imported successfully")

        # Test 2: Create squad instance
        print("\n🕵️ Test 2: Creating DetectiveSquadManager instance...")
        squad = DetectiveSquadManager()
        print("✅ DetectiveSquadManager instance created")

        # Test 3: Check JuliaOS availability
        print("\n🔗 Test 3: Checking JuliaOS availability...")
        juliaos_available = await squad.check_juliaos_availability()

        if juliaos_available:
            print("✅ JuliaOS is available and agents were created!")
            print(f"🎯 JuliaOS agents created: {len(squad.juliaos_agents)}")

            # Test 4: List created agents
            if squad.juliaos_agents:
                print("\n👥 Created JuliaOS Agents:")
                for agent_id, agent in squad.juliaos_agents.items():
                    print(f"  • {agent_id}: {agent.name}")
        else:
            print("⚠️ JuliaOS not available - using Python fallback mode")

        # Test 5: Test JuliaOS service directly
        print("\n🔧 Test 5: Testing JuliaOS service directly...")
        from services.juliaos_service import get_juliaos_service

        juliaos_service = get_juliaos_service()
        health = await juliaos_service.health_check()
        print(f"JuliaOS Health: {'✅ OK' if health else '❌ FAILED'}")

        if health:
            # List tools
            tools = await juliaos_service.list_tools()
            print(f"📊 JuliaOS Tools available: {len(tools)}")

            # List strategies
            strategies = await juliaos_service.list_strategies()
            print(f"🧠 JuliaOS Strategies available: {len(strategies)}")

            # List agents
            agents = await juliaos_service.list_agents()
            print(f"🕵️ JuliaOS Agents: {len(agents)}")

        print("\n" + "=" * 50)
        print("🎯 FASE 2 Integration Test Complete!")

        return juliaos_available

    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    result = asyncio.run(test_fase_2_integration())
    sys.exit(0 if result else 1)
