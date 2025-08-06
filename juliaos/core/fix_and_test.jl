#!/usr/bin/env julia

@info "🔧 INSTALANDO DotEnv rapidamente..."

using Pkg
Pkg.add("DotEnv")

@info "✅ DotEnv instalado!"

@info "🚀 TESTANDO FRAMEWORK..."
try
    include("src/framework/JuliaOSFramework.jl")
    @info "✅ Framework carregou!"

    using .JuliaOSFramework
    @info "✅ Using funcionou!"

    result = JuliaOSFramework.initialize()
    @info "✅ Initialize: $result"

catch e
    @error "💥 ERRO: $e"
end
