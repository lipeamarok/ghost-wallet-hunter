#!/usr/bin/env python3
"""
🔍 Quick Test - Investigation Endpoint
Teste rápido para verificar se o endpoint está funcionando
"""

import asyncio
import httpx
import json
import sys

async def quick_test():
    """Teste rápido do endpoint"""

    # Configuração
    base_url = "http://localhost:8001"
    test_wallet = "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"  # Phantom Team wallet

    async with httpx.AsyncClient(timeout=300.0) as client:
        try:
            print("🔍 Testing /legendary-squad/investigate endpoint...")
            print(f"📍 Wallet: {test_wallet}")
            print("⏳ This may take a few minutes...")

            # Test request
            payload = {
                "wallet_address": test_wallet,
                "investigation_type": "comprehensive",
                "include_context": True
            }

            response = await client.post(
                f"{base_url}/api/agents/legendary-squad/investigate",
                json=payload
            )

            if response.status_code == 200:
                data = response.json()
                print("✅ SUCCESS! Investigation completed!")
                print(f"📊 Status: {data.get('status')}")

                # Check if we have real results
                legendary_results = data.get("legendary_results", {})
                consensus = legendary_results.get("legendary_consensus", {})

                if consensus:
                    print(f"🎯 Risk Score: {consensus.get('consensus_risk_score', 'N/A')}")
                    print(f"🚨 Risk Level: {consensus.get('consensus_risk_level', 'N/A')}")
                    print(f"🔍 Detectives Analyzed: {len(legendary_results.get('detective_findings', {}))}")
                else:
                    print("⚠️ No consensus data found")

                return True
            else:
                print(f"❌ FAILED: {response.status_code}")
                print(f"📝 Error: {response.text}")
                return False

        except Exception as e:
            print(f"❌ ERROR: {e}")
            return False

if __name__ == "__main__":
    print("🚀 Quick Investigation Test")
    print("="*40)

    try:
        result = asyncio.run(quick_test())
        if result:
            print("\n🎉 Endpoint is working!")
        else:
            print("\n❌ Endpoint has issues!")

    except KeyboardInterrupt:
        print("\n⏹️ Test cancelled")
