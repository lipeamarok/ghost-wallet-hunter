"""
Test suite for False Positive Prevention System
Tests the complete anti-false positive pipeline with real scenarios
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import asyncio
from agents.poirot_agent import PoirotAgent
from agents.shared_models import RiskLevel
from services.false_positive_prevention import fp_prevention_service
from services.whitelist_service import whitelist_service


async def test_false_positive_prevention():
    """Test complete false positive prevention system."""

    print("🛡️ Testing False Positive Prevention System")
    print("=" * 60)

    # Test addresses
    test_cases = [
        {
            "name": "SAMO - Known memecoin",
            "address": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
            "expected_legitimate": True
        },
        {
            "name": "USDC - Major stablecoin",
            "address": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            "expected_legitimate": True
        },
        {
            "name": "SOL - Native token",
            "address": "So11111111111111111111111111111111111111112",
            "expected_legitimate": True
        },
        {
            "name": "Random address",
            "address": "11111111111111111111111111111111111111111",
            "expected_legitimate": False
        }
    ]

    # Test 1: Whitelist Service
    print("\n1️⃣ Testing Whitelist Service:")
    for case in test_cases:
        try:
            legitimacy = await whitelist_service.check_address_legitimacy(case["address"])
            is_legitimate = legitimacy.get("is_legitimate", False)
            confidence = legitimacy.get("confidence", 0.0)

            status = "✅" if is_legitimate == case["expected_legitimate"] else "❌"
            print(f"   {status} {case['name']}: {is_legitimate} (confidence: {confidence:.2f})")

        except Exception as e:
            print(f"   ❌ {case['name']}: Error - {e}")

    # Test 2: False Positive Prevention
    print("\n2️⃣ Testing False Positive Prevention:")
    for case in test_cases:
        try:
            # Simulate high risk detection
            initial_risk_score = 0.8  # High risk initially
            initial_risk_level = RiskLevel.HIGH

            fp_result = await fp_prevention_service.analyze_with_legitimacy_check(
                address=case["address"],
                initial_risk_score=initial_risk_score,
                initial_risk_level=initial_risk_level,
                analysis_context={"test": True}
            )

            final_risk_score = fp_result.get("risk_score", initial_risk_score)
            adjustment_applied = fp_result.get("risk_adjustment_applied", False)

            # Check if risk was adjusted down for legitimate addresses
            expected_adjustment = case["expected_legitimate"] and final_risk_score < initial_risk_score
            actual_adjustment = adjustment_applied and final_risk_score < initial_risk_score

            status = "✅" if (expected_adjustment == actual_adjustment) or not case["expected_legitimate"] else "❌"
            print(f"   {status} {case['name']}: Risk {initial_risk_score:.1f} → {final_risk_score:.1f} (adjusted: {adjustment_applied})")

        except Exception as e:
            print(f"   ❌ {case['name']}: Error - {e}")

    # Test 3: Poirot with False Positive Prevention
    print("\n3️⃣ Testing Poirot Agent with FP Prevention:")
    poirot = PoirotAgent()

    # Test with SAMO (should be detected as legitimate memecoin)
    try:
        samo_address = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"
        result = await poirot.investigate_wallet(samo_address)

        # Check if false positive prevention data is included
        fp_info = getattr(result, 'false_positive_prevention', None)
        risk_level = getattr(result, 'risk_level', 'unknown')

        if fp_info:
            print(f"   ✅ SAMO investigation: Risk level {risk_level}")
            print(f"      📊 FP Prevention applied: {fp_info.get('legitimacy_level', 'unknown')}")
            print(f"      📝 Context: {fp_info.get('legitimacy_info', {}).get('whitelist', {}).get('token_info', {}).get('name', 'Unknown')}")
        else:
            print(f"   ⚠️ SAMO investigation completed but no FP prevention data")

    except Exception as e:
        print(f"   ❌ Poirot test failed: {e}")

    # Test 4: Prevention Statistics
    print("\n4️⃣ False Positive Prevention Statistics:")
    try:
        stats = await fp_prevention_service.get_prevention_stats()
        print(f"   📊 Total checks: {stats.get('total_checks', 0)}")
        print(f"   🛡️ False positives prevented: {stats.get('false_positives_prevented', 0)}")
        print(f"   ⚙️ Risk adjustments made: {stats.get('risk_adjustments_made', 0)}")
        print(f"   ✅ Legitimacy confirmations: {stats.get('legitimacy_confirmations', 0)}")
        print(f"   📈 Prevention rate: {stats.get('prevention_rate', 0):.1f}%")

    except Exception as e:
        print(f"   ❌ Stats error: {e}")

    print("\n🎉 False Positive Prevention Testing Complete!")


if __name__ == "__main__":
    asyncio.run(test_false_positive_prevention())
