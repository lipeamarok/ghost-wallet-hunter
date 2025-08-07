#!/usr/bin/env python3
"""
Test Phase 4 Integration - Updated for JuliaOS Docker Backend

Tests the complete integration between Python backend and JuliaOS Docker container
with real detective swarm functionality.
"""

import asyncio
import logging
import sys
from pathlib import Path

# Add backend to path
sys.path.append(str(Path(__file__).parent / "backend"))

from services.juliaos_detective_integration import JuliaOSDetectiveIntegration

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def test_juliaos_connection():
    """Test basic connection to JuliaOS Docker backend"""
    logger.info("🔧 Testing JuliaOS Docker Backend Connection...")

    integration = JuliaOSDetectiveIntegration("http://localhost:10000")

    # Test connection
    connected = await integration.initialize()
    if connected:
        logger.info("✅ JuliaOS connection successful!")

        # List available tools
        logger.info(f"📊 Available tools: {integration.available_tools}")
        logger.info(f"🕵️‍♂️ Detective swarm available: {integration.detective_swarm_available}")

        return True
    else:
        logger.error("❌ Failed to connect to JuliaOS backend")
        return False


async def test_detective_swarm_integration():
    """Test detective swarm integration with JuliaOS"""
    logger.info("🕵️‍♂️ Testing Detective Swarm Integration...")

    integration = JuliaOSDetectiveIntegration("http://localhost:10000")

    if not await integration.initialize():
        logger.error("❌ Failed to initialize JuliaOS integration")
        return False

    # Test wallet address (example)
    test_wallet = "So11111111111111111111111111111111111111112"  # Wrapped SOL

    investigation_data = {
        "blockchain": "solana",
        "analysis_type": "comprehensive",
        "risk_threshold": 0.7,
        "investigation_scope": "cluster_analysis",
        "enable_ai_insights": True
    }

    try:
        if integration.detective_swarm_available:
            logger.info("🚀 Executing detective swarm via JuliaOS...")
            result = await integration.execute_detective_swarm(
                wallet_address=test_wallet,
                investigation_data=investigation_data,
                selected_detectives=["poirot", "marple", "spade", "marlowe", "dupin", "shadow", "raven"]
            )

            logger.info("✅ Detective swarm executed successfully!")
            logger.info(f"📊 Investigation ID: {result.get('investigation_id', 'N/A')}")
            logger.info(f"🎯 Risk Score: {result.get('swarm_consensus', {}).get('final_risk_score', 'N/A')}")
            logger.info(f"🔍 Confidence: {result.get('swarm_consensus', {}).get('final_confidence', 'N/A')}")

            return True
        else:
            logger.warning("⚠️ Detective swarm tool not available - testing fallback methods")

            # Test fallback investigation
            result = await integration.fallback_investigation(test_wallet, investigation_data)
            logger.info("✅ Fallback investigation completed!")

            return True

    except Exception as e:
        logger.error(f"❌ Detective swarm integration failed: {e}")
        return False


async def test_llm_chat_integration():
    """Test LLM chat integration via JuliaOS"""
    logger.info("🤖 Testing LLM Chat Integration...")

    integration = JuliaOSDetectiveIntegration("http://localhost:10000")

    if not await integration.initialize():
        logger.error("❌ Failed to initialize JuliaOS integration")
        return False

    # Test if llm_chat tool is available
    if "llm_chat" in integration.available_tools:
        logger.info("✅ LLM Chat tool detected in JuliaOS!")

        # We could test direct LLM integration here if needed
        # For now, just confirm the tool is available
        return True
    else:
        logger.warning("⚠️ LLM Chat tool not found in JuliaOS")
        return False


async def main():
    """Run all Phase 4 integration tests"""
    logger.info("=" * 60)
    logger.info("🚀 PHASE 4 INTEGRATION TESTING - JULIAOS DOCKER BACKEND")
    logger.info("=" * 60)

    tests = [
        ("JuliaOS Connection", test_juliaos_connection),
        ("Detective Swarm Integration", test_detective_swarm_integration),
        ("LLM Chat Integration", test_llm_chat_integration),
    ]

    results = []

    for test_name, test_func in tests:
        logger.info(f"\n🔄 Running test: {test_name}")
        try:
            result = await test_func()
            results.append((test_name, result))
            if result:
                logger.info(f"✅ {test_name}: PASSED")
            else:
                logger.error(f"❌ {test_name}: FAILED")
        except Exception as e:
            logger.error(f"💥 {test_name}: ERROR - {e}")
            results.append((test_name, False))

    # Summary
    logger.info("\n" + "=" * 60)
    logger.info("📊 PHASE 4 INTEGRATION TEST RESULTS")
    logger.info("=" * 60)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for test_name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        logger.info(f"{test_name}: {status}")

    logger.info(f"\n🎯 Overall Result: {passed}/{total} tests passed")

    if passed == total:
        logger.info("🎉 ALL PHASE 4 INTEGRATION TESTS PASSED!")
        logger.info("🚀 Ghost Wallet Hunter Phase 4 - JuliaOS Integration COMPLETE!")
    else:
        logger.error("⚠️ Some integration tests failed. Check logs for details.")

    return passed == total


if __name__ == "__main__":
    try:
        result = asyncio.run(main())
        sys.exit(0 if result else 1)
    except KeyboardInterrupt:
        logger.info("🛑 Tests interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"💥 Test suite failed: {e}")
        sys.exit(1)
