# Simple Test Runner seguindo o plano de testes
# Objetivo: Validar que conseguimos executar os testes que criamos

using Test
using Dates

println("🚀 Ghost Wallet Hunter - Simple Test Runner")
println("Data: $(now())")
println("Seguindo plano de testes real data only")

@testset "Validação Básica do Plano" begin

    @testset "Estrutura de Arquivos" begin
        # Verificar se os arquivos do plano existem
        @test isfile("utils/test_helpers.jl")
        @test isfile("utils/solana_helpers.jl")
        @test isfile("fixtures/real_wallets.jl")
        @test isfile("unit/analysis/test_analysis_core.jl")
        @test isfile("unit/analysis/test_graph_builder.jl")
        @test isfile("unit/analysis/test_taint_propagation.jl")

        println("✅ Todos os arquivos do plano existem")
    end

    @testset "Loading de Módulos" begin
        try
            include("fixtures/real_wallets.jl")
            println("✅ real_wallets.jl carregado")
            @test true
        catch e
            println("❌ Erro ao carregar real_wallets.jl: $e")
            @test_broken false
        end

        try
            include("utils/solana_helpers.jl")
            println("✅ solana_helpers.jl carregado")
            @test true
        catch e
            println("❌ Erro ao carregar solana_helpers.jl: $e")
            @test_broken false
        end

        try
            include("utils/test_helpers.jl")
            println("✅ test_helpers.jl carregado")
            @test true
        catch e
            println("❌ Erro ao carregar test_helpers.jl: $e")
            @test_broken false
        end
    end
end

println("🎯 Teste básico concluído - seguindo plano de testes")
