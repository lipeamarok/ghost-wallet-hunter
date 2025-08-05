"""
Real A2A Client Example
======================

Exemplo de cliente A2A real que funciona com dados reais.
"""

import asyncio
import httpx
import json
from a2a_types import SendMessageRequest, MessageSendParams


async def test_real_investigation():
    """Testa investigação real com dados da Solana"""

    # Wallet real para testar (pode ser qualquer endereço Solana público)
    test_wallet = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"  # Exemplo

    print("🔍 Testing Real A2A Investigation...")
    print(f"📋 Target wallet: {test_wallet}")

    async with httpx.AsyncClient() as client:
        try:
            # 1. Listar agentes disponíveis
            print("\n1. Listing available detectives...")
            agents_response = await client.get("http://127.0.0.1:9100/agents")

            if agents_response.status_code == 200:
                agents_data = agents_response.json()
                print(f"✅ Found {agents_data['total']} real detectives")

                # Selecionar primeiro detetive para teste
                first_agent = agents_data['agents'][0]
                agent_id = first_agent['id']
                agent_name = first_agent['name']

                print(f"🕵️ Selected: {agent_name} ({agent_id})")

                # 2. Executar investigação real
                print(f"\n2. Starting real investigation with {agent_name}...")
                investigation_payload = {
                    "wallet_address": test_wallet
                }

                investigation_response = await client.post(
                    f"http://127.0.0.1:9100/{agent_id}/investigate",
                    json=investigation_payload
                )

                if investigation_response.status_code == 200:
                    result = investigation_response.json()
                    print("✅ Real investigation completed!")
                    print(f"🎯 Detective: {result.get('agent_name')}")
                    print(f"🔬 Specialty: {result.get('detective_specialty')}")

                    investigation = result.get('investigation', {})
                    if 'error' not in investigation:
                        print(f"💰 Wallet Balance: {investigation.get('balance_sol', 0):.4f} SOL")
                        print(f"📊 Total Transactions: {investigation.get('total_transactions', 0)}")
                        print(f"⚡ Activity Score: {investigation.get('activity_score', 0):.2f}")

                        risk_indicators = investigation.get('risk_indicators', {})
                        if any(risk_indicators.values()):
                            print("⚠️ Risk Indicators:")
                            for indicator, value in risk_indicators.items():
                                if value:
                                    print(f"   - {indicator}: {value}")
                        else:
                            print("✅ No significant risk indicators detected")
                    else:
                        print(f"❌ Investigation error: {investigation['error']}")
                else:
                    print(f"❌ Investigation failed: {investigation_response.status_code}")
                    print(investigation_response.text)

            else:
                print(f"❌ Failed to get agents: {agents_response.status_code}")

        except Exception as e:
            print(f"❌ Test failed: {str(e)}")


async def test_real_message():
    """Testa envio de mensagem real"""

    print("\n🔍 Testing Real A2A Messaging...")

    async with httpx.AsyncClient() as client:
        try:
            # Obter primeiro agente
            agents_response = await client.get("http://127.0.0.1:9100/agents")

            if agents_response.status_code == 200:
                agents_data = agents_response.json()
                first_agent = agents_data['agents'][0]
                agent_id = first_agent['id']

                # Enviar mensagem
                message_payload = {
                    "message": {
                        "type": "investigation_request",
                        "content": "Please provide a status update on your capabilities"
                    },
                    "inputMode": "text"
                }

                message_response = await client.post(
                    f"http://127.0.0.1:9100/{agent_id}/message",
                    json=message_payload
                )

                if message_response.status_code == 200:
                    result = message_response.json()
                    print("✅ Message sent successfully!")
                    print(f"🤖 Agent: {result.get('agent_name')}")
                    print(f"💬 Response: {result.get('content', {}).get('message')}")
                else:
                    print(f"❌ Message failed: {message_response.status_code}")

        except Exception as e:
            print(f"❌ Message test failed: {str(e)}")


async def main():
    """Executa testes reais"""
    print("🚀 Starting Real A2A Tests...")
    print("=" * 50)

    # Verificar se servidor está rodando
    try:
        async with httpx.AsyncClient() as client:
            health_response = await client.get("http://127.0.0.1:9100/health")
            if health_response.status_code == 200:
                print("✅ A2A Server is running")
            else:
                print("❌ A2A Server not responding")
                return
    except Exception as e:
        print(f"❌ Cannot connect to A2A Server: {e}")
        return

    # Executar testes
    await test_real_investigation()
    await test_real_message()

    print("\n" + "=" * 50)
    print("🏁 Real A2A Tests Completed!")


if __name__ == "__main__":
    asyncio.run(main())
