#!/usr/bin/env julia
# render_compatibility_check.jl
# Script específico para verificar compatibilidade com o ambiente Render

using Dates  # Necessário para now()

println("🔍 VERIFICAÇÃO DE COMPATIBILIDADE RENDER")
println("=" ^ 50)

# 1. Verificar limitações de recursos do Render
println("\n💾 1. VERIFICANDO LIMITAÇÕES DE RECURSOS...")

# Verificar Julia version
println("📦 Julia version: $(VERSION)")
if VERSION < v"1.8"
    println("⚠️  AVISO: Julia version antiga, recomendado >= 1.8")
else
    println("✅ Julia version compatível")
end

# Verificar memória disponível
try
    total_memory = Sys.total_memory()
    free_memory = Sys.free_memory()
    println("💾 Memória total: $(round(total_memory/1024^3, digits=2)) GB")
    println("💾 Memória livre: $(round(free_memory/1024^3, digits=2)) GB")

    if free_memory < 500_000_000  # 500MB
        println("⚠️  AVISO: Pouca memória livre (< 500MB)")
    else
        println("✅ Memória suficiente")
    end
catch
    println("⚠️  Não foi possível verificar memória")
end

# 2. Verificar problemas comuns do Render
println("\n🚨 2. VERIFICANDO PROBLEMAS COMUNS DO RENDER...")

# Problema 1: Port binding
port = get(ENV, "PORT", "10000")
println("🌐 Port configurado: $port")
try
    port_num = parse(Int, port)
    if port_num < 1024 || port_num > 65535
        println("❌ Port inválido: $port_num")
    else
        println("✅ Port válido")
    end
catch
    println("❌ Port não é um número válido: $port")
end

# Problema 2: Timeout de build
println("⏰ Verificando tempo de build...")
build_start = time()

# Simular operações que podem causar timeout
try
    using Pkg
    Pkg.status()
    build_time = time() - build_start
    println("⏱️  Tempo de operações básicas: $(round(build_time, digits=2))s")

    if build_time > 300  # 5 minutos
        println("⚠️  AVISO: Operações muito lentas (> 5min)")
    else
        println("✅ Tempo de build adequado")
    end
catch e
    println("❌ Erro nas operações básicas: $e")
end

# Problema 3: Permissões de arquivo
println("📁 Verificando permissões de arquivo...")
try
    test_file = "test_permissions.txt"
    write(test_file, "test")
    content = read(test_file, String)
    rm(test_file)
    println("✅ Permissões de escrita OK")
catch e
    println("❌ Problemas de permissão: $e")
end

# 3. Verificar dependências específicas do Render
println("\n📦 3. VERIFICANDO DEPENDÊNCIAS ESPECÍFICAS...")

render_critical_packages = [
    "HTTP",
    "JSON3",
    "Sockets",
    "Dates",
    "UUIDs",
    "Logging"
]

for pkg in render_critical_packages
    try
        eval(Meta.parse("using $pkg"))
        println("✅ $pkg: OK")
    catch e
        println("❌ $pkg: ERRO - $e")
        println("🚨 CRÍTICO: Este erro impedirá o deploy!")
    end
end

# 4. Verificar arquivo de configuração específico do Render
println("\n⚙️  4. VERIFICANDO CONFIGURAÇÕES RENDER...")

# Verificar render.yaml
if isfile("../../render.yaml")
    println("✅ render.yaml encontrado")
    try
        render_content = read("../../render.yaml", String)
        if contains(render_content, "buildCommand")
            println("✅ buildCommand configurado")
        else
            println("⚠️  buildCommand não encontrado")
        end

        if contains(render_content, "startCommand")
            println("✅ startCommand configurado")
        else
            println("❌ startCommand não encontrado - CRÍTICO!")
        end
    catch e
        println("❌ Erro ao ler render.yaml: $e")
    end
else
    println("❌ render.yaml não encontrado")
end

# 5. Simular cenários de falha do Render
println("\n💥 5. SIMULANDO CENÁRIOS DE FALHA...")

# Cenário 1: Out of Memory
println("🧠 Testando uso de memória...")
try
    # Criar array grande para testar memória
    test_array = zeros(1000, 1000)
    println("✅ Teste de memória OK")
catch e
    println("❌ Falha de memória: $e")
end

# Cenário 2: Network timeout
println("🌐 Testando timeout de rede...")
try
    using HTTP
    # Teste rápido de HTTP (sem fazer request real)
    router = HTTP.Router()
    println("✅ HTTP router criado")
catch e
    println("❌ Falha na configuração HTTP: $e")
end

# Cenário 3: File system limits
println("📁 Testando limites do sistema de arquivos...")
try
    temp_files = []
    for i in 1:10
        filename = "temp_$i.txt"
        write(filename, "test data $i")
        push!(temp_files, filename)
    end

    # Cleanup
    for file in temp_files
        rm(file)
    end
    println("✅ Sistema de arquivos OK")
catch e
    println("❌ Problemas no sistema de arquivos: $e")
end

# RELATÓRIO FINAL
println("\n" * "=" ^ 50)
println("📊 RELATÓRIO DE COMPATIBILIDADE RENDER")
println("=" ^ 50)
println("🕐 Verificação realizada em: $(now())")
println("")
println("🎯 RESULTADO GERAL:")
println("   - Se todos os itens acima estão ✅, o deploy deve funcionar")
println("   - Se há ❌ críticos, corrija antes do deploy")
println("   - Se há ⚠️  avisos, monitore após o deploy")
println("")
println("🚀 DICAS PARA DEPLOY NO RENDER:")
println("   1. Mantenha o build time < 10 minutos")
println("   2. Use Julia 1.8+ para melhor performance")
println("   3. Configure PORT=10000 nas variáveis de ambiente")
println("   4. Monitore uso de memória")
println("   5. Teste este script antes de cada deploy")
println("")
println("=" ^ 50)
println("✅ VERIFICAÇÃO CONCLUÍDA")
println("=" ^ 50)
