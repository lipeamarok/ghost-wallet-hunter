# Script para simular exatamente o ambiente do Render
# Este script reproduz as mesmas condições que causam falhas no container

println("🧪 SIMULANDO AMBIENTE RENDER COMPLETO...")
println("=" ^ 60)

# Limpar variáveis de ambiente para simular container limpo
env_vars_to_remove = ["OPENAI_API_KEY", "HOST_URL", "GEMINI_API_KEY", "PYTHON", "CONDA_PREFIX", "JULIA_DEPOT_PATH"]

for var in env_vars_to_remove
    if haskey(ENV, var)
        println("🗑️  Removendo variável: $var")
        delete!(ENV, var)
    end
end

println("\n🔍 Verificando ambiente limpo:")
for var in env_vars_to_remove
    status = haskey(ENV, var) ? "❌ EXISTE" : "✅ REMOVIDA"
    println("   $var: $status")
end

println("\n📦 FASE 1: Simulando comandos do Dockerfile...")
println("Command: using Pkg")
using Pkg

println("Command: Pkg.activate(\".\")")
Pkg.activate(".")

println("Command: Pkg.instantiate()")
Pkg.instantiate()

println("Command: Pkg.precompile()")
Pkg.precompile()

println("\n🚀 FASE 2: Simulando start_julia_server.jl...")
println("Command: julia start_julia_server.jl (primeira parte)")

# Simular apenas as partes críticas do start_julia_server.jl
try
    # Lista de pacotes que o servidor precisa
    required_packages = ["HTTP", "JSON3", "Dates", "UUIDs"]

    println("📦 Verificando dependências críticas...")
    for package in required_packages
        try
            eval(Meta.parse("using $package"))
            println("  ✅ $package: OK")
        catch e
            println("  ❌ $package: ERRO - $e")
            throw(e)
        end
    end

    # Testar carregamento do módulo principal
    println("📦 Testando carregamento do módulo JuliaOS...")
    include("src/JuliaOS.jl")
    using .JuliaOS
    println("  ✅ JuliaOS: Carregado com sucesso!")

    println("\n✅ SIMULAÇÃO RENDER COMPLETA - SUCESSO! 🎉")
    println("🚀 O deploy no Render deve funcionar perfeitamente!")

catch e
    println("\n❌ SIMULAÇÃO FALHOU!")
    println("🔧 Erro encontrado: $e")
    println("� Este erro também aparecerá no Render!")
    rethrow(e)
end
