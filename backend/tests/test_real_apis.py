"""
Teste Direto das APIs Externas

Este arquivo testa se estamos realmente buscando dados reais das APIs externas
ou se estamos usando apenas dados mock/exemplos.
"""

import asyncio
import httpx
import json
from datetime import datetime


async def test_real_apis():
    """Testa as APIs reais para verificar se estão funcionando."""

    print("🔍 TESTANDO APIS REAIS - Verificando se os dados são reais ou mock")
    print("=" * 70)

    # Token real do SAMO (Samoyed Coin) para teste
    samo_address = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"

    # Token real do USDC para teste
    usdc_address = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"

    client = httpx.AsyncClient(timeout=30.0)

    try:
        print(f"\n📍 TESTE 1: Jupiter API - Token SAMO")
        print("-" * 50)

        jupiter_url = f"https://token.jup.ag/token/{samo_address}"
        print(f"URL: {jupiter_url}")

        response = await client.get(jupiter_url)
        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print("✅ DADOS REAIS RECEBIDOS:")
            print(f"  Nome: {data.get('name', 'N/A')}")
            print(f"  Símbolo: {data.get('symbol', 'N/A')}")
            print(f"  Decimais: {data.get('decimals', 'N/A')}")
            print(f"  Tags: {data.get('tags', [])}")
            print(f"  Logo: {data.get('logoURI', 'N/A')[:50]}...")
        else:
            print(f"❌ FALHA: {response.status_code}")
            print(f"Response: {response.text[:200]}")

        print(f"\n📍 TESTE 2: CoinGecko API - Token USDC")
        print("-" * 50)

        coingecko_url = f"https://api.coingecko.com/api/v3/coins/solana/contract/{usdc_address}"
        print(f"URL: {coingecko_url}")

        response = await client.get(coingecko_url)
        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print("✅ DADOS REAIS RECEBIDOS:")
            print(f"  Nome: {data.get('name', 'N/A')}")
            print(f"  Símbolo: {data.get('symbol', 'N/A')}")
            print(f"  Market Cap: ${data.get('market_data', {}).get('market_cap', {}).get('usd', 'N/A'):,}")
            print(f"  Preço: ${data.get('market_data', {}).get('current_price', {}).get('usd', 'N/A')}")
            print(f"  ID CoinGecko: {data.get('id', 'N/A')}")
        else:
            print(f"❌ FALHA: {response.status_code}")
            print(f"Response: {response.text[:200]}")

        print(f"\n📍 TESTE 3: Solscan API - Token SAMO")
        print("-" * 50)

        solscan_url = f"https://public-api.solscan.io/token/meta?tokenAddress={samo_address}"
        print(f"URL: {solscan_url}")

        response = await client.get(solscan_url)
        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print("✅ DADOS REAIS RECEBIDOS:")
            print(f"  Nome: {data.get('name', 'N/A')}")
            print(f"  Símbolo: {data.get('symbol', 'N/A')}")
            print(f"  Supply: {data.get('supply', 'N/A')}")
            print(f"  Holders: {data.get('holder', 'N/A')}")
            print(f"  Decimais: {data.get('decimals', 'N/A')}")
        else:
            print(f"❌ FALHA: {response.status_code}")
            print(f"Response: {response.text[:200]}")

        print(f"\n📍 TESTE 4: Verificando se nosso serviço usa essas APIs")
        print("-" * 50)

        # Importar nosso serviço
        import sys
        import os
        sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

        from services.token_enrichment import get_token_enrichment_service

        enrichment_service = await get_token_enrichment_service()

        print("Testando nosso serviço com token SAMO...")
        token_info = await enrichment_service.enrich_token_info(samo_address)

        print("📊 RESULTADO DO NOSSO SERVIÇO:")
        print(f"  Nome identificado: {token_info.get('name', 'Unknown')}")
        print(f"  Tipo: {token_info.get('type', 'unknown')}")
        print(f"  Confiança: {token_info.get('confidence', 0):.1%}")
        print(f"  Fonte: {token_info.get('source', 'none')}")

        if token_info.get('name', 'Unknown') != 'Unknown':
            print("✅ NOSSO SERVIÇO ESTÁ USANDO DADOS REAIS!")
        else:
            print("❌ NOSSO SERVIÇO NÃO CONSEGUIU IDENTIFICAR O TOKEN")

        # Fechar cliente
        await enrichment_service.close()

    except Exception as e:
        print(f"❌ ERRO DURANTE TESTE: {e}")
        import traceback
        traceback.print_exc()

    finally:
        await client.aclose()

    print("\n" + "=" * 70)
    print("🎯 CONCLUSÃO:")
    print("Se você viu dados reais acima (nome, símbolo, preços), então")
    print("o sistema ESTÁ fazendo chamadas reais para as APIs externas!")
    print("=" * 70)


if __name__ == "__main__":
    asyncio.run(test_real_apis())
