"""
Teste FASE 2 - Integração Python ↔ JuliaOS
============================================

Script para testar se as modificações da FASE 2 estão funcionando:
1. Conexão JuliaOS
2. Criação de Agents
3. Verificação de Tools e Strategies
4. DetectiveSquad integration
"""

import asyncio
import os
import sys

# Adicionar o diretório backend ao path
backend_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, backend_dir)

async def test_juliaos_connection():
    """Teste 1: Conexão básica com JuliaOS"""
    print("🔗 Teste 1: Conexão JuliaOS")
    try:
        from services.juliaos_service import get_juliaos_service

        service = get_juliaos_service()
        health = await service.health_check()

        if health:
            print("✅ JuliaOS conexão OK")
            return True
        else:
            print("❌ JuliaOS não está respondendo")
            return False

    except Exception as e:
        print(f"❌ Erro na conexão: {e}")
        return False

async def test_juliaos_tools_and_strategies():
    """Teste 2: Verificar tools e strategies registradas"""
    print("\n📊 Teste 2: Tools e Strategies")
    try:
        from services.juliaos_service import get_juliaos_service

        service = get_juliaos_service()

        # Testar tools
        tools = await service.list_tools()
        print(f"📋 Tools disponíveis: {len(tools)}")

        ghost_tools = [t for t in tools if 'ghost' in t.name.lower() or 'wallet' in t.name.lower()]
        print(f"🎯 Ghost Wallet Hunter tools: {len(ghost_tools)}")

        # Testar strategies
        strategies = await service.list_strategies()
        print(f"🧠 Strategies disponíveis: {len(strategies)}")

        detective_strategies = [s for s in strategies if 'detective' in s.name.lower()]
        print(f"🕵️ Detective strategies: {len(detective_strategies)}")

        return len(tools) > 0 and len(strategies) > 0

    except Exception as e:
        print(f"❌ Erro ao listar tools/strategies: {e}")
        return False

async def test_detective_squad_creation():
    """Teste 3: Criação de Detective Squad com JuliaOS"""
    print("\n🕵️ Teste 3: Detective Squad Creation")
    try:
        # Teste simplificado - apenas verificar se conseguimos importar e conectar
        print("📦 Tentando importar dependências...")

        # Testar imports básicos
        from services.juliaos_service import get_juliaos_service
        from services.juliaos_detective_integration import get_juliaos_detective_integration

        print("✅ Imports básicos OK")

        # Testar se conseguimos criar instância do serviço
        service = get_juliaos_service()
        print("✅ JuliaOS service criado")

        # Testar se conseguimos obter integration
        integration = await get_juliaos_detective_integration()
        print("✅ Detective integration criado")

        # Testar health check da integration
        health_status = await integration.health_check()
        available = health_status.get("available", False)

        print(f"🔧 Integration health: {'✅ OK' if available else '❌ FAILED'}")

        # Se disponível, testar criação de agent
        if available:
            print("🎯 Testando criação de agent...")

            # Tentar criar um agent de teste
            test_agent = await service.create_detective_agent(
                agent_id="test_ghost_detective",
                name="Test Detective",
                description="Test detective agent for FASE 2",
                strategy_name="detective_investigation",
                tools=["analyze_wallet", "llm_chat"]
            )

            if test_agent:
                print(f"✅ Agent teste criado: {test_agent.name}")

                # Limpar agent de teste
                await service.delete_agent("test_ghost_detective")
                print("🧹 Agent teste removido")

                return True
            else:
                print("⚠️ Falha ao criar agent teste")
                return False
        else:
            print("⚠️ Integration não disponível")
            return False

    except Exception as e:
        print(f"❌ Erro no Detective Squad: {e}")
        return False

async def test_agent_verification():
    """Teste 4: Verificar se agents estão funcionando"""
    print("\n🔍 Teste 4: Verificação de Agents")
    try:
        from services.juliaos_service import get_juliaos_service

        service = get_juliaos_service()
        agents = await service.list_agents()

        print(f"🤖 Total de agents: {len(agents)}")

        ghost_agents = [a for a in agents if a.id.startswith("ghost_")]
        print(f"👻 Ghost Wallet Hunter agents: {len(ghost_agents)}")

        if ghost_agents:
            print("🎯 Agents Ghost encontrados:")
            for agent in ghost_agents:
                print(f"  • {agent.id}: {agent.name} [{agent.state}]")

        return len(ghost_agents) > 0

    except Exception as e:
        print(f"❌ Erro na verificação de agents: {e}")
        return False

async def main():
    """Executar todos os testes da FASE 2"""
    print("🧪 TESTE INTEGRAÇÃO FASE 2 - Python ↔ JuliaOS")
    print("=" * 60)

    results = []

    # Teste 1: Conexão
    results.append(await test_juliaos_connection())

    # Teste 2: Tools e Strategies
    results.append(await test_juliaos_tools_and_strategies())

    # Teste 3: Detective Squad
    results.append(await test_detective_squad_creation())

    # Teste 4: Verificação de Agents
    results.append(await test_agent_verification())

    # Resultado final
    print("\n" + "=" * 60)
    success_count = sum(results)
    total_tests = len(results)

    print(f"🎯 RESULTADO: {success_count}/{total_tests} testes passaram")

    if success_count == total_tests:
        print("🎉 FASE 2 - INTEGRAÇÃO COMPLETA E FUNCIONANDO!")
    elif success_count >= 2:
        print("⚠️ FASE 2 - INTEGRAÇÃO PARCIAL (alguns problemas)")
    else:
        print("❌ FASE 2 - INTEGRAÇÃO COM FALHAS CRÍTICAS")

    return success_count >= 2

if __name__ == "__main__":
    try:
        result = asyncio.run(main())
        exit_code = 0 if result else 1
        print(f"\n🏁 Script finalizado (exit code: {exit_code})")
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n⚠️ Teste interrompido pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Erro crítico: {e}")
        sys.exit(1)
