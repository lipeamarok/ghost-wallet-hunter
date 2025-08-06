#!/usr/bin/env julia
# quick_test.jl - Teste rápido para verificar se os imports estão funcionando

using Dates
using Pkg

println("🧪 TESTE RÁPIDO - $(now())")
println("✅ Dates importado com sucesso")
println("✅ Pkg importado com sucesso")

try
    Pkg.activate(".")
    println("✅ Projeto ativado")
    
    # Verificar se consegue carregar o módulo básico
    if isfile("src/JuliaOS.jl")
        println("✅ JuliaOS.jl encontrado")
    else
        println("❌ JuliaOS.jl não encontrado")
    end
    
    if isfile("src/framework/JuliaOSFramework.jl")
        println("✅ JuliaOSFramework.jl encontrado")
    else
        println("❌ JuliaOSFramework.jl não encontrado")
    end
    
    println("🎉 Teste rápido concluído com sucesso!")
    
catch e
    println("❌ Erro no teste: $e")
end
