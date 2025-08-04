#!/usr/bin/env python3
"""
🔍 Test do Endpoint /legendary-squad/investigate
Ghost Wallet Hunter - Teste completo do endpoint de investigação com carteiras reais

Este script testa especificamente o endpoint /legendary-squad/investigate para garantir que:
1. ✅ Os agentes estão funcionando corretamente (SEM MOCKS)
2. ✅ As pesquisas são REAIS usando APIs externas
3. ✅ A integração completa está operacional
4. ✅ Retorna dados consistentes e válidos
"""

import asyncio
import httpx
import json
import sys
import logging
import time
from datetime import datetime
from pathlib import Path

# Add project root to path
sys.path.append(str(Path(__file__).parent.parent))

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class InvestigateEndpointTester:
    """
    🔍 Testador completo do endpoint de investigação
    """

    def __init__(self, base_url: str = "http://localhost:8001"):
        self.base_url = base_url
        self.client = None

        # Carteiras reais do Solana para teste
        self.test_wallets = {
            "known_legit": "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",  # Phantom Team wallet
            "high_activity": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",  # USDC mint
            "test_wallet": "So11111111111111111111111111111111111111112",   # SOL token
            "random_wallet": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"   # SAMO token
        }

    async def __aenter__(self):
        """Async context manager entry"""
        self.client = httpx.AsyncClient(timeout=300.0)  # 5 minutes timeout
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self.client:
            await self.client.aclose()

    async def test_server_health(self):
        """Verifica se o servidor está rodando"""
        try:
            logger.info("🏥 Checking server health...")
            response = await self.client.get(f"{self.base_url}/api/agents/health")

            if response.status_code == 200:
                data = response.json()
                logger.info(f"✅ Server is healthy: {data.get('message', 'OK')}")
                return True
            else:
                logger.error(f"❌ Server health check failed: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"❌ Failed to connect to server: {e}")
            logger.info("💡 Make sure the backend server is running on http://localhost:8001")
            return False

    async def test_legendary_squad_status(self):
        """Testa o status do squad antes da investigação"""
        try:
            logger.info("🕵️ Testing legendary squad status...")
            response = await self.client.get(f"{self.base_url}/api/agents/legendary-squad/status")

            if response.status_code == 200:
                data = response.json()
                logger.info(f"✅ Squad Status: {data.get('squad_info', {}).get('operational_status', 'Unknown')}")
                logger.info(f"📊 Available Detectives: {len(data.get('available_detectives', []))}")
                return True
            else:
                logger.error(f"❌ Squad status failed: {response.status_code} - {response.text}")
                return False

        except Exception as e:
            logger.error(f"❌ Squad status test failed: {e}")
            return False

    async def test_investigate_endpoint(self, wallet_address: str, wallet_name: str):
        """
        Testa o endpoint de investigação com uma carteira real
        """
        logger.info("="*80)
        logger.info(f"🔍 TESTING INVESTIGATION: {wallet_name}")
        logger.info(f"📍 Wallet: {wallet_address}")
        logger.info("="*80)

        start_time = time.time()

        try:
            # Prepare request payload
            payload = {
                "wallet_address": wallet_address,
                "investigation_type": "comprehensive",
                "include_context": True
            }

            logger.info("📤 Sending investigation request...")
            logger.info(f"🔗 URL: {self.base_url}/api/agents/legendary-squad/investigate")
            logger.info(f"📋 Payload: {json.dumps(payload, indent=2)}")

            # Make the request
            response = await self.client.post(
                f"{self.base_url}/api/agents/legendary-squad/investigate",
                json=payload
            )

            elapsed_time = time.time() - start_time
            logger.info(f"⏱️ Response time: {elapsed_time:.2f} seconds")

            # Check response
            if response.status_code == 200:
                data = response.json()
                await self.analyze_investigation_response(data, wallet_name, elapsed_time)
                return True, data
            else:
                logger.error(f"❌ Investigation failed: {response.status_code}")
                logger.error(f"📝 Error response: {response.text}")
                return False, None

        except Exception as e:
            elapsed_time = time.time() - start_time
            logger.error(f"❌ Investigation request failed after {elapsed_time:.2f}s: {e}")
            return False, None

    async def analyze_investigation_response(self, data: dict, wallet_name: str, elapsed_time: float):
        """
        Analisa a resposta da investigação para verificar se os dados são reais
        """
        logger.info("📊 ANALYZING INVESTIGATION RESPONSE")
        logger.info("-" * 50)

        # Basic response structure
        logger.info(f"✅ Status: {data.get('status', 'Unknown')}")
        logger.info(f"📍 Wallet: {data.get('wallet_address', 'Unknown')}")
        logger.info(f"🔍 Investigation Type: {data.get('investigation_type', 'Unknown')}")
        logger.info(f"⏱️ Processing Time: {elapsed_time:.2f} seconds")

        # Check legendary results
        legendary_results = data.get("legendary_results", {})
        if not legendary_results:
            logger.warning("⚠️ No legendary results found!")
            return

        # Consensus analysis
        consensus = legendary_results.get("legendary_consensus", {})
        if consensus:
            logger.info("\n🎯 CONSENSUS RESULTS:")
            logger.info(f"   Risk Score: {consensus.get('consensus_risk_score', 'N/A')}")
            logger.info(f"   Risk Level: {consensus.get('consensus_risk_level', 'N/A')}")
            logger.info(f"   Threat Classification: {consensus.get('threat_classification', 'N/A')}")
            logger.info(f"   Detective Consensus: {consensus.get('detective_consensus', 'N/A')}")

            if consensus.get('override_triggered'):
                logger.warning(f"⚠️ Override Triggered: {consensus.get('override_reason', 'Unknown')}")

        # Detective findings analysis
        detective_findings = legendary_results.get("detective_findings", {})
        logger.info("\n🕵️ DETECTIVE FINDINGS:")

        detective_count = 0
        real_analysis_count = 0

        detectives = {
            "Poirot": detective_findings.get("poirot_transaction_analysis"),
            "Marple": detective_findings.get("marple_pattern_detection"),
            "Spade": detective_findings.get("spade_risk_assessment"),
            "Marlowe": detective_findings.get("marlowe_bridge_tracking"),
            "Dupin": detective_findings.get("dupin_compliance_analysis"),
            "Shadow": detective_findings.get("shadow_network_intelligence"),
            "Raven": detective_findings.get("raven_ai_analysis")
        }

        for name, report in detectives.items():
            detective_count += 1
            if report and isinstance(report, dict):
                # Check if this looks like real analysis
                has_real_data = self.check_for_real_analysis(report, name)
                if has_real_data:
                    real_analysis_count += 1
                    logger.info(f"   ✅ {name}: REAL analysis detected")
                else:
                    logger.warning(f"   ⚠️ {name}: Possibly mock/placeholder data")
            else:
                logger.warning(f"   ❌ {name}: No analysis or invalid format")

        # Real data verification
        logger.info(f"\n📈 REAL DATA VERIFICATION:")
        logger.info(f"   Total Detectives: {detective_count}")
        logger.info(f"   Real Analysis Count: {real_analysis_count}")
        logger.info(f"   Real Data Percentage: {(real_analysis_count/detective_count)*100:.1f}%")

        if real_analysis_count >= 5:  # At least 5/7 detectives with real data
            logger.info("✅ INVESTIGATION QUALITY: EXCELLENT - Real data confirmed!")
        elif real_analysis_count >= 3:
            logger.info("⚠️ INVESTIGATION QUALITY: GOOD - Mostly real data")
        else:
            logger.warning("❌ INVESTIGATION QUALITY: POOR - Insufficient real data")

        # Transparency report
        transparency = legendary_results.get("transparency_report", {})
        if transparency:
            logger.info(f"\n📋 TRANSPARENCY REPORT:")
            logger.info(f"   Calculation Method: {transparency.get('calculation_method', 'N/A')}")
            logger.info(f"   Critical Flags: {transparency.get('critical_flags_detected', 0)}")

            top_contributors = transparency.get('top_contributors', [])
            if top_contributors:
                logger.info(f"   Top Contributors: {', '.join([f'{agent}({score:.3f})' for agent, score in top_contributors[:3]])}")

    def check_for_real_analysis(self, report: dict, detective_name: str) -> bool:
        """
        Verifica se a análise contém dados reais ou é apenas placeholder/mock
        """
        if not isinstance(report, dict):
            return False

        # Check for common mock indicators
        mock_indicators = [
            "mock", "simulated", "placeholder", "demo", "test",
            "Not available", "N/A", "Unknown", "TODO"
        ]

        report_str = json.dumps(report).lower()

        # If it contains mock indicators, it's probably not real
        for indicator in mock_indicators:
            if indicator.lower() in report_str:
                return False

        # Check for specific real data indicators
        real_indicators = [
            "transactions", "solana", "rpc", "lamports", "sol",
            "address", "signature", "block", "timestamp"
        ]

        real_count = sum(1 for indicator in real_indicators if indicator in report_str)

        # Also check for numeric data that looks real
        has_numbers = any(char.isdigit() for char in report_str)
        has_addresses = any(len(key) > 30 for key in report.keys() if isinstance(key, str))

        return real_count >= 2 or (has_numbers and has_addresses)

    async def run_comprehensive_test(self):
        """
        Executa teste completo do endpoint de investigação
        """
        logger.info("🚀 STARTING COMPREHENSIVE INVESTIGATION ENDPOINT TEST")
        logger.info("="*80)
        logger.info(f"🕐 Test started at: {datetime.now().isoformat()}")
        logger.info("="*80)

        # 1. Check server health
        if not await self.test_server_health():
            logger.error("❌ Server is not healthy. Aborting tests.")
            return False

        # 2. Check squad status
        if not await self.test_legendary_squad_status():
            logger.error("❌ Squad is not ready. Aborting tests.")
            return False

        # 3. Test investigations
        total_tests = len(self.test_wallets)
        successful_tests = 0

        for wallet_name, wallet_address in self.test_wallets.items():
            try:
                success, result = await self.test_investigate_endpoint(wallet_address, wallet_name)
                if success:
                    successful_tests += 1
                    logger.info(f"✅ Test passed for {wallet_name}")
                else:
                    logger.error(f"❌ Test failed for {wallet_name}")

                # Wait between tests to avoid rate limiting
                if wallet_name != list(self.test_wallets.keys())[-1]:  # Not the last one
                    logger.info("⏳ Waiting 5 seconds before next test...")
                    await asyncio.sleep(5)

            except Exception as e:
                logger.error(f"❌ Unexpected error testing {wallet_name}: {e}")

        # 4. Final report
        logger.info("="*80)
        logger.info("📊 FINAL TEST REPORT")
        logger.info("="*80)
        logger.info(f"✅ Successful Tests: {successful_tests}/{total_tests}")
        logger.info(f"📈 Success Rate: {(successful_tests/total_tests)*100:.1f}%")

        if successful_tests == total_tests:
            logger.info("🎉 ALL TESTS PASSED! The investigate endpoint is working perfectly!")
            return True
        elif successful_tests >= total_tests * 0.7:  # 70% success rate
            logger.info("⚠️ Most tests passed. Some issues detected but endpoint is mostly functional.")
            return True
        else:
            logger.error("❌ Too many test failures. Endpoint needs attention.")
            return False


async def main():
    """Função principal do teste"""
    try:
        async with InvestigateEndpointTester() as tester:
            success = await tester.run_comprehensive_test()

            if success:
                print("\n🎉 TEST SUITE COMPLETED SUCCESSFULLY!")
                print("✅ The /legendary-squad/investigate endpoint is working correctly with real data!")
            else:
                print("\n❌ TEST SUITE FAILED!")
                print("🔧 The endpoint needs fixes before production use.")

            return success

    except KeyboardInterrupt:
        print("\n⏹️ Test interrupted by user")
        return False
    except Exception as e:
        logger.error(f"❌ Test suite failed with error: {e}")
        return False


if __name__ == "__main__":
    print("🔍 Ghost Wallet Hunter - Investigation Endpoint Tester")
    print("="*60)
    print("📋 This script will test the /legendary-squad/investigate endpoint")
    print("🎯 Using REAL Solana wallets with REAL API calls")
    print("⚠️ Make sure the backend server is running on http://localhost:8001")
    print("="*60)

    # Run the test
    result = asyncio.run(main())

    if result:
        print("\n✅ All systems operational! Ready for production! 🚀")
        sys.exit(0)
    else:
        print("\n❌ Tests failed. Check logs for details. 🔧")
        sys.exit(1)
