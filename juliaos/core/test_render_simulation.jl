# Script para simular exatamente o ambiente do Render
# Este script reproduz as mesmas condições que causam falhas no container

println("🧪 SIMULANDO AMBIENTE RENDER...")
println("=" ^ 50)

# Limpar variáveis de ambiente para simular container limpo
env_vars_to_remove = ["OPENAI_API_KEY", "HOST_URL", "GEMINI_API_KEY", "PYTHON", "CONDA_PREFIX"]

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

println("\n📦 Simulando comandos do Render...")
println("Command: using Pkg")
using Pkg

println("Command: Pkg.activate(\".\")")
Pkg.activate(".")

println("Command: Pkg.instantiate()")
Pkg.instantiate()

println("Command: Pkg.precompile()")
Pkg.precompile()

println("\n✅ TESTE RENDER SIMULADO COMPLETO!")
println("Se chegou até aqui, o deploy no Render deve funcionar! 🚀")
