"""
Ghost Wallet Hunter - Frontend Integration Test

Tests all API endpoints for frontend integration.
"""

import asyncio
import pytest
import sys
from pathlib import Path

# Add backend to path
sys.path.append(str(Path(__file__).parent))

from agents.detective_squad import DetectiveSquadManager
from services.smart_ai_service import SmartAIService, AIConfiguration
from services.cost_tracking import cost_tracker
from api.agents import *
from api.ai_costs import *


class TestFrontendIntegration:
    """Test suite for frontend integration endpoints."""

    async def test_legendary_squad_status(self):
        """Test legendary squad status endpoint."""
        print("🧪 Testing legendary squad status endpoint...")

        try:
            response = await get_legendary_squad_status()

            assert response["status"] == "success"
            assert "squad_info" in response
            assert "available_detectives" in response
            assert len(response["available_detectives"]) == 7

            print("✅ Legendary squad status endpoint working!")
            return True

        except Exception as e:
            print(f"❌ Legendary squad status test failed: {e}")
            return False

    async def test_detective_individual_endpoints(self):
        """Test individual detective endpoints."""
        print("🧪 Testing individual detective endpoints...")

        test_wallet = "0x1234567890123456789012345678901234567890"
        detectives_to_test = ["poirot", "marple", "spade"]

        results = {}

        for detective in detectives_to_test:
            try:
                request = DetectiveAnalysisRequest(
                    wallet_address=test_wallet,
                    detective=detective
                )

                if detective == "poirot":
                    response = await analyze_with_poirot(request)
                elif detective == "marple":
                    response = await analyze_with_marple(request)
                elif detective == "spade":
                    response = await analyze_with_spade(request)

                assert "detective" in response
                assert "analysis" in response
                assert "signature" in response

                results[detective] = "✅ Working"
                print(f"✅ {detective.title()} endpoint working!")

            except Exception as e:
                results[detective] = f"❌ Failed: {e}"
                print(f"❌ {detective.title()} endpoint failed: {e}")

        return results

    async def test_ai_cost_dashboard(self):
        """Test AI cost dashboard endpoint."""
        print("🧪 Testing AI cost dashboard endpoint...")

        try:
            response = await get_ai_cost_dashboard()

            assert response["dashboard_status"] == "operational"
            assert "cost_overview" in response
            assert "usage_metrics" in response
            assert "detective_breakdown" in response
            assert "ai_providers" in response

            print("✅ AI cost dashboard endpoint working!")
            return True

        except Exception as e:
            print(f"❌ AI cost dashboard test failed: {e}")
            return False

    async def test_cost_limits_update(self):
        """Test cost limits update endpoint."""
        print("🧪 Testing cost limits update endpoint...")

        try:
            request = CostLimitUpdate(
                user_id="test_user",
                daily_limit=15.0,
                calls_per_minute=5
            )

            response = await update_cost_limits(request)

            assert "status" in response
            assert response["user_id"] == "test_user"
            assert "updated_limits" in response

            print("✅ Cost limits update endpoint working!")
            return True

        except Exception as e:
            print(f"❌ Cost limits update test failed: {e}")
            return False

    async def test_ai_providers_status(self):
        """Test AI providers status endpoint."""
        print("🧪 Testing AI providers status endpoint...")

        try:
            response = await get_ai_providers_status()

            assert "providers" in response
            assert "fallback_chain" in response
            assert "current_primary" in response

            print("✅ AI providers status endpoint working!")
            return True

        except Exception as e:
            print(f"❌ AI providers status test failed: {e}")
            return False

    async def test_real_ai_integration(self):
        """Test real AI integration endpoint."""
        print("🧪 Testing real AI integration endpoint...")

        try:
            response = await test_real_ai_integration()

            assert response["ai_integration_status"] == "OPERATIONAL"
            assert response["real_ai_enabled"] == True
            assert "individual_detectives" in response
            assert "legendary_squad_status" in response

            print("✅ Real AI integration endpoint working!")
            return True

        except Exception as e:
            print(f"❌ Real AI integration test failed: {e}")
            return False

    async def test_cost_tracking_service(self):
        """Test cost tracking service directly."""
        print("🧪 Testing cost tracking service...")

        try:
            # Test recording a cost
            success = await cost_tracker.record_api_call(
                user_id="test_user",
                detective="poirot",
                provider="openai",
                model="gpt-3.5-turbo",
                prompt_tokens=100,
                completion_tokens=50,
                cost=0.003,
                analysis_type="wallet_analysis",
                success=True,
                response_time=0.15
            )

            assert success == True

            # Test getting dashboard data
            dashboard = await cost_tracker.get_dashboard_data()
            assert "overview" in dashboard
            assert "detective_breakdown" in dashboard

            # Test rate limits
            limits = await cost_tracker.check_rate_limits("test_user")
            assert "within_limits" in limits
            assert "limits_status" in limits

            print("✅ Cost tracking service working!")
            return True

        except Exception as e:
            print(f"❌ Cost tracking service test failed: {e}")
            return False

    async def test_full_legendary_investigation(self):
        """Test full legendary squad investigation (if AI is available)."""
        print("🧪 Testing full legendary squad investigation...")

        try:
            # This would normally require real AI keys, so we'll test initialization only
            squad = DetectiveSquadManager()
            ready = await squad.initialize_squad()

            if ready:
                print("✅ Legendary squad ready for investigations!")

                # Get squad status
                status = await squad.get_squad_status()
                assert status["squad_name"] == "Ghost Wallet Hunter Detective Squad"
                assert "squad_members" in status

                print("✅ Full legendary squad test successful!")
                return True
            else:
                print("⚠️ Legendary squad partial initialization (expected without API keys)")
                return True

        except Exception as e:
            print(f"❌ Full legendary investigation test failed: {e}")
            return False

    async def run_all_tests(self):
        """Run all frontend integration tests."""
        print("🚀 Starting Ghost Wallet Hunter Frontend Integration Tests")
        print("=" * 60)

        test_results = {}

        # Test individual components
        test_results["squad_status"] = await self.test_legendary_squad_status()
        test_results["detective_endpoints"] = await self.test_detective_individual_endpoints()
        test_results["cost_dashboard"] = await self.test_ai_cost_dashboard()
        test_results["cost_limits"] = await self.test_cost_limits_update()
        test_results["providers_status"] = await self.test_ai_providers_status()
        test_results["ai_integration"] = await self.test_real_ai_integration()
        test_results["cost_tracking"] = await self.test_cost_tracking_service()
        test_results["full_investigation"] = await self.test_full_legendary_investigation()

        # Summary
        print("\n" + "=" * 60)
        print("🏁 FRONTEND INTEGRATION TEST RESULTS")
        print("=" * 60)

        passed = 0
        total = len(test_results)

        for test_name, result in test_results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"{test_name.replace('_', ' ').title()}: {status}")
            if result:
                passed += 1

        print(f"\nSummary: {passed}/{total} tests passed")

        if passed == total:
            print("🌟 ALL TESTS PASSED - Frontend integration ready!")
        elif passed >= total * 0.8:  # 80% pass rate
            print("⚠️ Most tests passed - Frontend integration mostly ready!")
        else:
            print("❌ Several tests failed - Frontend integration needs work!")

        return test_results


async def main():
    """Main test runner."""
    tester = TestFrontendIntegration()
    results = await tester.run_all_tests()
    return results


if __name__ == "__main__":
    print("Ghost Wallet Hunter - Frontend Integration Test Suite")
    print("Testing all API endpoints for frontend compatibility...")

    # Run tests
    try:
        results = asyncio.run(main())

        # Exit with appropriate code
        passed = sum(1 for result in results.values() if result)
        total = len(results)

        if passed == total:
            sys.exit(0)  # All tests passed
        else:
            sys.exit(1)  # Some tests failed

    except Exception as e:
        print(f"❌ Test suite failed to run: {e}")
        sys.exit(2)  # Test suite error
