#!/usr/bin/env python3
"""
🔍 Teste JuliaOS Integration Status
Ghost Wallet Hunter - Verificação completa do status do JuliaOS

Este script verifica:
1. ✅ Se o JuliaOS está realmente conectado
2. ✅ Se está usando AI real ou fallback
3. ✅ Performance atual do sistema
4. ✅ Recomendações de otimização
"""

import asyncio
import httpx
import json
import sys
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class JuliaOSStatusTester:
    """Testador completo do status do JuliaOS e performance."""

    def __init__(self, base_url: str = "http://localhost:8001"):
        self.base_url = base_url
        self.client = None

    async def __aenter__(self):
        self.client = httpx.AsyncClient(timeout=60.0)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.client:
            await self.client.aclose()

    async def test_juliaos_status(self):
        """Testa o status do JuliaOS."""
        try:
            logger.info("🔍 Testing JuliaOS integration status...")
            response = await self.client.get(f"{self.base_url}/api/performance/juliaos/status")

            if response.status_code == 200:
                data = response.json()
                juliaos_info = data.get("juliaos_integration", {})

                logger.info("📊 JULIAOS STATUS REPORT")
                logger.info("="*50)
                logger.info(f"Connection: {juliaos_info.get('connection', 'unknown')}")
                logger.info(f"Status: {juliaos_info.get('status', 'unknown')}")
                logger.info(f"Real JuliaOS: {juliaos_info.get('real_juliaos', False)}")
                logger.info(f"Analysis Capability: {juliaos_info.get('analysis_capability', 'unknown')}")

                if juliaos_info.get('error'):
                    logger.warning(f"⚠️ Error: {juliaos_info['error']}")

                if juliaos_info.get('warning'):
                    logger.warning(f"⚠️ Warning: {juliaos_info['warning']}")

                # Recommendations
                recommendations = data.get("recommendations", [])
                if recommendations:
                    logger.info("\n💡 RECOMMENDATIONS:")
                    for i, rec in enumerate(recommendations, 1):
                        logger.info(f"   {i}. {rec}")

                # Determine real status
                real_juliaos = juliaos_info.get('real_juliaos', False)
                connection = juliaos_info.get('connection', 'unknown')

                if real_juliaos and connection == 'connected':
                    logger.info("✅ JULIAOS IS FULLY OPERATIONAL!")
                    return True
                elif connection == 'connected' and not real_juliaos:
                    logger.warning("⚠️ JULIAOS CONNECTED BUT USING FALLBACK MODE!")
                    return False
                else:
                    logger.error("❌ JULIAOS IS NOT OPERATIONAL!")
                    return False
            else:
                logger.error(f"❌ Failed to get JuliaOS status: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"❌ JuliaOS status test failed: {e}")
            return False

    async def test_performance_status(self):
        """Testa o status de performance geral."""
        try:
            logger.info("\n🚀 Testing overall performance status...")
            response = await self.client.get(f"{self.base_url}/api/performance/status")

            if response.status_code == 200:
                data = response.json()

                logger.info("📊 PERFORMANCE STATUS REPORT")
                logger.info("="*50)

                # Cache performance
                cache_perf = data.get("cache_performance", {})
                if cache_perf:
                    logger.info(f"Cache Hit Rate: {cache_perf.get('hit_rate_percent', 0):.1f}%")
                    logger.info(f"Cache Entries: {cache_perf.get('total_entries', 0)}")
                    logger.info(f"Total Requests: {cache_perf.get('total_requests', 0)}")

                # Analysis performance
                analysis_perf = data.get("analysis_performance", {})
                overall_stats = analysis_perf.get("overall_stats", {})
                if overall_stats:
                    logger.info(f"Average Analysis Time: {overall_stats.get('avg_time_seconds', 0):.2f}s")
                    logger.info(f"Total Analyses: {overall_stats.get('total_analyses', 0)}")
                    logger.info(f"Slow Analyses: {overall_stats.get('slow_analyses_count', 0)}")

                # Recommendations
                recommendations = analysis_perf.get("recommendations", [])
                if recommendations:
                    logger.info("\n💡 PERFORMANCE RECOMMENDATIONS:")
                    for i, rec in enumerate(recommendations, 1):
                        logger.info(f"   {i}. {rec}")

                return True
            else:
                logger.error(f"❌ Failed to get performance status: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"❌ Performance status test failed: {e}")
            return False

    async def test_system_health(self):
        """Testa a saúde geral do sistema."""
        try:
            logger.info("\n🏥 Testing system health...")
            response = await self.client.get(f"{self.base_url}/api/performance/health")

            if response.status_code == 200:
                data = response.json()

                logger.info("📊 SYSTEM HEALTH REPORT")
                logger.info("="*50)

                overall_health = data.get("overall_health", {})
                logger.info(f"Health Score: {overall_health.get('score', 0)}/100")
                logger.info(f"Health Grade: {overall_health.get('grade', 'F')}")

                components = data.get("components", {})
                logger.info(f"Cache System: {components.get('cache_system', 'unknown')}")
                logger.info(f"Analysis Performance: {components.get('analysis_performance', 'unknown')}")
                logger.info(f"JuliaOS Integration: {components.get('juliaos_integration', 'unknown')}")

                system_ready = data.get("system_ready", False)
                if system_ready:
                    logger.info("✅ SYSTEM IS READY FOR PRODUCTION!")
                else:
                    logger.warning("⚠️ SYSTEM NEEDS OPTIMIZATION BEFORE PRODUCTION!")

                return system_ready
            else:
                logger.error(f"❌ Failed to get system health: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"❌ System health test failed: {e}")
            return False

    async def test_analysis_timing(self):
        """Testa o timing das análises."""
        try:
            logger.info("\n⏱️ Testing analysis timing...")
            response = await self.client.get(f"{self.base_url}/api/performance/analysis/timing")

            if response.status_code == 200:
                data = response.json()

                logger.info("📊 ANALYSIS TIMING REPORT")
                logger.info("="*50)

                timing_analysis = data.get("timing_analysis", {})
                overall_stats = timing_analysis.get("overall_stats", {})

                if overall_stats:
                    avg_time = overall_stats.get("avg_time_seconds", 0)
                    max_time = overall_stats.get("max_time_seconds", 0)
                    min_time = overall_stats.get("min_time_seconds", 0)

                    logger.info(f"Average Time: {avg_time:.2f}s")
                    logger.info(f"Maximum Time: {max_time:.2f}s")
                    logger.info(f"Minimum Time: {min_time:.2f}s")

                    grade = data.get("performance_grade", "F")
                    logger.info(f"Performance Grade: {grade}")

                    if avg_time > 300:  # 5 minutes
                        logger.error("❌ CRITICAL: Analysis time too high for production!")
                        return False
                    elif avg_time > 120:  # 2 minutes
                        logger.warning("⚠️ WARNING: Analysis time is high!")
                        return True
                    else:
                        logger.info("✅ Analysis timing is acceptable!")
                        return True
                else:
                    logger.info("ℹ️ No timing data available yet")
                    return True

            else:
                logger.error(f"❌ Failed to get timing report: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"❌ Analysis timing test failed: {e}")
            return False

    async def run_comprehensive_status_check(self):
        """Executa verificação completa de status."""
        logger.info("🚀 STARTING COMPREHENSIVE STATUS CHECK")
        logger.info("="*60)
        logger.info(f"🕐 Test started at: {datetime.now().isoformat()}")
        logger.info("="*60)

        results = {}

        # Test JuliaOS
        results['juliaos'] = await self.test_juliaos_status()

        # Test Performance
        results['performance'] = await self.test_performance_status()

        # Test System Health
        results['health'] = await self.test_system_health()

        # Test Analysis Timing
        results['timing'] = await self.test_analysis_timing()

        # Final Report
        logger.info("="*60)
        logger.info("📋 FINAL STATUS REPORT")
        logger.info("="*60)

        passed_tests = sum(1 for result in results.values() if result)
        total_tests = len(results)

        logger.info(f"✅ Tests Passed: {passed_tests}/{total_tests}")

        for test_name, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            logger.info(f"   {test_name.upper()}: {status}")

        # Critical Issues Check
        critical_issues = []

        if not results['juliaos']:
            critical_issues.append("JuliaOS is not operational - using fallback mode")

        if not results['timing']:
            critical_issues.append("Analysis timing is too slow for production")

        if not results['health']:
            critical_issues.append("System health score is below production threshold")

        if critical_issues:
            logger.error("\n🚨 CRITICAL ISSUES DETECTED:")
            for i, issue in enumerate(critical_issues, 1):
                logger.error(f"   {i}. {issue}")
            logger.error("\n❌ SYSTEM NOT READY FOR PRODUCTION!")
            return False
        else:
            logger.info("\n🎉 ALL SYSTEMS OPERATIONAL!")
            logger.info("✅ SYSTEM READY FOR PRODUCTION!")
            return True


async def main():
    """Função principal do teste."""
    try:
        async with JuliaOSStatusTester() as tester:
            success = await tester.run_comprehensive_status_check()

            if success:
                print("\n🎉 STATUS CHECK COMPLETED SUCCESSFULLY!")
                print("✅ All systems are operational and ready for production!")
            else:
                print("\n❌ STATUS CHECK FAILED!")
                print("🔧 Critical issues detected that need attention.")

            return success

    except KeyboardInterrupt:
        print("\n⏹️ Status check interrupted by user")
        return False
    except Exception as e:
        logger.error(f"❌ Status check failed with error: {e}")
        return False


if __name__ == "__main__":
    print("🔍 Ghost Wallet Hunter - JuliaOS & Performance Status Checker")
    print("="*70)
    print("📋 This script will check:")
    print("   🤖 JuliaOS integration status (real vs fallback)")
    print("   ⚡ System performance metrics")
    print("   🏥 Overall system health")
    print("   ⏱️ Analysis timing performance")
    print("⚠️ Make sure the backend server is running on http://localhost:8001")
    print("="*70)

    # Run the test
    result = asyncio.run(main())

    if result:
        print("\n✅ All systems green! Production ready! 🚀")
        sys.exit(0)
    else:
        print("\n❌ Issues detected. Check logs for details. 🔧")
        sys.exit(1)
