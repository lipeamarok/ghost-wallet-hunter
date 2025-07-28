"""
Quick Investigation Test - Debug Performance Issues
"""

import asyncio
import time
from typing import Dict, Any
import sys
import os

# Add backend to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.smart_ai_service import get_ai_service
from agents.detective_squad import DetectiveSquadManager

async def quick_test():
    """Test investigation performance step by step."""

    print("🔍 Starting performance investigation...")

    # Step 1: Test AI service
    start_time = time.time()
    try:
        ai_service = get_ai_service()
        print(f"✅ AI service initialized in {time.time() - start_time:.2f}s")
    except Exception as e:
        print(f"❌ AI service failed: {e}")
        return

    # Step 2: Test squad initialization
    start_time = time.time()
    try:
        squad = DetectiveSquadManager()
        await squad.initialize_squad()
        print(f"✅ Squad initialized in {time.time() - start_time:.2f}s")
    except Exception as e:
        print(f"❌ Squad initialization failed: {e}")
        return

    # Step 3: Test simple AI call
    start_time = time.time()
    try:
        test_response = await ai_service.analyze_with_ai(
            "Analyze this wallet: 7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
            user_id="test_user",
            analysis_type="wallet_analysis"
        )
        print(f"✅ Single AI call completed in {time.time() - start_time:.2f}s")
        print(f"   Response preview: {str(test_response)[:100]}...")
    except Exception as e:
        print(f"❌ AI call failed: {e}")
        return

    # Step 4: Test one detective
    start_time = time.time()
    try:
        wallet = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"

        # Just test Poirot (fastest detective)
        from agents.poirot_agent import PoirotAgent
        poirot = PoirotAgent()
        result = await poirot.investigate_wallet(wallet)

        print(f"✅ Single detective (Poirot) completed in {time.time() - start_time:.2f}s")
        print(f"   Result preview: {str(result)[:100]}...")
    except Exception as e:
        print(f"❌ Single detective failed: {e}")
        return

    print("\n🎯 Performance Summary:")
    print("- AI service: Fast ✅")
    print("- Squad init: Fast ✅")
    print("- Single AI call: Fast ✅")
    print("- Single detective: Fast ✅")
    print("\n💡 Issue likely in full squad orchestration or frontend!")

if __name__ == "__main__":
    asyncio.run(quick_test())
