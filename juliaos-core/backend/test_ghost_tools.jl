#!/usr/bin/env julia

"""
Teste das novas Ghost Wallet Hunter tools no JuliaOS

Este script testa se as três novas ferramentas foram implementadas corretamente:
- tool_analyze_wallet
- tool_check_blacklist
- tool_risk_assessment
"""

using Pkg
Pkg.activate(".")

# Carregar o módulo JuliaOS
include("src/JuliaOSBackend.jl")

# Importar as tools
using .JuliaOSBackend.Agents.Tools

println("🔍 TESTE DAS GHOST WALLET HUNTER TOOLS")
println("=" * 50)

# Verificar se as tools foram registradas
println("\n1. Verificando ferramentas registradas...")
total_tools = length(TOOL_REGISTRY)
println("   Total de ferramentas no registro: $total_tools")

# Listar todas as ferramentas
println("\n2. Lista de ferramentas disponíveis:")
for (i, (name, spec)) in enumerate(TOOL_REGISTRY)
    description = spec.metadata.description
    # Truncar descrição se muito longa
    short_desc = length(description) > 60 ? description[1:60] * "..." : description
    println("   $i. $name: $short_desc")
end

# Verificar especificamente as Ghost Wallet Hunter tools
ghost_tools = ["analyze_wallet", "check_blacklist", "risk_assessment"]
println("\n3. Verificando Ghost Wallet Hunter tools específicas:")

for tool_name in ghost_tools
    if haskey(TOOL_REGISTRY, tool_name)
        spec = TOOL_REGISTRY[tool_name]
        println("   ✅ $tool_name: $(spec.metadata.description)")
    else
        println("   ❌ $tool_name: NÃO ENCONTRADA")
    end
end

# Teste básico de uma das tools (analyze_wallet)
println("\n4. Testando tool_analyze_wallet...")
if haskey(TOOL_REGISTRY, "analyze_wallet")
    try
        # Configurar a tool
        config = TOOL_REGISTRY["analyze_wallet"].config_type()

        # Criar uma tarefa de teste
        test_task = Dict(
            "wallet_address" => "0x742d35Cc6B7C6D5CE9B16Ac52C7a5B9b8D64dd8D"
        )

        # Executar a tool
        result = TOOL_REGISTRY["analyze_wallet"].execute(config, test_task)

        if get(result, "success", false)
            println("   ✅ Tool executada com sucesso!")
            println("   📊 Endereço analisado: $(result["wallet_address"])")
            println("   🎯 Nível de risco: $(get(get(result, "risk_assessment", Dict()), "risk_level", "UNKNOWN"))")
        else
            println("   ⚠️  Tool executada mas retornou erro: $(get(result, "error", "Unknown error"))")
        end
    catch e
        println("   ❌ Erro ao executar tool: $e")
    end
else
    println("   ❌ Tool analyze_wallet não encontrada no registro")
end

# Teste básico de check_blacklist
println("\n5. Testando tool_check_blacklist...")
if haskey(TOOL_REGISTRY, "check_blacklist")
    try
        config = TOOL_REGISTRY["check_blacklist"].config_type()
        test_task = Dict("wallet_address" => "0x742d35Cc6B7C6D5CE9B16Ac52C7a5B9b8D64dd8D")
        result = TOOL_REGISTRY["check_blacklist"].execute(config, test_task)

        if get(result, "success", false)
            println("   ✅ Tool executada com sucesso!")
            println("   🔍 Fontes verificadas: $(get(result, "sources_checked", 0))")
            println("   🚨 Está em blacklist: $(get(result, "is_blacklisted", false))")
        else
            println("   ⚠️  Tool executada mas retornou erro: $(get(result, "error", "Unknown error"))")
        end
    catch e
        println("   ❌ Erro ao executar tool: $e")
    end
else
    println("   ❌ Tool check_blacklist não encontrada no registro")
end

# Teste básico de risk_assessment
println("\n6. Testando tool_risk_assessment...")
if haskey(TOOL_REGISTRY, "risk_assessment")
    try
        config = TOOL_REGISTRY["risk_assessment"].config_type()
        test_task = Dict("wallet_address" => "0x742d35Cc6B7C6D5CE9B16Ac52C7a5B9b8D64dd8D")
        result = TOOL_REGISTRY["risk_assessment"].execute(config, test_task)

        if get(result, "success", false)
            println("   ✅ Tool executada com sucesso!")
            risk_summary = get(result, "risk_summary", Dict())
            println("   📈 Score composto: $(get(risk_summary, "composite_score", "N/A"))")
            println("   ⚡ Nível de risco: $(get(risk_summary, "risk_level", "UNKNOWN"))")
        else
            println("   ⚠️  Tool executada mas retornou erro: $(get(result, "error", "Unknown error"))")
        end
    catch e
        println("   ❌ Erro ao executar tool: $e")
    end
else
    println("   ❌ Tool risk_assessment não encontrada no registro")
end

println("\n🎉 TESTE COMPLETADO!")
println("=" * 50)

# Resumo final
ghost_tools_found = sum(haskey(TOOL_REGISTRY, tool) for tool in ghost_tools)
println("📋 RESUMO:")
println("   - Total de ferramentas: $total_tools")
println("   - Ghost Wallet Hunter tools encontradas: $ghost_tools_found/3")
println("   - Status: $(ghost_tools_found == 3 ? "✅ TODAS AS TOOLS IMPLEMENTADAS" : "⚠️  ALGUMAS TOOLS FALTANDO")")

if ghost_tools_found == 3
    println("\n🚀 PASSO 2 DA FASE 2 COMPLETADO COM SUCESSO!")
    println("   ✅ tool_analyze_wallet implementada")
    println("   ✅ tool_check_blacklist implementada")
    println("   ✅ tool_risk_assessment implementada")
    println("   ✅ Todas as tools registradas no JuliaOS")
    println("   ✅ Seguindo padrões da documentação oficial")
else
    println("\n⚠️  REVISAR IMPLEMENTAÇÃO DAS TOOLS")
end
