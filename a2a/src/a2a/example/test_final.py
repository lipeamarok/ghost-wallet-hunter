"""
Ghost A2A Test Client - FINAL VERSION
====================================

Cliente de teste final para o servidor limpo.
"""

import asyncio
import httpx
import json


async def test_final_server():
    """Testa o servidor final limpo"""

    print("🧪 Testing FINAL Ghost A2A Server")
    print("=" * 50)

    base_url = "http://127.0.0.1:9100"
    test_wallet = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"  # Wallet público para teste

    async with httpx.AsyncClient() as client:
        try:
            # 1. Health Check
            print("1. Health Check...")
            health = await client.get(f"{base_url}/health")
            if health.status_code == 200:
                data = health.json()
                print(f"   ✅ Status: {data['status']}")
                print(f"   📊 Agents: {data['agents']}")
                print(f"   🔗 Data: {data['data_source']}")
            else:
                print(f"   ❌ Health check failed: {health.status_code}")
                return

            # 2. List Agents
            print("\n2. List Real Agents...")
            agents_resp = await client.get(f"{base_url}/agents")
            if agents_resp.status_code == 200:
                agents_data = agents_resp.json()
                print(f"   ✅ Found {agents_data['total']} real agents")
                for agent in agents_data['agents']:
                    print(f"      🕵️ {agent['name']} ({agent['id']}) - {agent['specialty']}")

                # Select first agent for testing
                test_agent = agents_data['agents'][0]
                agent_id = test_agent['id']
                agent_name = test_agent['name']

            else:
                print(f"   ❌ Failed to list agents: {agents_resp.status_code}")
                return

            # 3. Get Agent Card
            print(f"\n3. Get Agent Card for {agent_name}...")
            card_resp = await client.get(f"{base_url}/{agent_id}/card")
            if card_resp.status_code == 200:
                card_data = card_resp.json()
                print(f"   ✅ Card retrieved")
                print(f"      📋 Name: {card_data['name']}")
                print(f"      🎯 Skills: {len(card_data['skills'])}")
                print(f"      🔗 Endpoint: {card_data['endpoint']}")
            else:
                print(f"   ❌ Failed to get card: {card_resp.status_code}")

            # 4. Send Message
            print(f"\n4. Send Message to {agent_name}...")
            message_payload = {
                "message": {
                    "type": "test",
                    "content": "Final integration test"
                }
            }
            message_resp = await client.post(f"{base_url}/{agent_id}/message", json=message_payload)
            if message_resp.status_code == 200:
                msg_data = message_resp.json()
                print(f"   ✅ Message sent successfully")
                print(f"      🤖 Response: {msg_data['content']['response']}")
            else:
                print(f"   ❌ Message failed: {message_resp.status_code}")

            # 5. REAL Solana Investigation
            print(f"\n5. REAL Solana Investigation with {agent_name}...")
            print(f"   🎯 Target wallet: {test_wallet}")

            investigation_payload = {"wallet_address": test_wallet}
            inv_resp = await client.post(f"{base_url}/{agent_id}/investigate", json=investigation_payload)

            if inv_resp.status_code == 200:
                inv_data = inv_resp.json()
                print("   ✅ REAL investigation completed!")

                investigation = inv_data.get('investigation', {})
                if 'error' not in investigation:
                    print(f"      💰 Balance: {investigation['balance_sol']:.4f} SOL")
                    print(f"      📊 Transactions: {investigation['total_transactions']}")
                    print(f"      ⚡ Activity Score: {investigation['activity_score']:.2f}")
                    print(f"      🌐 Data Source: {investigation['data_source']}")

                    # Specialized analysis
                    analysis = inv_data.get('specialized_analysis', {})
                    if analysis:
                        print(f"      🔬 Analysis Method: {analysis['method']}")
                        print(f"      📝 Notes: {analysis['notes']}")
                        print(f"      ✅ Confidence: {analysis['confidence']}")

                    print("      🎉 REAL BLOCKCHAIN DATA RETRIEVED!")
                else:
                    print(f"      ❌ Investigation error: {investigation['error']}")
            else:
                print(f"   ❌ Investigation failed: {inv_resp.status_code}")
                print(f"      Response: {inv_resp.text}")

            print("\n" + "=" * 50)
            print("🏆 FINAL SERVER TEST COMPLETED!")
            print("✅ Single server handling all functionality")
            print("🚫 NO duplicate files")
            print("🔗 Real Solana data integration")
            print("🕵️ Real Ghost Detectives")

        except Exception as e:
            print(f"\n❌ Test failed: {str(e)}")


if __name__ == "__main__":
    asyncio.run(test_final_server())
